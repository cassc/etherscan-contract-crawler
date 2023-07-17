// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.16;

import "../../libraries/LibInterchain.sol";
import "../../utils/ReentrancyGuard.sol";
import "../base/RangoBaseInterchainMiddleware.sol";

/// @title The middleware contract that handles Rango's receive messages from stargate.
/// @author George
/// @dev Note that this is not a facet and should be deployed separately.
contract RangoStargateMiddleware is ReentrancyGuard, IRango, IStargateReceiver, RangoBaseInterchainMiddleware {

    /// @dev keccak256("exchange.rango.middleware.stargate")
    bytes32 internal constant STARGATE_MIDDLEWARE_NAMESPACE = hex"8f95700cb6d0d3fbe23970b0fed4ae8d3a19af1ff9db49b72f280b34bdf7bad8";

    struct RangoStargateMiddlewareStorage {
        address stargateRouter;
    }

    function initStargateMiddleware(
        address _owner,
        address _stargateRouter,
        address _weth
    ) external onlyOwner {
        initBaseMiddleware(_owner, address(0), _weth);
        updateStargateRouterAddressInternal(_stargateRouter);
    }

    /// Events

    /// @notice Emits when the Stargate address is updated
    /// @param oldAddress The previous address
    /// @param newAddress The new address
    event StargateRouterAddressUpdated(address oldAddress, address newAddress);

    /// External Functions

    /// @notice Updates the address of stargateRouter
    /// @param newAddress The new address of owner
    function updateStargateRouter(address newAddress) external onlyOwner {
        updateStargateRouterAddressInternal(newAddress);
    }

    // @param _chainId The remote chainId sending the tokens
    // @param _srcAddress The remote Bridge address
    // @param _nonce The message ordering nonce
    // @param _token The token contract on the local chain
    // @param amountLD The qty of local _token contract tokens
    // @param _payload The bytes containing the _tokenOut, _deadline, _amountOutMin, _toAddr
    function sgReceive(
        uint16,
        bytes memory,
        uint256,
        address _token,
        uint256 amountLD,
        bytes memory payload
    ) external payable override nonReentrant {
        require(msg.sender == getRangoStargateMiddlewareStorage().stargateRouter,
            "sgReceive function can only be called by Stargate router");
        Interchain.RangoInterChainMessage memory m = abi.decode((payload), (Interchain.RangoInterChainMessage));
        (address receivedToken, uint dstAmount, IRango.CrossChainOperationStatus status) = LibInterchain.handleDestinationMessage(_token, amountLD, m);

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

    /// Private and Internal
    function updateStargateRouterAddressInternal(address newAddress) private {
        require(newAddress != address(0), "Invalid StargateRouter");
        RangoStargateMiddlewareStorage storage s = getRangoStargateMiddlewareStorage();
        address oldAddress = s.stargateRouter;
        s.stargateRouter = newAddress;
        emit StargateRouterAddressUpdated(oldAddress, newAddress);
    }

    /// @dev fetch local storage
    function getRangoStargateMiddlewareStorage() private pure returns (RangoStargateMiddlewareStorage storage s) {
        bytes32 namespace = STARGATE_MIDDLEWARE_NAMESPACE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := namespace
        }
    }
}