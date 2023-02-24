// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "../../interfaces/ISwitchboard.sol";
import "../../interfaces/IOracle.sol";
import "../../utils/AccessControl.sol";

import "../../libraries/RescueFundsLib.sol";

abstract contract SwitchboardBase is ISwitchboard, AccessControl {
    IOracle public oracle__;
    bool public tripGlobalFuse;
    mapping(uint256 => uint256) public executionOverhead;

    event SwitchboardTripped(bool tripGlobalFuse);
    event ExecutionOverheadSet(uint256 dstChainSlug, uint256 executionOverhead);
    event OracleSet(address oracle);
    event FeesWithdrawn(address account, uint256 value);

    error TransferFailed();
    error FeesNotEnough();

    function payFees(uint256 dstChainSlug_) external payable override {
        (uint256 expectedFees, ) = _calculateFees(dstChainSlug_);
        if (msg.value < expectedFees) revert FeesNotEnough();
    }

    function getMinFees(
        uint256 dstChainSlug_
    ) external view override returns (uint256, uint256) {
        return _calculateFees(dstChainSlug_);
    }

    function _calculateFees(
        uint256 dstChainSlug_
    ) internal view returns (uint256 switchboardFee, uint256 verificationFee) {
        uint256 dstRelativeGasPrice = oracle__.relativeGasPrice(dstChainSlug_);

        switchboardFee = _getSwitchboardFees(
            dstChainSlug_,
            dstRelativeGasPrice
        );
        verificationFee =
            executionOverhead[dstChainSlug_] *
            dstRelativeGasPrice;
    }

    function _getSwitchboardFees(
        uint256 dstChainSlug_,
        uint256 dstRelativeGasPrice_
    ) internal view virtual returns (uint256) {}

    /**
     * @notice updates execution overhead
     * @param executionOverhead_ new execution overhead cost
     */
    function setExecutionOverhead(
        uint256 dstChainSlug_,
        uint256 executionOverhead_
    ) external onlyOwner {
        executionOverhead[dstChainSlug_] = executionOverhead_;
        emit ExecutionOverheadSet(dstChainSlug_, executionOverhead_);
    }

    /**
     * @notice updates oracle address
     * @param oracle_ new oracle
     */
    function setOracle(address oracle_) external onlyOwner {
        oracle__ = IOracle(oracle_);
        emit OracleSet(oracle_);
    }

    // TODO: to support fee distribution
    /**
     * @notice transfers the fees collected to `account_`
     * @param account_ address to transfer ETH
     */
    function withdrawFees(address account_) external onlyOwner {
        require(account_ != address(0));

        uint256 value = address(this).balance;
        (bool success, ) = account_.call{value: value}("");
        if (!success) revert TransferFailed();

        emit FeesWithdrawn(account_, value);
    }

    function rescueFunds(
        address token_,
        address userAddress_,
        uint256 amount_
    ) external onlyOwner {
        RescueFundsLib.rescueFunds(token_, userAddress_, amount_);
    }
}