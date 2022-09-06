// ____ _  _ ___  ___ _   _
// |___ |\/| |__]  |   \_/
// |___ |  | |     |    |

// All signs suggest a universe that could and plausibly did arise from a deeper nothing
// — Lawrence M. Krauss

// Empty website https://empty.finance
// Twitter: https://twitter.com/emptyfinance
// Telegram: https://t.me/emptinesschat

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function createPair(address tokenA, address tokenB)
    external
    returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract EMPTY is ERC20, Ownable {
    using SafeMath for uint256;

    // They were the first believers
    // They are the legends of the EMPTY{UNIVERSE}

    address [] public legends = [
        0x099Ec0d7E419A89162780320f047C00fca867b74,
        0x0d2e3C4117AbdeB3BBD1F1feeFed1755B22C650A,
        0x15284E820a145A23EF18a70AE0CE71c1a4B71061,
        0x198E18EcFdA347c6cdaa440E22b2ff89eaA2cB6f,
        0x1d0D7BD1eF5DFddE86c8B145cDf948Ad8F0E9961,
        0x21895643A3aC93305119A9383E5300e6D253aAe6,
        0x3A8A7c790E307BBE7872e3dDF63627611dC5A028,
        0x3B474Ff1c78474731Db2790CD2c84F5B282134C9,
        0x40d015D66e14D24b3acB0923eC5845fC1e377da8,
        0x4f62c7A202a5e52B81a8BdBC1C67956830717f99,
        0x5364cca9204Fa6c8e3B1Dc7413246656A091B1a3,
        0x54B72a146Fb342d4A4a927d4b96A6f338bfB9415,
        0x56786fC3e0D6AA413B37cE25A9E58e5e993bb236,
        0x6908Cc437c8BEA5c19A81e487A1528635EC2b197,
        0x6E37E554BCb1db002Dfcc45d6272b86d58C7932b,
        0x70cbfbbfF66B4Ee208B2975b21b12cCa968E1B2b,
        0x739BFD1EE9507AC69dcc57160d03d586FD611937,
        0x7F049056383D8B67d48D7b754676e5Dc7b10a92e,
        0x86bEe7eB6a5a20274B00A2ce43B85bA07Bf27ee0,
        0x9130E5EaC5c209594072DD222C1591eF22F7b7DF,
        0x979c388e134b711f1c3Ac1F29DE610b4bA30586D,
        0x9B228B4F71B3Bc7e4b478251f218060D7B70Dc25,
        0xA129d24923F2aa1C3aB28024625607adD5A293Dc,
        0xa1BfeD37D33BEcd523772CBC6eB99052f0f81a81,
        0xA3B9465Dc7aE35F578aE6E23b36Cb77d60AF1A10,
        0xC64a7a3C01296b3A37B8d8aAa31246021175b5e0,
        0xCC4FE0bC29CA11185712FE3c28A937D5cA0362EB,
        0xD17e05022bC516F66047aEF23002b7B09554d884,
        0xdBe36381d9F5Bc33A8E8bF5164122664cFB6621d,
        0xdD9f24EfC84D93deeF3c8745c837ab63E80Abd27,
        0xDdd722b850d7526000d0a9220348c9aBB0F462f6,
        0xdec08cb92a506B88411da9Ba290f3694BE223c26,
        0xe7c5DE03987777a18FF279A5e8d8A91Dd91db688,
        0xe95E113CE69D078511813a338cc9D5569f676191,
        0xEd2C0F6C08f3C123ff299B11682Cea4778AfC848,
        0xF5264Fa41Ad3b420972E71d5A23B3fA5569498C7
    ];

    uint256 [] private legendsSnapshot = [
        5192477958807120000000,
        15930482667868500000000,
        5000000000000000000000,
        28249262925422200000000,
        8408417447831030000000,
        7248289436567360000000,
        1700000000000000000000,
        10777827721106500000000,
        536634639842064000000,
        5300420800315430000000,
        16109227627710200000000,
        40000000000528600000000,
        74445335644776100,
        4583179699839150000000,
        904504998952059000000,
        4000000000000000000000,
        20715063960531200000000,
        14189844626463500000000,
        7745291969122090000000,
        24617622366050700000000,
        22000000000000000000000,
        27999000000000000000000,
        10753000000000000000000,
        25870783882183500000000,
        31029528560911200000000,
        846141055074095000000,
        6203486490600870000000,
        20674000000000000000000,
        726695352966925000,
        7140215692794080000,
        32287798315245600000000,
        28455166228131200000000,
        688201649662236000,
        15000498235041000000000,
        9276354879339470000000,
        4297267179046500000000
    ];

    IUniswapV2Router02 public immutable uniswapV2Router;

    address public immutable uniswapV2Pair;
    address public devWallet;
    address public USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    mapping(address => bool) private _isExcludedFromFees;

    uint256 public swapTokensAtAmount;
    uint256 public buyDevFee;
    uint256 public buyLiquidityFee;
    uint256 public buyTotalFees;
    uint256 public sellDevFee;
    uint256 public sellLiquidityFee;
    uint256 public sellTotalFees;

    bool public legendsMinted = false;
    bool public swapEnabled = true;
    bool private swapping;

    constructor() ERC20("EMPTY.FINANCE", "EMPTY") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), USDC);

        uint256 totalSupply = 1000000e18;

        swapTokensAtAmount = (totalSupply * 5) / 10000; // 0.05%

        buyDevFee = 3;
        buyLiquidityFee = 3;
        buyTotalFees = buyDevFee + buyLiquidityFee;
        sellDevFee = 3;
        sellLiquidityFee = 3;
        sellTotalFees = sellDevFee + sellLiquidityFee;

        devWallet = owner();

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        excludeFromFees(address(0x0000), true);

        // Calculating legends balances to be minted
        require(legends.length == legendsSnapshot.length, 'Legends: error');
        uint256 legendsBalances = 0;
        for (uint i = 0; i < legends.length; i++) {
            legendsBalances += legendsSnapshot[i];
        }

        _mint(msg.sender, totalSupply.sub(legendsBalances));
    }

    // Mint to previous holders, only once
    function mintToLegends() external onlyOwner {
        require(legendsMinted == false, 'Legends: already minted');

        for (uint i = 0; i < legends.length; i++) {
            _mint(legends[i], legendsSnapshot[i]);
        }

        legendsMinted = true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (canSwap && swapEnabled && !swapping && to == uniswapV2Pair && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            swapping = true;
            swapBack();
            swapping = false;
        }

        bool takeFee = !swapping;
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        uint256 tokensForLiquidity = 0;

        if (takeFee) {
            // sell
            if (to == uniswapV2Pair && sellTotalFees > 0) {
                fees = amount.mul(sellTotalFees).div(100);
                tokensForLiquidity = (fees * sellLiquidityFee) / sellTotalFees;
            }
            // buy
            else if (from == uniswapV2Pair && buyTotalFees > 0) {
                fees = amount.mul(buyTotalFees).div(100);
                tokensForLiquidity = (fees * buyLiquidityFee) / buyTotalFees;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
            if (tokensForLiquidity > 0) {
                super._transfer(address(this), uniswapV2Pair, tokensForLiquidity);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function swapTokensForUSDC(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = USDC;

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            devWallet,
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance == 0) {
            return;
        }

        swapTokensForUSDC(contractBalance);
    }

    receive() external payable {}

    function updateDevWallet(address newWallet) external onlyOwner {
        devWallet = newWallet;
    }

    function updateSwapEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
    }

    function updateBuyFee(uint256 _devFee, uint256 _liquidityFee) external onlyOwner {
        buyDevFee = _devFee;
        buyLiquidityFee = _liquidityFee;
        buyTotalFees = buyDevFee + buyLiquidityFee;
        require(buyTotalFees <= 10, "Fees > 10%");
    }

    function updateSellFees(uint256 _devFee, uint256 _liquidityFee) external onlyOwner {
        sellDevFee = _devFee;
        sellLiquidityFee = _liquidityFee;
        sellTotalFees = sellDevFee + sellLiquidityFee;
        require(sellTotalFees <= 10, "Must keep fees at 10% or less");
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner returns (bool) {
        require(newAmount >= (totalSupply() * 1) / 100000, "< 0.001% total supply.");
        require(newAmount <= (totalSupply() * 5) / 1000, "> 0.5% total supply.");
        swapTokensAtAmount = newAmount;
        return true;
    }
}