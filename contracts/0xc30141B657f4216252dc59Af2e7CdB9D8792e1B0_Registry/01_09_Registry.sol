// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./helpers/errors.sol";
import "./ImplBase.sol";
import "./MiddlewareImplBase.sol";

/**
// @title Movr Regisrtry Contract.
// @notice This is the main contract that is called using fund movr.
// This contains all the bridge and middleware ids. 
// RouteIds signify which bridge to be used. 
// Middleware Id signifies which aggregator will be used for swapping if required. 
*/
contract Registry is Ownable {
    using SafeERC20 for IERC20;
    address private constant NATIVE_TOKEN_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    ///@notice RouteData stores information for a route
    struct RouteData {
        address route;
        bool isEnabled;
        bool isMiddleware;
    }
    RouteData[] public routes;
    modifier onlyExistingRoute(uint256 _routeId) {
        require(
            routes[_routeId].route != address(0),
            MovrErrors.ROUTE_NOT_FOUND
        );
        _;
    }

    constructor(address _owner) Ownable() {
        // first route is for direct bridging
        routes.push(RouteData(NATIVE_TOKEN_ADDRESS, true, true));
        transferOwnership(_owner);
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    //
    // Events
    //
    event NewRouteAdded(
        uint256 routeID,
        address route,
        bool isEnabled,
        bool isMiddleware
    );
    event RouteDisabled(uint256 routeID);
    event ExecutionCompleted(
        uint256 middlewareID,
        uint256 bridgeID,
        uint256 inputAmount
    );

    /**
    // @param id route id of middleware to be used
    // @param optionalNativeAmount is the amount of native asset that the route requires 
    // @param inputToken token address which will be swapped to
    // BridgeRequest inputToken 
    // @param data to be used by middleware
    */
    struct MiddlewareRequest {
        uint256 id;
        uint256 optionalNativeAmount;
        address inputToken;
        bytes data;
    }

    /**
    // @param id route id of bridge to be used
    // @param optionalNativeAmount optinal native amount, to be used
    // when bridge needs native token along with ERC20    
    // @param inputToken token addresss which will be bridged 
    // @param data bridgeData to be used by bridge
    */
    struct BridgeRequest {
        uint256 id;
        uint256 optionalNativeAmount;
        address inputToken;
        bytes data;
    }

    /**
    // @param receiverAddress Recipient address to recieve funds on destination chain
    // @param toChainId Destination ChainId
    // @param amount amount to be swapped if middlewareId is 0  it will be
    // the amount to be bridged
    // @param middlewareRequest middleware Requestdata
    // @param bridgeRequest bridge request data
    */
    struct UserRequest {
        address receiverAddress;
        uint256 toChainId;
        uint256 amount;
        MiddlewareRequest middlewareRequest;
        BridgeRequest bridgeRequest;
    }

    /**
    // @notice function responsible for calling the respective implementation 
    // depending on the bridge to be used
    // If the middlewareId is 0 then no swap is required,
    // we can directly bridge the source token to wherever required,
    // else, we first call the Swap Impl Base for swapping to the required 
    // token and then start the bridging
    // @dev It is required for isMiddleWare to be true for route 0 as it is a special case
    // @param _userRequest calldata follows the input data struct
    */
    function outboundTransferTo(UserRequest calldata _userRequest)
        external
        payable
    {
        require(_userRequest.amount != 0, MovrErrors.INVALID_AMT);

        // make sure bridge ID is not 0
        require(
            _userRequest.bridgeRequest.id != 0,
            MovrErrors.INVALID_BRIDGE_ID
        );

        // make sure bridge input is provided
        require(
            _userRequest.bridgeRequest.inputToken != address(0),
            MovrErrors.ADDRESS_0_PROVIDED
        );

        // load middleware info and validate
        RouteData memory middlewareInfo = routes[
            _userRequest.middlewareRequest.id
        ];
        require(
            middlewareInfo.route != address(0) &&
                middlewareInfo.isEnabled &&
                middlewareInfo.isMiddleware,
            MovrErrors.ROUTE_NOT_ALLOWED
        );

        // load bridge info and validate
        RouteData memory bridgeInfo = routes[_userRequest.bridgeRequest.id];
        require(
            bridgeInfo.route != address(0) &&
                bridgeInfo.isEnabled &&
                !bridgeInfo.isMiddleware,
            MovrErrors.ROUTE_NOT_ALLOWED
        );

        emit ExecutionCompleted(
            _userRequest.middlewareRequest.id,
            _userRequest.bridgeRequest.id,
            _userRequest.amount
        );

        // if middlewareID is 0 it means we dont want to perform a action before bridging
        // and directly want to move for bridging
        if (_userRequest.middlewareRequest.id == 0) {
            // perform the bridging
            ImplBase(bridgeInfo.route).outboundTransferTo{value: msg.value}(
                _userRequest.amount,
                msg.sender,
                _userRequest.receiverAddress,
                _userRequest.bridgeRequest.inputToken,
                _userRequest.toChainId,
                _userRequest.bridgeRequest.data
            );
            return;
        }

        // we first perform an action using the middleware
        // we determine if the input asset is a native asset, if yes we pass
        // the amount as value, else we pass the optionalNativeAmount
        uint256 _amountOut = MiddlewareImplBase(middlewareInfo.route)
            .performAction{
            value: _userRequest.middlewareRequest.inputToken ==
                NATIVE_TOKEN_ADDRESS
                ? _userRequest.amount +
                    _userRequest.middlewareRequest.optionalNativeAmount
                : _userRequest.middlewareRequest.optionalNativeAmount
        }(
            msg.sender,
            _userRequest.middlewareRequest.inputToken,
            _userRequest.amount,
            address(this),
            _userRequest.middlewareRequest.data
        );

        // we mutate this variable if the input asset to bridge Impl is NATIVE
        uint256 nativeInput = _userRequest.bridgeRequest.optionalNativeAmount;

        // if the input asset is ERC20, we need to grant the bridge implementation approval
        if (_userRequest.bridgeRequest.inputToken != NATIVE_TOKEN_ADDRESS) {
            IERC20(_userRequest.bridgeRequest.inputToken).safeIncreaseAllowance(
                    bridgeInfo.route,
                    _amountOut
                );
        } else {
            // if the input asset is native we need to set it as value
            nativeInput =
                _amountOut +
                _userRequest.bridgeRequest.optionalNativeAmount;
        }

        // send off to bridge
        ImplBase(bridgeInfo.route).outboundTransferTo{value: nativeInput}(
            _amountOut,
            address(this),
            _userRequest.receiverAddress,
            _userRequest.bridgeRequest.inputToken,
            _userRequest.toChainId,
            _userRequest.bridgeRequest.data
        );
    }

    //
    // Route management functions
    //

    /// @notice add routes to the registry.
    function addRoutes(RouteData[] calldata _routes)
        external
        onlyOwner
        returns (uint256[] memory)
    {
        require(_routes.length != 0, MovrErrors.EMPTY_INPUT);
        uint256[] memory _routeIds = new uint256[](_routes.length);
        for (uint256 i = 0; i < _routes.length; i++) {
            require(
                _routes[i].route != address(0),
                MovrErrors.ADDRESS_0_PROVIDED
            );
            routes.push(_routes[i]);
            _routeIds[i] = routes.length - 1;
            emit NewRouteAdded(
                i,
                _routes[i].route,
                _routes[i].isEnabled,
                _routes[i].isMiddleware
            );
        }

        return _routeIds;
    }

    ///@notice disables the route  if required.
    function disableRoute(uint256 _routeId)
        external
        onlyOwner
        onlyExistingRoute(_routeId)
    {
        routes[_routeId].isEnabled = false;
        emit RouteDisabled(_routeId);
    }

    function rescueFunds(
        address _token,
        address _receiverAddress,
        uint256 _amount
    ) external onlyOwner {
        IERC20(_token).safeTransfer(_receiverAddress, _amount);
    }
}