// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './ElasticRigidVault.sol';
import './RigidAddressSet.sol';
import './interfaces/IRedistributor.sol';

abstract contract ZunamiElasticRigidVault is AccessControl, ElasticRigidVault, RigidAddressSet {
    using Math for uint256;

    bytes32 public constant REBALANCER_ROLE = keccak256('REBALANCER_ROLE');

    uint256 public constant FEE_DENOMINATOR = 1000000; // 100.0000%
    uint256 public constant MAX_FEE = 50000; // 5%

    uint256 public withdrawFee;
    address public feeDistributor;

    uint256 public dailyDepositDuration; // in blocks
    uint256 public dailyDepositLimit; // in minimal value

    uint256 public dailyWithdrawDuration; // in blocks
    uint256 public dailyWithdrawLimit; // in minimal value

    uint256 public dailyDepositTotal;
    uint256 public dailyDepositCountingBlock; // start block of limit counting

    uint256 public dailyWithdrawTotal;
    uint256 public dailyWithdrawCountingBlock; // start block of limit counting

    IAssetPriceOracle public immutable priceOracle;
    IRedistributor public redistributor;

    uint256 private _assetPriceCacheDuration = 1200; // cache every 4 hour

    event AssetPriceCacheDurationSet(
        uint256 newAssetPriceCacheDuration,
        uint256 oldAssetPriceCacheDuration
    );
    event DailyDepositParamsChanged(uint256 dailyDepositDuration, uint256 dailyDepositLimit);
    event DailyWithdrawParamsChanged(uint256 dailyWithdrawDuration, uint256 dailyWithdrawLimit);
    event WithdrawFeeChanged(uint256 withdrawFee);
    event FeeDistributorChanged(address feeDistributor);
    event RedistributorChanged(address redistributor);

    constructor(address priceOracle_) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        require(priceOracle_ != address(0), 'Zero price oracle');
        priceOracle = IAssetPriceOracle(priceOracle_);

        cacheAssetPrice();
    }

    function assetPrice() public view override returns (uint256) {
        return priceOracle.lpPrice();
    }

    function assetPriceCacheDuration() public view override returns (uint256) {
        return _assetPriceCacheDuration;
    }

    function setAssetPriceCacheDuration(uint256 assetPriceCacheDuration_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        emit AssetPriceCacheDurationSet(assetPriceCacheDuration_, _assetPriceCacheDuration);
        _assetPriceCacheDuration = assetPriceCacheDuration_;
    }

    function changeDailyDepositParams(uint256 dailyDepositDuration_, uint256 dailyDepositLimit_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        dailyDepositDuration = dailyDepositDuration_;
        dailyDepositLimit = dailyDepositLimit_;

        dailyDepositTotal = 0;
        dailyDepositCountingBlock = dailyDepositDuration_ > 0 ? block.number : 0;

        emit DailyDepositParamsChanged(dailyDepositDuration_, dailyDepositLimit_);
    }

    function changeDailyWithdrawParams(uint256 dailyWithdrawDuration_, uint256 dailyWithdrawLimit_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        dailyWithdrawDuration = dailyWithdrawDuration_;
        dailyWithdrawLimit = dailyWithdrawLimit_;

        dailyWithdrawTotal = 0;
        dailyWithdrawCountingBlock = dailyWithdrawDuration_ > 0 ? block.number : 0;

        emit DailyWithdrawParamsChanged(dailyWithdrawDuration_, dailyWithdrawLimit_);
    }

    function changeWithdrawFee(uint256 withdrawFee_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(withdrawFee_ <= MAX_FEE, 'Bigger that MAX_FEE constant');
        withdrawFee = withdrawFee_;

        emit WithdrawFeeChanged(withdrawFee_);
    }

    function changeFeeDistributor(address feeDistributor_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(feeDistributor_ != address(0), 'Zero fee distributor');
        feeDistributor = feeDistributor_;

        emit FeeDistributorChanged(feeDistributor_);
    }

    function _beforeDeposit(
        address caller,
        address,
        uint256 value,
        uint256
    ) internal override {
        uint256 dailyDuration = dailyDepositDuration;
        if (dailyDuration > 0 && !hasRole(REBALANCER_ROLE, caller)) {
            if (block.number > dailyDepositCountingBlock + dailyDuration) {
                dailyDepositTotal = value;
                dailyDepositCountingBlock = block.number;
            } else {
                dailyDepositTotal += value;
            }
            require(dailyDepositTotal <= dailyDepositLimit, 'Daily deposit limit overflow');
        }
    }

    function _beforeWithdraw(
        address caller,
        address,
        address,
        uint256 value,
        uint256
    ) internal override {
        uint256 dailyDuration = dailyWithdrawDuration;
        if (dailyDuration > 0 && !hasRole(REBALANCER_ROLE, caller)) {
            if (block.number > dailyWithdrawCountingBlock + dailyDuration) {
                dailyWithdrawTotal = value;
                dailyWithdrawCountingBlock = block.number;
            } else {
                dailyWithdrawTotal += value;
            }
            require(dailyWithdrawTotal <= dailyWithdrawLimit, 'Daily withdraw limit overflow');
        }
    }

    function _calcFee(address caller, uint256 nominal)
        internal
        view
        override
        returns (uint256 nominalFee)
    {
        nominalFee = 0;
        uint256 withdrawFee_ = withdrawFee;
        if (withdrawFee_ > 0 && !hasRole(REBALANCER_ROLE, caller)) {
            nominalFee = nominal.mulDiv(withdrawFee_, FEE_DENOMINATOR, Math.Rounding.Down);
        }
    }

    function _withdrawFee(uint256 nominalFee) internal override {
        if (nominalFee > 0) {
            SafeERC20.safeTransfer(IERC20Metadata(asset()), feeDistributor, nominalFee);
        }
    }

    function containRigidAddress(address _rigidAddress) public view override returns (bool) {
        return _containRigidAddress(_rigidAddress);
    }

    function addRigidAddress(address _rigidAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!containRigidAddress(_rigidAddress), 'Not elastic address');
        uint256 balanceElastic = balanceOf(_rigidAddress);
        _addRigidAddress(_rigidAddress);
        if (balanceElastic > 0) {
            _convertElasticToRigidBalancePartially(_rigidAddress, balanceElastic);
        }
    }

    function removeRigidAddress(address _rigidAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(containRigidAddress(_rigidAddress), 'Not rigid address');
        uint256 balanceRigid = balanceOf(_rigidAddress);
        _removeRigidAddress(_rigidAddress);
        if (balanceRigid > 0) {
            _convertRigidToElasticBalancePartially(_rigidAddress, balanceRigid);
        }
    }

    function setRedistributor(address _redistributor) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_redistributor != address(0), 'Zero redistributor address');
        redistributor = IRedistributor(_redistributor);
        emit RedistributorChanged(_redistributor);
    }

    function redistribute() public {
        uint256 totalRigidNominal = _convertToNominalWithCaching(
            totalSupplyRigid(),
            Math.Rounding.Up
        );

        uint256 lockedNominalRigid_ = lockedNominalRigid();
        require(
            lockedNominalRigid_ >= totalRigidNominal,
            'Wrong redistribution total nominal balance'
        );

        uint256 nominal;
        unchecked {
            nominal = lockedNominalRigid_ - totalRigidNominal;
        }

        _decreaseLockedNominalRigidBy(nominal);

        IRedistributor redistributor_ = redistributor;
        SafeERC20.safeIncreaseAllowance(IERC20Metadata(asset()), address(redistributor_), nominal);
        redistributor_.requestRedistribution(nominal);
    }
}