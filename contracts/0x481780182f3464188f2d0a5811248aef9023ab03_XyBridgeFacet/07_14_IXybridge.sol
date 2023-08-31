pragma solidity 0.8.17;
import "../interfaces/IERC20.sol";

struct XyBridgeData {
    // uint256 minReturnAmount; // input same amount
    // uint256 expectedToChainTokenAmount; // => SwapDescription.amount - fee
    // uint32 slippage; // ex) 1223 slippage equals to 12.23% // => only having toChain swap so '0'
    address toChainToken; // => toChain token address
    address aggregatorAdaptor; // = > 0x0000000000000000000000000000000000000000
    address referrer;
}

struct FeeStructure {
    bool isSet;
    uint256 gas;
    uint256 min;
    uint256 max;
    uint256 rate;
    uint256 decimals;
}

struct SwapDescription {
    IERC20 fromToken; // => input fromChainToken
    IERC20 toToken; // => input fromChainToken
    address receiver; // => execute address ( = maybe toChain plexusDiamond )
    uint256 amount;
    uint256 minReturnAmount;
}

struct ToChainDescription {
    uint32 toChainId;
    IERC20 toChainToken; // => toChain token address
    uint256 expectedToChainTokenAmount; // => SwapDescription.amount - fee
    uint32 slippage; // ex) 1223 slippage equals to 12.23% // => only having toChain swap
}

struct SwapRequest {
    uint32 toChainId;
    uint256 swapId;
    address receiver;
    address sender;
    uint256 YPoolTokenAmount;
    uint256 xyFee;
    uint256 gasFee;
    IERC20 YPoolToken;
    RequestStatus status;
}

enum RequestStatus {
    Open,
    Closed
}

interface IXybridge {
    function getSwapRequest(uint256 _swapId) external returns (SwapRequest memory);

    function getFeeStructure(uint32 _chainId, address _token) external returns (FeeStructure memory);

    function getEverClosed(uint32 _chainId, uint256 _swapId) external returns (bool);

    function swap(
        address aggregatorAdaptor, // only bridge => 0x0000000000000000000000000000000000000000
        SwapDescription memory swapDesc,
        bytes memory aggregatorData, // only bridge => 0x00
        ToChainDescription calldata toChainDesc
    ) external payable;

    function swapWithReferrer(
        address aggregatorAdaptor,
        SwapDescription memory swapDesc,
        bytes memory aggregatorData,
        ToChainDescription calldata toChainDesc,
        address referrer
    ) external payable;
}