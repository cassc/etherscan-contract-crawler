pragma solidity 0.8.15;

import "IERC20.sol";
import "Ownable.sol";
import "SafeERC20.sol";

interface ICurveRouter {
    function exchange_multiple(
        address[9] memory _route,
        uint256[3][4] memory _swap_params,
        uint256 _amount,
        uint256 _expected,
        address[4] memory _pools,
        address _receiver
    ) external returns (uint256);

    function get_exchange_multiple_amount(
        address[9] memory _route,
        uint256[3][4] memory _swap_params,
        uint256 _amount
    ) external view returns (uint256);
}

contract CurveConverter is Ownable {
    using SafeERC20 for IERC20;

    ICurveRouter public router;

    address public assetConverter;

    struct CurveSwapData {
        address[9] route;
        uint256[3][4] swapParams;
    }

    mapping(address => mapping(address => CurveSwapData)) swapDatas; 
    mapping(address => bool) internal isApproved;

    constructor(address _assetConverter, ICurveRouter _router) {
        require(address(_router) != address(0), "Null address provided");
        require(_assetConverter != address(0), "Null address provided");
        assetConverter = _assetConverter;
        router = _router;
    }

    struct UpdateSwapDataParams {
        address source;
        address destination;
        CurveSwapData swapData;
    }

    function updateSwapDatas(UpdateSwapDataParams[] memory updates)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < updates.length; i++) {
            swapDatas[updates[i].source][updates[i].destination] = updates[i]
                .swapData;
        }
    }
    
    function swap(
        address source,
        address destination,
        uint256 value,
        address beneficiary
    ) external returns (uint256) {
        require(msg.sender == assetConverter, "Invalid caller");
        CurveSwapData memory swapData = swapDatas[source][destination];
        if (!isApproved[source]) {
            IERC20(source).safeIncreaseAllowance(
                address(router),
                type(uint256).max
            );
            isApproved[source] = true;
        }
        return
            router.exchange_multiple(
                swapData.route,
                swapData.swapParams,
                value,
                0,
                [address(0), address(0), address(0), address(0)],
                beneficiary
            );
    }

    function previewSwap(
        address source,
        address destination,
        uint256 value
    ) external view returns (uint256) {
        CurveSwapData memory swapData = swapDatas[source][destination];
        return router.get_exchange_multiple_amount(swapData.route, swapData.swapParams, value);
    }
}