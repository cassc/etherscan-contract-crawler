pragma solidity 0.8.17;

import "EnumerableSet.sol";
import "IERC20Metadata.sol";
import "SafeERC20.sol";
import "IBridgeAdapter.sol";
import "LzApp.sol";
import "EnumerableMap.sol";
import "DoubleEndedQueue.sol";

interface IRootVault is IERC20 {
    function totalAssets() external view returns (uint256);

	function convertToAssets(uint256 shares) external view returns(uint256);
}

interface IRootVaultZap {
    function deposit(address token, uint256 value)
        external
        returns (uint256 shares);

    function redeem(address token, uint256 shares)
        external
        returns (uint256 assets);
}

abstract contract CrossLedgerVault is LzApp {
    using SafeERC20 for IERC20Metadata;
    using SafeERC20 for IERC20;
	using SafeERC20 for IRootVault;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
	using EnumerableMap for EnumerableMap.UintToUintMap;


	enum LzMessage { UPDATE, REDEEM, DEPOSITED_FROM_BRIDGE }

    mapping(uint256 => uint16) public chainIdToLzChainId;
	mapping(uint16 => uint256) public LzChainIdToChainId;

	function _encodeUpdateMessage(bytes32 transferId, uint256 opId) pure internal returns(bytes memory) {
		bytes memory params = abi.encode(transferId, opId);
		return abi.encode(LzMessage.UPDATE, params);
	}

	function _encodeRedeemMessage(uint256 opId, uint256 shares, uint256 totalSupply, address receiver, address asset) pure internal returns(bytes memory) {
		bytes memory params = abi.encode(opId, shares, totalSupply, receiver, asset);
		return abi.encode(LzMessage.REDEEM, params);
	}

	function _encodeDepositedFromBridgeMessage(bytes32 transferId, uint256 totalAssetsBefore, uint256 totalAssetsAfter) pure internal returns(bytes memory) {
		bytes memory params = abi.encode(transferId, totalAssetsBefore, totalAssetsAfter);
		return abi.encode(LzMessage.DEPOSITED_FROM_BRIDGE, params);
	}

    EnumerableSet.AddressSet internal tokens;
    IRootVault public rootVault;
    IRootVaultZap public rootVaultZap;
    EnumerableSet.UintSet internal chains;

    // asset address => chain id => bridge adapter address
    mapping(address => mapping(uint256 => IBridgeAdapter))
        public bridgeAdapters;
	mapping(address => uint256) public bridgeAdapterToChainId;

    constructor(
        IRootVault _rootVault,
        IRootVaultZap _zap,
        address _lzEndpoint
    ) LzApp(_lzEndpoint) {
        rootVault = _rootVault;
        rootVaultZap = _zap;
		rootVault.safeIncreaseAllowance(address(rootVaultZap), type(uint256).max);
    }

	modifier onlyFromBridgeAdapter() {
        require(bridgeAdapterToChainId[msg.sender] != 0, "invalid caller");
		_;
    }

    modifier onlyAllowedToken(address token) {
        require(tokens.contains(token), "token is not allowed");
        _;
    }

    function addNewChain(uint256 chainId, uint16 lzChainId) external onlyOwner {
        chains.add(chainId);
		LzChainIdToChainId[lzChainId] = chainId;
		chainIdToLzChainId[chainId] = lzChainId;
    }

    function updateBridgeAdapter(
        address asset,
        uint256 chainId,
        IBridgeAdapter bridgeAdapter
    ) external onlyOwner onlyAllowedToken(asset) {
        require(
            chains.contains(chainId),
            "That distributed ledger has not been added yet"
        );
        bridgeAdapters[asset][chainId] = bridgeAdapter;
        IERC20Metadata(asset).safeApprove(
            address(bridgeAdapter),
            type(uint256).max
        );
		bridgeAdapterToChainId[address(bridgeAdapter)] = chainId;
    }

    function addNewToken(address token) external onlyOwner {
        require(!tokens.contains(token), "That token has already been added");

        tokens.add(token);
        IERC20Metadata(token).safeIncreaseAllowance(
            address(rootVaultZap),
            type(uint256).max
        );
    }

    function removeToken(address token) external onlyOwner onlyAllowedToken(token) {
        tokens.remove(token);
    }

    function _estimateLzCall(
        uint16 lzChainId,
        bytes memory payload,
        bytes memory adapterParams
    ) internal view returns (uint256 estimate) {
        (estimate, ) = lzEndpoint.estimateFees(
            lzChainId,
            address(this),
            payload,
            false,
            adapterParams
        );
    }

    function depositFundsToRootVault(bytes32 transferId, address asset, uint256 value)
        public
		virtual
        onlyFromBridgeAdapter
        onlyAllowedToken(asset)
        returns (uint256 shares)
    {
        IERC20(asset).safeTransferFrom(msg.sender, address(this), value);
        return _depositLocal(asset, value);
    }

	function transferCompleted(bytes32 transferId, address asset, uint256 value)
        public
		virtual
        onlyFromBridgeAdapter
    {
        
    }

    function totalAssets() public view returns(uint256) {
        return rootVault.convertToAssets(rootVault.balanceOf(address(this)));
    }

    function _depositLocal(address asset, uint256 assets) internal returns(uint256 shares) {
        return rootVaultZap.deposit(asset, assets);
    }

    function _redeemLocal(uint256 shares, uint256 totalSupply, address asset) internal returns(uint256 assets) {
        uint256 amountToRedeem = shares * rootVault.balanceOf(address(this)) / totalSupply;
        if (amountToRedeem > 0) {
            assets = rootVaultZap.redeem(asset, amountToRedeem);
        }
    }

	receive() external payable {

	}
}