// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IAggregator } from "../../interfaces/IAgregator.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { ICurveFi_3_int128 } from "../../interfaces/ICurve.sol";
import { NeuronPoolBase } from "../NeuronPoolBase.sol";
import { UniswapV3Helper } from "../../lib/UniswapV3Helper.sol";

contract NeuronPoolCurveSBTC is NeuronPoolBase, Ownable {
    using SafeERC20 for IERC20Metadata;

    ICurveFi_3_int128 internal constant BASE_POOL = ICurveFi_3_int128(0x7fC77b5c7614E1533320Ea6DDc2Eb61fa00A9714);

    IERC20Metadata internal constant RENBTC = IERC20Metadata(0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D);
    IERC20Metadata internal constant WBTC = IERC20Metadata(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
    IERC20Metadata internal constant SBTC = IERC20Metadata(0xfE18be6b3Bd88A2D2A7f928d00292E7a9963CfC6);

    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    IAggregator public pricerBtcUsd = IAggregator(0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c);

    bytes[] public swapsUsdcWbtc = [
        abi.encodePacked(USDC, uint24(500), WETH, uint24(500), WBTC),
        abi.encodePacked(USDC, uint24(500), WETH, uint24(3000), WBTC),
        abi.encodePacked(USDC, uint24(3000), WETH, uint24(500), WBTC),
        abi.encodePacked(USDC, uint24(3000), WETH, uint24(3000), WBTC)
    ];

    bytes[] public swapsWbtcUsdc = [
        abi.encodePacked(WBTC, uint24(500), WETH, uint24(500), USDC),
        abi.encodePacked(WBTC, uint24(3000), WETH, uint24(500), USDC),
        abi.encodePacked(WBTC, uint24(500), WETH, uint24(3000), USDC),
        abi.encodePacked(WBTC, uint24(3000), WETH, uint24(3000), USDC)
    ];

    uint256 public swapSlippage = 500;

    constructor(
        address _token,
        address _governance,
        address _controller
    ) NeuronPoolBase(_token, _governance, _controller) {}

    function getSupportedTokens() external view override returns (address[] memory tokens) {
        tokens = new address[](5);
        tokens[0] = address(token);
        tokens[1] = address(RENBTC);
        tokens[2] = address(WBTC);
        tokens[3] = address(SBTC);
        tokens[4] = address(USDC);
    }

    function deposit(address _enterToken, uint256 _amount) public payable override nonReentrant returns (uint256) {
        require(_amount > 0, "!_amount");

        address self = address(this);
        IERC20Metadata enterToken = IERC20Metadata(_enterToken);
        IERC20Metadata _token = token;

        uint256 _balance = balance();

        if (enterToken == _token) {
            _token.safeTransferFrom(msg.sender, self, _amount);
        } else if (enterToken == USDC) {
            uint256 amount = _swapUSDCtoWBTC(_amount);
            _amount = depositBaseToken(WBTC, amount);
        } else {
            enterToken.safeTransferFrom(msg.sender, self, _amount);
            _amount = depositBaseToken(enterToken, _amount);
        }

        return _mintShares(_amount, _balance);
    }

    function depositBaseToken(IERC20Metadata _enterToken, uint256 _amount) internal returns (uint256) {
        address self = address(this);
        IERC20Metadata _token = token;
        IERC20Metadata enterToken = IERC20Metadata(_enterToken);

        uint256[3] memory addLiquidityPayload;
        if (enterToken == RENBTC) {
            addLiquidityPayload[0] = _amount;
        } else if (enterToken == WBTC) {
            addLiquidityPayload[1] = _amount;
        } else if (enterToken == SBTC) {
            addLiquidityPayload[2] = _amount;
        } else {
            revert("!token");
        }

        enterToken.safeApprove(address(BASE_POOL), 0);
        enterToken.safeApprove(address(BASE_POOL), _amount);

        uint256 initialLpTokenBalance = _token.balanceOf(self);

        BASE_POOL.add_liquidity(addLiquidityPayload, 0);

        uint256 resultLpTokenBalance = _token.balanceOf(self);

        require(resultLpTokenBalance > initialLpTokenBalance, "Tokens were not received from the liquidity pool");

        return resultLpTokenBalance - initialLpTokenBalance;
    }

    function withdraw(address _withdrawableToken, uint256 _shares) public override nonReentrant {
        uint256 amount = _withdrawLpTokens(_shares);

        IERC20Metadata withdrawableToken = IERC20Metadata(_withdrawableToken);

        if (withdrawableToken != token) {
            if (withdrawableToken == USDC) {
                amount = _swapWBTCtoUSDC(withdrawBaseToken(address(WBTC), amount));
            } else {
                amount = withdrawBaseToken(address(_withdrawableToken), amount);
            }
        }

        require(amount > 0, "!amount");

        withdrawableToken.safeTransfer(msg.sender, amount);
    }

    function withdrawBaseToken(address _withdrawableToken, uint256 _userLpTokensAmount) internal returns (uint256) {
        address self = address(this);
        IERC20Metadata withdrawableToken = IERC20Metadata(_withdrawableToken);

        int128 tokenIndex;
        if (withdrawableToken == RENBTC) {
            tokenIndex = 0;
        } else if (withdrawableToken == WBTC) {
            tokenIndex = 1;
        } else if (withdrawableToken == SBTC) {
            tokenIndex = 2;
        } else {
            revert("!token");
        }

        uint256 initialLpTokenBalance = withdrawableToken.balanceOf(self);
        BASE_POOL.remove_liquidity_one_coin(_userLpTokensAmount, tokenIndex, 0);
        uint256 resultLpTokenBalance = withdrawableToken.balanceOf(self);

        require(resultLpTokenBalance > initialLpTokenBalance, "!base_amount");

        return resultLpTokenBalance - initialLpTokenBalance;
    }

    function _getBtcPrice() internal view returns (uint256) {
        (, int256 price, , , ) = pricerBtcUsd.latestRoundData();
        return uint256(price);
    }

    function _swapUSDCtoWBTC(uint256 _amount) internal returns (uint256) {
        USDC.safeTransferFrom(msg.sender, address(this), _amount);

        uint256 amountOutMinimum = (_amount * 1e28) / _getBtcPrice() / 1e18; //result decimals 8

        USDC.safeApprove(UniswapV3Helper.UNISWAP_V3_ROUTER, 0);
        USDC.safeApprove(UniswapV3Helper.UNISWAP_V3_ROUTER, _amount);

        return UniswapV3Helper.trySwap(address(this), swapsUsdcWbtc, _amount, amountOutMinimum, swapSlippage);
    }

    function _swapWBTCtoUSDC(uint256 _amount) internal returns (uint256) {
        uint256 amountOutMinimum = (_amount * _getBtcPrice()) / 1e10; //result decimals 6

        WBTC.safeApprove(UniswapV3Helper.UNISWAP_V3_ROUTER, 0);
        WBTC.safeApprove(UniswapV3Helper.UNISWAP_V3_ROUTER, _amount);

        return UniswapV3Helper.trySwap(address(this), swapsWbtcUsdc, _amount, amountOutMinimum, swapSlippage);
    }

    function setPricerBtcUsd(address _newPricerBtcUsd) external onlyOwner {
        require(_newPricerBtcUsd != address(0), "!_newPricerBtcUsd");
        pricerBtcUsd = IAggregator(_newPricerBtcUsd);
    }

    function setSwaps(bytes[] memory _newSwapsUsdcWbtc, bytes[] memory _newSwapsWbtcUsdc) external onlyOwner {
        if (_newSwapsUsdcWbtc.length > 0) {
            swapsUsdcWbtc = _newSwapsUsdcWbtc;
        }
        if (_newSwapsWbtcUsdc.length > 0) {
            swapsWbtcUsdc = _newSwapsWbtcUsdc;
        }
    }

    function setSwapSlippage(uint256 _newSwapSlippage) external onlyOwner {
        require(_newSwapSlippage <= UniswapV3Helper.MAX_SLIPPAGE, "!_newSwapSlippage");
        swapSlippage = _newSwapSlippage;
    }
}