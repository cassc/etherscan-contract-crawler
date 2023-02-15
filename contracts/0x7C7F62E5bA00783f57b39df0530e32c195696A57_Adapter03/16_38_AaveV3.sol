pragma solidity 0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../Utils.sol";

import "../../AugustusStorage.sol";

interface IAaveV3WETHGateway {
    function depositETH(
        address pool,
        address onBehalfOf,
        uint16 referralCode
    ) external payable;

    function withdrawETH(
        address pool,
        uint256 amount,
        address onBehalfOf
    ) external;
}

interface IAaveV3Pool {
    function supply(
        IERC20 asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function withdraw(
        IERC20 asset,
        uint256 amount,
        address to
    ) external returns (uint256);
}

contract AaveV3 {
    struct AaveData {
        address aToken;
    }

    uint16 public immutable aaveV3RefCode;
    address public immutable aaveV3Pool;
    address public immutable aaveV3WethGateway;

    constructor(
        uint16 _refCode,
        address _pool,
        address _wethGateway
    ) public {
        aaveV3RefCode = _refCode;
        aaveV3Pool = _pool;
        aaveV3WethGateway = _wethGateway;
    }

    function swapOnAaveV3(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        bytes calldata payload
    ) internal {
        _swapOnAaveV3(fromToken, toToken, fromAmount, payload);
    }

    function buyOnAaveV3(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        bytes calldata payload
    ) internal {
        _swapOnAaveV3(fromToken, toToken, fromAmount, payload);
    }

    function _swapOnAaveV3(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        bytes memory payload
    ) private {
        AaveData memory data = abi.decode(payload, (AaveData));

        if (address(fromToken) == address(data.aToken)) {
            if (address(toToken) == Utils.ethAddress()) {
                Utils.approve(aaveV3WethGateway, address(fromToken), fromAmount);
                IAaveV3WETHGateway(aaveV3WethGateway).withdrawETH(aaveV3Pool, fromAmount, address(this));
            } else {
                Utils.approve(aaveV3Pool, address(fromToken), fromAmount);
                IAaveV3Pool(aaveV3Pool).withdraw(toToken, fromAmount, address(this));
            }
        } else if (address(toToken) == address(data.aToken)) {
            if (address(fromToken) == Utils.ethAddress()) {
                IAaveV3WETHGateway(aaveV3WethGateway).depositETH{ value: fromAmount }(
                    aaveV3Pool,
                    address(this),
                    aaveV3RefCode
                );
            } else {
                Utils.approve(aaveV3Pool, address(fromToken), fromAmount);
                IAaveV3Pool(aaveV3Pool).supply(fromToken, fromAmount, address(this), aaveV3RefCode);
            }
        } else {
            revert("Invalid aToken");
        }
    }
}