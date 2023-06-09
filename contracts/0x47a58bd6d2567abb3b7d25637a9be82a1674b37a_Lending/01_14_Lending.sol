// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./Fund.sol";
import "./HourlyBondSubscriptionLending.sol";
import "../libraries/IncentiveReporter.sol";

// TODO activate bonds for lending

/// @title Manage lending for a variety of bond issuers
contract Lending is RoleAware, HourlyBondSubscriptionLending {
    /// mapping issuers to tokens
    /// (in crossmargin, the issuers are tokens  themselves)
    mapping(address => address) public issuerTokens;

    /// In case of shortfall, adjust debt
    mapping(address => uint256) public haircuts;

    /// map of available issuers
    mapping(address => bool) public activeIssuers;

    uint256 constant BORROW_RATE_UPDATE_WINDOW = 60 minutes;

    address public immutable MFI;

    constructor(address _MFI, address _roles) RoleAware(_roles) {
        MFI = _MFI;
    }

    /// Make a issuer available for protocol
    function activateIssuer(address issuer) external {
        activateIssuer(issuer, issuer);
    }

    /// Make issuer != token available for protocol (isol. margin)
    function activateIssuer(address issuer, address token)
        public
        onlyOwnerExecActivator
    {
        activeIssuers[issuer] = true;
        issuerTokens[issuer] = token;
    }

    /// Remove a issuer from trading availability
    function deactivateIssuer(address issuer) external onlyOwnerExecActivator {
        activeIssuers[issuer] = false;
    }

    /// Set lending cap
    function setLendingCap(address issuer, uint256 cap)
        external
        onlyOwnerExecActivator
    {
        lendingMeta[issuer].lendingCap = cap;
    }

    /// Set withdrawal window
    function setWithdrawalWindow(uint256 window) external onlyOwnerExec {
        withdrawalWindow = window;
    }

    function setNormalRatePerPercent(uint256 rate) external onlyOwnerExec {
        normalRatePerPercent = rate;
    }

    function setHighRatePerPercent(uint256 rate) external onlyOwnerExec {
        highRatePerPercent = rate;
    }

    /// Set hourly yield APR for issuer
    function setHourlyYieldAPR(address issuer, uint256 aprPercent)
        external
        onlyOwnerExecActivator
    {
        YieldAccumulator storage yieldAccumulator =
            hourlyBondYieldAccumulators[issuer];

        if (yieldAccumulator.accumulatorFP == 0) {
            uint256 yieldFP = FP48 + (FP48 * aprPercent) / 100 / (24 * 365);
            hourlyBondYieldAccumulators[issuer] = YieldAccumulator({
                accumulatorFP: FP48,
                lastUpdated: block.timestamp,
                hourlyYieldFP: yieldFP
            });
        } else {
            YieldAccumulator storage yA =
                getUpdatedHourlyYield(
                    issuer,
                    yieldAccumulator,
                    RATE_UPDATE_WINDOW
                );
            yA.hourlyYieldFP = (FP48 * (100 + aprPercent)) / 100 / (24 * 365);
        }
    }

    /// @dev how much interest has accrued to a borrowed balance over time
    function applyBorrowInterest(
        uint256 balance,
        address issuer,
        uint256 yieldQuotientFP
    ) external returns (uint256 balanceWithInterest, uint256 accumulatorFP) {
        require(isBorrower(msg.sender), "Not approved call");

        YieldAccumulator storage yA = borrowYieldAccumulators[issuer];
        updateBorrowYieldAccu(yA);
        accumulatorFP = yA.accumulatorFP;

        balanceWithInterest = applyInterest(
            balance,
            accumulatorFP,
            yieldQuotientFP
        );

        uint256 deltaAmount = balanceWithInterest - balance;
        LendingMetadata storage meta = lendingMeta[issuer];
        meta.totalBorrowed += deltaAmount;
    }

    /// @dev view function to get balance with borrowing interest applied
    function viewWithBorrowInterest(
        uint256 balance,
        address issuer,
        uint256 yieldQuotientFP
    ) external view returns (uint256) {
        uint256 accumulatorFP =
            viewCumulativeYieldFP(
                borrowYieldAccumulators[issuer],
                block.timestamp
            );
        return applyInterest(balance, accumulatorFP, yieldQuotientFP);
    }

    /// @dev gets called by router to register if a trader borrows issuers
    function registerBorrow(address issuer, uint256 amount) external {
        require(isBorrower(msg.sender), "Not approved borrower");
        require(activeIssuers[issuer], "Not approved issuer");

        LendingMetadata storage meta = lendingMeta[issuer];
        meta.totalBorrowed += amount;

        getUpdatedHourlyYield(
            issuer,
            hourlyBondYieldAccumulators[issuer],
            BORROW_RATE_UPDATE_WINDOW
        );

        require(
            meta.totalLending >= meta.totalBorrowed,
            "Insufficient lending"
        );
    }

    /// @dev gets called when external sources provide lending
    function registerLend(address issuer, uint256 amount) external {
        require(isLender(msg.sender), "Not an approved lender");
        require(activeIssuers[issuer], "Not approved issuer");
        LendingMetadata storage meta = lendingMeta[issuer];
        addToTotalLending(meta, amount);

        getUpdatedHourlyYield(
            issuer,
            hourlyBondYieldAccumulators[issuer],
            RATE_UPDATE_WINDOW
        );
    }

    /// @dev gets called when external sources pay withdraw their bobnd
    function registerWithdrawal(address issuer, uint256 amount) external {
        require(isLender(msg.sender), "Not an approved lender");
        require(activeIssuers[issuer], "Not approved issuer");
        LendingMetadata storage meta = lendingMeta[issuer];
        subtractFromTotalLending(meta, amount);

        getUpdatedHourlyYield(
            issuer,
            hourlyBondYieldAccumulators[issuer],
            RATE_UPDATE_WINDOW
        );
    }

    /// @dev gets called by router if loan is extinguished
    function payOff(address issuer, uint256 amount) external {
        require(isBorrower(msg.sender), "Not approved borrower");
        lendingMeta[issuer].totalBorrowed -= amount;
    }

    /// @dev get the borrow yield for a specific issuer/token
    function viewAccumulatedBorrowingYieldFP(address issuer)
        external
        view
        returns (uint256)
    {
        YieldAccumulator storage yA = borrowYieldAccumulators[issuer];
        return viewCumulativeYieldFP(yA, block.timestamp);
    }

    function viewAPRPer10k(YieldAccumulator storage yA)
        internal
        view
        returns (uint256)
    {
        uint256 hourlyYieldFP = yA.hourlyYieldFP;

        uint256 aprFP =
            ((hourlyYieldFP * 10_000 - FP48 * 10_000) * 365 days) / (1 hours);

        return aprFP / FP48;
    }

    /// @dev get current borrowing interest per 10k for a token / issuer
    function viewBorrowAPRPer10k(address issuer)
        external
        view
        returns (uint256)
    {
        return viewAPRPer10k(borrowYieldAccumulators[issuer]);
    }

    /// @dev get current lending APR per 10k for a token / issuer
    function viewHourlyBondAPRPer10k(address issuer)
        external
        view
        returns (uint256)
    {
        return viewAPRPer10k(hourlyBondYieldAccumulators[issuer]);
    }

    /// @dev In a liquidity crunch make a fallback bond until liquidity is good again
    function makeFallbackBond(
        address issuer,
        address holder,
        uint256 amount
    ) external {
        require(isLender(msg.sender), "Not an approved lender");
        _makeHourlyBond(issuer, holder, amount);
    }

    /// @dev withdraw an hour bond
    function withdrawHourlyBond(address issuer, uint256 amount) external {
        HourlyBond storage bond = hourlyBondAccounts[issuer][msg.sender];
        super._withdrawHourlyBond(issuer, bond, amount, msg.sender);

        if (bond.amount == 0) {
            delete hourlyBondAccounts[issuer][msg.sender];
        }

        disburse(issuer, msg.sender, amount);

        IncentiveReporter.subtractFromClaimAmount(issuer, msg.sender, amount);
    }

    /// Shut down hourly bond account for `issuer`
    function closeHourlyBondAccount(address issuer) external {
        HourlyBond storage bond = hourlyBondAccounts[issuer][msg.sender];

        uint256 amount = bond.amount;
        super._withdrawHourlyBond(issuer, bond, amount, msg.sender);

        disburse(issuer, msg.sender, amount);

        delete hourlyBondAccounts[issuer][msg.sender];

        IncentiveReporter.subtractFromClaimAmount(issuer, msg.sender, amount);
    }

    /// @dev buy hourly bond subscription
    function buyHourlyBondSubscription(address issuer, uint256 amount)
        external
    {
        require(activeIssuers[issuer], "Not approved issuer");

        collectToken(issuer, msg.sender, amount);

        super._makeHourlyBond(issuer, msg.sender, amount);

        IncentiveReporter.addToClaimAmount(issuer, msg.sender, amount);
    }

    function initBorrowYieldAccumulator(address issuer)
        external
        onlyOwnerExecActivator
    {
        YieldAccumulator storage yA = borrowYieldAccumulators[issuer];
        require(yA.accumulatorFP == 0, "don't re-initialize");

        yA.accumulatorFP = FP48;
        yA.lastUpdated = block.timestamp;
        yA.hourlyYieldFP = FP48 + (FP48 * borrowMinAPR) / 1000 / (365 * 24);
    }

    function setBorrowingFactorPercent(uint256 borrowingFactor)
        external
        onlyOwnerExec
    {
        borrowingFactorPercent = borrowingFactor;
    }

    function issuanceBalance(address issuer)
        internal
        view
        override
        returns (uint256)
    {
        address token = issuerTokens[issuer];
        if (token == issuer) {
            // cross margin
            return IERC20(token).balanceOf(fund());
        } else {
            return lendingMeta[issuer].totalLending - haircuts[issuer];
        }
    }

    function disburse(
        address issuer,
        address recipient,
        uint256 amount
    ) internal {
        uint256 haircutAmount = haircuts[issuer];
        if (haircutAmount > 0 && amount > 0) {
            uint256 totalLending = lendingMeta[issuer].totalLending;
            uint256 adjustment =
                (amount * min(totalLending, haircutAmount)) / totalLending;
            amount = amount - adjustment;
            haircuts[issuer] -= adjustment;
        }

        address token = issuerTokens[issuer];
        Fund(fund()).withdraw(token, recipient, amount);
    }

    function collectToken(
        address issuer,
        address source,
        uint256 amount
    ) internal {
        Fund(fund()).depositFor(source, issuerTokens[issuer], amount);
    }

    function haircut(uint256 amount) external {
        haircuts[msg.sender] += amount;
    }

    function addIncentive(
        address token,
        uint256 amount,
        uint256 endTimestamp
    ) external onlyOwnerExecActivator {
        LendingMetadata storage meta = lendingMeta[token];
        meta.incentiveEnd = endTimestamp;
        meta.incentiveTarget = amount;
        meta.incentiveLastUpdated = block.timestamp;
    }

    function disburseIncentive(
        HourlyBond storage bond,
        LendingMetadata storage meta,
        address holder
    ) internal override {
        uint256 allocationDelta =
            meta.cumulIncentiveAllocationFP - bond.incentiveAllocationStart;
        if (allocationDelta > 0) {
            uint256 disburseAmount = (allocationDelta * bond.amount) / FP48;
            Fund(fund()).withdraw(MFI, holder, disburseAmount);
            bond.incentiveAllocationStart += allocationDelta;
        }
    }

    function withdrawIncentive(address token) external {
        LendingMetadata storage meta = lendingMeta[token];
        updateIncentiveAllocation(meta);
        disburseIncentive(
            hourlyBondAccounts[token][msg.sender],
            meta,
            msg.sender
        );
    }
}