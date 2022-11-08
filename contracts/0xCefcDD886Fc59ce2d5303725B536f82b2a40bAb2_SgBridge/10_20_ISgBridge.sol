//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ISgBridge {

    event Bridge(address indexed user, uint16 indexed chainId, uint256 amount);
    event BridgeAndSwapSuccess(address indexed user, uint16 indexed srcChainId, address dstToken, uint256 amount);
    event BridgeSuccess(address indexed user, uint16 indexed srcChainId, address dstToken, uint256 amount);
    event ExternalCallSuccess(address indexed user, uint16 indexed srcChainId, address dstToken, uint256 amount);

//    event QuoterChanged(address user, address newQuoter);
    /**
    * Auth
    */
    function setStargatePoolId(address token, uint256 poolId) external;
//    function setSwapper(address swapperLib_) external;
    function setSupportedDestination(uint16 destChainId, address receiver, uint256 destPoolId) external;

    /**
    * Public
    */
    function bridge(address token,
        uint256 amount,
        uint16 destChainId,
        address destinationAddress,
        address destinationToken,
        address routerSrcChain,
        bytes memory srcRoutingCallData,
        bytes memory dstChainCallData
    ) external payable;

    /**
    * View
    */
    function isTokenSupported(address token) external view returns (bool);
    function isTokensSupported(address[] calldata tokens) external view returns (bool[] memory);
    function isPairsSupported(address[][] calldata tokens) external view returns (bool[] memory);
//    function quote(address tokenA, address tokenB, uint256 amountA) external returns (uint256);
    function estimateGasFee(address token,
        uint16 destChainId,
        bytes calldata destinationCalldata) external view returns (uint256);

    function swapRouter(
        address tokenA,
        uint256 amountA,
        address router,
        bytes memory callData
    ) external payable;
}