/*
     ____.  _____ _____________________    _____  .___ 
    |    | /  _  \\______   \__    ___/   /  _  \ |   |
    |    |/  /_\  \|       _/ |    |     /  /_\  \|   |
/\__|    /    |    \    |   \ |    |    /    |    \   |
\________\____|__  /____|_  / |____| /\ \____|__  /___|
                 \/       \/         \/         \/     


Transform words into stunning art 

Website: https://jart.ai/
Twitter: https://twitter.com/jart_ai
Telegram: https://t.me/jart_ai

Total supply: 420,690,000 tokens
Tax: 4% (1% - LP, 1% - operational costs, 2% marketing)
*/

pragma solidity 0.8.17;

import {ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IUniswapV2Router02} from "./external/interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "./external/interfaces/IUniswapV2Factory.sol";
import {JartAiConfig} from "./JartAiConfig.sol";

contract JartAi is ERC20 {
    using SafeERC20 for IERC20;

    uint256 constant TOTAL_SUPPLY = 420_690_000 * 1e6;

    JartAiConfig public immutable CONFIG;
    IUniswapV2Router02 public immutable UNISWAP_ROUTER;
    address public immutable MAIN_PAIR;

    bool feesDisabled;
    uint256 amountForMarketing;

    constructor(address router) ERC20("JART AI", "JARTAI") {
        UNISWAP_ROUTER = IUniswapV2Router02(router);
        MAIN_PAIR = IUniswapV2Factory(UNISWAP_ROUTER.factory()).createPair(
            address(this),
            UNISWAP_ROUTER.WETH()
        );

        CONFIG = new JartAiConfig();
        CONFIG.setMinAmounts(TOTAL_SUPPLY / 100000, TOTAL_SUPPLY / 10000);
        CONFIG.setMarketingWallet(msg.sender);
        CONFIG.setOwner(msg.sender);

        _mint(msg.sender, TOTAL_SUPPLY);
    }

    function claimDonations(IERC20 token) external {
        address wallet = CONFIG.marketingWallet();

        if (address(token) == address(this)) {
            token.safeTransfer(wallet, amountForMarketing);
            amountForMarketing = 0;
        } else {
            token.safeTransfer(wallet, token.balanceOf(address(this)));
        }
        payable(wallet).transfer(address(this).balance);
    }

    function marketingFee() external view returns (uint256) {
        return CONFIG.marketingFee();
    }

    function liquidityFee() external view returns (uint256) {
        return CONFIG.liquidityFee();
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        // simple transfer
        if (
            (from != MAIN_PAIR && to != MAIN_PAIR) ||
            feesDisabled ||
            CONFIG.isExcludedFromSwapFee(from) ||
            CONFIG.isExcludedFromSwapFee(to)
        ) {
            super._transfer(from, to, amount);
            return;
        }

        if (to == MAIN_PAIR) {
            uint256 amountForLiquidity = balanceOf(address(this)) -
                amountForMarketing;

            address marketingWallet = CONFIG.marketingWallet();
            uint256 minAmountForLiquidity = CONFIG.minAmountForLiquidity();
            if (amountForLiquidity > minAmountForLiquidity) {
                _addLiquidityOneSide(minAmountForLiquidity, marketingWallet);
            }

            uint256 minAmountForMarketing = CONFIG.minAmountForMarketing();
            if (amountForMarketing > minAmountForMarketing) {
                _swapForEth(minAmountForMarketing, marketingWallet);
                amountForMarketing -= minAmountForMarketing;
            }
        }

        uint256 feeDenominator = CONFIG.FEE_DENOMINATOR();
        uint256 marketingAmount = (amount * CONFIG.marketingFee()) /
            feeDenominator;
        uint256 liquidityAmount = (amount * CONFIG.liquidityFee()) /
            feeDenominator;
        amountForMarketing += marketingAmount;
        super._transfer(from, address(this), marketingAmount + liquidityAmount);
        super._transfer(from, to, amount - marketingAmount - liquidityAmount);
    }

    function _addLiquidityOneSide(uint256 amountForLiquidity, address recipient)
        private
        disableFees
    {
        uint256 ethBefore = address(this).balance;

        // swap half for eth
        uint256 amountForEth = amountForLiquidity / 2;
        _swapForEth(amountForEth, address(this));

        // add liquidity
        _approve(
            address(this),
            address(UNISWAP_ROUTER),
            amountForLiquidity - amountForEth
        );
        UNISWAP_ROUTER.addLiquidityETH{
            value: address(this).balance - ethBefore
        }(
            address(this),
            amountForLiquidity - amountForEth,
            0,
            0,
            recipient,
            block.timestamp
        );
    }

    function _swapForEth(uint256 amount, address recipient)
        private
        disableFees
    {
        _approve(address(this), address(UNISWAP_ROUTER), amount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = UNISWAP_ROUTER.WETH();

        UNISWAP_ROUTER.swapExactTokensForETH(
            amount,
            0,
            path,
            recipient,
            block.timestamp
        );
    }

    modifier disableFees() {
        bool feesDisabledBefore = feesDisabled;

        feesDisabled = true;
        _;
        feesDisabled = feesDisabledBefore;
    }

    receive() external payable {}
}