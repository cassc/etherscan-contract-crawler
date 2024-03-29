// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../../libraries/LibInterchain.sol";
import "../../utils/ReentrancyGuard.sol";
import "../base/RangoBaseInterchainMiddleware.sol";
import "../../interfaces/IWormholeRouter.sol";
import "../../interfaces/IWormhole.sol";
import "../../interfaces/IWormholeTokenBridge.sol";
import "../../interfaces/WormholeBridgeStructs.sol";

/// @title The middleware contract that handles Rango's receive messages from wormhole.
/// @author AMA
/// @dev Note that this is not a facet and should be deployed separately.
contract RangoWormholeMiddleware is ReentrancyGuard, IRango, RangoBaseInterchainMiddleware {

    /// @dev keccak256("exchange.rango.middleware.wormhole")
    bytes32 internal constant WORMHOLE_MIDDLEWARE_NAMESPACE = hex"03b65cc2ae1a0403a8a39c713a7539556dcb0e1f9e232988c2d31a10f06ab207";

    struct RangoWormholeMiddlewareStorage {
        address wormholeRouter;
        // @notice hashes of the transactions that should be refunded
        mapping(bytes32 => bool) refundHashes;
        // @notice for refunds where payload cannot be decoded to get recipient, therefore the receiver address is set manually
        mapping(bytes32 => address) refundHashAddresses;
    }

    constructor(
        address _owner,
        address _wormholeRouter,
        address _weth
    ) RangoBaseInterchainMiddleware(_owner, address(0), _weth){
        updateWormholeRouterAddressInternal(_wormholeRouter);
    }

    /// Events

    /// @notice Emits when the Wormhole address is updated
    /// @param oldAddress The previous address
    /// @param newAddress The new address
    event WormholeRouterAddressUpdated(address oldAddress, address newAddress);
    /// @notice Emitted when a refund state is updated
    /// @param refundHash The hash of data for which state is changed
    /// @param enabled The boolean signaling the state. true value means refund is enabled.
    /// @param refundAddress The address that should receive the refund.
    event RefundHashStateUpdated(bytes32 indexed refundHash, bool enabled, address refundAddress);
    /// @notice Emitted when a refund has been executed
    /// @param refundHash The hash of data for which state is changed
    /// @param refundAddress The address that should receive the refund.
    event PayloadHashRefunded(bytes32 indexed refundHash, address refundAddress);

    /// External Functions

    /// @notice Updates the address of wormholeRouter
    /// @param newAddress The new address of owner
    function updateWormholeRouter(address newAddress) external onlyOwner {
        updateWormholeRouterAddressInternal(newAddress);
    }

    /// @notice Add payload hashes to refund the user.
    /// @param hashes Array of payload hashes to be enabled or disabled for refund
    /// @param booleans Array of booleans corresponding to the hashes. true value means enable refund.
    /// @param addresses addresses that should receive the refund. Can be 0x0000 if the refund should be done based on interchain message
    function updateRefundHashes(
        bytes32[] calldata hashes,
        bool[] calldata booleans,
        address[] calldata addresses
    ) external onlyOwner {
        updateRefundHashesInternal(hashes, booleans, addresses);
    }

    /// @param expectedToken the token that will be received from wormhole.
    /// @dev expected token be extracted from vaas but we pass it as argument to save gas. (see extractTokenAddressForVaas)
    function completeTransferWithPayload(
        address expectedToken,
        bytes memory vaas
    ) external nonReentrant
    {
        RangoWormholeMiddlewareStorage storage s = getRangoWormholeMiddlewareStorage();
        IWormholeTokenBridge whTokenBridge = IWormholeTokenBridge(s.wormholeRouter);
        /// check for refund
        bytes32 refundHash = keccak256(vaas);
        if (s.refundHashes[refundHash] == true) {
            // transfer tokens to this contract
            bytes memory payloadRefund = whTokenBridge.completeTransferWithPayload(vaas);
            WormholeBridgeStructs.TransferWithPayload memory transferRefund = whTokenBridge.parseTransferWithPayload(payloadRefund);
            address refundAddr = s.refundHashAddresses[refundHash];
            address requestId = LibSwapper.ETH;
            address originalSender = LibSwapper.ETH;
            uint16 dAppTag;
            if (refundAddr == address(0)) {
                Interchain.RangoInterChainMessage memory im = abi.decode((transferRefund.payload), (Interchain.RangoInterChainMessage));
                refundAddr = im.recipient;
                requestId = im.requestId;
                originalSender = im.originalSender;
                dAppTag = im.dAppTag;
            }
            require(refundAddr != address(0), "Cannot refund to burn address");

            (,bytes memory queriedDecimalsRefund) = expectedToken.staticcall(abi.encodeWithSignature("decimals()"));
            uint8 decimalsRefund = abi.decode(queriedDecimalsRefund, (uint8));
            uint256 exactAmountRefund = deNormalizeAmount(transferRefund.amount, decimalsRefund);
            SafeERC20.safeTransfer(IERC20(expectedToken), refundAddr, exactAmountRefund);
            s.refundHashes[refundHash] = false;
            emit RefundHashStateUpdated(refundHash, false, refundAddr);
            emit PayloadHashRefunded(refundHash, refundAddr);
            emit RangoBridgeCompleted(
                requestId,
                expectedToken,
                originalSender,
                refundAddr,
                exactAmountRefund,
                CrossChainOperationStatus.RefundInDestination,
                dAppTag
            );

            return;
        }

        uint balanceBefore = IERC20(expectedToken).balanceOf(address(this));
        // wormhole sends token to our contract with this call
        bytes memory payload = whTokenBridge.completeTransferWithPayload(vaas);
        uint balanceAfter = IERC20(expectedToken).balanceOf(address(this));

        WormholeBridgeStructs.TransferWithPayload memory transfer = whTokenBridge.parseTransferWithPayload(payload);
        Interchain.RangoInterChainMessage memory m = abi.decode((transfer.payload), (Interchain.RangoInterChainMessage));
        require(expectedToken == m.bridgeRealOutput, "expected token is not equal to received token");

        (,bytes memory queriedDecimals) = m.bridgeRealOutput.staticcall(abi.encodeWithSignature("decimals()"));
        uint8 decimals = abi.decode(queriedDecimals, (uint8));

        // adjust decimals
        uint256 exactAmount = deNormalizeAmount(transfer.amount, decimals);
        require(balanceAfter - balanceBefore >= exactAmount, "expected amount not transferred");
        (address receivedToken, uint dstAmount, IRango.CrossChainOperationStatus status) = LibInterchain.handleDestinationMessage(
            m.bridgeRealOutput,
            exactAmount,
            m
        );
        emit RangoBridgeCompleted(
            m.bridgeRealOutput,
            receivedToken,
            m.originalSender,
            m.recipient,
            dstAmount,
            status,
            m.dAppTag
        );
    }

    function extractTokenAddressForVaas(bytes calldata vaas) external view returns (address){
        RangoWormholeMiddlewareStorage storage s = getRangoWormholeMiddlewareStorage();
        IWormholeTokenBridge whTokenBridge = IWormholeTokenBridge(s.wormholeRouter);
        IWormhole wh = IWormhole(whTokenBridge.wormhole());
        IWormhole.VM memory vm = wh.parseVM(vaas);
        WormholeBridgeStructs.TransferWithPayload memory transfer = whTokenBridge.parseTransferWithPayload(vm.payload);

        // extract token address
        if (transfer.tokenChain == whTokenBridge.chainId()) {
            return address(uint160(uint256(transfer.tokenAddress)));
        } else {
            address tmpWrappedAsset = whTokenBridge.wrappedAsset(transfer.tokenChain, transfer.tokenAddress);
            require(tmpWrappedAsset != LibSwapper.ETH, "Address is zero");
            return tmpWrappedAsset;
        }
    }

    function deNormalizeAmount(uint256 amount, uint8 decimals) internal pure returns (uint256){
        if (decimals > 8) {
            amount *= 10 ** (decimals - 8);
        }
        return amount;
    }

    function updateRefundHashesInternal(bytes32[] calldata hashes, bool[] calldata booleans, address[] calldata addresses) private {
        RangoWormholeMiddlewareStorage storage s = getRangoWormholeMiddlewareStorage();
        bytes32 hash;
        bool enabled;
        address refundAddr;
        for (uint256 i = 0; i < hashes.length; i++) {
            hash = hashes[i];
            enabled = booleans[i];
            s.refundHashes[hash] = enabled;
            refundAddr = addresses[i];
            if (refundAddr != address(0))
                s.refundHashAddresses[hash] = refundAddr;
            emit RefundHashStateUpdated(hash, enabled, refundAddr);
        }
    }

    /// Private and Internal
    function updateWormholeRouterAddressInternal(address newAddress) private {
        RangoWormholeMiddlewareStorage storage s = getRangoWormholeMiddlewareStorage();
        require(newAddress != LibSwapper.ETH, "Invalid Address");
        address oldAddress = s.wormholeRouter;
        s.wormholeRouter = newAddress;
        emit WormholeRouterAddressUpdated(oldAddress, newAddress);
    }

    /// @dev fetch local storage
    function getRangoWormholeMiddlewareStorage() private pure returns (RangoWormholeMiddlewareStorage storage s) {
        bytes32 namespace = WORMHOLE_MIDDLEWARE_NAMESPACE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := namespace
        }
    }
}