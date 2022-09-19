// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;


import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";


contract WhitelistRegistry {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    address owner;
    EnumerableSet.AddressSet private _whitelistedTargets;
    EnumerableSet.Bytes32Set private _whitelistedActions;

    constructor(address _daaManager){
        owner = _daaManager;
    }

    /// @dev Add action to whitelisted action list
    /// @param actionId The bytes4 action to add to bytes32 list
    function enableActionId(bytes4 actionId) external onlyOwner {
        require(actionId != 0x67314f12, "NoOwnerChange");
        _whitelistedActions.add(keccak256(abi.encode(actionId)));
    }

    /// @dev Add actions to whitelisted action list
    /// @param actionIds The bytes4 action list to add to bytes32 list
    function batchEnableActionIds(bytes4[] calldata actionIds) external onlyOwner {
        uint len = actionIds.length;
        for (uint i=0; i< len; i++){
            if (actionIds[i] != 0x67314f12) {
                _whitelistedActions.add(keccak256(abi.encode(actionIds[i])));
            }
        }
    }

    /// @dev Add target address to whitelisted target list
    /// @param target The action address to add to the address list
    function enableTargetDest(address target) external onlyOwner {
        _whitelistedTargets.add(target);
    }

    /// @dev Add target address batch to whitelisted target list
    /// @param targets The action address to add to the address list
    function batchEnableTargets(address[] calldata targets) external onlyOwner {
        uint len = targets.length;
        for (uint i=0; i< len; i++){
            _whitelistedTargets.add(targets[i]);
        }
    }

    /// @dev Remove action from whitelisted action list
    /// @param actionId The bytes4 action to add to bytes32 list
    function disableActionId(bytes4 actionId) external onlyOwner {
        _whitelistedActions.remove(keccak256(abi.encode(actionId)));
    }

    /// @dev Renove a batch of actions from whitelisted action list
    /// @param actionIds The bytes4 action list to remove to bytes32 list
    function batchRemoveActionIds(bytes4[] calldata actionIds) external onlyOwner {
        uint len = actionIds.length;
        for (uint i=0; i< len; i++){
            _whitelistedActions.remove(keccak256(abi.encode(actionIds[i])));
        }
    }

    /// @dev Remove target address from whitelisted target list
    /// @param target The action address to remove from the address list
    function disableTargetDest(address target) external onlyOwner {
        _whitelistedTargets.remove(target);
    }

    /// @dev Remove target address batch to whitelisted target list
    /// @param targets The action address to add to the address list
    function batchRemoveTargets(address[] calldata targets) external onlyOwner {
        uint len = targets.length;
        for (uint i=0; i< len; i++){
            _whitelistedTargets.remove(targets[i]);
        }
    }

    function changeOwner(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function isActionWhitelisted(bytes4 actionId) external view returns (bool) {
        return _whitelistedActions.contains(keccak256(abi.encode(actionId)));
    }

    function isTargetWhitelisted(address target) external view returns (bool) {
        return _whitelistedTargets.contains(target);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "NotAuth");
        _;
    }

}