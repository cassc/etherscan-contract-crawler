// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IQuoterV2} from "@pancake/v3-periphery/contracts/interfaces/IQuoterV2.sol";
import {IPancakeV3Factory} from "@pancake/v3-core/contracts/interfaces/IPancakeV3Factory.sol";
import {TickMath} from "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import {IPancakeV3Pool} from "@pancake/v3-core/contracts/interfaces/IPancakeV3Pool.sol";
import {IPancakeV3SwapCallback} from "@pancake/v3-core/contracts/interfaces/callback/IPancakeV3SwapCallback.sol";
import {IConverter} from "contracts/interfaces/IConverter.sol";

/// @author YLDR <[email protected]>
contract PancakeV3Converter is IConverter, Ownable, IPancakeV3SwapCallback {
    using SafeERC20 for IERC20;

    IPancakeV3Factory public factory;
    IQuoterV2 public quoter;

    uint24 defaultFee = 500;

    mapping(address => mapping(address => uint24)) public fees;

    constructor(IPancakeV3Factory _factory, IQuoterV2 _quoter) Ownable() {
        factory = _factory;
        quoter = _quoter;
    }

    struct UpdateFeeParams {
        address source;
        address destination;
        uint24 fee;
    }

    function updateFees(UpdateFeeParams[] memory updates) public onlyOwner {
        for (uint256 i = 0; i < updates.length; i++) {
            fees[updates[i].source][updates[i].destination] = updates[i].fee;
            fees[updates[i].destination][updates[i].source] = updates[i].fee;
        }
    }

    function _getFee(address source, address destination) internal view returns (uint24) {
        return fees[source][destination] == 0 ? defaultFee : fees[source][destination];
    }

    function swap(address source, address destination, uint256 value, address beneficiary) external returns (uint256) {
        uint24 fee = _getFee(source, destination);
        IPancakeV3Pool pool = IPancakeV3Pool(factory.getPool(source, destination, fee));
        require(address(pool) != address(0), "Pool does not exist");
        bool zeroForOne = source < destination;
        (int256 amount0, int256 amount1) = pool.swap(
            beneficiary,
            zeroForOne,
            int256(value),
            zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1,
            abi.encode(source, destination, fee)
        );
        return uint256(-(zeroForOne ? amount1 : amount0));
    }

    function pancakeV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external override {
        (address source, address destination, uint24 fee) = abi.decode(data, (address, address, uint24));
        require(msg.sender == factory.getPool(source, destination, fee), "Invalid caller");
        IERC20(source).safeTransfer(msg.sender, uint256(source < destination ? amount0Delta : amount1Delta));
    }

    function previewSwap(address source, address destination, uint256 value) external returns (uint256 amountOut) {
        (amountOut,,,) = quoter.quoteExactInputSingle(
            IQuoterV2.QuoteExactInputSingleParams(source, destination, value, _getFee(source, destination), 0)
        );
    }
}