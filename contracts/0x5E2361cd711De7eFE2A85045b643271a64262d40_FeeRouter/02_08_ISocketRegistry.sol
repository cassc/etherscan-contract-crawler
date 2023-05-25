pragma solidity ^0.8.4;

abstract contract ISocketRegistry {
    /**
     * @notice Container for Bridge Request
     * @member id denotes the underlying bridge to be used
     * @member optionalNativeAmount native token amount if not to be included in the value.
     * @member inputToken token being bridged
     * @member data this can be decoded to get extra data needed for different bridges
     */
    struct BridgeRequest {
        uint256 id;
        uint256 optionalNativeAmount;
        address inputToken;
        bytes data;
    }


    /**
     * @notice Container for Middleware Request
     * @member id denotes the underlying middleware to be used
     * @member optionalNativeAmount native token amount if not to be included in the value.
     * @member inputToken token being sent to middleware, for example swaps
     * @member data this can be decoded to get extra data needed for different middlewares
     */
    struct MiddlewareRequest {
        uint256 id;
        uint256 optionalNativeAmount;
        address inputToken;
        bytes data;
    }


    /**
     * @notice Container for User Request
     * @member receiverAddress address of the user receiving the bridged amount
     * @member toChainId id of the chain being bridged to
     * @member amount amount being bridged through registry
     * @member middlewareRequest 
     * @member bridgeRequest 
     */
    struct UserRequest {
        address receiverAddress;
        uint256 toChainId;
        uint256 amount;
        MiddlewareRequest middlewareRequest;
        BridgeRequest bridgeRequest;
    }

    /**
     * @notice Container for Route Data
     * @dev middlwares and bridges are both added into the same routes
     * @member route address of the implementation contract fo a bride or middleware
     * @member isEnabled bool variable that denotes if the particular route is enabled or disabled
     * @member isMiddleware bool variable that denotes if the particular route is a middleware or not
     */
    struct RouteData {
        address route;
        bool isEnabled;
        bool isMiddleware;
    }

    /**
     * @notice Resgistered Routes on the socket registry
     * @dev middlwares and bridges are both added into the same routes
     */
    RouteData[] public routes;

    /**
     * @notice Function called in the socket registry for bridging
     */
    function outboundTransferTo(UserRequest calldata _userRequest)
        external
        payable
        virtual;
}