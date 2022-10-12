// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./debridge/Flags.sol";
import "./debridge/IDeBridgeGateExtended.sol";
import "./debridge/ICallProxy.sol";

import ".././interfaces/ICSMCrossChainRouter.sol";
import ".././interfaces/IPoolCrossChain.sol";

contract CSMCrossChainRouter is ICSMCrossChainRouter, AccessControl, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant ROUTE_ROLE = keccak256("ROUTE_ROLE");
    bytes32 public constant ACCOUNTANT_ROLE = keccak256("ACCOUNTANT_ROLE");

    /// @notice approved assets by address and chain address(IAsset)=>chainId=>assetId
    mapping(address => mapping(uint256 => uint256)) private _approvedAssetIds;

    /// @notice approved assets by chain and asset id chainId=>assetId=>address(IAsset)
    mapping(uint256 => mapping(uint256 => address)) private _approvedAsset;

    mapping(uint256 => mapping(uint256 => CrossChainAsset)) private _crossChainAsset;

    /// @notice routers that will receive the messages and route them to the specific action, chainId=>address
    mapping(uint256 => address) private _approvedRouters;

    /// @notice a mapping containing all pools indexed by their assets address(IAsset)=>poolAddress
    mapping(address => IPoolCrossChain) private _poolPerAsset;

    /// @dev DeBridgeGate's address on the current chain
    IDeBridgeGateExtended public deBridgeGate;

    address payable public refundAddress;

    event MessageRouted(uint256 destinationChain, address indexed destinationAddress);
    event MessageReceived(
        address indexed sender,
        address indexed srcAsset,
        address indexed dstAsset,
        uint256 amount,
        uint256 haircut
    );
    event ToggleAssetAndChain(
        uint256 chainId,
        address assetAddress,
        address tokenAddress,
        uint256 assetId,
        uint256 decimals,
        bool add
    );
    event ModifyCrossChainParams(uint256 chainId, uint256 assetId, uint256 cash, uint256 liability);
    event TogglePoolPerAssets(address asset, IPoolCrossChain pool);
    event ToggleApprovedRouter(uint256 chainId, address router);
    event ForceResumeL0(uint256 srcChain, bytes srcAddress);
    event RetryL0Payload(uint256 srcChain, bytes srcAddress, bytes payload);
    event MessageFailed(uint256 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes _payload);
    event ExecutionFeeChanged(uint256 _oldFee, uint256 _newFee);

    constructor(IDeBridgeGateExtended deBridgeGate_) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ROUTE_ROLE, msg.sender);
        _setupRole(ACCOUNTANT_ROLE, msg.sender);
        deBridgeGate = deBridgeGate_;
        refundAddress = payable(msg.sender);
    }

    function isApprovedAsset(uint256 chainId_, uint256 assetId_) public view override returns (bool) {
        return _approvedAsset[chainId_][assetId_] != address(0);
    }

    function isApprovedRouter(uint256 chainId_, address router_) public view override returns (bool) {
        return _approvedRouters[chainId_] == router_;
    }

    function isApprovedAsset(uint256 chainId_, address assetAddress_) public view override returns (bool) {
        return _approvedAssetIds[assetAddress_][chainId_] > 0;
    }

    function getAssetData(uint256 chainId_, uint256 assetId_) external view override returns (CrossChainAsset memory) {
        return _crossChainAsset[chainId_][assetId_];
    }

    function getAssetData(uint256 chainId_, address assetAddress_)
        external
        view
        override
        returns (CrossChainAsset memory)
    {
        return _crossChainAsset[chainId_][_approvedAssetIds[assetAddress_][chainId_]];
    }

    function getApprovedAssetId(address assetAddress_, uint256 chainId_) public view override returns (uint256) {
        return _approvedAssetIds[assetAddress_][chainId_];
    }

    function getCrossChainAssetParams(uint256 chainId_, uint256 assetId_)
        external
        view
        override
        returns (uint256, uint256)
    {
        return (_crossChainAsset[chainId_][assetId_].cash, _crossChainAsset[chainId_][assetId_].liability);
    }

    function estimateFee() public view override returns (uint256) {
        return deBridgeGate.globalFixedNativeFee();
    }

    /// @dev make sure msg.value is equals with the fee
    function route(
        uint256 dstChain_,
        address dstAddress_,
        bytes calldata payload_,
        uint256 executionFee_
    ) external payable override onlyRole(ROUTE_ROLE) nonReentrant {
        IDeBridgeGate.SubmissionAutoParamsTo memory autoParams;
        uint256 amountAfterBridge = (executionFee_ * (10000 - deBridgeGate.globalTransferFeeBps())) / 10000;
        // use the execution fee to modify the state on dst chain
        autoParams.executionFee = amountAfterBridge;

        // Exposing nativeSender must be requested explicitly
        // We request it bc of CrossChainCounter's onlyCrossChainIncrementor modifier
        autoParams.flags = Flags.setFlag(autoParams.flags, Flags.PROXY_WITH_SENDER, true);

        // if something happens, we need to revert the transaction, otherwise the sender will loose assets
        autoParams.flags = Flags.setFlag(autoParams.flags, Flags.REVERT_IF_EXTERNAL_FAIL, true);

        autoParams.data = payload_;
        autoParams.fallbackAddress = abi.encodePacked(refundAddress);
        require(executionFee_ + deBridgeGate.globalFixedNativeFee() <= msg.value, "NOT_ENOUGH_FEE");

        deBridgeGate.send{ value: msg.value }(
            address(0), // _tokenAddress
            executionFee_, // _amount
            dstChain_, // _chainIdTo
            abi.encodePacked(_approvedRouters[dstChain_]), // _receiver
            "", // _permit
            false, // _useAssetFee
            0, // _referralCode
            abi.encode(autoParams) // _autoParams
        );
        emit MessageRouted(dstChain_, dstAddress_);
    }

    function routerReceive(
        address sender_,
        address srcAsset_,
        address dstAsset_,
        uint256 amount_,
        uint256 haircut_,
        uint256 nonce_
    ) external {
        ICallProxy callProxy = ICallProxy(deBridgeGate.callProxy());

        // checks if the caller is deBridge proxy
        require(address(callProxy) == msg.sender, "NOT_PROXY");

        uint256 chainIdFrom = callProxy.submissionChainIdFrom();

        // verify if the tx originates from the router on src chain approved router == senderAddress
        bytes memory nativeSender = callProxy.submissionNativeSender();
        address senderAddress = bytesToAddress(nativeSender);
        require(_approvedRouters[chainIdFrom] == senderAddress, "SRC_CHAIN_NOT_APPROVED");

        require(isApprovedAsset(chainIdFrom, srcAsset_), "ASSET_NOT_APPROVED");

        _poolPerAsset[dstAsset_].receiveSwapCrossChain(
            sender_,
            chainIdFrom,
            srcAsset_,
            dstAsset_,
            amount_,
            haircut_,
            nonce_
        );

        emit MessageReceived(sender_, srcAsset_, dstAsset_, amount_, haircut_);
    }

    function toggleAssetAndChain(
        uint256 chainId_,
        address assetAddress_,
        address tokenAddress_,
        uint256 assetId_,
        uint256 decimals_,
        bool add_
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        if (add_) {
            require(chainId_ > 0, "INVALID_CHAIN");
            require(assetAddress_ != address(0), "INVALID_ASSET_ADDRESS");
            require(tokenAddress_ != address(0), "INVALID_ASSET_ADDRESS");
            require(assetId_ > 0, "INVALID_ASSET_ID");
            require(decimals_ > 0, "INVALID_DECIMALS");

            _approvedAssetIds[assetAddress_][chainId_] = assetId_;
            _approvedAsset[chainId_][assetId_] = assetAddress_;
            _crossChainAsset[chainId_][assetId_] = CrossChainAsset(
                0,
                0,
                decimals_,
                uint64(assetId_),
                assetAddress_,
                tokenAddress_
            );
        } else {
            delete _approvedAssetIds[assetAddress_][chainId_];
            delete _approvedAsset[chainId_][assetId_];
            delete _crossChainAsset[chainId_][assetId_];
        }

        emit ToggleAssetAndChain(chainId_, assetAddress_, tokenAddress_, assetId_, decimals_, add_);
    }

    // TODO add a timestamp check so in case these variables weren't updated for X amount of time, the swap to fail.
    function modifyCrossChainParams(
        uint256 chainId_,
        uint256 assetId_,
        uint256 cash_,
        uint256 liability_
    ) external onlyRole(ACCOUNTANT_ROLE) {
        require(_approvedAsset[chainId_][assetId_] != address(0), "ASSET_NOT_AVAILABLE");

        CrossChainAsset storage crossChainAsset = _crossChainAsset[chainId_][assetId_];
        crossChainAsset.cash = cash_;
        crossChainAsset.liability = liability_;
        emit ModifyCrossChainParams(chainId_, assetId_, cash_, liability_);
    }

    function togglePoolPerAssets(address asset_, IPoolCrossChain pool_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _poolPerAsset[asset_] = pool_;
        emit TogglePoolPerAssets(asset_, pool_);
    }

    function toggleApprovedRouters(uint256 chainId_, address router_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _approvedRouters[chainId_] = router_;
        emit ToggleApprovedRouter(chainId_, router_);
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}