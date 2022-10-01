// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/AccessControl.sol';
import './ElasticVault.sol';

abstract contract ZunamiElasticVault is ElasticVault, AccessControl {
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

    IAssetPriceOracle public priceOracle;
    
    event DailyDepositParamsChanged(uint256 dailyDepositDuration, uint256 dailyDepositLimit);
    event DailyWithdrawParamsChanged(uint256 dailyWithdrawDuration, uint256 dailyWithdrawLimit);
    event WithdrawFeeChanged(uint256 withdrawFee);
    event FeeDistributorChanged(address feeDistributor);

    constructor(address priceOracle_) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        require(priceOracle_ != address(0), 'Zero price oracle');
        priceOracle = IAssetPriceOracle(priceOracle_);
    }

    function assetPrice() public view override returns (uint256) {
        return priceOracle.lpPrice();
    }

    function changeDailyDepositParams(uint256 dailyDepositDuration_, uint256 dailyDepositLimit_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        dailyDepositDuration = dailyDepositDuration_;
        dailyDepositLimit = dailyDepositLimit_;

        dailyDepositTotal = 0;
        dailyDepositCountingBlock = dailyDepositDuration > 0 ? block.number : 0;

        emit DailyDepositParamsChanged(dailyDepositDuration_, dailyDepositLimit_);
    }

    function changeDailyWithdrawParams(uint256 dailyWithdrawDuration_, uint256 dailyWithdrawLimit_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        dailyWithdrawDuration = dailyWithdrawDuration_;
        dailyWithdrawLimit = dailyWithdrawLimit_;

        dailyWithdrawTotal = 0;
        dailyWithdrawCountingBlock = dailyWithdrawDuration > 0 ? block.number : 0;

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
        if (dailyDepositDuration > 0 && !hasRole(REBALANCER_ROLE, caller)) {
            if (block.number > dailyDepositCountingBlock + dailyDepositDuration) {
                dailyDepositTotal = 0;
                dailyDepositCountingBlock = block.number;
            }
            dailyDepositTotal += value;
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
        if (dailyWithdrawDuration > 0 && !hasRole(REBALANCER_ROLE, caller)) {
            if (block.number > dailyWithdrawCountingBlock + dailyWithdrawDuration) {
                dailyWithdrawTotal = 0;
                dailyWithdrawCountingBlock = block.number;
            }
            dailyWithdrawTotal += value;
            require(dailyWithdrawTotal <= dailyWithdrawLimit, 'Daily withdraw limit overflow');
        }
    }

    function _calcFee(
        address caller,
        uint256 value,
        uint256 nominal
    ) internal view override returns (uint256 valueFee, uint256 nominalFee) {
        valueFee = 0;
        nominalFee = 0;
        if (withdrawFee > 0 && !hasRole(REBALANCER_ROLE, caller)) {
            nominalFee = nominal.mulDiv(withdrawFee, FEE_DENOMINATOR, Math.Rounding.Down);
            valueFee = value.mulDiv(withdrawFee, FEE_DENOMINATOR, Math.Rounding.Down);
        }
    }

    function _withdrawFee(uint256 valueFee, uint256) internal override {
        if (valueFee > 0) {
            SafeERC20.safeTransfer(IERC20Metadata(asset()), feeDistributor, valueFee);
        }
    }
}