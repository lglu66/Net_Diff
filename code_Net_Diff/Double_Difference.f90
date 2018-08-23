! ============= Double Difference ===============
! Purpose:
!        Form double difference equation for each station
! Input:
!         SD                   station difference structure
!  Output:
!         DD                  double difference structure
!
! Written by: Yize Zhang
! ==========================================

subroutine Double_Difference(SD, DD, RefSat)
use MOD_SD
use MOD_DD
use MOD_FileID
use MOD_VAR
use MOD_CycleSlip
use MOD_GLO_Fre
implicit none
    type(type_SD)  :: SD
    type(type_DD)  :: DD
    integer :: RefSat(5)
    ! Local variables
    integer :: N, N0
    integer(1) :: i, j, sys, L_ref(5), freq

    DD%PRN=0;      DD%A=0.d0
    DD%Q=0.d0;     DD%P=0.d0;     DD%Ele=0.d0
    DD%P1=0.d0;    DD%P2=0.d0
    DD%L1=0.d0;    DD%L2=0.d0
    DD%WL=0.d0;  DD%W4=0.d0
    DD%EWL=0.d0;DD%EWL_amb=99.d0; DD%WL_amb=99.d0

    ! find the order of the reference satellite
    do i=1,SD%PRNS
        do sys=1,5
            if (SD%PRN(i)==RefSat(sys)) then
                L_ref(sys)=i
                exit
            end if
        end do
    end do

    ! ******Start to do double difference *******
    N=0
    N0=1
    do sys=1,5
        if (sys==1) then
            if ((.not.(SystemUsed(sys))) .and. (.not.(SystemUsed(5))) ) cycle  ! If no GPS and QZSS
        elseif (sys==5) then
            if (.not.(SystemUsed(6))) cycle   ! If no IRNSS
        else
            if (.not.(SystemUsed(sys))) cycle
        end if
        if (RefSat(sys)==0) cycle
        do j=1,SD%PRNS   ! in the other satellites
            if (SD%Sys(j)/=sys) cycle
            if (SD%PRN(j)==RefSat(sys)) cycle
            N                        =    N+1
            DD%Sys(N)   =    Sys
            DD%System(N)       =    SD%System(j)
            DD%PRN(N)       =    SD%PRN(j)
            DD%PRN_S(N)       =    SD%PRN_S(j)
            DD%Ele(DD%PRN(N))       =    SD%Ele(j)
            DD%Q(N,N)       =    SD%Q(j)
            if (sys==2 .and. GloParaNum>0) then  ! If GLONASS
                SD%A(L_ref(sys),ParaNum-GloParaNum+1:ParaNum)=0.d0  ! Set the reference GLONASS satellite IFB as zero
            end if
            DD%A(N, :)    =    SD%A(j,:) - SD%A(L_ref(sys),:)
            DD%corr(N)       =    SD%corr(j)-SD%corr(L_ref(sys))
            DD%s(N)           =    SD%s(j)-SD%s(L_ref(sys))
            if ((SD%P1(L_ref(sys))/=0.d0) .and. (SD%P1(j)/=0.d0)) then
                DD%P1(N)=SD%P1(j)-SD%P1(L_ref(sys))
            end if
            if ((SD%P2(L_ref(sys))/=0.d0) .and. (SD%P2(j)/=0.d0)) then
                DD%P2(N)=SD%P2(j)-SD%P2(L_ref(sys))
            end if
            if (DD%P1(N)==0.d0 .and. DD%P2(N)==0.d0) then
                N=N-1  ! If no DD pseudo-range observation, cycle
                cycle
            end if
            if ((SD%L1(L_ref(sys))/=0.d0) .and. (SD%L1(j)/=0.d0) .and. ((a1/=0.d0) .or. (b1/=0.d0)) ) then
                DD%L1(N)=SD%L1(j)-SD%L1(L_ref(sys))
            end if
            if ((SD%L2(L_ref(sys))/=0.d0) .and. (SD%L2(j)/=0.d0) .and. ((a2/=0.d0) .or. (b2/=0.d0)) ) then
                DD%L2(N)=SD%L2(j)-SD%L2(L_ref(sys))
            end if
            if (sys==1) then   ! GPS/QZSS
                f1=10.23d6*154d0
                f2=10.23d6*120d0
                f3=10.23d6*115d0
            elseif (sys==2) then   ! GLONASS
                freq=Fre_Chann(DD%PRN(N)-GNum)
                f1=(1602.0d0+freq*0.5625d0)*1.0D6   ! f1=(1602.0d0+K*0.5625d0)*1.0d6
                f2=(1246.0d0+freq*0.4375d0)*1.0D6
            elseif  (sys==3) then   ! COMPASS
                if (freq_comb=='L1L2') then
                    f1=10.23d6*152.6d0
                    f2=10.23d6*118.0d0
                    f3=10.23d6*124.0d0
                elseif (freq_comb=='L1L3') then
                    f1=10.23d6*152.6d0
                    f2=10.23d6*124.0d0
                elseif (freq_comb=='L2L3') then
                    f1=10.23d6*118.0d0
                    f2=10.23d6*124.0d0
                end if
            elseif  (sys==4) then ! GALILEO
                if (freq_comb=='L1L2') then   ! E1 E5a
                    f1=10.23d6*154.d0
                    f2=10.23d6*115.0d0
                    f3=10.23d6*118.0d0
                elseif (freq_comb=='L1L3') then   ! E1 E5b
                    f1=10.23d6*154.d0
                    f2=10.23d6*118.d0
                elseif (freq_comb=='L2L3') then   ! E5a E5b
                    f1=10.23d6*115.0d0
                    f2=10.23d6*118.0d0
                end if
            elseif (sys==5) then   ! IRNSS
                f1=10.23d6*115.d0
                f2=10.23d6*243.6d0
            else
                cycle
            end if
            if ((SD%WL(L_ref(sys))/=0.d0) .and. (SD%WL(j)/=0.d0)) then
                DD%WL(N)=SD%WL(j)-SD%WL(L_ref(sys))
            end if
            if ((SD%WL_amb(RefSat(sys))/=99.d0) .and. (SD%WL_amb(DD%PRN(N))/=99.d0)) then  ! Just for test, not good due to the code multipath
                ! Wide lane ambiguity can be used to constraint L1&L2 observation
                DD%WL_amb(DD%PRN(N))=SD%WL_amb(DD%PRN(N))-SD%WL_amb(RefSat(sys))  ! Wide Lane ambiguity, in cycle
                if (abs(DD%WL_amb(DD%PRN(N))-real(nint(DD%WL_amb(DD%PRN(N)))))<0.3d0) then  ! Only when the fraction part is less than 0.3cycle
                    DD%WL_amb(DD%PRN(N))=real(nint(DD%WL_amb(DD%PRN(N)))) ! After double differece, DCB is eliminated theoretically, round to integer value
                end if
            end if
            if ((SD%W4(L_ref(sys))/=0.d0) .and. (SD%W4(j)/=0.d0)) then
                DD%W4(N)=SD%W4(j)-SD%W4(L_ref(sys))
            end if
            if ((SD%EWL(L_ref(sys))/=0.d0) .and. (SD%EWL(j)/=0.d0)) then
                DD%EWL_amb(DD%PRN(N))=SD%EWL_amb(j)-SD%EWL_amb(L_ref(sys))
                DD%EWL_amb(DD%PRN(N))=real(nint(DD%EWL_amb(DD%PRN(N))))  ! After double differece, DCB is eliminated, round to integer value
                DD%EWL(N)=SD%EWL(j)-SD%EWL(L_ref(sys)) - DD%EWL_amb(DD%PRN(N))*c/(f2-f3)
            end if
            write(unit=LogID,fmt='(A6,1X,A1,I2,2F8.3,4F13.3)') '==DD', DD%System(N), DD%PRN_S(N),DD%P1(N),DD%P2(N), &
                            DD%L1(N)/c*f1,DD%L2(N)/c*f2,DD%WL(N)/c*(a1*f1+a2*f2),DD%W4(N)/c*(b1*f1+b2*f2)
        end do   ! do j=1,SD%PRNS   ! in the other satellites
        DD%Q(N0:N,N0:N)=DD%Q(N0:N,N0:N)+SD%Q(L_ref(sys))
        N0=N+1
    end do
    DD%PRNS =  N
    DD%week =  SD%week
    DD%sow   =  SD%sow    
    call InvSqrt(DD%Q(1:N,1:N), N, DD%P(1:N,1:N))

    return
end subroutine