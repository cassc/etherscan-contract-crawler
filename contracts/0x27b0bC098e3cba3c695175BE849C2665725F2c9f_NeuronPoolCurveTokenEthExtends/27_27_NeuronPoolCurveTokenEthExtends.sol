// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IAggregator } from "../../interfaces/IAgregator.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import { ICurveFi_2 } from "../../interfaces/ICurve.sol";
import { NeuronPoolBaseInitialize } from "../NeuronPoolBaseInitialize.sol";
import { IUniswapRouterV2 } from "../../interfaces/IUniswapRouterV2.sol";
import { UniswapV3Helper } from "../../lib/UniswapV3Helper.sol";
import { IWETH } from "../../interfaces/IWETH.sol";

contract NeuronPoolCurveTokenEthExtends is NeuronPoolBaseInitialize, OwnableUpgradeable {
    using SafeERC20 for IERC20Metadata;

    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    IAggregator public pricerEthUsd;

    ICurveFi_2 internal basePool;
    IERC20Metadata internal secondTokenInBasePool;

    bytes[] public swapsUsdcWeth;

    bytes[] public swapsWethUsdc;

    uint256 public swapSlippage;

    function initialize(
        address _token,
        address _governance,
        address _controller,
        address _basePool,
        address _secondTokenInBasePool
    ) external initializer {
        __NeuronPoolBaseInitialize_init(_token, _governance, _controller);
        __Ownable_init_unchained();
        basePool = ICurveFi_2(_basePool);
        secondTokenInBasePool = IERC20Metadata(_secondTokenInBasePool);
        pricerEthUsd = IAggregator(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        swapsUsdcWeth = [abi.encodePacked(USDC, uint24(500), WETH), abi.encodePacked(USDC, uint24(3000), WETH)];
        swapsWethUsdc = [abi.encodePacked(WETH, uint24(500), USDC), abi.encodePacked(WETH, uint24(3000), USDC)];
        swapSlippage = 500;
    }

    function getSupportedTokens() external view override returns (address[] memory tokens) {
        tokens = new address[](5);
        tokens[0] = address(token);
        tokens[1] = address(ETH);
        tokens[2] = WETH;
        tokens[3] = address(secondTokenInBasePool);
        tokens[4] = address(USDC);
    }

    function deposit(address _enterToken, uint256 _amount) public payable override nonReentrant returns (uint256) {
        IERC20Metadata enterToken = IERC20Metadata(_enterToken);

        require(_amount > 0, "!_amount");

        if (enterToken == ETH) require(msg.value == _amount, "msg.value != _amount");

        address self = address(this);
        IERC20Metadata _token = token;

        uint256 _balance = balance();

        if (enterToken == _token) {
            _token.safeTransferFrom(msg.sender, self, _amount);
        } else if (enterToken == USDC) {
            _amount = depositBaseToken(ETH, _swapUSDCtoETH(_amount));
        } else {
            if (address(enterToken) == WETH) {
                IERC20Metadata(WETH).safeTransferFrom(msg.sender, self, _amount);
                IWETH(WETH).withdraw(_amount);
                enterToken = ETH;
            }
            _amount = depositBaseToken(enterToken, _amount);
        }

        return _mintShares(_amount, _balance);
    }

    function depositBaseToken(IERC20Metadata _enterToken, uint256 _amount) internal returns (uint256) {
        address self = address(this);
        IERC20Metadata _token = token;
        ICurveFi_2 _basePool = basePool;

        uint256[2] memory addLiquidityPayload;

        if (_enterToken == ETH) {
            addLiquidityPayload[0] = _amount;
        } else if (_enterToken == secondTokenInBasePool) {
            addLiquidityPayload[1] = _amount;
            _enterToken.safeTransferFrom(msg.sender, self, _amount);
            _enterToken.safeApprove(address(_basePool), 0);
            _enterToken.safeApprove(address(_basePool), _amount);
        } else {
            revert("!token");
        }

        uint256 initialLpTokenBalance = _token.balanceOf(self);
        _basePool.add_liquidity{ value: _enterToken == ETH ? _amount : 0 }(addLiquidityPayload, 0);

        uint256 resultLpTokenBalance = _token.balanceOf(self);

        require(resultLpTokenBalance > initialLpTokenBalance, "Tokens were not received from the liquidity pool");

        return resultLpTokenBalance - initialLpTokenBalance;
    }

    function withdraw(address _withdrawableToken, uint256 _shares) public override nonReentrant {
        uint256 amount = _withdrawLpTokens(_shares);
        IERC20Metadata withdrawableToken = IERC20Metadata(_withdrawableToken);

        if (withdrawableToken != token) {
            if (withdrawableToken == USDC) {
                amount = _swapETHtoUSDC(withdrawBaseToken(address(ETH), amount));
            } else if (_withdrawableToken == WETH) {
                amount = withdrawBaseToken(address(ETH), amount);
                IWETH(WETH).deposit{ value: amount }();
                withdrawableToken = IERC20Metadata(WETH);
            } else {
                amount = withdrawBaseToken(address(_withdrawableToken), amount);
            }
        }

        require(amount > 0, "!withdrawableAmount");

        if (withdrawableToken == ETH) {
            (bool success, ) = payable(msg.sender).call{ value: amount }("");
            require(success, "Transfer ETH failed");
        } else {
            withdrawableToken.safeTransfer(msg.sender, amount);
        }
    }

    function withdrawBaseToken(address _withdrawableToken, uint256 _userLpTokensAmount) internal returns (uint256) {
        address self = address(this);
        IERC20Metadata withdrawableToken = IERC20Metadata(_withdrawableToken);

        int128 tokenIndex;
        if (withdrawableToken == ETH) {
            tokenIndex = 0;

            uint256 initialETHBalance = self.balance;
            basePool.remove_liquidity_one_coin(_userLpTokensAmount, tokenIndex, 0);
            uint256 resultETHBalance = self.balance;

            require(resultETHBalance > initialETHBalance, "!base_amount");

            return resultETHBalance - initialETHBalance;
        } else if (withdrawableToken == secondTokenInBasePool) {
            tokenIndex = 1;

            uint256 initialWithdrawableTokenBalance = withdrawableToken.balanceOf(self);
            basePool.remove_liquidity_one_coin(_userLpTokensAmount, tokenIndex, 0);
            uint256 resultWithdrawableTokenBalance = withdrawableToken.balanceOf(self);

            require(resultWithdrawableTokenBalance > initialWithdrawableTokenBalance, "!base_amount");

            return resultWithdrawableTokenBalance - initialWithdrawableTokenBalance;
        } else {
            revert("!token");
        }
    }

    function _getEthPrice() internal view returns (uint256) {
        (, int256 price, , , ) = pricerEthUsd.latestRoundData();
        return uint256(price);
    }

    function _swapUSDCtoETH(uint256 _amount) internal returns (uint256) {
        address self = address(this);
        USDC.safeTransferFrom(msg.sender, self, _amount);

        uint256 amountOutMinimum = (_amount * 1e38) / _getEthPrice() / 1e18; //result decimals 18

        USDC.safeApprove(UniswapV3Helper.UNISWAP_V3_ROUTER, 0);
        USDC.safeApprove(UniswapV3Helper.UNISWAP_V3_ROUTER, _amount);

        uint256 outputAmount = UniswapV3Helper.trySwap(self, swapsUsdcWeth, _amount, amountOutMinimum, swapSlippage);

        IWETH(WETH).withdraw(outputAmount);

        return outputAmount;
    }

    function _swapETHtoUSDC(uint256 _amount) internal returns (uint256) {
        uint256 amountOutMinimum = (_amount * _getEthPrice()) / 1e30; //result decimals 6

        IWETH(WETH).deposit{ value: _amount }();

        IERC20Metadata(WETH).safeApprove(UniswapV3Helper.UNISWAP_V3_ROUTER, 0);
        IERC20Metadata(WETH).safeApprove(UniswapV3Helper.UNISWAP_V3_ROUTER, _amount);

        return UniswapV3Helper.trySwap(address(this), swapsWethUsdc, _amount, amountOutMinimum, swapSlippage);
    }

    function setPricerEthUsd(address _newPricerEthUsd) external onlyOwner {
        require(_newPricerEthUsd != address(0), "!_newPricerEthUsd");
        pricerEthUsd = IAggregator(_newPricerEthUsd);
    }

    function setSwaps(bytes[] memory _newSwapsUsdcWeth, bytes[] memory _newSwapsWethUsdc) external onlyOwner {
        if (_newSwapsUsdcWeth.length > 0) {
            swapsUsdcWeth = _newSwapsUsdcWeth;
        }
        if (_newSwapsWethUsdc.length > 0) {
            swapsWethUsdc = _newSwapsWethUsdc;
        }
    }

    function setSwapSlippage(uint256 _newSwapSlippage) external onlyOwner {
        require(_newSwapSlippage <= UniswapV3Helper.MAX_SLIPPAGE, "!_newSwapSlippage");
        swapSlippage = _newSwapSlippage;
    }
}