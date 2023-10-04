// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/utils/Context.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import "./library/Babylonian.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IRouter.sol";
import "./interfaces/IFactory.sol";
import "./interfaces/ITTMarketplace.sol";
import "./interfaces/ITeamNFT.sol";

pragma solidity ^0.8.9;

contract TTZapper is Context, ERC1155Holder {
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for IERC20;

    IRouter public constant router =
        IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    address public constant WETH =
        address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    address public immutable teamToken;

    ITeamNFT public immutable teamNft;

    ITTMarketplace public immutable marketplace;
    IUniswapV2Pair public immutable teamTokenPair;

    uint256 public constant minimumAmount = 1000;

    constructor(address _marketplace, address _teamToken, address _teamNFT) {
        marketplace = ITTMarketplace(_marketplace);
        teamToken = _teamToken;
        teamNft = ITeamNFT(_teamNFT);
        address _factory = IRouter(router).factory();
        teamTokenPair = IUniswapV2Pair(
            IFactory(_factory).getPair(WETH, teamToken)
        );
        _approveTokenIfNeeded(teamToken, address(marketplace));
        _approveTokenIfNeeded(WETH, address(router));
    }

    receive() external payable {}

    function buyWithETH(
        uint256 sellId,
        uint256 nftAmount,
        uint256 tokenId
    ) external payable {
        require(
            msg.value >= minimumAmount,
            "TTZapper: Insignificant input amount"
        );

        IWETH(WETH).deposit{value: msg.value}();
        uint256 _wethBalance = IERC20(WETH).balanceOf(address(this));
        swap(
            address(teamToken),
            (estimateSwap(_wethBalance) * 98) / 100,
            WETH,
            _wethBalance
        );

        // SellList memory nftSaleInfo = marketplace.sales(sellId);

        _buyNFT(sellId, nftAmount);

        teamNft.safeTransferFrom(
            address(this),
            _msgSender(),
            tokenId,
            nftAmount,
            ""
        );

        _returnTokens();
    }

    function _buyNFT(
        uint256 sellId,
        uint quantity
    ) internal returns (uint256 amountBought) {
        amountBought = marketplace.buyTeamNFT(sellId, quantity);
    }

    // _baseBalance = swap(zapToken, 0, tokenIn, tokenInAmount);
    // _approveTokenIfNeeded(zapToken, address(beefyUniV2Zap));
    // beefyUniV2Zap.beefIn(
    //     beefyVault,
    //     tokenAmountOutMin,
    //     zapToken,
    //     _baseBalance
    // );

    // vault.transfer(_msgSender(), vault.balanceOf(address(this)));
    // address[] memory _returnAssetTokens;
    // if (zapToken != want) {
    //     IUniswapV2Pair _pairAddress = IUniswapV2Pair(
    //         basePairInfo.wantAddress
    //     );
    //     _returnAssetTokens = new address[](2);
    //     _returnAssetTokens[0] = _pairAddress.token0();
    //     _returnAssetTokens[1] = _pairAddress.token1();
    // } else {
    //     _returnAssetTokens = new address[](1);
    //     _returnAssetTokens[0] = zapToken;
    // }
    // _returnAssets(_returnAssetTokens);

    function swap(
        address tokenOut,
        uint256 tokenAmountOutMin,
        address tokenIn,
        uint256 tokenInAmount
    ) internal returns (uint256 baseBalance) {
        if (tokenIn != tokenOut) {
            _swap(tokenOut, tokenAmountOutMin, tokenIn, tokenInAmount);
        }
        baseBalance = IERC20(tokenOut).balanceOf(address(this));
    }

    function _returnTokens() private {
        address[] memory _returnAssetTokens;
        _returnAssetTokens = new address[](2);
        _returnAssetTokens[0] = WETH;
        _returnAssetTokens[1] = teamToken;
        _returnAssets(_returnAssetTokens);
    }

    function _returnAssets(address[] memory tokens) private {
        uint256 balance;
        for (uint256 i; i < tokens.length; i++) {
            balance = IERC20(tokens[i]).balanceOf(address(this));
            if (balance > 0) {
                if (tokens[i] == WETH) {
                    IWETH(WETH).withdraw(balance);
                    (bool success, ) = _msgSender().call{value: balance}(
                        new bytes(0)
                    );
                    require(success, "TTZapper: ETH transfer failed");
                } else {
                    IERC20(tokens[i]).safeTransfer(_msgSender(), balance);
                }
            }
        }
    }

    function estimateSwap(
        uint256 fullInvestmentIn
    ) public view returns (uint256 swapAmountOut) {
        IUniswapV2Pair pair = teamTokenPair;
        bool isInputA = pair.token0() == WETH;
        require(
            isInputA || pair.token1() == teamToken,
            "Input token not present in liqudity pair"
        );

        (uint256 reserveA, uint256 reserveB, ) = pair.getReserves();
        (reserveA, reserveB) = isInputA
            ? (reserveA, reserveB)
            : (reserveB, reserveA);

        swapAmountOut = router.getAmountOut(
            fullInvestmentIn,
            reserveA,
            reserveB
        );
    }

    function _swap(
        address tokenOut,
        uint256 tokenAmountOutMin,
        address tokenIn,
        uint256 tokenInAmount
    ) internal returns (uint256[] memory amounts) {
        uint256 wethAmount;

        if (tokenIn == WETH) {
            wethAmount = tokenInAmount;
        } else {
            IUniswapV2Pair pair = IUniswapV2Pair(teamTokenPair);
            bool isInputA = pair.token0() == tokenIn;
            require(
                isInputA || pair.token1() == tokenIn,
                "TTZapper: Input token not present in input pair"
            );
            address[] memory path;
            IRouter tokenInRouter = IRouter(router);
            path = new address[](2);
            path[0] = tokenIn;
            path[1] = WETH;
            // }
            amounts = tokenInRouter.swapExactTokensForTokens(
                tokenInAmount,
                0,
                path,
                address(this),
                block.timestamp
            );
            wethAmount = IERC20(WETH).balanceOf(address(this));
        }

        if (tokenOut != WETH) {
            IRouter baseRouter = router;
            address[] memory basePath;

            basePath = new address[](2);
            basePath[0] = WETH;
            basePath[1] = tokenOut;

            amounts = baseRouter.swapExactTokensForTokens(
                wethAmount,
                tokenAmountOutMin,
                basePath,
                address(this),
                block.timestamp
            );
        }
    }

    function _giveAllowance(address _address, address _router) internal {
        IERC20(_address).approve(_router, 0);
        IERC20(_address).approve(_router, uint256(1e50));
    }

    function _removeAllowance(address _address, address _router) internal {
        IERC20(_address).approve(_router, 0);
    }

    function _approveTokenIfNeeded(address token, address spender) private {
        if (IERC20(token).allowance(address(this), spender) == 0) {
            IERC20(token).approve(spender, type(uint256).max);
        }
    }
}