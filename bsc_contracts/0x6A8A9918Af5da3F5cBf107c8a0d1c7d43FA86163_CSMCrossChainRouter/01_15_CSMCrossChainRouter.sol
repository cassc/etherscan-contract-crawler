// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./l0/ILayerZeroReceiver.sol";
import "./l0/ILayerZeroEndpoint.sol";
import "./l0/ILayerZeroUserApplicationConfig.sol";

import ".././interfaces/ICSMCrossChainRouterL0.sol";
import ".././interfaces/IPoolCrossChainL0.sol";
import "hardhat/console.sol";

contract CSMCrossChainRouter is ICSMCrossChainRouterL0, AccessControl, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant ROUTE_ROLE = keccak256("ROUTE_ROLE");
    bytes32 public constant ACCOUNTANT_ROLE = keccak256("ACCOUNTANT_ROLE");

    /// @notice approved assets by address and chain address(IAsset)=>chainId=>assetId
    mapping(address => mapping(uint16 => uint256)) private _approvedAssetIds;

    /// @notice approved assets by chain and asset id chainId=>assetId=>address(IAsset)
    mapping(uint16 => mapping(uint256 => address)) private _approvedAsset;

    mapping(uint16 => mapping(uint256 => CrossChainAsset)) private _crossChainAsset;

    /// @notice routers that will receive the messages and route them to the specific action, chainId=>address
    mapping(uint16 => bytes) private _approvedRouters;

    /// @notice a mapping containing all pools indexed by their assets address(IAsset)=>poolAddress
    mapping(address => IPoolCrossChainL0) private _poolsPerAssets;

    mapping(uint16 => mapping(bytes => mapping(uint64 => bytes32))) public failedMessages;

    /// @notice received parameters per chain per nonce
    mapping(uint16 => mapping(uint256 => CCReceiveParams)) private receivedParamsPerChain;

    ILayerZeroEndpoint public immutable layerZeroEndpoint;

    address payable public refundAddress;

    event MessageRouted(uint16 destinationChain, address indexed destinationAddress, uint64 nextNonce);
    event MessageReceived(
        address sender,
        uint16 srcChainId,
        address srcAsset,
        address dstAsset,
        uint256 nonce,
        uint256 amount,
        uint256 haircut,
        bytes signature
    );
    event ToggleAssetAndChain(
        uint16 chainId,
        address assetAddress,
        address tokenAddress,
        uint256 assetId,
        uint256 decimals,
        bool add
    );
    event ModifyCrossChainParams(uint16 chainId, uint256 assetId, uint256 cash, uint256 liability);
    event TogglePoolPerAssets(address asset, IPoolCrossChainL0 pool);
    event ToggleApprovedRouter(uint16 chainId, address router);
    event ForceResumeL0(uint16 srcChain, bytes srcAddress);
    event RetryL0Payload(uint16 srcChain, bytes srcAddress, bytes payload);
    event MessageFailed(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes _payload);

    constructor(ILayerZeroEndpoint l0Endpoint_) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ROUTE_ROLE, msg.sender);
        _setupRole(ACCOUNTANT_ROLE, msg.sender);
        layerZeroEndpoint = l0Endpoint_;
        refundAddress = payable(msg.sender);
    }

    function isApprovedAsset(uint16 chainId_, uint256 assetId_) public view override returns (bool) {
        return _approvedAsset[chainId_][assetId_] != address(0);
    }

    function isApprovedAsset(uint16 chainId_, address assetAddress_) public view override returns (bool) {
        return _approvedAssetIds[assetAddress_][chainId_] > 0;
    }

    function isApprovedRouter(uint16 chainId_) external view returns (bytes memory) {
        return _approvedRouters[chainId_];
    }

    function getAssetData(uint16 chainId_, uint256 assetId_) external view override returns (CrossChainAsset memory) {
        return _crossChainAsset[chainId_][assetId_];
    }

    function getAssetData(uint16 chainId_, address assetAddress_)
        external
        view
        override
        returns (CrossChainAsset memory)
    {
        return _crossChainAsset[chainId_][_approvedAssetIds[assetAddress_][chainId_]];
    }

    function getApprovedAssetId(address assetAddress_, uint16 chainId_) public view override returns (uint256) {
        return _approvedAssetIds[assetAddress_][chainId_];
    }

    function getCrossChainAssetParams(uint16 chainId_, uint256 assetId_)
        external
        view
        override
        returns (uint256, uint256)
    {
        return (_crossChainAsset[chainId_][assetId_].cash, _crossChainAsset[chainId_][assetId_].liability);
    }

    function getFailedMessages(
        uint16 chainId_,
        bytes calldata srcAddress_,
        uint64 nonce_
    ) external view returns (bytes32) {
        return failedMessages[chainId_][srcAddress_][nonce_];
    }

    function estimateFee(uint16 dstChain_, bytes calldata payload_) external view override returns (uint256) {
        uint16 version = 1;
        uint256 gasForDestinationLzReceive = 350000;
        bytes memory adapterParams = abi.encodePacked(version, gasForDestinationLzReceive);
        (uint256 messageFee, ) = layerZeroEndpoint.estimateFees(
            dstChain_,
            address(this),
            payload_,
            false,
            adapterParams
        );

        return messageFee;
    }

    function nextNonce(uint16 dstChain_) public view returns (uint256) {
        return layerZeroEndpoint.getOutboundNonce(dstChain_, address(this)) + 1;
    }

    function getMessageReceived(uint16 srcChain_, uint256 nonce_) external view returns (CCReceiveParams memory) {
        return receivedParamsPerChain[srcChain_][nonce_];
    }

    /// @dev make sure msg.value is equals with the fee
    function route(
        uint16 dstChain_,
        address dstAddress_,
        uint256 fee_,
        bytes calldata payload_
    ) external payable override onlyRole(ROUTE_ROLE) nonReentrant {
        uint16 version = 1;
        uint256 gasForDestinationLzReceive = 300000; // TODO see this gas if it's enough
        bytes memory adapterParams = abi.encodePacked(version, gasForDestinationLzReceive);
        uint256 nonce = nextNonce(dstChain_);
        // send LayerZero message
        layerZeroEndpoint.send{ value: fee_ }( // {value: messageFee} will be paid out of this contract!
            dstChain_, // destination chainId
            abi.encodePacked(_approvedRouters[dstChain_]), // destination address of router contract on the other chain
            payload_, // abi.encode()'ed bytes
            refundAddress, // (msg.sender will be this contract) refund address (LayerZero will refund any extra gas back to caller of send()
            address(0x0), // future param, unused for this example
            adapterParams // v1 adapterParams, specify custom destination gas qty
        );

        emit MessageRouted(dstChain_, dstAddress_, uint64(nonce));
    }

    function lzReceive(
        uint16 srcChainId_,
        bytes memory srcAddressBytes_,
        uint64 nonce_,
        bytes memory payload_
    ) external override {
        // TODO remove this for testing
        require(msg.sender == address(layerZeroEndpoint), "UNAUTHORIZED");

        try this.nonBlockingReceive(srcChainId_, srcAddressBytes_, nonce_, payload_) {} catch {
            failedMessages[srcChainId_][srcAddressBytes_][nonce_] = keccak256(payload_);
            emit MessageFailed(srcChainId_, srcAddressBytes_, nonce_, payload_);
        }
    }

    function nonBlockingReceive(
        uint16 srcChainId_,
        bytes memory srcAddressBytes_,
        uint64 nonce_,
        bytes memory payload_
    ) external {
        handleReceive(srcChainId_, srcAddressBytes_, nonce_, payload_);
    }

    function handleReceive(
        uint16 srcChainId_,
        bytes memory srcAddressBytes_,
        uint64 nonce_,
        bytes memory payload_
    ) internal {
        require(msg.sender == address(this) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "INVALID_CALLER");

        require(keccak256(_approvedRouters[srcChainId_]) == keccak256(srcAddressBytes_), "SRC_CHAIN_NOT_APPROVED");

        CCReceiveParams memory params;
        (
            params.sender,
            params.srcChainId,
            params.dstChainId,
            params.srcAsset,
            params.dstAsset,
            params.amount,
            params.haircut,
            params.signature
        ) = abi.decode(payload_, (address, uint16, uint16, address, address, uint256, uint256, bytes));

        require(srcChainId_ == params.srcChainId, "WRONG_CHAIN");

        require(isApprovedAsset(params.srcChainId, params.srcAsset), "ASSET_NOT_APPROVED");

        IPoolCrossChainL0 pool = _poolsPerAssets[params.dstAsset];
        require(params.dstChainId == pool.chainId(), "WRONG_CHAIN");
        receivedParamsPerChain[srcChainId_][nonce_] = params;
        _poolsPerAssets[params.dstAsset].receiveSwapCrossChain(params);

        emit MessageReceived(
            params.sender,
            params.srcChainId,
            params.srcAsset,
            params.dstAsset,
            nonce_,
            params.amount,
            params.haircut,
            params.signature
        );
    }

    function toggleAssetAndChain(
        uint16 chainId_,
        address assetAddress_,
        address tokenAddress_,
        uint256 assetId_,
        uint16 decimals_,
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

    function modifyCrossChainParams(
        uint16 chainId_,
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

    function togglePoolPerAssets(address asset_, IPoolCrossChainL0 pool_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _poolsPerAssets[asset_] = pool_;
        emit TogglePoolPerAssets(asset_, pool_);
    }

    function toggleApprovedRouters(uint16 chainId_, address router_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _approvedRouters[chainId_] = abi.encodePacked(router_, address(this));
        emit ToggleApprovedRouter(chainId_, router_);
    }

    function retryMessage(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) public payable onlyRole(DEFAULT_ADMIN_ROLE) {
        // assert there is message to retry
        bytes32 payloadHash = failedMessages[_srcChainId][_srcAddress][_nonce];
        require(payloadHash != bytes32(0), "NO_STORED_MESSAGE");
        require(keccak256(_payload) == payloadHash, "INVALID_PAYLOAD");
        // clear the stored message
        failedMessages[_srcChainId][_srcAddress][_nonce] = bytes32(0);
        // execute the message. revert if it fails again
        handleReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    function forceResumeL0Payload(uint16 srcChainId_, bytes calldata srcAddress_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        layerZeroEndpoint.forceResumeReceive(srcChainId_, srcAddress_);
        emit ForceResumeL0(srcChainId_, srcAddress_);
    }

    function retryL0Payload(
        uint16 srcChainId_,
        bytes calldata srcAddress_,
        bytes calldata payload_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        layerZeroEndpoint.retryPayload(srcChainId_, srcAddress_, payload_);
        emit RetryL0Payload(srcChainId_, srcAddress_, payload_);
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}