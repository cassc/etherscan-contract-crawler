// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IMiraidon} from "../interfaces/IMiraidon.sol";
import {IMultichainRouter, IMultichainToken} from "../interfaces/IMultichainRouter.sol";
import {LibUtil} from "../libraries/LibUtil.sol";
import {LibAsset, IERC20} from "../libraries/LibAsset.sol";
import {LibFeeCollect} from "../libraries/LibFeeCollect.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {GenericErrors} from "../libraries/GenericErrors.sol";
import {SwapperV2, LibSwap} from "../helpers/SwapperV2.sol";
import {Validatable} from "../helpers/Validatable.sol";
import {ReentrancyGuard} from "../helpers/ReentrancyGuard.sol";

contract MultichainFacet is IMiraidon, SwapperV2, ReentrancyGuard, Validatable {
    /// Storage ///

    bytes32 internal constant NAMESPACE =
        keccak256("com.miraidon.facets.multichain");

    struct Storage {
        mapping(address => bool) allowedRouters;
        bool initialized;
    }

    /// Errors ///
    error NotImplementError();

    /// Types ///

    struct MultichainData {
        address router;
    }

    /// Events ///

    event MultichainInitialized();
    event MultichainRouterRegistered(address indexed router, bool allowed);

    /**
     * @notice Init
     * @notice Initialize local variables for the Multichain Facet
     * @param routers Allowed Multichain Routers
     */
    function initMultichain(address[] calldata routers) external {
        LibDiamond.enforceIsContractOwner();

        Storage storage s = getStorage();

        require(!s.initialized, GenericErrors.E20);

        uint256 len = routers.length;
        for (uint256 i = 0; i < len; i++) {
            require(routers[i] != address(0), GenericErrors.E14);
            s.allowedRouters[routers[i]] = true;
        }

        s.initialized = true;

        emit MultichainInitialized();
    }

    /**
     * @notice Register router
     * @param router Address of the router
     * @param allowed Whether the address is allowed or not
     */
    function registerBridge(address router, bool allowed) external {
        LibDiamond.enforceIsContractOwner();

        require(router != address(0), GenericErrors.E14);

        Storage storage s = getStorage();

        require(s.initialized, GenericErrors.E21);

        s.allowedRouters[router] = allowed;

        emit MultichainRouterRegistered(router, allowed);
    }

    /**
     * @notice Batch register routers
     * @param routers Router addresses
     * @param allowed Array of whether the addresses are allowed or not
     */
    function registerBridge(
        address[] calldata routers,
        bool[] calldata allowed
    ) external {
        LibDiamond.enforceIsContractOwner();

        Storage storage s = getStorage();

        require(s.initialized, GenericErrors.E21);

        uint256 len = routers.length;
        for (uint256 i = 0; i < len; ) {
            require(routers[i] != address(0), GenericErrors.E14);
            s.allowedRouters[routers[i]] = allowed[i];

            emit MultichainRouterRegistered(routers[i], allowed[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
     *  @notice Bridges tokens via Multichain
     *  @param _bridgeData the core information needed for bridging
     *  @param _multichainData data specific to Multichain
     */
    function startBridgeTokensViaMultichain(
        IMiraidon.BridgeData memory _bridgeData,
        MultichainData calldata _multichainData
    )
        external
        payable
        nonReentrant
        whenNotPaused
        refundExcessNative(payable(msg.sender))
        doesNotContainSourceSwaps(_bridgeData)
        doesNotContainDestinationCalls(_bridgeData)
        validateBridgeData(_bridgeData)
    {
        Storage storage s = getStorage();
        require(s.allowedRouters[_multichainData.router], GenericErrors.E56);
        // Multichain (formerly Multichain) tokens can wrap other tokens
        (address underlyingToken, bool isNative) = _getUnderlyingToken(
            _bridgeData.sendingAssetId,
            _multichainData.router
        );
        if (!isNative)
            LibAsset.depositAsset(underlyingToken, _bridgeData.minAmount);
        _startBridge(_bridgeData, _multichainData, underlyingToken, isNative);
    }

    /**
     *  @notice Not used now.
     *          Performs a swap before bridging via Multichain
     *  @param _bridgeData the core information needed for bridging
     *  @param _swapData an array of swap related data for performing swaps before bridging
     *  @param _multichainData data specific to Multichain
     */
    function swapAndStartBridgeTokensViaMultichain(
        IMiraidon.BridgeData memory _bridgeData,
        LibSwap.SwapData[] calldata _swapData,
        MultichainData memory _multichainData
    )
        external
        payable
        nonReentrant
        whenNotPaused
        refundExcessNative(payable(msg.sender))
        containsSourceSwaps(_bridgeData)
        doesNotContainDestinationCalls(_bridgeData)
        validateBridgeData(_bridgeData)
    {
        Storage storage s = getStorage();
        require(s.allowedRouters[_multichainData.router], GenericErrors.E56);
        _bridgeData.minAmount = _depositAndSwap(
            _bridgeData.transactionId,
            _bridgeData.minAmount,
            _swapData,
            payable(msg.sender)
        );
        (address underlyingToken, bool isNative) = _getUnderlyingToken(
            _bridgeData.sendingAssetId,
            _multichainData.router
        );
        _startBridge(_bridgeData, _multichainData, underlyingToken, isNative);
    }

    /**
     * @notice Unwraps the underlying token from the Multichain token if necessary
     * @param token The (maybe) wrapped token
     * @param router The Multichain router
     */
    function _getUnderlyingToken(
        address token,
        address router
    ) private returns (address underlyingToken, bool isNative) {
        // Token must implement IMultichainRouter interface
        require(!LibAsset.isNativeAsset(token), GenericErrors.E00);
        underlyingToken = IMultichainToken(token).underlying();
        // The native token does not use the standard null address ID
        isNative = IMultichainRouter(router).wNATIVE() == underlyingToken;
        // Some Multichain complying tokens may wrap nothing
        if (!isNative && LibAsset.isNativeAsset(underlyingToken)) {
            underlyingToken = token;
        }
    }

    /**
     * @notice Contains the business logic for the bridge via Multichain
     * @param _bridgeData the core information needed for bridging
     * @param _multichainData data specific to Multichain
     * @param underlyingToken the underlying token to swap
     * @param isNative denotes whether the token is a native token vs ERC20
     */
    function _startBridge(
        IMiraidon.BridgeData memory _bridgeData,
        MultichainData memory _multichainData,
        address underlyingToken,
        bool isNative
    ) private {
        require(
            block.chainid != _bridgeData.destinationChainId,
            GenericErrors.E02
        );
        if (!isNative) {
            // Give Multichain approval to bridge tokens
            LibAsset.maxApproveERC20(
                IERC20(underlyingToken),
                _multichainData.router,
                _bridgeData.minAmount
            );
        }
        _bridgeData.minAmount = LibFeeCollect.fix(_bridgeData.minAmount);
        if (isNative) {
            IMultichainRouter(_multichainData.router).anySwapOutNative{
                value: _bridgeData.minAmount
            }(
                _bridgeData.sendingAssetId,
                _bridgeData.receiver,
                _bridgeData.destinationChainId
            );
        } else {
            // Was the token wrapping another token?
            if (_bridgeData.sendingAssetId != underlyingToken) {
                IMultichainRouter(_multichainData.router).anySwapOutUnderlying(
                    _bridgeData.sendingAssetId,
                    _bridgeData.receiver,
                    _bridgeData.minAmount,
                    _bridgeData.destinationChainId
                );
            } else {
                IMultichainRouter(_multichainData.router).anySwapOut(
                    _bridgeData.sendingAssetId,
                    _bridgeData.receiver,
                    _bridgeData.minAmount,
                    _bridgeData.destinationChainId
                );
            }
        }

        emit MiraidonTransferStarted(_bridgeData);
    }

    /// @dev fetch local storage
    function getStorage() private pure returns (Storage storage s) {
        bytes32 namespace = NAMESPACE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := namespace
        }
    }
}