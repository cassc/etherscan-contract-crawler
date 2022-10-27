// Router contract of:
//  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄       ▄▄       ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄    ▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄        ▄ 
// ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░▌     ▐░░▌     ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░▌  ▐░▌▐░░░░░░░░░░░▌▐░░▌      ▐░▌
// ▐░█▀▀▀▀▀▀▀▀▀ ▐░█▀▀▀▀▀▀▀▀▀ ▐░▌░▌   ▐░▐░▌      ▀▀▀▀█░█▀▀▀▀ ▐░█▀▀▀▀▀▀▀█░▌▐░▌ ▐░▌ ▐░█▀▀▀▀▀▀▀▀▀ ▐░▌░▌     ▐░▌
// ▐░▌          ▐░▌          ▐░▌▐░▌ ▐░▌▐░▌          ▐░▌     ▐░▌       ▐░▌▐░▌▐░▌  ▐░▌          ▐░▌▐░▌    ▐░▌
// ▐░▌          ▐░▌          ▐░▌ ▐░▐░▌ ▐░▌          ▐░▌     ▐░▌       ▐░▌▐░▌░▌   ▐░█▄▄▄▄▄▄▄▄▄ ▐░▌ ▐░▌   ▐░▌
// ▐░▌          ▐░▌          ▐░▌  ▐░▌  ▐░▌          ▐░▌     ▐░▌       ▐░▌▐░░▌    ▐░░░░░░░░░░░▌▐░▌  ▐░▌  ▐░▌
// ▐░▌          ▐░▌          ▐░▌   ▀   ▐░▌          ▐░▌     ▐░▌       ▐░▌▐░▌░▌   ▐░█▀▀▀▀▀▀▀▀▀ ▐░▌   ▐░▌ ▐░▌
// ▐░▌          ▐░▌          ▐░▌       ▐░▌          ▐░▌     ▐░▌       ▐░▌▐░▌▐░▌  ▐░▌          ▐░▌    ▐░▌▐░▌
// ▐░█▄▄▄▄▄▄▄▄▄ ▐░█▄▄▄▄▄▄▄▄▄ ▐░▌       ▐░▌          ▐░▌     ▐░█▄▄▄▄▄▄▄█░▌▐░▌ ▐░▌ ▐░█▄▄▄▄▄▄▄▄▄ ▐░▌     ▐░▐░▌
// ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░▌       ▐░▌          ▐░▌     ▐░░░░░░░░░░░▌▐░▌  ▐░▌▐░░░░░░░░░░░▌▐░▌      ▐░░▌
//  ▀▀▀▀▀▀▀▀▀▀▀  ▀▀▀▀▀▀▀▀▀▀▀  ▀         ▀            ▀       ▀▀▀▀▀▀▀▀▀▀▀  ▀    ▀  ▀▀▀▀▀▀▀▀▀▀▀  ▀        ▀▀ 
// Welcome to CryptoContractManagement.
// Join us on our journey of revolutionizing the fund generation mode of crypto tokens.
//
// Key features:
// - Sophisticated taxation model to allow tokens to gather funds without hurting the charts
// - Highly customizable infrastructure which gives all the power into the hands of the token developers
// - Novel approach to separate token funding from its financial ecosystem
//
// Socials:
// - Website: https://ccmtoken.tech
// - Github: https://github.com/orgs/crypto-contract-management/repositories
// - Telegram: https://t.me/CCMGlobal
// - Twitter: https://twitter.com/ccmtoken

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IPancakeRouter.sol";
import "./PcsPair.sol";
import "./TaxableRouter.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

library TransferHelper {
    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

contract CCMRouterV2 is TaxableRouter, UUPSUpgradeable {
    address public pcsRouter;
    address public pcsFactory;
    address public WETH;
    // List of taxable tokens.
    mapping(address => bool) public taxableToken;
    // Data differing between test and live chain
    //bytes32 constant pcsPairInitHash = hex"3a8a968e398c9691c40a1f5833d775b822e80b01691cf647d10960571ac84af0"; // local
    //bytes32 constant pcsPairInitHash = hex"ecba335299a6693cb2ebc4782e74669b84290b6378ea3a3873c7231a8d7d1074"; // testnet
    bytes32 constant pcsPairInitHash = hex"00fb7f630766e6a796048ea87d01acd3068e8ff67d078148a3fa3f4a84f69bd5"; // live net

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp || deadline == 0);
        _;
    }

    function initialize(address _pcsRouter, address _pcsFactory, address _weth) initializer public {
        TaxableRouter.initialize();
        pcsRouter = _pcsRouter;
        pcsFactory = _pcsFactory;
        WETH = _weth;
        setTaxableToken(_weth, true);
    }

    receive() external payable { }


    /// @notice Sets a taxable IERC20 token.
    /// @param token Token to tax
    function setTaxableToken(address token, bool isTaxable) public onlyOwner {
        taxableToken[token] = isTaxable;
    }

    // PancakeSwap helper functions.
    function pcsSortTokens(address a, address b) private pure returns(address token0, address token1) {
        (token0, token1) = a < b ? (a, b) : (b, a);
    }
    // calculates the CREATE2 address for a pair without making any external calls
    function pcsPairFor(address factory, address tokenA, address tokenB) private pure returns (address pair) {
        (address token0, address token1) = pcsSortTokens(tokenA, tokenB);
        pair = address(uint160(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                pcsPairInitHash
            )))));
    }
    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    // Taken from pcs router.
    function pcsGetAmountOut(address pair, address inAddress, uint amountIn, address outAddress) internal view returns (uint amountOut) {
        (address token0,) = pcsSortTokens(inAddress, outAddress);
        (uint reserve0, uint reserve1,) = IPancakePair(pair).getReserves();
        (uint reserveIn, uint reserveOut) = inAddress == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
        uint amountInWithFee = amountIn * 9975;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * 10000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    struct SwapInfo {
        uint tokensToTakeOut;
        uint tokensToSendFurther;
    }
    struct TaxInfo {
        address taxReceiver;
        address taxableToken;
        uint tokenTaxes;
    }

    /// @notice Execute the swapping mechanism on `path` using `taxInfos`.
    /// @param path Swap path.
    /// @param taxInfos Information about how many tokens to continue swapping with and how many to hold back.
    function _swap(address[] calldata path, SwapInfo[] memory taxInfos) private {
        bytes memory payload = new bytes(0);
        uint i;
        for (; i < path.length - 2; i++) {
            SwapInfo memory tokenSwapInfo = taxInfos[i];
            (address input, address output, address outputSuccessor) = (path[i], path[i + 1], path[i + 2]);
            address currentPair = pcsPairFor(pcsFactory, input, output);
            address nextPair = pcsPairFor(pcsFactory, output, outputSuccessor);
            (address token0,) = pcsSortTokens(input, output);
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), tokenSwapInfo.tokensToTakeOut) : (tokenSwapInfo.tokensToTakeOut, uint(0));
            if(tokenSwapInfo.tokensToTakeOut - tokenSwapInfo.tokensToSendFurther > 0){
                IPancakePair(currentPair).swap(amount0Out, amount1Out, address(this), payload);
                IERC20(output).transfer(nextPair, tokenSwapInfo.tokensToSendFurther);
            } else {
                IPancakePair(currentPair).swap(amount0Out, amount1Out, nextPair, payload);
            }
        }
        // Run last iteration manually and send tokens to us.
        (address inputLast, address outputLast) = (path[path.length - 2], path[path.length - 1]);
        (address token0Last,) = pcsSortTokens(inputLast, outputLast);
        
        uint amountOut = taxInfos[i].tokensToTakeOut;
        (uint amount0Last, uint amount1OutLast) = inputLast == token0Last ? (uint(0), amountOut) : (amountOut, uint(0));
        IPancakePair(pcsPairFor(pcsFactory, inputLast, outputLast)).swap(amount0Last, amount1OutLast, address(this), payload);
    }
    
    /// @notice Gathers information about a swapping path and how many taxes to take for each swap in-between.
    /// @param sender The sender of the swap.
    /// @param amountIn The initial amount in for the first swap.
    /// @param path The swap path.
    /// @return amounts The amounts swapped.
    /// @return swapInfos How many tokens to continue swapping with and how many to hold back.
    /// @return taxInfos How many tokens a certain tax receiver gets for a certain taxable token.
    function _getSwapInfos(address sender, uint amountIn, address[] calldata path) private returns(
        uint[] memory amounts, SwapInfo[] memory swapInfos, TaxInfo[] memory taxInfos) {
        amounts = new uint[](path.length);
        swapInfos = new SwapInfo[](path.length - 1);
        taxInfos = new TaxInfo[](path.length - 1);

        // The first swap can be a buy and we just take taxes for that one immediately.
        if(taxableToken[path[0]] && !taxableToken[path[1]]){
            (uint amountLeft,  uint tokenTax) = takeBuyTax(path[1], path[0], sender, amountIn);
            uint tokensOut = pcsGetAmountOut(pcsPairFor(pcsFactory, path[0], path[1]), path[0], amountLeft, path[1]);
            swapInfos[0] = SwapInfo(tokensOut, amountLeft);
            taxInfos[0] = TaxInfo(path[1], path[0], tokenTax);
            amounts[0] = amountIn = amountLeft;
            amounts[1] = tokensOut;
        } else {
            amounts[0] = amountIn;
        }
        // Create swap infos for every pair which takes taxes by 
        // not sending all available tokens to the pcs pairs.
        for(uint i = 0; i < path.length - 1; ++i){
            uint tokensOut = pcsGetAmountOut(pcsPairFor(pcsFactory, path[i], path[i + 1]), path[i], amountIn, path[i + 1]);
            bool isSell = !taxableToken[path[i]] && taxableToken[path[i + 1]];
            bool nextIsBuy = taxableToken[path[i + 1]] && i < path.length - 2 && !taxableToken[path[i + 2]];
            // Sell
            if(isSell){
                (uint amountLeft, uint tokenTax) = takeSellTax(path[i], path[i + 1], sender, tokensOut);
                swapInfos[i] = SwapInfo(tokensOut, amountLeft);
                taxInfos[i] = TaxInfo(path[i], path[i + 1], tokenTax);
                amounts[i + 1] = amountIn = tokensOut = amountLeft;
            }
            // Buy
            if(nextIsBuy){
                (uint amountLeft,  uint tokenTax) = takeBuyTax(path[i + 2], path[i + 1], sender, tokensOut);
                // If we already got a sell before and now we take immediate buy taxes
                // we have a swap of for example CCMT => WETH => SHIB.
                // Make sure the tax infos are at their correct place for that case (+1).
                // Also we have to further reduce the amount to send further for the existing swap info.
                if(isSell){
                    swapInfos[i].tokensToSendFurther = amountLeft;
                    taxInfos[i + 1] = TaxInfo(path[i + 2], path[i + 1], tokenTax);
                }
                else{
                    swapInfos[i] = SwapInfo(tokensOut, amountLeft);
                    taxInfos[i] = TaxInfo(path[i + 2], path[i + 1], tokenTax);
                }
                amounts[i + 1] = amountIn = amountLeft;
            }
            if(swapInfos[i].tokensToTakeOut == 0) {
                
                swapInfos[i] = SwapInfo(tokensOut, tokensOut);
                amounts[i + 1] = amountIn = tokensOut;
            }
        }
    }

    /// @notice Core function to initiate token swapping.
    /// @param amountIn How many tokens to start swapping with.
    /// @param amountOutMin Minimum tokens to receive for the function caller.
    /// @param path The swap path.
    /// @return amounts Actual amounts swapped.
    function _swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path
    ) private returns (uint[] memory amounts) {
        (uint[] memory swapAmounts, SwapInfo[] memory swapInfos, TaxInfo[] memory taxInfos) = _getSwapInfos(msg.sender, amountIn, path);
        amounts = swapAmounts;
        
        require(amounts[amounts.length - 1] >= amountOutMin, "CCM: LESS_OUT");
        
        IERC20(path[0]).transfer(pcsPairFor(pcsFactory, path[0], path[1]), amounts[0]);
        
        _swap(path, swapInfos);
        // Distribute taxes.
        for(uint i = 0; i < taxInfos.length; ++i){
            TaxInfo memory si = taxInfos[i];
            if(si.tokenTaxes > 0 && si.taxableToken != address(0)){
                IERC20(si.taxableToken).transfer(si.taxReceiver, si.tokenTaxes);
                ITaxToken(si.taxReceiver).onTaxClaimed(si.taxableToken, si.tokenTaxes);
            }
        }
    }

    /// @notice Swaps exactly `amountIn` ERC20 tokens for other ERC20 tokens.
    /// @param amountIn How many tokens to start swapping with.
    /// @param amountOutMin Minimum tokens to receive for the function caller.
    /// @param path The swap path.
    /// @param to The token receiver.
    /// @param deadline Timestamp after which the transaction has to be mined.
    /// @return amounts Actual amounts swapped.
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) public ensure(deadline) returns (uint[] memory amounts){
        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
        amounts = _swapExactTokensForTokens(amountIn, amountOutMin, path);
        require(IERC20(path[path.length - 1]).transfer(to, amounts[amounts.length - 1]));
    }

    /// @notice Swaps enough ERC20 tokens to get exactly `amountOut` ERC20 tokens out.
    /// @param amountOut How many tokens to get.
    /// @param amountInMax Maximum tokens to put in from the caller to get `amountOut` tokens.
    /// @param path The swap path.
    /// @param to The token receiver.
    /// @param deadline Timestamp after which the transaction has to be mined.
    /// @return amounts Actual amounts swapped.
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external ensure(deadline) returns (uint[] memory amounts) {
        uint amountIn = IPancakeRouter02(pcsRouter).getAmountsIn(amountOut, path)[0];
        require(amountIn <= amountInMax, "CCM: NEED_TO_MUCH_IN");
        amounts = swapExactTokensForTokens(amountIn, 0, path, to, deadline);
    }
    /// @notice Same as `swapExactTokensForTokens` but starting with BNB rather than an ERC20 token.
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        public
        virtual
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        uint amountIn = msg.value;
        IWETH(WETH).deposit{value: amountIn}();
        amounts = _swapExactTokensForTokens(amountIn, amountOutMin, path);
        require(IERC20(path[path.length - 1]).transfer(to, amounts[amounts.length - 1]));
    }
    /// @notice Same as `swapTokensForExactTokens` but ending with BNB rather than an ERC20 token.
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        virtual
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        // Transfer tokens from caller to this router and then swap these tokens via PCS.
        // Save BNB balance before and after to know how much BNB to send the caller after swapping.
        uint tokensNeeded = IPancakeRouter02(pcsRouter).getAmountsIn(amountOut, path)[0];
        require(tokensNeeded <= amountInMax, 'CCM: NOT_ENOUGH_OUT_FOR_IN');
        IERC20(path[0]).transferFrom(msg.sender, address(this), tokensNeeded);
        amounts = _swapExactTokensForTokens(tokensNeeded, 0, path);
        uint ethToTransfer = amounts[amounts.length - 1];
        IWETH(WETH).withdraw(ethToTransfer);

        TransferHelper.safeTransferETH(to, ethToTransfer);
    }
    /// @notice Same as `swapExactTokensForTokens` but ending with BNB rather than an ERC20 token.
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        public
        virtual
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
        amounts = _swapExactTokensForTokens(amountIn, amountOutMin, path);
        uint ethToTransfer = amounts[amounts.length - 1];
        IWETH(WETH).withdraw(ethToTransfer);
        // Now send to the caller.
        TransferHelper.safeTransferETH(to, ethToTransfer);
    }
    /// @notice Same as `swapTokensForExactTokens` but starting with BNB rather than an ERC20 token.
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        virtual
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        amounts = IPancakeRouter02(pcsRouter).getAmountsIn(amountOut, path);
        require(amounts[0] <= msg.value, 'CCM: NOT_ENOUGH_IN_FOR_OUT');
        if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
        IWETH(WETH).deposit{value: amounts[0]}();
        amounts = _swapExactTokensForTokens(amounts[0], 0, path);
        require(IERC20(path[path.length - 1]).transfer(to, amounts[amounts.length - 1]));
    }
    /// @notice Swaps exactly `amountIn` ERC20 tokens to get ERC20 tokens out.
    /// @notice Does support fees on tokens that take those by requiring that the final amount out is at least `amountOutMin`.
    /// @param amountIn Tokens to put in.
    /// @param amountOutMin Minimum tokens to get out.
    /// @param path The swap path.
    /// @param to The token receiver.
    /// @param deadline Timestamp after which the transaction has to be mined.
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external ensure(deadline) virtual {
        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
        uint[] memory amounts = _swapExactTokensForTokens(amountIn, amountOutMin, path);
        uint tokensToSend = amounts[amounts.length - 1];
        require(tokensToSend >= amountOutMin, "CCM: LESS_OUT");
        require(IERC20(path[path.length - 1]).transfer(to, tokensToSend), "Final transfer failed");
    }

    /// @notice Calculates the slippage needed to execute a trade between ERC20 tokens.
    /// @notice That function always reverts to make sure no changes have been made to the blockchain.
    /// @param amountIn The amount to put in.
    /// @param path The swap path.
    /// @param deadline Timestamp after which the transaction has to be mined.
    /// @notice Returns nothing, but reverts with an estimated slippage which gives a whole percentage for a certain `amountIn`.
    function estimateSlippage(
        uint amountIn,
        address[] calldata path,
        uint deadline
    ) public ensure(deadline){
        (uint[] memory swapAmounts,,) = _getSwapInfos(msg.sender, amountIn, path);
        uint[] memory amountsOut = IPancakeRouter02(pcsRouter).getAmountsOut(amountIn, path);
        uint shouldGet = amountsOut[amountsOut.length - 1];
        uint reallyGet = swapAmounts[swapAmounts.length - 1];
        revert(StringsUpgradeable.toString(100 - (reallyGet * 100 / shouldGet)));
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override {
        require(msg.sender == owner(), "CCM: CANNOT_UPGRADE");
    }
}