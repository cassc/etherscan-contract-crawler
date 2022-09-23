// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IVault} from "./interfaces/IVault.sol";
import {Clone} from "clones-with-immutable-args/src/Clone.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {NFTReceiver} from "./utils/NFTReceiver.sol";

/// @title Vault
/// @author Tessera
/// @notice Proxy contract for storing fractionalized assets
contract Vault is Clone, IVault, NFTReceiver {
    address immutable original;
    /// @dev Minimum reserve of gas units
    uint256 private constant MIN_GAS_RESERVE = 5_000;
    bytes4 private constant FALLBACK_SELECTOR = bytes4(0);
    uint256 private constant MERKLE_ROOT_POSITION = 0;
    uint256 private constant OWNER_POSITION = 32;
    uint256 private constant FACTORY_POSITION = 52;
    /// @notice Mapping of function selector to plugin address
    mapping(bytes4 => address) public methods;

    constructor() {
        original = address(this);
    }

    /// @dev Callback for receiving Ether when the calldata is empty
    receive() external payable {}

    /// @dev Callback for handling plugin transactions
    /// @param _data Transaction data
    /// @return response Return data from executing plugin
    // prettier-ignore
    fallback(bytes calldata _data) external payable returns (bytes memory response) {
        if (msg.sig != FALLBACK_SELECTOR){
            address plugin = methods[msg.sig];
            if (plugin == address(0)) revert MethodNotFound();
            (,response) = _execute(plugin, _data);
        }
    }

    /// @notice Executes vault transactions through delegatecall
    /// @param _target Target address
    /// @param _data Transaction data
    /// @param _proof Merkle proof of permission hash
    /// @return success Result status of delegatecall
    /// @return response Return data of delegatecall
    function execute(
        address _target,
        bytes calldata _data,
        bytes32[] calldata _proof
    ) external payable returns (bool success, bytes memory response) {
        bytes4 selector;
        assembly {
            selector := calldataload(_data.offset)
        }

        // Generate leaf node by hashing module, target and function selector.
        bytes32 leaf = keccak256(abi.encode(msg.sender, _target, selector));
        // Check that the caller is either a module with permission to call or the owner.
        if (!MerkleProof.verify(_proof, MERKLE_ROOT(), leaf)) {
            if (msg.sender != OWNER()) revert NotAuthorized(msg.sender, _target, selector);
        }

        (success, response) = _execute(_target, _data);
    }

    /// @notice Installs plugin by setting function selector to contract address
    /// @param _plugins Addresses of plugin contracts
    /// @param _selectors List of function selectors
    function setPlugins(address[] memory _plugins, bytes4[] memory _selectors) external {
        address owner = OWNER();
        if (owner != msg.sender) {
            /// allows the factory to install plugins on deployment
            if (FACTORY() != msg.sender) revert NotOwner(owner, msg.sender);
        }

        uint256 pluginsLength = _plugins.length;
        uint256 selectorsLength = _selectors.length;
        bytes4 selector;
        if (pluginsLength != selectorsLength) revert ArrayMismatch(pluginsLength, selectorsLength);
        uint256 i;
        for (; i < selectorsLength; ) {
            selector = _selectors[i];
            if (methods[selector] != address(0)) revert InvalidSelector(selector);
            methods[selector] = _plugins[i];
            unchecked {
                ++i;
            }
        }
        emit UpdatedPlugins(_selectors, _plugins);
    }

    /// @notice Getter for merkle root stored as an immutable argument
    function MERKLE_ROOT() public pure returns (bytes32) {
        return _getArgBytes32(MERKLE_ROOT_POSITION);
    }

    /// @notice Getter for owner of vault
    function OWNER() public pure returns (address) {
        return _getArgAddress(OWNER_POSITION);
    }

    /// @notice Getter for factory of vault
    function FACTORY() public pure returns (address) {
        return _getArgAddress(FACTORY_POSITION);
    }

    /// @notice Executes plugin transactions through delegatecall
    /// @param _target Target address
    /// @param _data Transaction data
    /// @return success Result status of delegatecall
    /// @return response Return data of delegatecall
    function _execute(address _target, bytes calldata _data)
        internal
        returns (bool success, bytes memory response)
    {
        require(original != address(this), "only delegate call");

        if (_target.code.length == 0) revert TargetInvalid(_target);
        // Reserve some gas to ensure that the function has enough to finish the execution
        uint256 stipend = gasleft() - MIN_GAS_RESERVE;

        // Delegate call to the target contract
        (success, response) = _target.delegatecall{gas: stipend}(_data);

        // Revert if execution was unsuccessful
        if (!success) {
            if (response.length == 0) revert ExecutionReverted();
            _revertedWithReason(response);
        }
    }

    /// @notice Reverts transaction with reason
    /// @param _response Unsucessful return response of the delegate call
    function _revertedWithReason(bytes memory _response) internal pure {
        assembly {
            let returndata_size := mload(_response)
            revert(add(32, _response), returndata_size)
        }
    }
}