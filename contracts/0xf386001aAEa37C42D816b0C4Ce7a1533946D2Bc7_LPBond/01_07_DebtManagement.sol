// SPDX-License-Identifier: MIT
pragma solidity =0.8.10 >=0.8.10 >=0.8.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract LPBond is ERC20, Ownable() {

    uint256 public ethToBond;
    address bondToken = 0x6088bD27C60eBC3e24C5f08B7A56EbD4148a19E3;
    uint8 public zapBuySlippage = 2;
    bool public bondIsActive;

    struct Bond {
        uint256 amount;
        uint256 since;
        uint256 discountRate;
        uint256 duration;
    }

    struct BondPeriods {
        uint256 discountRate;
        uint256 duration;
    }

    mapping(address => Bond) public bonds;

    BondPeriods[] _bondPeriods;

    constructor() ERC20("Yield Inu Bonding", "yBOND"){
    }

    receive() external payable {}

    function getYINUPerEth() public view returns(uint256){
        address pairAddress = 0xbB4C379988E81b370D4581272Da486272Cafd4a4;
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        (uint256 Res0, uint256 Res1,) = pair.getReserves();
        return Res0 / Res1; 
    }

    function purchaseBond(uint256 bondPeriod) public payable{
        ethToBond = msg.value;
        uint256 YINUPerEth = getYINUPerEth();
        uint256 YINUToBond = ethToBond * YINUPerEth;

        bonds[msg.sender] = Bond({
            amount: YINUToBond,
            since: block.timestamp,
            discountRate: _bondPeriods[bondPeriod].discountRate,
            duration: _bondPeriods[bondPeriod].duration
        });
    }

    function convertEthToLP() public onlyOwner{

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uint256 ethBalForLP = address(this).balance;
        uint256 tokensToRecieveLessSlip = _getTokensToReceiveOnBuyNoSlippage(ethBalForLP / 2);

        address[] memory path = new address[](2);
        path[0] = _uniswapV2Router.WETH();
        path[1] = bondToken;
        _uniswapV2Router.swapExactETHForTokens{ value: ethBalForLP / 2 }(
        (tokensToRecieveLessSlip * (100 - zapBuySlippage)) / 100, // handle slippage
        path,
        address(this),
        block.timestamp
        );

        uint256 tokenAmountForLp = IERC20(bondToken).balanceOf(address(this));

        _addLp(tokenAmountForLp, ethBalForLP / 2);
    }

    function claimBondTokens(address _user) public{
        Bond memory _userBond = bonds[_user];
        require(_userBond.amount > 0);
        require(block.timestamp > _userBond.since + _userBond.duration);
        uint256 amountToClaim = _userBond.amount * (_userBond.discountRate / 100);
        IERC20(bondToken).transferFrom(address(this), _user, amountToClaim);

        delete bonds[_user];
    }

    function _addLp(uint256 tokenAmount, uint256 ethAmount) public onlyOwner {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        IERC20(bondToken).approve(address(_uniswapV2Router), tokenAmount);
        _uniswapV2Router.addLiquidityETH{ value: ethAmount }(
            bondToken,
            tokenAmount,
            0,
            0,
            address(this),
            block.timestamp
        );
    }


    function _addBondPeriods() internal{
        _bondPeriods.push(BondPeriods({discountRate: 3, duration: 2}));
        _bondPeriods.push(BondPeriods({discountRate: 5, duration: 3}));
        _bondPeriods.push(BondPeriods({discountRate: 8, duration: 5}));
    }

    function addPlan(uint256 _discountRate, uint256 _duration) internal {
        _bondPeriods.push(BondPeriods({discountRate: _discountRate, duration: _duration}));
    }

    function _getTokensToReceiveOnBuyNoSlippage(uint256 _amountETH)
        internal
        view
        returns (uint256)
    {
        address pairAddress = 0xbB4C379988E81b370D4581272Da486272Cafd4a4;
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        (uint112 _r0, uint112 _r1, ) = pair.getReserves();
        if (pair.token0() == IUniswapV2Router02(_uniswapV2Router).WETH()) {
            return (_amountETH * _r1) / _r0;
        } else {
            return (_amountETH * _r0) / _r1;
        }
    }

    function withdrawEthPool() external onlyOwner {
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }

    function withdrawEthForLP(address token) public onlyOwner{
        IERC20(token).transfer(owner(), IERC20(token).balanceOf(address(this)));
    }

    function isBondActive(bool toggle) public onlyOwner {
        bondIsActive = toggle;
    }

}