// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "@violetprotocol/extendable/extensions/InternalExtension.sol";

interface IGasRefund {
    /**
     * @dev Emitted when gas is refunded to a user
     */
    event GasRefunded(address recipient, uint256 weiRefunded);

    /**
     * @dev Emitted when funds are deposited into the contract
     */
    event Deposited(address by, uint256 amount);

    /**
     * @dev Emitted when funds are withdrawn from the contract
     */
    event Withdrawn(address by, uint256 amount);

    /**
     * @notice Deposits ETH into the contract for refunding gas
     */
    function depositFunds() external payable;

    /**
     * @notice Withdraws ETH from the contract
     */
    function withdrawFunds(uint256 amount) external;

    /**
     * @notice Refunds all gas spent up until this point in execution to the transaction sender
     */
    function refundExecution(uint256 amount) external;
}

abstract contract GasRefundExtension is IGasRefund, InternalExtension {
    /**
     * @dev see {IExtension-getSolidityInterface}
     */
    function getSolidityInterface() public pure virtual override returns (string memory) {
        return
            "function depositFunds() external;\n"
            "function withdrawFunds(uint256 amount) external;\n"
            "function refundExecution(uint256 amount) external;\n";
    }

    /**
     * @dev see {IExtension-getInterface}
     */
    function getInterface() public virtual override returns (Interface[] memory interfaces) {
        interfaces = new Interface[](1);

        bytes4[] memory functions = new bytes4[](3);
        functions[0] = IGasRefund.depositFunds.selector;
        functions[1] = IGasRefund.withdrawFunds.selector;
        functions[2] = IGasRefund.refundExecution.selector;

        interfaces[0] = Interface(type(IGasRefund).interfaceId, functions);
    }
}