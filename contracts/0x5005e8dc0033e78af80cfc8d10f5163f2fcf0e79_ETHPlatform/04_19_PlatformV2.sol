// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "../v1/utils/SafeMath16.sol";
import "./utils/SafeMath168.sol";
import "./interfaces/IPlatformV2.sol";
import "./interfaces/IPositionRewardsV2.sol";

contract PlatformV2 is IPlatformV2, Ownable, ERC20, ReentrancyGuard {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using SafeMath168 for uint168;

    uint80 public latestOracleRoundId;
    uint32 public latestSnapshotTimestamp;
    bool private canPurgeLatestSnapshot = false;
    bool public emergencyWithdrawAllowed = false;
    bool private purgeSnapshots = true;

    uint8 public maxAllowedLeverage = 1;

    uint168 public constant MAX_FEE_PERCENTAGE = 10000;
    uint256 public constant PRECISION_DECIMALS = 1e10;
    uint256 public constant MAX_CVI_VALUE = 20000;

    uint256 public immutable initialTokenToLPTokenRate;

    IERC20 private token;
    ICVIOracleV3 private cviOracle;
    ILiquidationV2 private liquidation;
    IFeesCalculatorV3 private feesCalculator;
    IFeesCollector internal feesCollector;
    IPositionRewardsV2 private rewards;

    uint256 public lpsLockupPeriod = 3 days;
    uint256 public buyersLockupPeriod = 6 hours;

    uint256 public totalPositionUnitsAmount;
    uint256 public totalFundingFeesAmount;
    uint256 public totalLeveragedTokensAmount;

    address private stakingContractAddress = address(0);
    
    mapping(uint256 => uint256) public cviSnapshots;

    mapping(address => uint256) public lastDepositTimestamp;
    mapping(address => Position) public override positions;

    mapping(address => bool) public revertLockedTransfered;

    constructor(IERC20 _token, string memory _lpTokenName, string memory _lpTokenSymbolName, uint256 _initialTokenToLPTokenRate,
        IFeesCalculatorV3 _feesCalculator,
        ICVIOracleV3 _cviOracle,
        ILiquidationV2 _liquidation) public ERC20(_lpTokenName, _lpTokenSymbolName) {

        token = _token;
        initialTokenToLPTokenRate = _initialTokenToLPTokenRate;
        feesCalculator = _feesCalculator;
        cviOracle = _cviOracle;
        liquidation = _liquidation;
    }

    function deposit(uint256 _tokenAmount, uint256 _minLPTokenAmount) external virtual override nonReentrant returns (uint256 lpTokenAmount) {
        _deposit(_tokenAmount, _minLPTokenAmount);
    }

    function withdraw(uint256 _tokenAmount, uint256 _maxLPTokenBurnAmount) external override nonReentrant returns (uint256 burntAmount, uint256 withdrawnAmount) {
        (burntAmount, withdrawnAmount) = _withdraw(_tokenAmount, false, _maxLPTokenBurnAmount);
    }

    function withdrawLPTokens(uint256 _lpTokensAmount) external override nonReentrant returns (uint256 burntAmount, uint256 withdrawnAmount) {
        require(_lpTokensAmount > 0, "Amount must be positive");
        (burntAmount, withdrawnAmount) = _withdraw(0, true, _lpTokensAmount);
    }

    struct OpenPositionLocals {
        uint256 balance;
        uint256 collateralRatio;
        uint256 marginDebt;
        uint256 positionBalance;
        uint256 latestSnapshot;
        uint256 openPositionFee;
        uint256 minPositionUnitsAmount;
        uint168 buyingPremiumFee;
        uint168 buyingPremiumFeePercentage;
        uint168 tokenAmountToOpenPosition;
        uint256 maxPositionUnitsAmount;
        uint16 cviValue;
    }

    function openPosition(uint168 _tokenAmount, uint16 _maxCVI, uint168 _maxBuyingPremiumFeePercentage, uint8 _leverage) external override virtual nonReentrant returns (uint168 positionUnitsAmount) {
        _openPosition(_tokenAmount, _maxCVI, _maxBuyingPremiumFeePercentage, _leverage);
    }

    function closePosition(uint168 _positionUnitsAmount, uint16 _minCVI) external override nonReentrant returns (uint256 tokenAmount) {
        require(_positionUnitsAmount > 0, "Position units not positive");
        require(_minCVI > 0 && _minCVI <= MAX_CVI_VALUE, "Bad min CVI value");

        Position storage position = positions[msg.sender];

        require(position.positionUnitsAmount >= _positionUnitsAmount, "Not enough opened position units");
        require(block.timestamp.sub(position.creationTimestamp) >= buyersLockupPeriod, "Position locked");

        (uint16 cviValue, uint256 latestSnapshot) = updateSnapshots(true);
        require(cviValue >= _minCVI, "CVI too low");

        (uint256 positionBalance, uint256 fundingFees, uint256 marginDebt, bool wasLiquidated) = _closePosition(position, _positionUnitsAmount, latestSnapshot, cviValue);

        // If was liquidated, balance is negative, nothing to return
        if (wasLiquidated) {
            return 0;
        }

        (uint256 newTotalPositionUnitsAmount, uint256 newTotalFundingFeesAmount) = subtractTotalPositionUnits(_positionUnitsAmount, fundingFees);
        totalPositionUnitsAmount = newTotalPositionUnitsAmount;
        totalFundingFeesAmount = newTotalFundingFeesAmount;
        position.positionUnitsAmount = position.positionUnitsAmount.sub(_positionUnitsAmount);

        uint256 closePositionFee = positionBalance
            .mul(uint256(feesCalculator.calculateClosePositionFeePercent(position.creationTimestamp)))
            .div(MAX_FEE_PERCENTAGE);

        emit ClosePosition(msg.sender, positionBalance.add(fundingFees), closePositionFee.add(fundingFees), position.positionUnitsAmount, position.leverage, cviValue);

        if (position.positionUnitsAmount == 0) {
            delete positions[msg.sender];
        }

        totalLeveragedTokensAmount = totalLeveragedTokensAmount.sub(positionBalance).sub(marginDebt);
        tokenAmount = positionBalance.sub(closePositionFee);

        collectProfit(closePositionFee);
        transferFunds(tokenAmount);
    }

    function _closePosition(Position storage _position, uint256 _positionUnitsAmount, uint256 _latestSnapshot, uint16 _cviValue) private returns (uint256 positionBalance, uint256 fundingFees, uint256 marginDebt, bool wasLiquidated) {
        fundingFees = _calculateFundingFees(cviSnapshots[_position.creationTimestamp], _latestSnapshot, _positionUnitsAmount);
        
        (uint256 currentPositionBalance, bool isPositive, uint256 __marginDebt) = __calculatePositionBalance(_positionUnitsAmount, _position.leverage, _cviValue, _position.openCVIValue, fundingFees);
        
        // Position might be liquidable but balance is positive, we allow to avoid liquidity in such a condition
        if (!isPositive) {
            checkAndLiquidatePosition(msg.sender, false); // Will always liquidate
            wasLiquidated = true;
            fundingFees = 0;
        } else {
            positionBalance = currentPositionBalance;
            marginDebt = __marginDebt;
        }
    }

    function liquidatePositions(address[] calldata _positionOwners) external override nonReentrant returns (uint256 finderFeeAmount) {
        updateSnapshots(true);
        bool liquidationOccured = false;
        for ( uint256 i = 0; i < _positionOwners.length; i++) {
            Position memory position = positions[_positionOwners[i]];

            if (position.positionUnitsAmount > 0) {
                (bool wasLiquidated, uint256 liquidatedAmount, bool isPositive) = checkAndLiquidatePosition(_positionOwners[i], false);

                if (wasLiquidated) {
                    liquidationOccured = true;
                    finderFeeAmount = finderFeeAmount.add(liquidation.getLiquidationReward(liquidatedAmount, isPositive, position.positionUnitsAmount, position.openCVIValue, position.leverage));
                }
            }
        }

        require(liquidationOccured, "No liquidatable position");

        totalLeveragedTokensAmount = totalLeveragedTokensAmount.sub(finderFeeAmount);
        transferFunds(finderFeeAmount);
    }

    function setFeesCollector(IFeesCollector _newCollector) external override onlyOwner {
        if (address(feesCollector) != address(0) && address(token) != address(0)) {
            token.approve(address(feesCollector), 0);
        }

        feesCollector = _newCollector;

        if (address(_newCollector) != address(0) && address(token) != address(0)) {
            token.approve(address(_newCollector), uint256(-1));
        }
    }

    function setFeesCalculator(IFeesCalculatorV3 _newCalculator) external override onlyOwner {
        feesCalculator = _newCalculator;
    }

    function setCVIOracle(ICVIOracleV3 _newOracle) external override onlyOwner {
        cviOracle = _newOracle;
    }

    function setRewards(IPositionRewardsV2 _newRewards) external override onlyOwner {
        rewards = _newRewards;
    }

    function setLiquidation(ILiquidationV2 _newLiquidation) external override onlyOwner {
        liquidation = _newLiquidation;
    }

    function setLatestOracleRoundId(uint80 _newOracleRoundId) external override onlyOwner {
        latestOracleRoundId = _newOracleRoundId;
    }
    
    function setLPLockupPeriod(uint256 _newLPLockupPeriod) external override onlyOwner {
        require(_newLPLockupPeriod <= 2 weeks, "Lockup too long");
        lpsLockupPeriod = _newLPLockupPeriod;
    }

    function setBuyersLockupPeriod(uint256 _newBuyersLockupPeriod) external override onlyOwner {
        require(_newBuyersLockupPeriod <= 1 weeks, "Lockup too long");
        buyersLockupPeriod = _newBuyersLockupPeriod;
    }

    function setRevertLockedTransfers(bool _revertLockedTransfers) external override {
        revertLockedTransfered[msg.sender] = _revertLockedTransfers;   
    }

    function setEmergencyWithdrawAllowed(bool _newEmergencyWithdrawAllowed) external override onlyOwner {
        emergencyWithdrawAllowed = _newEmergencyWithdrawAllowed;
    }

    function setStakingContractAddress(address _newStakingContractAddress) external override onlyOwner {
        stakingContractAddress = _newStakingContractAddress;
    }

    function setCanPurgeSnapshots(bool _newCanPurgeSnapshots) external override onlyOwner {
        purgeSnapshots = _newCanPurgeSnapshots;
    }

    function setMaxAllowedLeverage(uint8 _newMaxAllowedLeverage) external override onlyOwner {
        maxAllowedLeverage = _newMaxAllowedLeverage;
    }

    function getToken() external view override returns (IERC20) {
        return token;
    }

    function calculatePositionBalance(address _positionAddress) external view override returns (uint256 currentPositionBalance, bool isPositive, uint168 positionUnitsAmount, uint8 leverage, uint256 fundingFees, uint256 marginDebt) {
        positionUnitsAmount = positions[_positionAddress].positionUnitsAmount;
        leverage = positions[_positionAddress].leverage;
        require(positionUnitsAmount > 0, "No position for given address");
        (currentPositionBalance, isPositive, fundingFees, marginDebt) = _calculatePositionBalance(_positionAddress, true);
    }

    function calculatePositionPendingFees(address _positionAddress, uint168 _positionUnitsAmount) external view override returns (uint256 pendingFees) {
        Position memory position = positions[_positionAddress];
        pendingFees = _calculateFundingFees(cviSnapshots[position.creationTimestamp], 
            cviSnapshots[latestSnapshotTimestamp], _positionUnitsAmount).add(
                calculateLatestFundingFees(latestSnapshotTimestamp, _positionUnitsAmount));
    }

    function totalBalance() public view override returns (uint256 balance) {
        (uint16 cviValue,,) = cviOracle.getCVILatestRoundData();
        return _totalBalance(cviValue);
    }

    function totalBalanceWithAddendum() external view override returns (uint256 balance) {
        return totalBalance().add(calculateLatestFundingFees(latestSnapshotTimestamp, totalPositionUnitsAmount));
    }

    function calculateLatestTurbulenceIndicatorPercent() external view override returns (uint16) {
        SnapshotUpdate memory updateData = _updateSnapshots(latestSnapshotTimestamp);
        if (updateData.updatedTurbulenceData) {
            return feesCalculator.calculateTurbulenceIndicatorPercent(updateData.totalTime, updateData.totalRounds);
        } else {
            return feesCalculator.turbulenceIndicatorPercent();
        }
    }

    function getLiquidableAddresses(address[] calldata _positionOwners) external view override returns (address[] memory) {
        address[] memory addressesToLiquidate = new address[](_positionOwners.length);

        uint256 liquidationAddressesAmount = 0;
        for (uint256 i = 0; i < _positionOwners.length; i++) {
            (uint256 currentPositionBalance, bool isBalancePositive,, ) = _calculatePositionBalance(_positionOwners[i], true);

            Position memory position = positions[_positionOwners[i]];

            if (position.positionUnitsAmount > 0 && liquidation.isLiquidationCandidate(currentPositionBalance, isBalancePositive, position.positionUnitsAmount, position.openCVIValue, position.leverage)) {
                addressesToLiquidate[liquidationAddressesAmount] = _positionOwners[i];
                liquidationAddressesAmount = liquidationAddressesAmount.add(1);
            }
        }

        address[] memory addressesToActuallyLiquidate = new address[](liquidationAddressesAmount);
        for (uint256 i = 0; i < liquidationAddressesAmount; i++) {
            addressesToActuallyLiquidate[i] = addressesToLiquidate[i];
        }

        return addressesToActuallyLiquidate;
    }

    function collectTokens(uint256 _tokenAmount) internal virtual {
        token.safeTransferFrom(msg.sender, address(this), _tokenAmount);
    }

    function _deposit(uint256 _tokenAmount, uint256 _minLPTokenAmount) internal returns (uint256 lpTokenAmount) {
        require(_tokenAmount > 0, "Tokens amount must be positive");
        lastDepositTimestamp[msg.sender] = block.timestamp;

        (uint16 cviValue,) = updateSnapshots(true);

        uint256 depositFee = _tokenAmount.mul(uint256(feesCalculator.depositFeePercent())) / MAX_FEE_PERCENTAGE;

        uint256 tokenAmountToDeposit = _tokenAmount.sub(depositFee);
        uint256 supply = totalSupply();
        uint256 balance = _totalBalance(cviValue);
    
        if (supply > 0 && balance > 0) {
            lpTokenAmount = tokenAmountToDeposit.mul(supply) / balance;
        } else {
            lpTokenAmount = tokenAmountToDeposit.mul(initialTokenToLPTokenRate);
        }

        emit Deposit(msg.sender, _tokenAmount, lpTokenAmount, depositFee);

        require(lpTokenAmount >= _minLPTokenAmount, "Too few LP tokens");
        require(lpTokenAmount > 0, "Too few tokens");

        totalLeveragedTokensAmount = totalLeveragedTokensAmount.add(tokenAmountToDeposit);

        _mint(msg.sender, lpTokenAmount);
        collectTokens(_tokenAmount);
        collectProfit(depositFee);
    }

    function _withdraw(uint256 _tokenAmount, bool _shouldBurnMax, uint256 _maxLPTokenBurnAmount) internal returns (uint256 burntAmount, uint256 withdrawnAmount) {
        require(lastDepositTimestamp[msg.sender].add(lpsLockupPeriod) <= block.timestamp, "Funds are locked");

        (uint16 cviValue,) = updateSnapshots(true);

        if (_shouldBurnMax) {
            burntAmount = _maxLPTokenBurnAmount;
            _tokenAmount = burntAmount.mul(_totalBalance(cviValue)).div(totalSupply());
        } else {
            require(_tokenAmount > 0, "Tokens amount must be positive");

            // Note: rounding up (ceiling) the to-burn amount to prevent precision loss
            burntAmount = _tokenAmount.mul(totalSupply()).sub(1).div(_totalBalance(cviValue)).add(1);
            require(burntAmount <= _maxLPTokenBurnAmount, "Too much LP tokens to burn");
        }

        require(burntAmount <= balanceOf(msg.sender), "Not enough LP tokens for account");
        require(emergencyWithdrawAllowed || getTokenBalance().sub(totalPositionUnitsAmount) >= _tokenAmount, "Collateral ratio broken");

        totalLeveragedTokensAmount = totalLeveragedTokensAmount.sub(_tokenAmount);

        uint256 withdrawFee = _tokenAmount.mul(uint256(feesCalculator.withdrawFeePercent())) / MAX_FEE_PERCENTAGE;
        withdrawnAmount = _tokenAmount.sub(withdrawFee);

        emit Withdraw(msg.sender, _tokenAmount, burntAmount, withdrawFee);
        
        _burn(msg.sender, burntAmount);

        collectProfit(withdrawFee);
        transferFunds(withdrawnAmount);
    }

    function _openPosition(uint168 _tokenAmount, uint16 _maxCVI, uint168 _maxBuyingPremiumFeePercentage, uint8 _leverage) internal returns (uint168 positionUnitsAmount) {
        require(_leverage > 0, "Leverage must be positive");
        require(_leverage <= maxAllowedLeverage, "Leverage excceeds max allowed");
        require(_tokenAmount > 0, "Tokens amount must be positive");
        require(_maxCVI > 0 && _maxCVI <= MAX_CVI_VALUE, "Bad max CVI value");

        OpenPositionLocals memory locals;

        (locals.cviValue, locals.latestSnapshot) = updateSnapshots(false);
        require(locals.cviValue <= _maxCVI, "CVI too high");

        (uint16 openPositionFeePercent, uint16 buyingPremiumFeeMaxPercent) = feesCalculator.openPositionFees();

        // Calculate buying premium fee, assuming the maxmimum 
        locals.openPositionFee = uint256(_tokenAmount).mul(_leverage).mul(openPositionFeePercent) / MAX_FEE_PERCENTAGE;
        locals.maxPositionUnitsAmount = uint256(_tokenAmount).sub(locals.openPositionFee).mul(_leverage).mul(MAX_CVI_VALUE) / locals.cviValue;
        locals.minPositionUnitsAmount = locals.maxPositionUnitsAmount.
            mul(MAX_FEE_PERCENTAGE.sub(buyingPremiumFeeMaxPercent)) / MAX_FEE_PERCENTAGE;

        locals.balance = getTokenBalance(_tokenAmount);

        locals.collateralRatio = 0;
        if (locals.balance > 0) {
            locals.collateralRatio = (totalPositionUnitsAmount.add(locals.minPositionUnitsAmount)).mul(PRECISION_DECIMALS).
                div((locals.balance.add(uint256(_tokenAmount) - locals.openPositionFee)));
        }
        (locals.buyingPremiumFee, locals.buyingPremiumFeePercentage) = feesCalculator.calculateBuyingPremiumFee(_tokenAmount, _leverage, locals.collateralRatio);

        require(locals.buyingPremiumFeePercentage <= _maxBuyingPremiumFeePercentage, "Premium fee too high");
        
        // Leaving buying premium in shared pool
        require(locals.openPositionFee < _tokenAmount, "Open fee too big");
        locals.tokenAmountToOpenPosition = (_tokenAmount - uint168(locals.openPositionFee)).sub(locals.buyingPremiumFee).mul(_leverage);
        
        Position storage position = positions[msg.sender];

        if (position.positionUnitsAmount > 0) {
            (positionUnitsAmount, locals.marginDebt, locals.positionBalance) = _mergePosition(position, locals.latestSnapshot, locals.cviValue, locals.tokenAmountToOpenPosition, _leverage);
            uint256 addedTotalLeveragedTokensAmount = totalLeveragedTokensAmount.add(uint256(_tokenAmount - locals.openPositionFee).add(locals.positionBalance).mul(_leverage));
            totalLeveragedTokensAmount = addedTotalLeveragedTokensAmount.sub(locals.marginDebt).sub(locals.positionBalance);
        } else {
            uint256 __positionUnitsAmount = uint256(locals.tokenAmountToOpenPosition).mul(MAX_CVI_VALUE) / locals.cviValue;
            positionUnitsAmount = uint168(__positionUnitsAmount);
            require(positionUnitsAmount == __positionUnitsAmount, "Too much position units");

            Position memory newPosition = Position(positionUnitsAmount, _leverage, locals.cviValue, uint32(block.timestamp), uint32(block.timestamp));

            positions[msg.sender] = newPosition;
            totalPositionUnitsAmount = totalPositionUnitsAmount.add(positionUnitsAmount);

            totalLeveragedTokensAmount = totalLeveragedTokensAmount.add((_tokenAmount - locals.openPositionFee) * _leverage);
        }   

        emit OpenPosition(msg.sender, _tokenAmount, _leverage, locals.openPositionFee.add(locals.buyingPremiumFee), positionUnitsAmount, locals.cviValue);

        collectTokens(_tokenAmount);        

        locals.balance = locals.balance.add(_tokenAmount);
        collectProfit(locals.openPositionFee);

        require(totalPositionUnitsAmount <= locals.balance, "Not enough liquidity");

        if (address(rewards) != address(0)) {
            rewards.reward(msg.sender, positionUnitsAmount, _leverage);
        }
    }

    struct MergePositionLocals {
        uint168 oldPositionUnits;
        uint256 newPositionUnits;
        uint256 newTotalPositionUnitsAmount;
        uint256 newTotalFundingFeesAmount;
    }

    function _mergePosition(Position storage _position, uint256 _latestSnapshot, uint16 _cviValue, uint256 _leveragedTokenAmount, uint8 _leverage) private returns (uint168 positionUnitsAmount, uint256 marginDebt, uint256 positionBalance) {
        MergePositionLocals memory locals;

        locals.oldPositionUnits = _position.positionUnitsAmount;
        (uint256 currentPositionBalance, uint256 fundingFees, uint256 __marginDebt, bool wasLiquidated) = _closePosition(_position, locals.oldPositionUnits, _latestSnapshot, _cviValue);
        
        // If was liquidated, balance is negative
        if (wasLiquidated) {
            currentPositionBalance = 0;
            locals.oldPositionUnits = 0;
            __marginDebt = 0;
            locals.oldPositionUnits = 0;
        }

        locals.newPositionUnits = currentPositionBalance.mul(_leverage).add(_leveragedTokenAmount).mul(MAX_CVI_VALUE).div(_cviValue);
        positionUnitsAmount = uint168(locals.newPositionUnits);
        require(positionUnitsAmount == locals.newPositionUnits, "Too much position units");

        _position.creationTimestamp = uint32(block.timestamp);
        _position.positionUnitsAmount = positionUnitsAmount;
        _position.openCVIValue = _cviValue;
        _position.leverage = _leverage;

        (locals.newTotalPositionUnitsAmount, locals.newTotalFundingFeesAmount) = subtractTotalPositionUnits(locals.oldPositionUnits, fundingFees);
        totalFundingFeesAmount = locals.newTotalFundingFeesAmount;
        totalPositionUnitsAmount = locals.newTotalPositionUnitsAmount.add(positionUnitsAmount);
        marginDebt = __marginDebt;
        positionBalance = currentPositionBalance;
    }

    function transferFunds(uint256 _tokenAmount) internal virtual {
        token.safeTransfer(msg.sender, _tokenAmount);
    }

    function _beforeTokenTransfer(address from, address to, uint256) internal override {
        if (lastDepositTimestamp[from].add(lpsLockupPeriod) > block.timestamp && 
            lastDepositTimestamp[from] > lastDepositTimestamp[to] && 
            from != stakingContractAddress && to != stakingContractAddress) {
                require(!revertLockedTransfered[to], "Recipient refuses locked tokens");
                lastDepositTimestamp[to] = lastDepositTimestamp[from];
        }
    }

    function sendProfit(uint256 _amount, IERC20 _token) internal virtual {
        feesCollector.sendProfit(_amount, _token);
    }

    function getTokenBalance() private view returns (uint256) {
        return getTokenBalance(0);
    }

    function getTokenBalance(uint256 _tokenAmount) internal view virtual returns (uint256) {
        return token.balanceOf(address(this));
    }

    struct SnapshotUpdate {
        uint256 latestSnapshot;
        uint256 singleUnitFundingFee;
        uint256 totalTime;
        uint256 totalRounds;
        uint80 newLatestRoundId;
        uint16 cviValue;
        bool updatedSnapshot;
        bool updatedLatestRoundId;
        bool updatedLatestTimestamp;
        bool updatedTurbulenceData;
    }

    function updateSnapshots(bool _canPurgeLatestSnapshot) private returns (uint16 latestCVIValue, uint256 latestSnapshot) {
        uint256 latestTimestamp = latestSnapshotTimestamp;
        SnapshotUpdate memory updateData = _updateSnapshots(latestTimestamp);

        if (updateData.updatedSnapshot) {
            cviSnapshots[block.timestamp] = updateData.latestSnapshot;
            totalFundingFeesAmount = totalFundingFeesAmount.add(updateData.singleUnitFundingFee.mul(totalPositionUnitsAmount) / PRECISION_DECIMALS);
        }

        if (updateData.updatedLatestRoundId) {
            latestOracleRoundId = updateData.newLatestRoundId;
        }

        if (updateData.updatedTurbulenceData) {
            feesCalculator.updateTurbulenceIndicatorPercent(updateData.totalTime, updateData.totalRounds);
        }

        if (updateData.updatedLatestTimestamp) {
            latestSnapshotTimestamp = uint32(block.timestamp);

            // Delete old snapshot if it can be deleted (not an open snapshot) to save gas
            if (canPurgeLatestSnapshot && purgeSnapshots) {
                delete cviSnapshots[latestTimestamp];
            }

            // Update purge since timestamp has changed and it is safe
            canPurgeLatestSnapshot = _canPurgeLatestSnapshot;
        } else if (canPurgeLatestSnapshot) {
            // Update purge only from true to false, so if an open was in the block, will never be purged
            canPurgeLatestSnapshot = _canPurgeLatestSnapshot;
        }

        return (updateData.cviValue, updateData.latestSnapshot);
    }

    function _updateSnapshots(uint256 _latestTimestamp) private view returns (SnapshotUpdate memory snapshotUpdate) {
        (uint16 cviValue, uint80 periodEndRoundId, uint256 periodEndTimestamp) = cviOracle.getCVILatestRoundData();
        snapshotUpdate.cviValue = cviValue;

        snapshotUpdate.latestSnapshot = cviSnapshots[block.timestamp];
        if (snapshotUpdate.latestSnapshot != 0) { // Block was already updated
            snapshotUpdate.singleUnitFundingFee = 0;
            return snapshotUpdate;
        }

        if (latestSnapshotTimestamp == 0) { // For first recorded block
            snapshotUpdate.latestSnapshot = PRECISION_DECIMALS;
            snapshotUpdate.updatedSnapshot = true;
            snapshotUpdate.newLatestRoundId = periodEndRoundId;
            snapshotUpdate.updatedLatestRoundId = true;
            snapshotUpdate.updatedLatestTimestamp = true;
            snapshotUpdate.singleUnitFundingFee = 0;
            return snapshotUpdate;
        }

        uint80 periodStartRoundId = latestOracleRoundId;
        require(periodEndRoundId >= periodStartRoundId, "Bad round id");

        snapshotUpdate.totalRounds = periodEndRoundId - periodStartRoundId;

        uint256 cviValuesNum = snapshotUpdate.totalRounds > 0 ? 2 : 1;
        IFeesCalculatorV3.CVIValue[] memory cviValues = new IFeesCalculatorV3.CVIValue[](cviValuesNum);
        
        if (snapshotUpdate.totalRounds > 0) {
            (uint16 periodStartCVIValue, uint256 periodStartTimestamp) = cviOracle.getCVIRoundData(periodStartRoundId);
            cviValues[0] = IFeesCalculatorV3.CVIValue(periodEndTimestamp.sub(_latestTimestamp), periodStartCVIValue);
            cviValues[1] = IFeesCalculatorV3.CVIValue(block.timestamp.sub(periodEndTimestamp), cviValue);

            snapshotUpdate.newLatestRoundId = periodEndRoundId;
            snapshotUpdate.updatedLatestRoundId = true;

            snapshotUpdate.totalTime = periodEndTimestamp.sub(periodStartTimestamp);
            snapshotUpdate.updatedTurbulenceData = true;
        } else {
            cviValues[0] = IFeesCalculatorV3.CVIValue(block.timestamp.sub(_latestTimestamp), cviValue);
        }

        snapshotUpdate.singleUnitFundingFee = feesCalculator.calculateSingleUnitFundingFee(cviValues);
        snapshotUpdate.latestSnapshot = cviSnapshots[_latestTimestamp].add(snapshotUpdate.singleUnitFundingFee);
        snapshotUpdate.updatedSnapshot = true;
        snapshotUpdate.updatedLatestTimestamp = true;
    }

    function _totalBalance(uint16 _cviValue) private view returns (uint256 balance) {
        return totalLeveragedTokensAmount.add(totalFundingFeesAmount).sub(totalPositionUnitsAmount.mul(_cviValue) / MAX_CVI_VALUE);
    }

    function collectProfit(uint256 amount) private {
        if (amount > 0 && address(feesCollector) != address(0)) {
            sendProfit(amount, token);
        }
    }

    function checkAndLiquidatePosition(address _positionAddress, bool _withAddendum) private returns (bool wasLiquidated, uint256 liquidatedAmount, bool isPositive) {
        (uint256 currentPositionBalance, bool isBalancePositive, uint256 fundingFees, uint256 marginDebt) = _calculatePositionBalance(_positionAddress, _withAddendum);
        isPositive = isBalancePositive;
        liquidatedAmount = currentPositionBalance;

        Position memory position = positions[_positionAddress];

        if (liquidation.isLiquidationCandidate(currentPositionBalance, isBalancePositive, position.positionUnitsAmount, position.openCVIValue, position.leverage)) {
            (uint256 newTotalPositionUnitsAmount, uint256 newTotalFundingFeesAmount) = subtractTotalPositionUnits(position.positionUnitsAmount, fundingFees);
            totalPositionUnitsAmount = newTotalPositionUnitsAmount;
            totalFundingFeesAmount = newTotalFundingFeesAmount;
            totalLeveragedTokensAmount = totalLeveragedTokensAmount.sub(marginDebt);

            emit LiquidatePosition(_positionAddress, currentPositionBalance, isBalancePositive, position.positionUnitsAmount);

            delete positions[_positionAddress];
            wasLiquidated = true;
        }
    }

    function subtractTotalPositionUnits(uint168 _positionUnitsAmountToSubtract, uint256 _fundingFeesToSubtract) private view returns (uint256 newTotalPositionUnitsAmount, uint256 newTotalFundingFeesAMount) {
        newTotalPositionUnitsAmount = totalPositionUnitsAmount.sub(_positionUnitsAmountToSubtract);
        newTotalFundingFeesAMount = totalFundingFeesAmount;
        if (newTotalPositionUnitsAmount == 0) {
            newTotalFundingFeesAMount = 0;
        } else {
            newTotalFundingFeesAMount = newTotalFundingFeesAMount.sub(_fundingFeesToSubtract);
        }
    }

    function _calculatePositionBalance(address _positionAddress, bool _withAddendum) private view returns (uint256 currentPositionBalance, bool isPositive, uint256 fundingFees, uint256 marginDebt) {
        Position memory position = positions[_positionAddress];

        (uint16 cviValue,,) = cviOracle.getCVILatestRoundData();

        fundingFees = _calculateFundingFees(cviSnapshots[position.creationTimestamp], cviSnapshots[latestSnapshotTimestamp], position.positionUnitsAmount);
        if (_withAddendum) {
            fundingFees = fundingFees.add(calculateLatestFundingFees(latestSnapshotTimestamp, position.positionUnitsAmount));
        }
        
        (currentPositionBalance, isPositive, marginDebt) = __calculatePositionBalance(position.positionUnitsAmount, position.leverage, cviValue, position.openCVIValue, fundingFees);
    }

    function __calculatePositionBalance(uint256 _positionUnits, uint8 _leverage, uint16 _cviValue, uint16 _openCVIValue, uint256 _fundingFees) private pure returns (uint256 currentPositionBalance, bool isPositive, uint256 marginDebt) {
        uint256 positionBalanceWithoutFees = _positionUnits.mul(_cviValue) / MAX_CVI_VALUE;

        marginDebt = _leverage > 1 ? _positionUnits.mul(_openCVIValue).mul(_leverage - 1) / MAX_CVI_VALUE / _leverage: 0;
        uint256 totalDebt = marginDebt.add(_fundingFees);

        if (positionBalanceWithoutFees >= totalDebt) {
            currentPositionBalance = positionBalanceWithoutFees.sub(totalDebt);
            isPositive = true;
        } else {
            currentPositionBalance = totalDebt.sub(positionBalanceWithoutFees);
        }
    }

    function _calculateFundingFees(uint256 startTimeSnapshot, uint256 endTimeSnapshot, uint256 positionUnitsAmount) private pure returns (uint256) {
        return endTimeSnapshot.sub(startTimeSnapshot).mul(positionUnitsAmount) / PRECISION_DECIMALS;
    }

    function calculateLatestFundingFees(uint256 startTime, uint256 positionUnitsAmount) private view returns (uint256) {
        SnapshotUpdate memory updateData = _updateSnapshots(latestSnapshotTimestamp);
        return _calculateFundingFees(cviSnapshots[startTime], updateData.latestSnapshot, positionUnitsAmount);
    }
}