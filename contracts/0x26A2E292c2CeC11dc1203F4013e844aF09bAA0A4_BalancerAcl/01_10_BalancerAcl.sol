// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}

interface IVault{
    enum SwapKind { GIVEN_IN, GIVEN_OUT }

    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

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
}

import "UUPSUpgradeable.sol";
import "OwnableUpgradeable.sol";

contract BalancerAcl is OwnableUpgradeable, UUPSUpgradeable {
    address public safeAddress;
    address public safeModule;

    bytes32 private _checkedRole = hex"01";
    uint256 private _checkedValue = 1;
    string public constant NAME = "BalancerAcl";
    uint public constant VERSION = 1;

    mapping(bytes32 => bool) public _poolIdWhitelist;
    mapping(address => bool) public _tokenWhitelist;

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

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

    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    struct OutputReference {
        uint256 index;
        uint256 key;
    }


    /// @notice Constructor function for Acl
    /// @param _safeAddress the Gnosis Safe (GnosisSafeProxy) instance's address
    /// @param _safeModule the CoboSafe module instance's address
    function initialize(
        address _safeAddress,
        address _safeModule
    ) public initializer {
        __BALANCERACL_init(_safeAddress, _safeModule);
    }

    function __BALANCERACL_init(
        address _safeAddress,
        address _safeModule
    ) internal onlyInitializing {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __BALANCERACL_init_unchained(_safeAddress, _safeModule);
    }

    function __BALANCERACL_init_unchained(
        address _safeAddress,
        address _safeModule
    ) internal onlyInitializing {
        require(_safeAddress != address(0), "Invalid safe address");
        require(_safeModule != address(0), "Invalid module address");
        safeAddress = _safeAddress;
        safeModule = _safeModule;

        // make the given safe the owner of the current acl.
        _transferOwnership(_safeAddress);
    }

    modifier onlySelf() {
        require(address(this) == msg.sender, "Caller is not inner");
        _;
    }

    modifier onlyModule() {
        require(safeModule == msg.sender, "Caller is not the module");
        _;
    }

    modifier onlySafe() {
        require(safeAddress == msg.sender, "Caller is not the safe");
        _;
    }

    function check(
        bytes32 _role,
        uint256 _value,
        bytes calldata data
    ) external onlyModule returns (bool) {
        _checkedRole = _role;
        _checkedValue = _value;
        (bool success, ) = address(this).staticcall(data);
        _checkedRole = hex"01";
        _checkedValue = 1;
        return success;
    }

    fallback() external {
        revert("Unauthorized access");
    }

    // ACL methods

    function setPool(bytes32 poolId, bool poolStatus) external onlySafe returns (bool){
        require(_poolIdWhitelist[poolId] != poolStatus, "poolId poolStatus existed");
        _poolIdWhitelist[poolId] = poolStatus;
        return true;
    }

    function setToken(address token, bool tokenStatus) external onlySafe returns (bool){
        require(_tokenWhitelist[token] != tokenStatus, "token tokenStatus existed");
        _tokenWhitelist[token] = tokenStatus;
        return true;
    }


    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable onlySelf {
        require(_poolIdWhitelist[poolId], "poolId is not allowed");
        require(sender == safeAddress, "sender address is not allowed");
        require(recipient == safeAddress, "recipient address is not allowed");
    }

    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external onlySelf {
        require(_poolIdWhitelist[poolId], "poolId is not allowed");
        require(sender == safeAddress, "sender address is not allowed");
        require(recipient == safeAddress, "recipient address is not allowed");
    }

    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    ) external payable onlySelf {
        require(
            funds.sender == safeAddress,
            "funds.sender address is not allowed"
        );
        require(
            funds.recipient == safeAddress,
            "funds.recipient is not allowed"
        );
        require(_tokenWhitelist[address(assets[0])], "Token is not allowed");
        require(_tokenWhitelist[address(assets[assets.length - 1])], "Token is not allowed");
    }

    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable onlySelf {
        require(
            funds.sender == safeAddress,
            "funds.sender address is not allowed"
        );
        require(
            funds.recipient == safeAddress,
            "funds.recipient is not allowed"
        );
        require(_tokenWhitelist[address(singleSwap.assetIn)], "Token is not allowed");
        require(_tokenWhitelist[address(singleSwap.assetOut)], "Token is not allowed");
    }

    // multicall
    function multicall(bytes[] calldata data) external payable onlySelf {
        for (uint256 i = 0; i < data.length; i++) {
            (bool success , bytes memory return_data) = address(this).staticcall(data[i]);
            require(success, "Failed in multicall");
        }
    }

    enum PoolKind { WEIGHTED }

    function joinPool(
        bytes32 poolId,
        PoolKind kind,
        address sender,
        address recipient,
        IVault.JoinPoolRequest memory request,
        uint256 value,
        uint256 outputReference
    ) external payable onlySelf {
        require(_poolIdWhitelist[poolId], "poolId is not allowed");
        require(sender == safeAddress, "sender address is not allowed");
        require(recipient == safeAddress, "recipient address is not allowed");
    }

    function exitPool(
        bytes32 poolId,
        PoolKind kind,
        address sender,
        address payable recipient,
        IVault.ExitPoolRequest memory request,
        OutputReference[] calldata outputReferences
    ) external payable onlySelf {
        require(_poolIdWhitelist[poolId], "poolId is not allowed");
        require(sender == safeAddress, "sender address is not allowed");
        require(recipient == safeAddress, "recipient address is not allowed");
    }

    function setRelayerApproval(
        address relayer,
        bool approved,
        bytes calldata authorisation
    ) external payable onlySelf {}


    function batchSwap(
        IVault.SwapKind kind,
        IVault.BatchSwapStep[] memory swaps,
        IAsset[] calldata assets,
        IVault.FundManagement calldata funds,
        int256[] calldata limits,
        uint256 deadline,
        uint256 value,
        OutputReference[] calldata outputReferences
    ) external payable onlySelf {
        require(
            funds.sender == safeAddress,
            "funds.sender address is not allowed"
        );
        require(
            funds.recipient == safeAddress,
            "funds.recipient is not allowed"
        );
        require(_tokenWhitelist[address(assets[0])], "Token is not allowed");
        require(_tokenWhitelist[address(assets[assets.length - 1])], "Token is not allowed");
    }

    /// @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
    /// {upgradeTo} and {upgradeToAndCall}.
    function _authorizeUpgrade(address) internal override onlyOwner {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}