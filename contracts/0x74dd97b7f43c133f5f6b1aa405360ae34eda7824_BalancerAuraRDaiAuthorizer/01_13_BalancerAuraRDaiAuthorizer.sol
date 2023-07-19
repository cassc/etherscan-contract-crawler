// commit 05f8641fe3078eefe6ddc9ac42345c5e969107f1
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "FarmingBaseACL.sol";

interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}

contract BalancerAuraRDaiAuthorizer is FarmingBaseACL {
    bytes32 public constant NAME = "BalancerAuraRDaiAuthorizer";
    uint256 public constant VERSION = 1;

    address public VAULT_ADDRESS;
    address public BOOSTER_ADDRESS;

    using EnumerableSet for EnumerableSet.Bytes32Set;
    EnumerableSet.Bytes32Set balancerFarmPoolIdWhitelist;

    struct JoinPoolRequest {
        IAsset[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    struct ExitPoolRequest {
        IAsset[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    event AddPoolIdWhitelist(bytes32 indexed _poolId, address indexed user);
    event RemovePoolIdWhitelist(bytes32 indexed _poolId, address indexed user);

    constructor(address _owner, address _caller) FarmingBaseACL(_owner, _caller) {}

    function contracts() public view override returns (address[] memory _contracts) {
        _contracts = new address[](2);
        _contracts[0] = BOOSTER_ADDRESS;
        _contracts[1] = VAULT_ADDRESS;
    }

    // Set
    function setBooster(address _booster) external onlyOwner {
        BOOSTER_ADDRESS = _booster;
    }

    function setVault(address _vault) external onlyOwner {
        VAULT_ADDRESS = _vault;
    }

    function addBalancerPoolIds(bytes32[] calldata _poolIds) external onlyOwner {
        for (uint256 i = 0; i < _poolIds.length; i++) {
            if (balancerFarmPoolIdWhitelist.add(_poolIds[i])) {
                emit AddPoolIdWhitelist(_poolIds[i], msg.sender);
            }
        }
    }

    function removeBalancerPoolIds(bytes32[] calldata _poolIds) external onlyOwner {
        for (uint256 i = 0; i < _poolIds.length; i++) {
            if (balancerFarmPoolIdWhitelist.remove(_poolIds[i])) {
                emit RemovePoolIdWhitelist(_poolIds[i], msg.sender);
            }
        }
    }

    // View
    function getBalancerPoolIdWhiteList() external view returns (bytes32[] memory) {
        return balancerFarmPoolIdWhitelist.values();
    }

    // Acl

    // Balancer
    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external view onlyContract(VAULT_ADDRESS) {
        _poolCheck(poolId, sender, recipient);
    }

    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external view onlyContract(VAULT_ADDRESS) {
        _poolCheck(poolId, sender, recipient);
    }

    // Aura
    function deposit(uint256 _pid, uint256 _amount, bool _stake) external view onlyContract(BOOSTER_ADDRESS) {
        _checkAllowPoolId(_pid);
        require(_stake == true, "_stake must be true");
    }

    // Internal
    function _poolCheck(bytes32 _poolId, address _sender, address _recipient) internal view {
        _checkBalancerAllowPoolId(_poolId);
        _checkRecipient(_sender);
        _checkRecipient(_recipient);
    }

    function _checkBalancerAllowPoolId(bytes32 _poolId) internal view {
        require(balancerFarmPoolIdWhitelist.contains(_poolId), "pool id not allowed");
    }
}