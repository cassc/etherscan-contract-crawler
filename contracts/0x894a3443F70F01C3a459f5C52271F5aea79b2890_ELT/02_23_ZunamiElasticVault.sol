// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/AccessControl.sol';
import "./ElasticVault.sol";

abstract contract ZunamiElasticVault is ElasticVault, AccessControl {
    using Math for uint256;

    bytes32 public constant REBALANCER_ROLE = keccak256("REBALANCER_ROLE");

    uint256 public constant FEE_DENOMINATOR = 1000000; // 100.0000%

    uint256 public feePercent;
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

    event PriceOracleChanged(address priceOracle);

    constructor(address priceOracle_) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(REBALANCER_ROLE, msg.sender);

        changePriceOracle(priceOracle_);
    }


    function assetPrice() public view override returns (uint256) {
        return priceOracle.lpPrice();
    }

    function changePriceOracle(address priceOracle_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(priceOracle_ != address(0), 'Zero price oracle');
        priceOracle = IAssetPriceOracle(priceOracle_);

        resetPriceCache();

        emit PriceOracleChanged(priceOracle_);
    }

    function changeDailyDepositParams(uint256 dailyDepositDuration_, uint256 dailyDepositLimit_)
    public
    onlyRole(DEFAULT_ADMIN_ROLE)
    {
        dailyDepositDuration = dailyDepositDuration_;
        dailyDepositLimit = dailyDepositLimit_;

        dailyDepositTotal = 0;
        dailyDepositCountingBlock = dailyDepositDuration > 0 ? block.number : 0;
    }

    function changeDailyWithdrawParams(uint256 dailyWithdrawDuration_, uint256 dailyWithdrawLimit_)
    public
    onlyRole(DEFAULT_ADMIN_ROLE)
    {
        dailyWithdrawDuration = dailyWithdrawDuration_;
        dailyWithdrawLimit = dailyWithdrawLimit_;

        dailyWithdrawTotal = 0;
        dailyWithdrawCountingBlock = dailyWithdrawDuration > 0 ? block.number : 0;
    }

    function changeWithdrawFee(uint256 withdrawFee_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(withdrawFee_ <= FEE_DENOMINATOR, 'Bigger that 100%');
        feePercent = withdrawFee_;
    }

    function changeFeeDistributor(address feeDistributor_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(feeDistributor_ != address(0), 'Zero fee distributor');
        feeDistributor = feeDistributor_;
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
                dailyDepositCountingBlock = dailyDepositCountingBlock + dailyDepositDuration;
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
                dailyWithdrawCountingBlock = dailyWithdrawCountingBlock + dailyWithdrawDuration;
            }
            dailyWithdrawTotal += value;
            require(dailyWithdrawTotal <= dailyWithdrawLimit, 'Daily withdraw limit overflow');
        }
    }

    function _calcFee(
        address caller,
        uint256 value,
        uint256 nominal
    ) internal view override returns(uint256 valueFee, uint256 nominalFee) {
        valueFee = 0;
        nominalFee = 0;
        if (feePercent > 0 && !hasRole(REBALANCER_ROLE, caller)) {
            nominalFee = nominal.mulDiv(feePercent, FEE_DENOMINATOR, Math.Rounding.Down);
            valueFee = value.mulDiv(feePercent, FEE_DENOMINATOR, Math.Rounding.Down);
        }
    }


    function _withdrawFee(
        uint256 valueFee,
        uint256
    ) internal override {
        if (valueFee > 0) {
            SafeERC20.safeTransfer(IERC20Metadata(asset()), feeDistributor, valueFee);
        }
    }
}