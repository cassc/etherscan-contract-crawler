pragma solidity 0.5.17;

import "./PeakDeFiStorage.sol";

contract PeakDeFiLogic3 is
    PeakDeFiStorage,
    Utils(address(0), address(0), address(0))
{
    /**
     * @notice Passes if the fund has not finalized the next smart contract to upgrade to
     */
    modifier notReadyForUpgrade {
        require(hasFinalizedNextVersion == false);
        _;
    }

    /**
     * @notice Executes function only during the given cycle phase.
     * @param phase the cycle phase during which the function may be called
     */
    modifier during(CyclePhase phase) {
        require(cyclePhase == phase);
        if (cyclePhase == CyclePhase.Intermission) {
            require(isInitialized);
        }
        _;
    }

    /**
     * Next phase transition handler
     * @notice Moves the fund to the next phase in the investment cycle.
     */
    function nextPhase() public nonReentrant {
        require(
            now >= startTimeOfCyclePhase.add(phaseLengths[uint256(cyclePhase)])
        );

        if (isInitialized == false) {
            // first cycle of this smart contract deployment
            // check whether ready for starting cycle
            isInitialized = true;
            require(proxyAddr != address(0)); // has initialized proxy
            require(proxy.peakdefiFundAddress() == address(this)); // upgrade complete
            require(hasInitializedTokenListings); // has initialized token listings

            // execute initialization function
            __init();

            require(
                previousVersion == address(0) ||
                    (previousVersion != address(0) &&
                        getBalance(usdc, address(this)) > 0)
            ); // has transfered assets from previous version
        } else {
            // normal phase changing
            if (cyclePhase == CyclePhase.Intermission) {
                require(hasFinalizedNextVersion == false); // Shouldn't progress to next phase if upgrading

                // Update total funds at management phase's beginning
                totalFundsAtManagePhaseStart = totalFundsInUSDC;

                // reset number of managers onboarded
                managersOnboardedThisCycle = 0;
            } else if (cyclePhase == CyclePhase.Manage) {
                // Burn any RepToken left in PeakDeFiFund's account
                require(
                    cToken.destroyTokens(
                        address(this),
                        cToken.balanceOf(address(this))
                    )
                );

                // Pay out commissions and fees
                uint256 profit = 0;


                    uint256 usdcBalanceAtManagePhaseStart
                 = totalFundsAtManagePhaseStart.add(totalCommissionLeft);
                if (
                    getBalance(usdc, address(this)) >
                    usdcBalanceAtManagePhaseStart
                ) {
                    profit = getBalance(usdc, address(this)).sub(
                        usdcBalanceAtManagePhaseStart
                    );
                }

                totalFundsInUSDC = getBalance(usdc, address(this))
                    .sub(totalCommissionLeft)
                    .sub(peakReferralTotalCommissionLeft);

                // Calculate manager commissions
                uint256 commissionThisCycle = COMMISSION_RATE
                    .mul(profit)
                    .add(ASSET_FEE_RATE.mul(totalFundsInUSDC))
                    .div(PRECISION);
                _totalCommissionOfCycle[cycleNumber] = totalCommissionOfCycle(
                    cycleNumber
                )
                    .add(commissionThisCycle); // account for penalties
                totalCommissionLeft = totalCommissionLeft.add(
                    commissionThisCycle
                );

                // Calculate referrer commissions
                uint256 peakReferralCommissionThisCycle = PEAK_COMMISSION_RATE
                    .mul(profit)
                    .mul(peakReferralToken.totalSupply())
                    .div(sToken.totalSupply())
                    .div(PRECISION);
                _peakReferralTotalCommissionOfCycle[cycleNumber] = peakReferralTotalCommissionOfCycle(
                    cycleNumber
                )
                    .add(peakReferralCommissionThisCycle);
                peakReferralTotalCommissionLeft = peakReferralTotalCommissionLeft
                    .add(peakReferralCommissionThisCycle);

                totalFundsInUSDC = getBalance(usdc, address(this))
                    .sub(totalCommissionLeft)
                    .sub(peakReferralTotalCommissionLeft);

                // Give the developer PeakDeFi shares inflation funding
                uint256 devFunding = devFundingRate
                    .mul(sToken.totalSupply())
                    .div(PRECISION);
                require(sToken.generateTokens(devFundingAccount, devFunding));

                // Emit event
                emit TotalCommissionPaid(
                    cycleNumber,
                    totalCommissionOfCycle(cycleNumber)
                );
                emit PeakReferralTotalCommissionPaid(
                    cycleNumber,
                    peakReferralTotalCommissionOfCycle(cycleNumber)
                );

                _managePhaseEndBlock[cycleNumber] = block.number;

                // Clear/update upgrade related data
                if (nextVersion == address(this)) {
                    // The developer proposed a candidate, but the managers decide to not upgrade at all
                    // Reset upgrade process
                    delete nextVersion;
                    delete hasFinalizedNextVersion;
                }
                if (nextVersion != address(0)) {
                    hasFinalizedNextVersion = true;
                    emit FinalizedNextVersion(cycleNumber, nextVersion);
                }

                // Start new cycle
                cycleNumber = cycleNumber.add(1);
            }

            cyclePhase = CyclePhase(addmod(uint256(cyclePhase), 1, 2));
        }

        startTimeOfCyclePhase = now;

        // Reward caller if they're a manager
        if (cToken.balanceOf(msg.sender) > 0) {
            require(cToken.generateTokens(msg.sender, NEXT_PHASE_REWARD));
        }

        emit ChangedPhase(
            cycleNumber,
            uint256(cyclePhase),
            now,
            totalFundsInUSDC
        );
    }

    /**
     * @notice Initializes several important variables after smart contract upgrade
     */
    function __init() internal {
        _managePhaseEndBlock[cycleNumber.sub(1)] = block.number;

        // load values from previous version
        totalCommissionLeft = previousVersion == address(0)
            ? 0
            : PeakDeFiStorage(previousVersion).totalCommissionLeft();
        totalFundsInUSDC = getBalance(usdc, address(this)).sub(
            totalCommissionLeft
        );
    }

    /**
     * Upgrading functions
     */

    /**
     * @notice Allows the developer to propose a candidate smart contract for the fund to upgrade to.
     *          The developer may change the candidate during the Intermission phase.
     * @param _candidate the address of the candidate smart contract
     * @return True if successfully changed candidate, false otherwise.
     */
    function developerInitiateUpgrade(address payable _candidate)
        public
        onlyOwner
        notReadyForUpgrade
        during(CyclePhase.Intermission)
        nonReentrant
        returns (bool _success)
    {
        if (_candidate == address(0) || _candidate == address(this)) {
            return false;
        }
        nextVersion = _candidate;
        emit DeveloperInitiatedUpgrade(cycleNumber, _candidate);
        return true;
    }

    /**
        Commission functions
     */

    /**
     * @notice Returns the commission balance of `_manager`
     * @return the commission balance and the received penalty, denoted in USDC
     */
    function commissionBalanceOf(address _manager)
        public
        view
        returns (uint256 _commission, uint256 _penalty)
    {
        if (lastCommissionRedemption(_manager) >= cycleNumber) {
            return (0, 0);
        }
        uint256 cycle = lastCommissionRedemption(_manager) > 0
            ? lastCommissionRedemption(_manager)
            : 1;
        uint256 cycleCommission;
        uint256 cyclePenalty;
        for (; cycle < cycleNumber; cycle++) {
            (cycleCommission, cyclePenalty) = commissionOfAt(_manager, cycle);
            _commission = _commission.add(cycleCommission);
            _penalty = _penalty.add(cyclePenalty);
        }
    }

    /**
     * @notice Returns the commission amount received by `_manager` in the `_cycle`th cycle
     * @return the commission amount and the received penalty, denoted in USDC
     */
    function commissionOfAt(address _manager, uint256 _cycle)
        public
        view
        returns (uint256 _commission, uint256 _penalty)
    {
        if (hasRedeemedCommissionForCycle(_manager, _cycle)) {
            return (0, 0);
        }
        // take risk into account
        uint256 baseRepTokenBalance = cToken.balanceOfAt(
            _manager,
            managePhaseEndBlock(_cycle.sub(1))
        );
        uint256 baseStake = baseRepTokenBalance == 0
            ? baseRiskStakeFallback(_manager)
            : baseRepTokenBalance;
        if (baseRepTokenBalance == 0 && baseRiskStakeFallback(_manager) == 0) {
            return (0, 0);
        }
        uint256 riskTakenProportion = riskTakenInCycle(_manager, _cycle)
            .mul(PRECISION)
            .div(baseStake.mul(MIN_RISK_TIME)); // risk / threshold
        riskTakenProportion = riskTakenProportion > PRECISION
            ? PRECISION
            : riskTakenProportion; // max proportion is 1

        uint256 fullCommission = totalCommissionOfCycle(_cycle)
            .mul(cToken.balanceOfAt(_manager, managePhaseEndBlock(_cycle)))
            .div(cToken.totalSupplyAt(managePhaseEndBlock(_cycle)));

        _commission = fullCommission.mul(riskTakenProportion).div(PRECISION);
        _penalty = fullCommission.sub(_commission);
    }

    /**
     * @notice Redeems commission.
     */
    function redeemCommission(bool _inShares)
        public
        during(CyclePhase.Intermission)
        nonReentrant
    {
        uint256 commission = __redeemCommission();

        if (_inShares) {
            // Deposit commission into fund
            __deposit(commission);

            // Emit deposit event
            emit Deposit(
                cycleNumber,
                msg.sender,
                USDC_ADDR,
                commission,
                commission,
                now
            );
        } else {
            // Transfer the commission in USDC
            usdc.safeTransfer(msg.sender, commission);
        }
    }

    /**
     * @notice Redeems commission for a particular cycle.
     * @param _inShares true to redeem in PeakDeFi Shares, false to redeem in USDC
     * @param _cycle the cycle for which the commission will be redeemed.
     *        Commissions for a cycle will be redeemed during the Intermission phase of the next cycle, so _cycle must < cycleNumber.
     */
    function redeemCommissionForCycle(bool _inShares, uint256 _cycle)
        public
        during(CyclePhase.Intermission)
        nonReentrant
    {
        require(_cycle < cycleNumber);

        uint256 commission = __redeemCommissionForCycle(_cycle);

        if (_inShares) {
            // Deposit commission into fund
            __deposit(commission);

            // Emit deposit event
            emit Deposit(
                cycleNumber,
                msg.sender,
                USDC_ADDR,
                commission,
                commission,
                now
            );
        } else {
            // Transfer the commission in USDC
            usdc.safeTransfer(msg.sender, commission);
        }
    }

    /**
     * @notice Redeems the commission for all previous cycles. Updates the related variables.
     * @return the amount of commission to be redeemed
     */
    function __redeemCommission() internal returns (uint256 _commission) {
        require(lastCommissionRedemption(msg.sender) < cycleNumber);

        uint256 penalty; // penalty received for not taking enough risk
        (_commission, penalty) = commissionBalanceOf(msg.sender);

        // record the redemption to prevent double-redemption
        for (
            uint256 i = lastCommissionRedemption(msg.sender);
            i < cycleNumber;
            i++
        ) {
            _hasRedeemedCommissionForCycle[msg.sender][i] = true;
        }
        _lastCommissionRedemption[msg.sender] = cycleNumber;

        // record the decrease in commission pool
        totalCommissionLeft = totalCommissionLeft.sub(_commission);
        // include commission penalty to this cycle's total commission pool
        _totalCommissionOfCycle[cycleNumber] = totalCommissionOfCycle(
            cycleNumber
        )
            .add(penalty);
        // clear investment arrays to save space
        delete userInvestments[msg.sender];
        delete userCompoundOrders[msg.sender];

        emit CommissionPaid(cycleNumber, msg.sender, _commission);
    }

    /**
     * @notice Redeems commission for a particular cycle. Updates the related variables.
     * @param _cycle the cycle for which the commission will be redeemed
     * @return the amount of commission to be redeemed
     */
    function __redeemCommissionForCycle(uint256 _cycle)
        internal
        returns (uint256 _commission)
    {
        require(!hasRedeemedCommissionForCycle(msg.sender, _cycle));

        uint256 penalty; // penalty received for not taking enough risk
        (_commission, penalty) = commissionOfAt(msg.sender, _cycle);

        _hasRedeemedCommissionForCycle[msg.sender][_cycle] = true;

        // record the decrease in commission pool
        totalCommissionLeft = totalCommissionLeft.sub(_commission);
        // include commission penalty to this cycle's total commission pool
        _totalCommissionOfCycle[cycleNumber] = totalCommissionOfCycle(
            cycleNumber
        )
            .add(penalty);
        // clear investment arrays to save space
        delete userInvestments[msg.sender];
        delete userCompoundOrders[msg.sender];

        emit CommissionPaid(_cycle, msg.sender, _commission);
    }

    /**
     * @notice Handles deposits by minting PeakDeFi Shares & updating total funds.
     * @param _depositUSDCAmount The amount of the deposit in USDC
     */
    function __deposit(uint256 _depositUSDCAmount) internal {
        // Register investment and give shares
        if (sToken.totalSupply() == 0 || totalFundsInUSDC == 0) {
            require(sToken.generateTokens(msg.sender, _depositUSDCAmount));
        } else {
            require(
                sToken.generateTokens(
                    msg.sender,
                    _depositUSDCAmount.mul(sToken.totalSupply()).div(
                        totalFundsInUSDC
                    )
                )
            );
        }
        totalFundsInUSDC = totalFundsInUSDC.add(_depositUSDCAmount);
    }

    /**
    PeakDeFi
   */

    /**
     * @notice Returns the commission balance of `_referrer`
     * @return the commission balance, denoted in USDC
     */
    function peakReferralCommissionBalanceOf(address _referrer)
        public
        view
        returns (uint256 _commission)
    {
        if (peakReferralLastCommissionRedemption(_referrer) >= cycleNumber) {
            return (0);
        }
        uint256 cycle = peakReferralLastCommissionRedemption(_referrer) > 0
            ? peakReferralLastCommissionRedemption(_referrer)
            : 1;
        uint256 cycleCommission;
        for (; cycle < cycleNumber; cycle++) {
            (cycleCommission) = peakReferralCommissionOfAt(_referrer, cycle);
            _commission = _commission.add(cycleCommission);
        }
    }

    /**
     * @notice Returns the commission amount received by `_referrer` in the `_cycle`th cycle
     * @return the commission amount, denoted in USDC
     */
    function peakReferralCommissionOfAt(address _referrer, uint256 _cycle)
        public
        view
        returns (uint256 _commission)
    {
        _commission = peakReferralTotalCommissionOfCycle(_cycle)
            .mul(
            peakReferralToken.balanceOfAt(
                _referrer,
                managePhaseEndBlock(_cycle)
            )
        )
            .div(peakReferralToken.totalSupplyAt(managePhaseEndBlock(_cycle)));
    }

    /**
     * @notice Redeems commission.
     */
    function peakReferralRedeemCommission()
        public
        during(CyclePhase.Intermission)
        nonReentrant
    {
        uint256 commission = __peakReferralRedeemCommission();

        // Transfer the commission in USDC
        usdc.safeApprove(address(peakReward), commission);
        peakReward.payCommission(msg.sender, address(usdc), commission, false);
    }

    /**
     * @notice Redeems commission for a particular cycle.
     * @param _cycle the cycle for which the commission will be redeemed.
     *        Commissions for a cycle will be redeemed during the Intermission phase of the next cycle, so _cycle must < cycleNumber.
     */
    function peakReferralRedeemCommissionForCycle(uint256 _cycle)
        public
        during(CyclePhase.Intermission)
        nonReentrant
    {
        require(_cycle < cycleNumber);

        uint256 commission = __peakReferralRedeemCommissionForCycle(_cycle);

        // Transfer the commission in USDC
        usdc.safeApprove(address(peakReward), commission);
        peakReward.payCommission(msg.sender, address(usdc), commission, false);
    }

    /**
     * @notice Redeems the commission for all previous cycles. Updates the related variables.
     * @return the amount of commission to be redeemed
     */
    function __peakReferralRedeemCommission()
        internal
        returns (uint256 _commission)
    {
        require(peakReferralLastCommissionRedemption(msg.sender) < cycleNumber);

        _commission = peakReferralCommissionBalanceOf(msg.sender);

        // record the redemption to prevent double-redemption
        for (
            uint256 i = peakReferralLastCommissionRedemption(msg.sender);
            i < cycleNumber;
            i++
        ) {
            _peakReferralHasRedeemedCommissionForCycle[msg.sender][i] = true;
        }
        _peakReferralLastCommissionRedemption[msg.sender] = cycleNumber;

        // record the decrease in commission pool
        peakReferralTotalCommissionLeft = peakReferralTotalCommissionLeft.sub(
            _commission
        );

        emit PeakReferralCommissionPaid(cycleNumber, msg.sender, _commission);
    }

    /**
     * @notice Redeems commission for a particular cycle. Updates the related variables.
     * @param _cycle the cycle for which the commission will be redeemed
     * @return the amount of commission to be redeemed
     */
    function __peakReferralRedeemCommissionForCycle(uint256 _cycle)
        internal
        returns (uint256 _commission)
    {
        require(!peakReferralHasRedeemedCommissionForCycle(msg.sender, _cycle));

        _commission = peakReferralCommissionOfAt(msg.sender, _cycle);

        _peakReferralHasRedeemedCommissionForCycle[msg.sender][_cycle] = true;

        // record the decrease in commission pool
        peakReferralTotalCommissionLeft = peakReferralTotalCommissionLeft.sub(
            _commission
        );

        emit PeakReferralCommissionPaid(_cycle, msg.sender, _commission);
    }
}