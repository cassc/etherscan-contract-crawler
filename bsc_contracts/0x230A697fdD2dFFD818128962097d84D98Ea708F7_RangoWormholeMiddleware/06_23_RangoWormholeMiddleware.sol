// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../../libraries/LibInterchain.sol";
import "../../utils/ReentrancyGuard.sol";
import "../base/RangoBaseInterchainMiddleware.sol";
import "../../interfaces/IWormholeRouter.sol";
import "../../interfaces/IWormholeTokenBridge.sol";
import "../../interfaces/WormholeBridgeStructs.sol";

//TODO: consider how to handle refunds!

/// @title The middleware contract that handles Rango's receive messages from wormhole.
/// @author AMA
/// @dev Note that this is not a facet and should be deployed separately.
contract RangoWormholeMiddleware is ReentrancyGuard, IRango, RangoBaseInterchainMiddleware {

    /// @dev keccak256("exchange.rango.middleware.wormhole")
    bytes32 internal constant WORMHOLE_MIDDLEWARE_NAMESPACE = hex"03b65cc2ae1a0403a8a39c713a7539556dcb0e1f9e232988c2d31a10f06ab207";

    struct RangoWormholeMiddlewareStorage {
        address wormholeRouter;
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

    /// External Functions

    /// @notice Updates the address of wormholeRouter
    /// @param newAddress The new address of owner
    function updateWormholeRouter(address newAddress) external onlyOwner {
        updateWormholeRouterAddressInternal(newAddress);
    }

    function completeTransferWithPayload(
        address expectedToken,
        bytes memory vaas
    ) external nonReentrant
    {
        require(expectedToken != LibSwapper.ETH, "received token can not be native");
        RangoWormholeMiddlewareStorage storage s = getRangoWormholeMiddlewareStorage();

        uint balanceBefore = IERC20(expectedToken).balanceOf(address(this));

        address wormholeTokenBridgeAddress = address(s.wormholeRouter);
        IWormholeTokenBridge whTokenBridge = IWormholeTokenBridge(wormholeTokenBridgeAddress);
        bytes memory payload = whTokenBridge.completeTransferWithPayload(vaas);

        WormholeBridgeStructs.TransferWithPayload memory transfer = whTokenBridge.parseTransferWithPayload(payload);
        Interchain.RangoInterChainMessage memory m = abi.decode((transfer.payload), (Interchain.RangoInterChainMessage));

        uint balanceAfter = IERC20(expectedToken).balanceOf(address(this));
        require(balanceAfter - balanceBefore >= transfer.amount, "expected amount not transferred");
        require(expectedToken == m.bridgeRealOutput, "expected token is not equal to received token");

        (,bytes memory queriedDecimals) = m.bridgeRealOutput.staticcall(abi.encodeWithSignature("decimals()"));
        uint8 decimals = abi.decode(queriedDecimals, (uint8));


        // adjust decimals
        uint256 exactAmount = deNormalizeAmount(transfer.amount, decimals);
        (address receivedToken, uint dstAmount, IRango.CrossChainOperationStatus status) = LibInterchain.handleDestinationMessage(
            m.bridgeRealOutput,
            exactAmount,
            m
        );
        emit RangoBridgeCompleted(
            m.requestId,
            receivedToken,
            m.originalSender,
            m.recipient,
            dstAmount,
            status,
            m.dAppTag
        );
    }

    function deNormalizeAmount(uint256 amount, uint8 decimals) internal pure returns (uint256){
        if (decimals > 8) {
            amount *= 10 ** (decimals - 8);
        }
        return amount;
    }

    /// Private and Internal
    function updateWormholeRouterAddressInternal(address newAddress) private {
        RangoWormholeMiddlewareStorage storage s = getRangoWormholeMiddlewareStorage();
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