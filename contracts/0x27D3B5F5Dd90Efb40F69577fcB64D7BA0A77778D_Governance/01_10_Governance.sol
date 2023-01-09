// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./Interfaces/IERC20.sol";
import "./Dependencies/LiquityMath.sol";
import "./Dependencies/BaseMath.sol";
import "./Dependencies/Ownable.sol";
import "./Interfaces/IOracle.sol";
import "./Interfaces/IBurnableERC20.sol";
import "./Interfaces/IGovernance.sol";

/*
 * The Default Pool holds the ETH and LUSD debt (but not LUSD tokens) from liquidations that have been redistributed
 * to active troves but not yet "applied", i.e. not yet recorded on a recipient active trove's struct.
 *
 * When a trove makes an operation that applies its pending ETH and LUSD debt, its pending ETH and LUSD debt is moved
 * from the Default Pool to the Active Pool.
 */
contract Governance is BaseMath, Ownable, IGovernance {
    using SafeMath for uint256;

    string public constant NAME = "Governance";
    uint256 public constant _100pct = 1000000000000000000; // 1e18 == 100%

    uint256 private BORROWING_FEE_FLOOR = (DECIMAL_PRECISION / 1000) * 0; // 0.5%
    uint256 private REDEMPTION_FEE_FLOOR = (DECIMAL_PRECISION / 1000) * 5; // 0.5%
    uint256 private MAX_BORROWING_FEE = (DECIMAL_PRECISION / 100) * 0; // 5%

    // Amount of ARTH to be locked in gas pool on opening troves
    uint256 private immutable ARTH_GAS_COMPENSATION;

    // Minimum amount of net ARTH debt a trove must have
    uint256 private immutable MIN_NET_DEBT;

    uint256 private immutable DEPLOYMENT_START_TIME;
    address public immutable troveManagerAddress;
    address public immutable borrowerOperationAddress;

    // Maximum amount of debt that this deployment can have (used to limit exposure to volatile assets)
    // set this according to how much ever debt we'd like to accumulate; default is infinity
    bool private allowMinting = true;

    // price feed
    IPriceFeed private priceFeed;

    // The fund which recieves all the fees.
    address private fund;

    address private maha;

    uint256 private maxDebtCeiling =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff; // infinity

    constructor(
        address _maha,
        address _timelock,
        address _troveManagerAddress,
        address _borrowerOperationAddress,
        address _priceFeed,
        address _fund,
        uint256 _maxDebtCeiling
    ) {
        troveManagerAddress = _troveManagerAddress;
        borrowerOperationAddress = _borrowerOperationAddress;
        DEPLOYMENT_START_TIME = block.timestamp;

        maha = _maha;
        priceFeed = IPriceFeed(_priceFeed);
        fund = address(_fund);
        if (_maxDebtCeiling > 0) maxDebtCeiling = _maxDebtCeiling;

        ARTH_GAS_COMPENSATION = 50e18;
        MIN_NET_DEBT = 250e18;

        transferOwnership(_timelock);
    }

    function setMaxDebtCeiling(uint256 _value) public onlyOwner {
        uint256 oldValue = maxDebtCeiling;
        maxDebtCeiling = _value;
        emit MaxDebtCeilingChanged(oldValue, _value, block.timestamp);
    }

    function setRedemptionFeeFloor(uint256 _value) public onlyOwner {
        uint256 oldValue = REDEMPTION_FEE_FLOOR;
        REDEMPTION_FEE_FLOOR = _value;
        emit RedemptionFeeFloorChanged(oldValue, _value, block.timestamp);
    }

    function setBorrowingFeeFloor(uint256 _value) public onlyOwner {
        uint256 oldValue = BORROWING_FEE_FLOOR;
        BORROWING_FEE_FLOOR = _value;
        emit BorrowingFeeFloorChanged(oldValue, _value, block.timestamp);
    }

    function setMaxBorrowingFee(uint256 _value) public onlyOwner {
        uint256 oldValue = MAX_BORROWING_FEE;
        MAX_BORROWING_FEE = _value;
        emit MaxBorrowingFeeChanged(oldValue, _value, block.timestamp);
    }

    function setFund(address _newFund) public onlyOwner {
        address oldAddress = address(fund);
        fund = address(_newFund);
        emit FundAddressChanged(oldAddress, _newFund, block.timestamp);
    }

    function setMAHA(address _maha) public onlyOwner {
        address oldAddress = address(maha);
        maha = address(_maha);
        emit MAHAChanged(oldAddress, _maha, block.timestamp);
    }

    function setPriceFeed(address _feed) public onlyOwner {
        address oldAddress = address(priceFeed);
        priceFeed = IPriceFeed(_feed);
        emit PriceFeedChanged(oldAddress, _feed, block.timestamp);
    }

    function setAllowMinting(bool _value) public onlyOwner {
        bool oldFlag = allowMinting;
        allowMinting = _value;
        emit AllowMintingChanged(oldFlag, _value, block.timestamp);
    }

    function getDeploymentStartTime() external view override returns (uint256) {
        return DEPLOYMENT_START_TIME;
    }

    function getMAHA() external view override returns (IERC20) {
        return IERC20(maha);
    }

    function getBorrowingFeeFloor() external view override returns (uint256) {
        return BORROWING_FEE_FLOOR;
    }

    function getRedemptionFeeFloor() external view override returns (uint256) {
        return REDEMPTION_FEE_FLOOR;
    }

    function getMaxBorrowingFee() external view override returns (uint256) {
        return MAX_BORROWING_FEE;
    }

    function getMaxDebtCeiling() external view override returns (uint256) {
        return maxDebtCeiling;
    }

    function getGasCompensation() external view override returns (uint256) {
        return ARTH_GAS_COMPENSATION;
    }

    function getMinNetDebt() external view override returns (uint256) {
        return MIN_NET_DEBT;
    }

    function getFund() external view override returns (address) {
        return fund;
    }

    function getAllowMinting() external view override returns (bool) {
        return allowMinting;
    }

    function getPriceFeed() external view override returns (IPriceFeed) {
        return priceFeed;
    }
}