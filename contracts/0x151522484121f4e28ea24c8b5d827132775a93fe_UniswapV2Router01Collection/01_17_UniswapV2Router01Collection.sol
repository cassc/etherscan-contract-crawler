// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { IUniswapV2Factory } from "../core/interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Pair } from "../core/interfaces/IUniswapV2Pair.sol";
import { IERC721 } from "../core/interfaces/IERC721.sol";
import { IWERC721 } from "../core/interfaces/IWERC721.sol";
import { TransferHelper } from "../lib/libraries/TransferHelper.sol";

import { IUniswapV2Router01Collection } from "./interfaces/IUniswapV2Router01Collection.sol";
import { UniswapV2Router01 } from "./UniswapV2Router01.sol";
import { UniswapV2Library } from "./libraries/UniswapV2Library.sol";
import { RoyaltyHelper } from "./libraries/RoyaltyHelper.sol";
import { IWETH } from "./interfaces/IWETH.sol";

contract UniswapV2Router01Collection is IUniswapV2Router01Collection, UniswapV2Router01 {
    address public override marketplaceAdmin;
    address public override marketplaceWallet;
    uint public override marketplaceFee;
    mapping(address => uint) public override royaltyFeeCap;

    constructor(address _factory, address _WETH, address _marketplaceAdmin, address _marketplaceWallet, uint _marketplaceFee) UniswapV2Router01(_factory, _WETH) {
        marketplaceAdmin = _marketplaceAdmin;
        marketplaceWallet = _marketplaceWallet;
        marketplaceFee = _marketplaceFee;
    }

    function updateAdmin(address _marketplaceAdmin) external
    {
        require(msg.sender == marketplaceAdmin, "SweepnFlipRouter: FORBIDDEN");
        marketplaceAdmin = _marketplaceAdmin;
        emit UpdateAdmin(_marketplaceAdmin);
    }

    function updateFeeConfig(address _marketplaceWallet, uint _marketplaceFee) external
    {
        require(msg.sender == marketplaceAdmin, "SweepnFlipRouter: FORBIDDEN");
        require(_marketplaceFee <= 100e16, "SweepnFlipRouter: INVALID_FEE");
        marketplaceWallet = _marketplaceWallet;
        marketplaceFee = _marketplaceFee;
        emit UpdateFeeConfig(_marketplaceWallet, _marketplaceFee);
    }

    function updateRoyaltyFeeCap(address collection, uint _royaltyFeeCap) external
    {
        require(msg.sender == marketplaceAdmin || msg.sender == collection, "SweepnFlipRouter: FORBIDDEN");
        require(_royaltyFeeCap <= 100e16, "SweepnFlipRouter: INVALID_FEE");
        royaltyFeeCap[collection] = _royaltyFeeCap;
        emit UpdateRoyaltyFeeCap(collection, _royaltyFeeCap);
    }

    function _getWrapper(address collection) internal returns (address wrapper) {
        wrapper = IUniswapV2Factory(factory).getWrapper(collection);
        if (wrapper == address(0)) {
            wrapper = IUniswapV2Factory(factory).createWrapper(collection);
        }
        if (!IERC721(collection).isApprovedForAll(address(this), wrapper)) {
            IERC721(collection).setApprovalForAll(wrapper, true);
        }
    }

    function _mint(address wrapper, address to, uint[] memory tokenIds) internal {
        address collection = IWERC721(wrapper).collection();
        for (uint i = 0; i < tokenIds.length; i++) {
            IERC721(collection).transferFrom(msg.sender, address(this), tokenIds[i]);
        }
        IWERC721(wrapper).mint(to, tokenIds);
    }

    // **** ADD LIQUIDITY ****
    function addLiquidityCollection(
        address tokenA,
        address collectionB,
        uint amountADesired,
        uint[] memory tokenIdsB,
        uint amountAMin,
        address to,
        uint deadline
    ) external override ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        address wrapperB = _getWrapper(collectionB);
        uint amountBMin = tokenIdsB.length * 1e18;
        (amountA, amountB) = _addLiquidity(
            tokenA,
            wrapperB,
            amountADesired,
            amountBMin,
            amountAMin,
            amountBMin
        );
        address pair = UniswapV2Library.pairFor(factory, tokenA, wrapperB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        _mint(wrapperB, pair, tokenIdsB);
        liquidity = IUniswapV2Pair(pair).mint(to);
    }
    function addLiquidityETHCollection(
        address collection,
        uint[] memory tokenIds,
        uint amountETHMin,
        address to,
        uint deadline
    ) external override payable ensure(deadline) returns (uint amountToken, uint amountETH, uint liquidity) {
        address wrapper = _getWrapper(collection);
        uint amountTokenMin = tokenIds.length * 1e18;
        (amountToken, amountETH) = _addLiquidity(
            wrapper,
            WETH,
            amountTokenMin,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pair = UniswapV2Library.pairFor(factory, wrapper, WETH);
        _mint(wrapper, pair, tokenIds);
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));
        liquidity = IUniswapV2Pair(pair).mint(to);
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH); // refund dust eth, if any
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidityCollection(
        address tokenA,
        address collectionB,
        uint liquidity,
        uint[] memory tokenIdsB,
        uint amountAMin,
        address to,
        uint deadline
    ) public override ensure(deadline) returns (uint amountA, uint amountB) {
        address wrapperB = _getWrapper(collectionB);
        uint amountBMin = tokenIdsB.length * 1e18;
        (amountA, amountB) = removeLiquidity(
            tokenA,
            wrapperB,
            liquidity,
            amountAMin,
            amountBMin,
            address(this),
            deadline
        );
        require(amountB == amountBMin, "SweepnFlipRouter: EXCESSIVE_B_AMOUNT");
        TransferHelper.safeTransfer(tokenA, to, amountA);
        IWERC721(wrapperB).burn(to, tokenIdsB);
    }
    function removeLiquidityETHCollection(
        address collection,
        uint liquidity,
        uint[] memory tokenIds,
        uint amountETHMin,
        address to,
        uint deadline
    ) public override ensure(deadline) returns (uint amountToken, uint amountETH) {
        address wrapper = _getWrapper(collection);
        uint amountTokenMin = tokenIds.length * 1e18;
        (amountToken, amountETH) = removeLiquidity(
            wrapper,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        require(amountToken == amountTokenMin, "SweepnFlipRouter: EXCESSIVE_A_AMOUNT");
        IWERC721(wrapper).burn(to, tokenIds);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }
/*
    function removeLiquidityWithPermitCollection(
        address tokenA,
        address collectionB,
        uint liquidity,
        uint[] memory tokenIdsB,
        uint amountAMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external override returns (uint amountA, uint amountB) {
        address wrapperB = _getWrapper(collectionB);
        address pair = UniswapV2Library.pairFor(factory, tokenA, wrapperB);
        uint value = approveMax ? type(uint).max : liquidity;
        IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountA, amountB) = removeLiquidityCollection(tokenA, collectionB, liquidity, tokenIdsB, amountAMin, to, deadline);
    }
    function removeLiquidityETHWithPermitCollection(
        address collection,
        uint liquidity,
        uint[] memory tokenIds,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external override returns (uint amountToken, uint amountETH) {
        address wrapper = _getWrapper(collection);
        address pair = UniswapV2Library.pairFor(factory, wrapper, WETH);
        uint value = approveMax ? type(uint).max : liquidity;
        IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountETH) = removeLiquidityETHCollection(collection, liquidity, tokenIds, amountETHMin, to, deadline);
    }
*/
    // **** SWAP ****
    function swapExactTokensForTokensCollection(
        uint[] memory tokenIdsIn,
        uint amountOutMin,
        address[] memory path,
        bool capRoyaltyFee,
        address to,
        uint deadline
    ) external override ensure(deadline) returns (uint[] memory amounts) {
        address collection = path[0];
        path[0] = _getWrapper(collection);
        amounts = UniswapV2Library.getAmountsOut(factory, tokenIdsIn.length * 1e18, path);
        uint amountOut = amounts[amounts.length - 1];
        (address[] memory royaltyReceivers, uint[] memory royaltyAmounts, uint totalRoyaltyAmount) = RoyaltyHelper.getRoyaltyInfo(collection, tokenIdsIn, amountOut, marketplaceWallet, marketplaceFee, capRoyaltyFee ? royaltyFeeCap[collection] : 100e16);
        _mint(path[0], UniswapV2Library.pairFor(factory, path[0], path[1]), tokenIdsIn);
        uint netAmountOut = amountOut - totalRoyaltyAmount;
        require(netAmountOut >= amountOutMin, "SweepnFlipRouter: INSUFFICIENT_OUTPUT_AMOUNT");
        if (totalRoyaltyAmount == 0) {
            _swap(amounts, path, to);
        } else {
            _swap(amounts, path, address(this));
            address tokenOut = path[path.length - 1];
            TransferHelper.safeTransfer(tokenOut, to, netAmountOut);
            TransferHelper.safeTransferBatch(tokenOut, royaltyReceivers, royaltyAmounts);
        }
    }
    function swapTokensForExactTokensCollection(
        uint[] memory tokenIdsOut,
        uint amountInMax,
        address[] memory path,
        bool capRoyaltyFee,
        address to,
        uint deadline
    ) external override ensure(deadline) returns (uint[] memory amounts) {
        address collection = path[path.length - 1];
        path[path.length - 1] = _getWrapper(collection);
        amounts = UniswapV2Library.getAmountsIn(factory, tokenIdsOut.length * 1e18, path);
        uint amountIn = amounts[0];
        (address[] memory royaltyReceivers, uint[] memory royaltyAmounts, uint totalRoyaltyAmount) = RoyaltyHelper.getRoyaltyInfo(collection, tokenIdsOut, amountIn, marketplaceWallet, marketplaceFee, capRoyaltyFee ? royaltyFeeCap[collection] : 100e16);
        require(amountIn + totalRoyaltyAmount <= amountInMax, "SweepnFlipRouter: EXCESSIVE_INPUT_AMOUNT");
        {
        address pair = UniswapV2Library.pairFor(factory, path[0], path[1]);
        TransferHelper.safeTransferFrom(path[0], msg.sender, pair, amountIn);
        }
        _swap(amounts, path, address(this));
        IWERC721(path[path.length - 1]).burn(to, tokenIdsOut);
        if (totalRoyaltyAmount > 0) {
            TransferHelper.safeTransferFromBatch(path[0], msg.sender, royaltyReceivers, royaltyAmounts);
        }
    }
    function swapExactTokensForETHCollection(uint[] memory tokenIdsIn, uint amountOutMin, address[] memory path, bool capRoyaltyFee, address to, uint deadline)
        external
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, "SweepnFlipRouter: INVALID_PATH");
        address collection = path[0];
        path[0] = _getWrapper(collection);
        amounts = UniswapV2Library.getAmountsOut(factory, tokenIdsIn.length * 1e18, path);
        uint amountOut = amounts[amounts.length - 1];
        (address[] memory royaltyReceivers, uint[] memory royaltyAmounts, uint totalRoyaltyAmount) = RoyaltyHelper.getRoyaltyInfo(collection, tokenIdsIn, amountOut, marketplaceWallet, marketplaceFee, capRoyaltyFee ? royaltyFeeCap[collection] : 100e16);
        _mint(path[0], UniswapV2Library.pairFor(factory, path[0], path[1]), tokenIdsIn);
        uint netAmountOut = amountOut - totalRoyaltyAmount;
        require(netAmountOut >= amountOutMin, "SweepnFlipRouter: INSUFFICIENT_OUTPUT_AMOUNT");
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, netAmountOut);
        if (totalRoyaltyAmount > 0) {
            TransferHelper.safeTransferETHBatch(royaltyReceivers, royaltyAmounts);
        }
    }
    function swapETHForExactTokensCollection(uint[] memory tokenIdsOut, address[] memory path, bool capRoyaltyFee, address to, uint deadline)
        external
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, "SweepnFlipRouter: INVALID_PATH");
        address collection = path[path.length - 1];
        path[path.length - 1] = _getWrapper(collection);
        amounts = UniswapV2Library.getAmountsIn(factory, tokenIdsOut.length * 1e18, path);
        uint amountIn = amounts[0];
        (address[] memory royaltyReceivers, uint[] memory royaltyAmounts, uint totalRoyaltyAmount) = RoyaltyHelper.getRoyaltyInfo(collection, tokenIdsOut, amountIn, marketplaceWallet, marketplaceFee, capRoyaltyFee ? royaltyFeeCap[collection] : 100e16);
        uint grossAmountIn = amountIn + totalRoyaltyAmount;
        require(grossAmountIn <= msg.value, "SweepnFlipRouter: EXCESSIVE_INPUT_AMOUNT");
        IWETH(WETH).deposit{value: amountIn}();
        {
        address pair = UniswapV2Library.pairFor(factory, path[0], path[1]);
        assert(IWETH(WETH).transfer(pair, amountIn));
        }
        _swap(amounts, path, address(this));
        IWERC721(path[path.length - 1]).burn(to, tokenIdsOut);
        if (totalRoyaltyAmount > 0) {
            TransferHelper.safeTransferETHBatch(royaltyReceivers, royaltyAmounts);
        }
        if (msg.value > grossAmountIn) TransferHelper.safeTransferETH(msg.sender, msg.value - grossAmountIn); // refund dust eth, if any
    }

    function getAmountsOutCollection(uint[] memory tokenIdsIn, address[] memory path, bool capRoyaltyFee) external view override returns (uint[] memory amounts)
    {
        address collection = path[0];
        path[0] = IUniswapV2Factory(factory).getWrapper(collection);
        amounts = UniswapV2Library.getAmountsOut(factory, tokenIdsIn.length * 1e18, path);
        uint amountOut = amounts[amounts.length - 1];
        (,,uint totalRoyaltyAmount) = RoyaltyHelper.getRoyaltyInfo(collection, tokenIdsIn, amountOut, marketplaceWallet, marketplaceFee, capRoyaltyFee ? royaltyFeeCap[collection] : 100e16);
        amounts[amounts.length - 1] = amountOut - totalRoyaltyAmount;
        return amounts;
    }

    function getAmountsInCollection(uint[] memory tokenIdsOut, address[] memory path, bool capRoyaltyFee) external view override returns (uint[] memory amounts)
    {
        address collection = path[path.length - 1];
        path[path.length - 1] = IUniswapV2Factory(factory).getWrapper(collection);
        amounts = UniswapV2Library.getAmountsIn(factory, tokenIdsOut.length * 1e18, path);
        uint amountIn = amounts[0];
        (,,uint totalRoyaltyAmount) = RoyaltyHelper.getRoyaltyInfo(collection, tokenIdsOut, amountIn, marketplaceWallet, marketplaceFee, capRoyaltyFee ? royaltyFeeCap[collection] : 100e16);
        amounts[0] = amountIn + totalRoyaltyAmount;
        return amounts;
    }

    event UpdateAdmin(address marketplaceAdmin);
    event UpdateFeeConfig(address marketplaceWallet, uint marketplaceFee);
    event UpdateRoyaltyFeeCap(address indexed collection, uint royaltyFeeCap);
}