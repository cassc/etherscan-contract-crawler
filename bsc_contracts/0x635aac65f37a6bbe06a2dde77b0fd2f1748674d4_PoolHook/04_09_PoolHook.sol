pragma solidity 0.8.15;

import {Ownable} from "openzeppelin/access/Ownable.sol";
import {IPoolHook} from "../interfaces/IPoolHook.sol";
import {Side, IPool} from "../interfaces/IPool.sol";
import {IMintableErc20} from "../interfaces/IMintableErc20.sol";
import {ILevelOracle} from "../interfaces/ILevelOracle.sol";

interface IPoolForHook {
    function oracle() external view returns (ILevelOracle);
    function isStableCoin(address) external view returns(bool);
}

contract PoolHook is Ownable, IPoolHook {
    uint256 constant MULTIPLIER_PRECISION = 100;
    uint256 constant MAX_MULTIPLIER = 5 * MULTIPLIER_PRECISION;
    uint8 constant lyLevelDecimals = 18;
    uint256 constant VALUE_PRECISION = 1e30;

    address private immutable pool;
    IMintableErc20 public immutable lyLevel;

    uint256 public positionSizeMultiplier = 100;
    uint256 public swapSizeMultiplier = 100;
    uint256 public stableSwapSizeMultiplier = 5;

    constructor(address _lyLevel, address _pool) {
        require(_lyLevel != address(0), "PoolHook:invalidAddress");
        require(_pool != address(0), "PoolHook:invalidAddress");
        lyLevel = IMintableErc20(_lyLevel);
        pool = _pool;
    }

    function validatePool(address sender) internal view {
        require(sender == pool, "PoolHook:!pool");
    }

    modifier onlyPool() {
        validatePool(msg.sender);
        _;
    }

    function postIncreasePosition(
        address _owner,
        address _indexToken,
        address _collateralToken,
        Side _side,
        bytes calldata _extradata
    ) external onlyPool {}

    function postDecreasePosition(
        address _owner,
        address _indexToken,
        address _collateralToken,
        Side _side,
        bytes calldata _extradata
    ) external onlyPool {
        (uint256 sizeChange, /* uint256 collateralValue */ ) = abi.decode(_extradata, (uint256, uint256));
        _handlePositionClosed(_owner, _indexToken, _collateralToken, _side, sizeChange);
        emit PostDecreasePositionExecuted(msg.sender, _owner, _indexToken, _collateralToken, _side, _extradata);
    }

    function postLiquidatePosition(
        address _owner,
        address _indexToken,
        address _collateralToken,
        Side _side,
        bytes calldata _extradata
    ) external onlyPool {
        (uint256 sizeChange, /* uint256 collateralValue */ ) = abi.decode(_extradata, (uint256, uint256));
        _handlePositionClosed(_owner, _indexToken, _collateralToken, _side, sizeChange);
        emit PostLiquidatePositionExecuted(msg.sender, _owner, _indexToken, _collateralToken, _side, _extradata);
    }

    function postSwap(address _user, address _tokenIn, address _tokenOut, bytes calldata _data) external onlyPool {
        (uint256 amountIn, /* uint256 amountOut */, bytes memory extradata) =
            abi.decode(_data, (uint256, uint256, bytes));
        (address benificier) = extradata.length != 0 ? abi.decode(extradata, (address)) : (address(0));
        benificier = benificier == address(0) ? _user : benificier;
        uint256 priceIn = _getPrice(_tokenIn, false);
        uint256 multiplier = _isStableSwap(_tokenIn, _tokenOut) ? stableSwapSizeMultiplier : swapSizeMultiplier;
        uint256 lyTokenAmount =
            (amountIn * priceIn * 10 ** lyLevelDecimals) * multiplier / MULTIPLIER_PRECISION / VALUE_PRECISION;
        if (lyTokenAmount != 0 && benificier != address(0)) {
            lyLevel.mint(benificier, lyTokenAmount);
        }
        emit PostSwapExecuted(msg.sender, _user, _tokenIn, _tokenOut, _data);
    }

    // ========= Admin function ========

    function setMultipliers(uint256 _positionSizeMultiplier, uint256 _swapSizeMultiplier, uint256 _stableSwapSizeMultiplier) external onlyOwner {
        require(_positionSizeMultiplier <= MAX_MULTIPLIER, "Multiplier too high");
        require(_swapSizeMultiplier <= MAX_MULTIPLIER, "Multiplier too high");
        require(_stableSwapSizeMultiplier <= MAX_MULTIPLIER, "Multiplier too high");
        positionSizeMultiplier = _positionSizeMultiplier;
        swapSizeMultiplier = _swapSizeMultiplier;
        stableSwapSizeMultiplier = _stableSwapSizeMultiplier;
        emit MultipliersSet(positionSizeMultiplier, swapSizeMultiplier, stableSwapSizeMultiplier);
    }

    // ========= Internal function ========
    function _handlePositionClosed(
        address _owner,
        address, /* _indexToken */
        address, /* _collateralToken */
        Side, /* _side */
        uint256 _sizeChange
    ) internal {
        uint256 lyTokenAmount =
            (_sizeChange * 10 ** lyLevelDecimals) * positionSizeMultiplier / MULTIPLIER_PRECISION / VALUE_PRECISION;

        if (lyTokenAmount != 0) {
            lyLevel.mint(_owner, lyTokenAmount);
        }
    }

    function _getPrice(address token, bool max) internal view returns (uint256) {
        ILevelOracle oracle = IPoolForHook(pool).oracle();
        return oracle.getPrice(token, max);
    }

    function _isStableSwap(address tokenIn, address tokenOut) internal view returns (bool) {
        IPoolForHook _pool = IPoolForHook(pool);
        return _pool.isStableCoin(tokenIn) && _pool.isStableCoin(tokenOut);
    }

    event ReferralControllerSet(address controller);
    event MultipliersSet(uint256 positionSizeMultiplier, uint256 swapSizeMultiplier, uint256 stableSwapSizeMultiplier);
}