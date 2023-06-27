// SPDX-License-Identifier: CSI

pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

/**
 * CNFT Platform Relay Contract
 */
contract PlatformRelay is AccessControl, Ownable2Step {
    error CannotBeZeroAddress();
    error TransferNotAllowed();
    event ContractDeployed(address contract_);

    bytes32 public constant PROXY_EXECUTOR = keccak256("PROXY_EXECUTOR");

    modifier onlyNonZeroAddressAllowed(address address_) {
        if (address_ == address(0)) revert CannotBeZeroAddress();
        _;
    }

    struct Call {
        address target;
        bytes callData;
    }

    string internal constant NAME = "ConsenSys NFT Platform Relayer";
    string internal constant VERSION = "1.0";

    constructor(address owner) onlyNonZeroAddressAllowed(owner) {
        _transferOwnership(owner);
    }

    /** -----------------------------------------------------------------------
     *  Owner permissioned functions
     * ------------------------------------------------------------------------
     */
    /// @notice Relay can not be owned directly by single EOA
    /// @param newOwner The target address to call
    function transferOwnership(address newOwner) public virtual override onlyOwner onlyNonZeroAddressAllowed(newOwner) {
        super.transferOwnership(newOwner);
    }

    /// @notice Add accounts which can execute transactions
    /// @param accounts The accounts to add
    function addExecutors(address[] memory accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _grantRole(PROXY_EXECUTOR, accounts[i]);
        }
    }

    /// @notice Remove accounts which can execute transactions
    /// @param accounts The accounts to remove
    function removeExecutors(address[] memory accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _revokeRole(PROXY_EXECUTOR, accounts[i]);
        }
    }

    /** -----------------------------------------------------------------------
     *  PROXY_EXECUTOR permissioned functions
     * ------------------------------------------------------------------------
     */
    /// @notice Relay a call via this contract
    /// @param target The target address to call
    /// @param callData The call data to pass to the target
    /// @return The return value from the call
    function execute(address target, bytes calldata callData) external onlyRole(PROXY_EXECUTOR) returns (bytes memory) {
        return executeInternal(target, callData);
    }

    /// @notice Relay multiple call via this contract. This will revert payable actions, ie sending msg.value.
    /// @param calls Array of calls to execute
    /// @return returnData The return value from the call
    function execute(Call[] calldata calls) external onlyRole(PROXY_EXECUTOR) returns (bytes[] memory returnData) {
        returnData = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            returnData[i] = executeInternal(calls[i].target, calls[i].callData);
        }
    }

    /// @dev Deploys a contract using `CREATE2`. The address where the contract
    /// will be deployed can be known in advance via {computeAddress}.
    /// @param bytecode must not be empty.
    /// @param salt must have not been used for `bytecode` already.
    function deploy(bytes32 salt, bytes memory bytecode) external onlyRole(PROXY_EXECUTOR) returns (address) {
        address address_ = Create2.deploy(0, salt, bytecode);
        emit ContractDeployed(address_);
        return address_;
    }

    /** -----------------------------------------------------------------------
     *  Helper functions
     * ------------------------------------------------------------------------
     */
    /// @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
    /// bytecode or salt will result in a new address.
    function computeAddress(bytes32 salt, bytes memory bytecode) external view returns (address) {
        return Create2.computeAddress(salt, keccak256(bytecode));
    }

    function executeInternal(address target, bytes memory callData) internal returns (bytes memory returnData) {
        (bool success, bytes memory ret) = target.call(callData);
        if (success != true) {
            // Next 5 lines from https://ethereum.stackexchange.com/a/83577
            if (ret.length < 68) revert();
            assembly {
                ret := add(ret, 0x04)
            }
            revert(abi.decode(ret, (string)));
        }
        return ret;
    }
}