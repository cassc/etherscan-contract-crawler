pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/ICurve.sol";
import "../libraries/SwapCalldataUtils.sol";
import "../libraries/Flags.sol";

contract DummyPool is ICurve {
    using SwapCalldataUtils for bytes;

    address public tokenA;
    address public tokenB;

    constructor(address _tokenA, address _tokenB) {
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    // called for any calldata (see SAMPLE_CALLDATA in src/SwapCalldataParser.js)
    // thus emulating real-world pool/router behavior
    fallback (bytes calldata _input) external returns (bytes memory) {
        // pick token where msg.sender have positive balance
        address token = IERC20(tokenA).balanceOf(msg.sender) > 0
            ? tokenA
            : tokenB;
        require(IERC20(token).balanceOf(msg.sender) > 0, "unexpected zeroes");

        // extract amount from the calldata
        (uint256 amount, bool success) = _input.getAmount();
        if (success) {
            (IERC20 srcToken, IERC20 dstToken) = _getSrcAndDst(token);
            _swap(srcToken, dstToken, msg.sender, msg.sender, amount);
        }
    }

    function swap(
        address token,
        address from,
        address to,
        uint256 amount
    ) external returns (uint256) {
        (IERC20 srcToken, IERC20 dstToken) = _getSrcAndDst(token);
        return _swap(srcToken, dstToken, from, to, amount);
    }

    function swap(
        address token,
        address from,
        address to
    ) external returns (uint256) {
        (IERC20 srcToken, IERC20 dstToken) = _getSrcAndDst(token);

        uint256 amount = srcToken.balanceOf(from);
        return _swap(srcToken, dstToken, from, to, amount);
    }

    function exchange_underlying(
        int128 _i,
        int128 _j,
        uint256 _dx,
        uint256 _min_dy
    ) external override returns (uint256) {
        address token = _i == 0 ? tokenA : tokenB;
        (IERC20 srcToken, IERC20 dstToken) = _getSrcAndDst(token);
        return _swap(srcToken, dstToken, msg.sender, msg.sender, _dx);
    }

    function exchange_underlying(
        address _pool,
        int128 _i,
        int128 _j,
        uint256 _dx,
        uint256 _min_dy,
        address _receiver
    ) external override returns (uint256) {
        address token = _i == 0 ? tokenA : tokenB;
        (IERC20 srcToken, IERC20 dstToken) = _getSrcAndDst(token);
        return _swap(srcToken, dstToken, msg.sender, _receiver, _dx);

        // address token = _i == 0 ? tokenA : tokenB;
        // (IERC20 srcToken, IERC20 dstToken) = _getSrcAndDst(token);

        // srcToken.transferFrom(msg.sender, address(this), _dx);
        // uint amount = ICurve(_pool).exchange_underlying(_i, _j, _dx, _min_dy);
        // if (amount > 0) {
        //     dstToken.transfer(_receiver, amount);
        // }
        // else {
        //     srcToken.transfer(msg.sender, _dx);
        // }
    }

    function _getSrcAndDst(address _srcToken)
        internal
        view
        returns (IERC20 srcToken, IERC20 dstToken)
    {
        srcToken = IERC20(tokenA);
        dstToken = IERC20(tokenB);
        if (_srcToken == address(dstToken)) {
            dstToken = srcToken;
            srcToken = IERC20(_srcToken);
        } else {
            require(_srcToken == address(srcToken));
        }
    }

    function _swap(
        IERC20 srcToken,
        IERC20 dstToken,
        address from,
        address to,
        uint256 amount
    ) internal returns (uint256) {
        uint256 amountOut = amount - amount / 100;

        if (dstToken.balanceOf(address(this)) > amountOut) {
            srcToken.transferFrom(from, address(this), amount);

            dstToken.transfer(to, amount - amount / 100);

            return amountOut;
        }
    }
}