// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ISmartWallet {
    /**
     * @dev Initializes the contract by checking compatibility and setting `_whitelistAddress`
     * that is later used to decide who is allowed to call {execute}.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function initialize(address _whitelistAddress) external;

    /**
     * @dev Allows caller to execute arbitrary method on arbitrary contract with arbitrary params.
     *
     * This method uses `CALL` opcode therefore method will be executed
     * in context (in the name) of this contract.
     *
     * To make simple `send`, `_encodedCalldata` should be `""`.
     *
     * It will revert if:
     * - contract was not initialized with {init},
     * - called from non-whitelisted address,
     * - `_contractAddress` doesn't implement method/has wrong params encoded in `_encodedCalldata`
     * - executed method fails within the called contract (revert message will be returned thanks to helper)
     *
     * Returns encoded bytes with result of called method.
     *
     * Example:
     *```
     * bytes memory encodedResult = execute(address(some ERC20), abi.encodeWithSignature("balanceOf(address)", 0x0...0)
     * uint256 decodedResult = abi.decode(encodedResult, uint256)
     *```
     */

    function execute(address _contractAddress, bytes calldata _encodedCalldata)
        external
        returns (bytes memory);

    function execute(
        address _contractAddress,
        bytes calldata _encodedCalldata,
        uint256 _value
    ) external returns (bytes memory);
}