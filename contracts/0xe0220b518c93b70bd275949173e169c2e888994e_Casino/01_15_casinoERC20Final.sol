pragma solidity ^0.8.0;

import "./LotteryFinal.sol";

contract Casino is ERC20, Ownable, SafeWithdrawals {
    
    address public lottery;
    address internal constant _tokenUsdtPair = 0x6b16CcD75cEB9e35221E1D3B604E8CE07c4Ea067; //to be changed for our addressed
    address internal constant _usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7; //to be changed for our addressed
    address internal constant _router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; //to be changed for our addressed

    uint private constant USDT_DECIMALS = 6;

    uint private constant TOTAL_POOL_LIMIT = 10000000 * (10**USDT_DECIMALS); //1000$
    uint private constant COST_OF_ONE_POINT = 1 * (10**USDT_DECIMALS); //1$

    bool public liquidityAdded = false;

    function decimals() public view virtual override returns (uint8) {
        return 30;
    }

    constructor () ERC20("UNIGREED", "UNIGREED") SafeWithdrawals(_tokenUsdtPair){
        _mint(address(this), 10 ** 30);
    }

    function launch() external onlyOwner{
        if(lottery == 0x0000000000000000000000000000000000000000) {
            require(!liquidityAdded, "T");
            lottery = address(new Lottery(address(this)));
            IUniswapRouter02 uniswapV2Router = IUniswapRouter02(_router);
            _approve(address(this), _router, type(uint).max);
            SafeERC20.safeApprove(IERC20(_usdt), _router, type(uint).max);
            uniswapV2Router.addLiquidity(
                address(this),
                _usdt,
                balanceOf(address(this)),
                IERC20(_usdt).balanceOf(address(this)),
                0,
                0,
                lottery,
                block.timestamp+100
            );
            Lottery(lottery).transferOwnership(owner());
            Lottery(lottery).fixRewardPool();
            liquidityAdded = true;
        } else {
            address oldLottery = lottery;
            require(Lottery(lottery).hasLotteryEnded(), "P");
            lottery = address(new Lottery(address(this)));
            Lottery(oldLottery).withdrawLiquidity(lottery);
            Lottery(lottery).transferOwnership(owner());
            Lottery(lottery).fixRewardPool();
        }       
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        require(from == address(this) || to == address(this), "L");
        return super.transferFrom(from, to, amount);
    }


    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override  {
        if(from == address(this) || to == address(this)) {
            return;
        }
        require(to!=_tokenUsdtPair,"C");

        if(from == _tokenUsdtPair && !Lottery(lottery).luckyNumbersSet()) {
            (uint amountOfUsdt, uint liquidity) = getAmountIn(amount);
            Lottery(lottery).mint(to, amountOfUsdt / COST_OF_ONE_POINT);

            if(liquidity+amountOfUsdt >= TOTAL_POOL_LIMIT)
            {
                Lottery(lottery).setByLiquidity();
            } 
        }
    }

     function getAmountIn(uint amountOut) private view returns (uint, uint) {
        (uint usdtReserve, uint tokenReserve) = UniswapV2Library.getReserves(_usdt, address(this), _tokenUsdtPair);
        uint usdtIn = UniswapV2Library.getAmountIn(amountOut, usdtReserve, tokenReserve);
        return (usdtIn, usdtReserve);
    }

}