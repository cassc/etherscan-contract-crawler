//**** SPDX-License-Identifier: Frensware *///// 🐸

//🐸🐸🐸🐸🐸🐸🐸🐸🐸🐸🐸🐸🐸🐸🐸🐸
//WETH: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 ... g: 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6
//p3p3d3x ROUTER: 0x724F7c8a9Cb973Ee7C0689a643D29908bC3865b5 ...
// CONSTRuctorArGUMENTS: 000000000000000000000000b4fbf271143f4fbf7b91a5ded31805e42b2208d6000000000000000000000000715b1c10da0c87880834e875bb108dfa2953e36d0000000000000000000000000000000000000000000000000000000000000032
//SPLIT THAT SHIT 50/50 (_MAXZAPREVERSERATIO) ⚡️⚡️⚡️⚡️⚡️⚡️⚡️⚡️  

/*＞＜﹐name: ZAP﹐🥽⚡️ᴢᴀᴘ⚡️, zapメ, ♛ Ꮓ Ѧ Ꭾ ㋦ ʸᵗ ♛, Zap⚡️ᴢᴀᴘ⚡️, zapメ, ♛ Ꮓ Ѧ Ꭾ ㋦ ʸᵗ ♛, Zap⚡️ᴢᴀᴘ⚡️, zapメ, 🐸♛ Ꮓ Ѧ Ꭾ ㋦ ʸᵗ ♛, Zap⚡️ᴢᴀᴘ⚡️, zapメ, ♛ Ꮓ Ѧ Ꭾ ㋦ ʸᵗ ♛, Zap⚡️ᴢᴀᴘ⚡️, zapメ, ♛ Ꮓ Ѧ Ꭾ ㋦ ʸᵗ ♛, Zap⚡️ᴢᴀᴘ⚡️, zapメ, ♛ Ꮓ Ѧ Ꭾ ㋦ ʸᵗ ♛, Zap⚡️ᴢᴀᴘ⚡️, zapメ, ♛ Ꮓ Ѧ Ꭾ ㋦ ʸᵗ ♛, Zap⚡️ᴢᴀᴘ⚡️, zapメ, ♛ Ꮓ Ѧ Ꭾ ㋦ ʸᵗ ♛, Zap
🎱🎱🎱🎱🎱🎱🐸🐸🎱🎱🎱🎱🐸🐸🎱🎱🎱🎱🎱🎱🎱🐸🐸🐸🎱🎱🎱🎱🎱🎱🎱🎱🎱🎱🎱🎱🎱🎱🎱🎱🎱

ʬʬ﹐🛁ᶻz﹕pronouns: ⚡️ᴢᴀᴘ⚡️, zapメ, ♛ Ꮓ Ѧ Ꭾ ㋦ ʸᵗ ♛, Zap⚡️ᴢᴀᴘ⚡️, zapメ, ♛ Ꮓ Ѧ Ꭾ ㋦ ʸᵗ ♛, Zap﹐★

🐄﹑sexuallity: ⚡️ᴢᴀᴘ⚡️, zapメ, ♛ Ꮓ Ѧ Ꭾ ㋦ ʸᵗ ♛, Zap⚡️ᴢᴀᴘ⚡️, zapメ, ♛ Ꮓ Ѧ Ꭾ ㋦ ʸᵗ ♛, Zap﹒⟡﹒⤿ 🐸

♡︎ ﹔📓﹒ext﹐ıllı🐸🐸🐸🐸🐸🐸🐸🐸

！🎱﹒﹒ext﹒⪨   @(ⁱⁿᵗᵉʳⁿᵃˡ_ʳᵘᵍ_ˢᵉʳᵛⁱᶜᵉ IRS/@supersorbet)   *//////// ⚡️⚡️⚡️ 🐸🐸
//////////////////////////////////////////////////// 🐸🐸🐸🐸🐸 🐸 pepedex.pepepal.com

pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {IPepeDexPair} from "./interfaces/IPepeDexPair.sol";
import {IPepeDexRouter02} from "./interfaces/IPepeDexRouter02.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {Babylonian} from "./libraries/Babylonian.sol";

/*
 * @author Inspiration from the work of Zapper and Beefy.
 * Implemented and modified by PepeDex/PepePal teams.
 */
contract PepeDexZapZapZapZapZapZapZapZapZap is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IWETH public WETH;

    IPepeDexRouter02 public pepeDexRouter;

    uint256 public constant MAX_INT = 2**256 - 1;

    uint256 public constant MINIMUM_AMOUNT = 1000;

    uint256 public maxZapReverseRatio;

    address private pepeDexRouterAddress;

    address private WETHAddress;

    event AdminTokenRecovery(address indexed tokenAddress, uint256 amountTokens);

    event NewMaxZapReverseRatio(uint256 maxZapReverseRatio);


    event ZapIn(
        address indexed tokenToZap,
        address indexed lpToken,
        uint256 tokenAmountIn,
        uint256 lpTokenAmountReceived,
        address indexed user
    );

    event ZapInRebalancing(
        address indexed token0ToZap,
        address indexed token1ToZap,
        address lpToken,
        uint256 token0AmountIn,
        uint256 token1AmountIn,
        uint256 lpTokenAmountReceived,
        address indexed user
    );

    event ZapOut(
        address indexed lpToken,
        address indexed tokenToReceive,
        uint256 lpTokenAmount,
        uint256 tokenAmountReceived,
        address indexed user
    );

    receive() external payable {
        assert(msg.sender == WETHAddress);
    }

    constructor(
        address _WETHAddress,
        address _pepeDexRouter,
        uint256 _maxZapReverseRatio
    ) {
        WETHAddress = _WETHAddress;
        WETH = IWETH(_WETHAddress);
        pepeDexRouterAddress = _pepeDexRouter;
        pepeDexRouter = IPepeDexRouter02(_pepeDexRouter);
        maxZapReverseRatio = _maxZapReverseRatio;
    }

    function zapInETH(address _lpToken, uint256 _tokenAmountOutMin) external payable nonReentrant {
        WETH.deposit{value: msg.value}();


        uint256 lpTokenAmountTransferred = _zapIn(WETHAddress, msg.value, _lpToken, _tokenAmountOutMin);


        emit ZapIn(
            address(0x0000000000000000000000000000000000000000),
            _lpToken,
            msg.value,
            lpTokenAmountTransferred,
            msg.sender
        );
    }

    function zapInToken(
        address _tokenToZap,
        uint256 _tokenAmountIn,
        address _lpToken,
        uint256 _tokenAmountOutMin
    ) external nonReentrant {

        IERC20(_tokenToZap).safeTransferFrom(msg.sender, address(this), _tokenAmountIn);


        uint256 lpTokenAmountTransferred = _zapIn(_tokenToZap, _tokenAmountIn, _lpToken, _tokenAmountOutMin);

        emit ZapIn(_tokenToZap, _lpToken, _tokenAmountIn, lpTokenAmountTransferred, msg.sender);
    }

    function zapInTokenRebalancing(
        address _token0ToZap,
        address _token1ToZap,
        uint256 _token0AmountIn,
        uint256 _token1AmountIn,
        address _lpToken,
        uint256 _tokenAmountInMax,
        uint256 _tokenAmountOutMin,
        bool _isToken0Sold
    ) external nonReentrant {

        IERC20(_token0ToZap).safeTransferFrom(msg.sender, address(this), _token0AmountIn);
        IERC20(_token1ToZap).safeTransferFrom(msg.sender, address(this), _token1AmountIn);

        uint256 lpTokenAmountTransferred = _zapInRebalancing(
            _token0ToZap,
            _token1ToZap,
            _token0AmountIn,
            _token1AmountIn,
            _lpToken,
            _tokenAmountInMax,
            _tokenAmountOutMin,
            _isToken0Sold
        );

        // Emit event
        emit ZapInRebalancing(
            _token0ToZap,
            _token1ToZap,
            _lpToken,
            _token0AmountIn,
            _token1AmountIn,
            lpTokenAmountTransferred,
            msg.sender
        );
    }

    function zapInETHRebalancing(
        address _token1ToZap,
        uint256 _token1AmountIn,
        address _lpToken,
        uint256 _tokenAmountInMax,
        uint256 _tokenAmountOutMin,
        bool _isToken0Sold
    ) external payable nonReentrant {
        WETH.deposit{value: msg.value}();

        IERC20(_token1ToZap).safeTransferFrom(msg.sender, address(this), _token1AmountIn);

        // Call zapIn function
        uint256 lpTokenAmountTransferred = _zapInRebalancing(
            WETHAddress,
            _token1ToZap,
            msg.value,
            _token1AmountIn,
            _lpToken,
            _tokenAmountInMax,
            _tokenAmountOutMin,
            _isToken0Sold
        );

        // Emit event
        emit ZapInRebalancing(
            address(0x0000000000000000000000000000000000000000),
            _token1ToZap,
            _lpToken,
            msg.value,
            _token1AmountIn,
            lpTokenAmountTransferred,
            msg.sender
        );
    }

    function zapOutETH(
        address _lpToken,
        uint256 _lpTokenAmount,
        uint256 _tokenAmountOutMin,
        uint256 _totalTokenAmountOutMin
    ) external nonReentrant {

        IERC20(_lpToken).safeTransferFrom(msg.sender, address(_lpToken), _lpTokenAmount);

        uint256 tokenAmountToTransfer = _zapOut(_lpToken, WETHAddress, _tokenAmountOutMin, _totalTokenAmountOutMin);

        WETH.withdraw(tokenAmountToTransfer);

        // Transfer ETH to the msg.sender
        (bool success, ) = msg.sender.call{value: tokenAmountToTransfer}(new bytes(0));
        require(success, "ETH: transfer fail");

        // Emit event
        emit ZapOut(
            _lpToken,
            address(0x0000000000000000000000000000000000000000),
            _lpTokenAmount,
            tokenAmountToTransfer,
            msg.sender
        );
    }

    function zapOutToken(
        address _lpToken,
        address _tokenToReceive,
        uint256 _lpTokenAmount,
        uint256 _tokenAmountOutMin,
        uint256 _totalTokenAmountOutMin
    ) external nonReentrant {
        // Transfer LP token to this address
        IERC20(_lpToken).safeTransferFrom(msg.sender, address(_lpToken), _lpTokenAmount);

        uint256 tokenAmountToTransfer = _zapOut(_lpToken, _tokenToReceive, _tokenAmountOutMin, _totalTokenAmountOutMin);

        IERC20(_tokenToReceive).safeTransfer(msg.sender, tokenAmountToTransfer);

        emit ZapOut(_lpToken, _tokenToReceive, _lpTokenAmount, tokenAmountToTransfer, msg.sender);
    }

    function updateMaxZapInverseRatio(uint256 _maxZapInverseRatio) external onlyOwner {
        maxZapReverseRatio = _maxZapInverseRatio;
        emit NewMaxZapReverseRatio(_maxZapInverseRatio);
    }

    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        IERC20(_tokenAddress).safeTransfer(msg.sender, _tokenAmount);
        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }


    function estimateZapInSwap(
        address _tokenToZap,
        uint256 _tokenAmountIn,
        address _lpToken
    )
        external
        view
        returns (
            uint256 swapAmountIn,
            uint256 swapAmountOut,
            address swapTokenOut
        )
    {
        address token0 = IPepeDexPair(_lpToken).token0();
        address token1 = IPepeDexPair(_lpToken).token1();

        require(_tokenToZap == token0 || _tokenToZap == token1, "Zap: Wrong tokens");

        // Convert to uint256 (from uint112)
        (uint256 reserveA, uint256 reserveB, ) = IPepeDexPair(_lpToken).getReserves();

        if (token0 == _tokenToZap) {
            swapTokenOut = token1;
            swapAmountIn = _calculateAmountToSwap(_tokenAmountIn, reserveA, reserveB);
            swapAmountOut = pepeDexRouter.getAmountOut(swapAmountIn, reserveA, reserveB);
        } else {
            swapTokenOut = token0;
            swapAmountIn = _calculateAmountToSwap(_tokenAmountIn, reserveB, reserveA);
            swapAmountOut = pepeDexRouter.getAmountOut(swapAmountIn, reserveB, reserveA);
        }

        return (swapAmountIn, swapAmountOut, swapTokenOut);
    }

    function estimateZapInRebalancingSwap(
        address _token0ToZap,
        address _token1ToZap,
        uint256 _token0AmountIn,
        uint256 _token1AmountIn,
        address _lpToken
    )
        external
        view
        returns (
            uint256 swapAmountIn,
            uint256 swapAmountOut,
            bool sellToken0
        )
    {
        require(
            _token0ToZap == IPepeDexPair(_lpToken).token0() || _token0ToZap == IPepeDexPair(_lpToken).token1(),
            "Zap: Wrong token0"
        );
        require(
            _token1ToZap == IPepeDexPair(_lpToken).token0() || _token1ToZap == IPepeDexPair(_lpToken).token1(),
            "Zap: Wrong token1"
        );

        require(_token0ToZap != _token1ToZap, "Zap: Same tokens");

        // Convert to uint256 (from uint112)
        (uint256 reserveA, uint256 reserveB, ) = IPepeDexPair(_lpToken).getReserves();

        if (_token0ToZap == IPepeDexPair(_lpToken).token0()) {
            sellToken0 = (_token0AmountIn * reserveB > _token1AmountIn * reserveA) ? true : false;

            // Calculate the amount that is expected to be swapped
            swapAmountIn = _calculateAmountToSwapForRebalancing(
                _token0AmountIn,
                _token1AmountIn,
                reserveA,
                reserveB,
                sellToken0
            );


            if (sellToken0) {
                swapAmountOut = pepeDexRouter.getAmountOut(swapAmountIn, reserveA, reserveB);
            } else {
                swapAmountOut = pepeDexRouter.getAmountOut(swapAmountIn, reserveB, reserveA);
            }
        } else {
            sellToken0 = (_token0AmountIn * reserveA > _token1AmountIn * reserveB) ? true : false;
            // Calculate the amount that is expected to be swapped
            swapAmountIn = _calculateAmountToSwapForRebalancing(
                _token0AmountIn,
                _token1AmountIn,
                reserveB,
                reserveA,
                sellToken0
            );

            // Calculate the amount expected to be received in the intermediary swap
            if (sellToken0) {
                swapAmountOut = pepeDexRouter.getAmountOut(swapAmountIn, reserveB, reserveA);
            } else {
                swapAmountOut = pepeDexRouter.getAmountOut(swapAmountIn, reserveA, reserveB);
            }
        }

        return (swapAmountIn, swapAmountOut, sellToken0);
    }

    function estimateZapOutSwap(
        address _lpToken,
        uint256 _lpTokenAmount,
        address _tokenToReceive
    )
        external
        view
        returns (
            uint256 swapAmountIn,
            uint256 swapAmountOut,
            address swapTokenOut
        )
    {
        address token0 = IPepeDexPair(_lpToken).token0();
        address token1 = IPepeDexPair(_lpToken).token1();

        require(_tokenToReceive == token0 || _tokenToReceive == token1, "Zap: Token not in LP");

        // Convert to uint256 (from uint112)
        (uint256 reserveA, uint256 reserveB, ) = IPepeDexPair(_lpToken).getReserves();

        if (token1 == _tokenToReceive) {
            // sell token0
            uint256 tokenAmountIn = (_lpTokenAmount * reserveA) / IPepeDexPair(_lpToken).totalSupply();

            swapAmountIn = _calculateAmountToSwap(tokenAmountIn, reserveA, reserveB);
            swapAmountOut = pepeDexRouter.getAmountOut(swapAmountIn, reserveA, reserveB);

            swapTokenOut = token0;
        } else {
            // sell token1
            uint256 tokenAmountIn = (_lpTokenAmount * reserveB) / IPepeDexPair(_lpToken).totalSupply();

            swapAmountIn = _calculateAmountToSwap(tokenAmountIn, reserveB, reserveA);
            swapAmountOut = pepeDexRouter.getAmountOut(swapAmountIn, reserveB, reserveA);

            swapTokenOut = token1;
        }

        return (swapAmountIn, swapAmountOut, swapTokenOut);
    }

    function _zapIn(
        address _tokenToZap,
        uint256 _tokenAmountIn,
        address _lpToken,
        uint256 _tokenAmountOutMin
    ) internal returns (uint256 lpTokenReceived) {
        require(_tokenAmountIn >= MINIMUM_AMOUNT, "Zap: Amount too low");

        address token0 = IPepeDexPair(_lpToken).token0();
        address token1 = IPepeDexPair(_lpToken).token1();

        require(_tokenToZap == token0 || _tokenToZap == token1, "Zap: Wrong tokens");

        // Retrieve the path
        address[] memory path = new address[](2);
        path[0] = _tokenToZap;

        // Initiates an estimation to swap
        uint256 swapAmountIn;

        {
            // Convert to uint256 (from uint112)
            (uint256 reserveA, uint256 reserveB, ) = IPepeDexPair(_lpToken).getReserves();

            require((reserveA >= MINIMUM_AMOUNT) && (reserveB >= MINIMUM_AMOUNT), "Zap: Reserves too low");

            if (token0 == _tokenToZap) {
                swapAmountIn = _calculateAmountToSwap(_tokenAmountIn, reserveA, reserveB);
                path[1] = token1;
                require(reserveA / swapAmountIn >= maxZapReverseRatio, "Zap: Quantity higher than limit");
            } else {
                swapAmountIn = _calculateAmountToSwap(_tokenAmountIn, reserveB, reserveA);
                path[1] = token0;
                require(reserveB / swapAmountIn >= maxZapReverseRatio, "Zap: Quantity higher than limit");
            }
        }

        // Approve token to zap if necessary
        _approveTokenIfNeeded(_tokenToZap, swapAmountIn);

        uint256[] memory swapedAmounts = pepeDexRouter.swapExactTokensForTokens(
            swapAmountIn,
            _tokenAmountOutMin,
            path,
            address(this),
            block.timestamp
        );

        // Approve other token if necessary
        if (token0 == _tokenToZap) {
            _approveTokenIfNeeded(token1, swapAmountIn);
        } else {
            _approveTokenIfNeeded(token0, swapAmountIn);
        }

        // Add liquidity and retrieve the amount of LP received by the sender
        (, , lpTokenReceived) = pepeDexRouter.addLiquidity(
            path[0],
            path[1],
            _tokenAmountIn - swapedAmounts[0],
            swapedAmounts[1],
            1,
            1,
            msg.sender,
            block.timestamp
        );

        return lpTokenReceived;
    }

    function _zapInRebalancing(
        address _token0ToZap,
        address _token1ToZap,
        uint256 _token0AmountIn,
        uint256 _token1AmountIn,
        address _lpToken,
        uint256 _tokenAmountInMax,
        uint256 _tokenAmountOutMin,
        bool _isToken0Sold
    ) internal returns (uint256 lpTokenReceived) {
        require(
            _token0ToZap == IPepeDexPair(_lpToken).token0() || _token0ToZap == IPepeDexPair(_lpToken).token1(),
            "Zap: Wrong token0"
        );
        require(
            _token1ToZap == IPepeDexPair(_lpToken).token0() || _token1ToZap == IPepeDexPair(_lpToken).token1(),
            "Zap: Wrong token1"
        );

        require(_token0ToZap != _token1ToZap, "Zap: Same tokens");

        // Initiates an estimation to swap
        uint256 swapAmountIn;

        {
            // Convert to uint256 (from uint112)
            (uint256 reserveA, uint256 reserveB, ) = IPepeDexPair(_lpToken).getReserves();

            require((reserveA >= MINIMUM_AMOUNT) && (reserveB >= MINIMUM_AMOUNT), "Zap: Reserves too low");

            if (_token0ToZap == IPepeDexPair(_lpToken).token0()) {
                swapAmountIn = _calculateAmountToSwapForRebalancing(
                    _token0AmountIn,
                    _token1AmountIn,
                    reserveA,
                    reserveB,
                    _isToken0Sold
                );
                require(reserveA / swapAmountIn >= maxZapReverseRatio, "Zap: Quantity higher than limit");
            } else {
                swapAmountIn = _calculateAmountToSwapForRebalancing(
                    _token0AmountIn,
                    _token1AmountIn,
                    reserveB,
                    reserveA,
                    _isToken0Sold
                );

                require(reserveB / swapAmountIn >= maxZapReverseRatio, "Zap: Quantity higher than limit");
            }
        }

        require(swapAmountIn <= _tokenAmountInMax, "Zap: Amount to swap too high");

        address[] memory path = new address[](2);

        // Define path for swapping and check whether to approve token to sell in intermediary swap
        if (_isToken0Sold) {
            path[0] = _token0ToZap;
            path[1] = _token1ToZap;
            _approveTokenIfNeeded(_token0ToZap, swapAmountIn);
        } else {
            path[0] = _token1ToZap;
            path[1] = _token0ToZap;
            _approveTokenIfNeeded(_token1ToZap, swapAmountIn);
        }

        // Execute the swap and retrieve quantity received
        uint256[] memory swapedAmounts = pepeDexRouter.swapExactTokensForTokens(
            swapAmountIn,
            _tokenAmountOutMin,
            path,
            address(this),
            block.timestamp
        );

        // Check whether to approve other token and add liquidity to LP
        if (_isToken0Sold) {
            _approveTokenIfNeeded(_token1ToZap, swapAmountIn);

            (, , lpTokenReceived) = pepeDexRouter.addLiquidity(
                path[0],
                path[1],
                (_token0AmountIn - swapedAmounts[0]),
                (_token1AmountIn + swapedAmounts[1]),
                1,
                1,
                msg.sender,
                block.timestamp
            );
        } else {
            _approveTokenIfNeeded(_token0ToZap, swapAmountIn);
            (, , lpTokenReceived) = pepeDexRouter.addLiquidity(
                path[0],
                path[1],
                (_token1AmountIn - swapedAmounts[0]),
                (_token0AmountIn + swapedAmounts[1]),
                1,
                1,
                msg.sender,
                block.timestamp
            );
        }

        return lpTokenReceived;
    }

    function _zapOut(
        address _lpToken,
        address _tokenToReceive,
        uint256 _tokenAmountOutMin,
        uint256 _totalTokenAmountOutMin
    ) internal returns (uint256) {
        address token0 = IPepeDexPair(_lpToken).token0();
        address token1 = IPepeDexPair(_lpToken).token1();

        require(_tokenToReceive == token0 || _tokenToReceive == token1, "Zap: Token not in LP");

        // Burn all LP tokens to receive the two tokens to this address
        (uint256 amount0, uint256 amount1) = IPepeDexPair(_lpToken).burn(address(this));

        require(amount0 >= MINIMUM_AMOUNT, "PepeDexRouter: INSUFFICIENT_A_AMOUNT");
        require(amount1 >= MINIMUM_AMOUNT, "PepeDexRouter: INSUFFICIENT_B_AMOUNT");

        address[] memory path = new address[](2);
        path[1] = _tokenToReceive;

        uint256 swapAmountIn;

        if (token0 == _tokenToReceive) {
            path[0] = token1;
            swapAmountIn = IERC20(token1).balanceOf(address(this));

            // Approve token to sell if necessary
            _approveTokenIfNeeded(token1, swapAmountIn);
        } else {
            path[0] = token0;
            swapAmountIn = IERC20(token0).balanceOf(address(this));

            // Approve token to sell if necessary
            _approveTokenIfNeeded(token0, swapAmountIn);
        }

        // Swap tokens
        pepeDexRouter.swapExactTokensForTokens(swapAmountIn, _tokenAmountOutMin, path, address(this), block.timestamp);

        // Return full balance for the token to receive by the sender
        require(_totalTokenAmountOutMin < IERC20(_tokenToReceive).balanceOf(address(this)), "amount is not enough");
        return IERC20(_tokenToReceive).balanceOf(address(this));
    }

    function _approveTokenIfNeeded(address _token, uint256 _swapAmountIn) private {
        if (IERC20(_token).allowance(address(this), pepeDexRouterAddress) < _swapAmountIn) {
            // Reset to 0
            IERC20(_token).safeApprove(pepeDexRouterAddress, 0);
            // Re-approve
            IERC20(_token).safeApprove(pepeDexRouterAddress, MAX_INT);
        }
    }

    function _calculateAmountToSwap(
        uint256 _token0AmountIn,
        uint256 _reserve0,
        uint256 _reserve1
    ) private view returns (uint256 amountToSwap) {
        uint256 halfToken0Amount = _token0AmountIn / 2;
        uint256 nominator = pepeDexRouter.getAmountOut(halfToken0Amount, _reserve0, _reserve1);
        uint256 denominator = pepeDexRouter.quote(
            halfToken0Amount,
            _reserve0 + halfToken0Amount,
            _reserve1 - nominator
        );

        // Adjustment for price impact
        amountToSwap =
            _token0AmountIn -
            Babylonian.sqrt((halfToken0Amount * halfToken0Amount * nominator) / denominator);

        return amountToSwap;
    }

    function _calculateAmountToSwapForRebalancing(
        uint256 _token0AmountIn,
        uint256 _token1AmountIn,
        uint256 _reserve0,
        uint256 _reserve1,
        bool _isToken0Sold
    ) private view returns (uint256 amountToSwap) {
        bool sellToken0 = (_token0AmountIn * _reserve1 > _token1AmountIn * _reserve0) ? true : false;

        require(sellToken0 == _isToken0Sold, "Zap: Wrong trade direction");

        if (sellToken0) {
            uint256 token0AmountToSell = (_token0AmountIn - (_token1AmountIn * _reserve0) / _reserve1) / 2;
            uint256 nominator = pepeDexRouter.getAmountOut(token0AmountToSell, _reserve0, _reserve1);
            uint256 denominator = pepeDexRouter.quote(
                token0AmountToSell,
                _reserve0 + token0AmountToSell,
                _reserve1 - nominator
            );

            // Calculate the amount to sell (in token0)
            token0AmountToSell =
                (_token0AmountIn - (_token1AmountIn * (_reserve0 + token0AmountToSell)) / (_reserve1 - nominator)) /
                2;

            // Adjustment for price impact
            amountToSwap =
                2 *
                token0AmountToSell -
                Babylonian.sqrt((token0AmountToSell * token0AmountToSell * nominator) / denominator);
        } else {
            uint256 token1AmountToSell = (_token1AmountIn - (_token0AmountIn * _reserve1) / _reserve0) / 2;
            uint256 nominator = pepeDexRouter.getAmountOut(token1AmountToSell, _reserve1, _reserve0);

            uint256 denominator = pepeDexRouter.quote(
                token1AmountToSell,
                _reserve1 + token1AmountToSell,
                _reserve0 - nominator
            );

            // Calculate the amount to sell (in token1)
            token1AmountToSell =
                (_token1AmountIn - ((_token0AmountIn * (_reserve1 + token1AmountToSell)) / (_reserve0 - nominator))) /
                2;

            // Adjustment for price impact
            amountToSwap =
                2 *
                token1AmountToSell -
                Babylonian.sqrt((token1AmountToSell * token1AmountToSell * nominator) / denominator);
        }

        return amountToSwap;
    }
}