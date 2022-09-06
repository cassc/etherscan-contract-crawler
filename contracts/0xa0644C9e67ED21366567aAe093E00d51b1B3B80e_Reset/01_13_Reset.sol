// SPDX-License-Identifier: NOLICENSE
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


/* Reset.News:
* 100 Billion Supply
*
*INITIAL TAX: (updatable)
*Fees on tx: 5% 
*   divided as:
*   0.5% burnt
*   4.5% split as:
*       Liquidity: ~0.5% (11/100)
*       Marketing (in eth) : ~ 4% (89/100) 
*
*   Antisnipe: 
Buys in first 2 blocks since add of liquidity will get taxed 99%
*   
*Total Fee % for buy and sell can change independently (transfer between EOAs treated as sell)
*MaxTx on sell: 1% of supply
*Maxwallet: 1% of supply (updatable)
* 
*/

contract Reset is ERC20Burnable, Ownable {

    struct status {
        bool isExcludedFromFees;
        bool isAutomatedMarketMakerPair;
        bool isExcludedFromMaxTx;
        bool isExcludedFromMaxWallet;
        bool isBot;
    }

    event BlacklistedUser(address botAddress, bool indexed value);

    mapping(address => status) public statuses;

    uint256 public constant blocksToWait = 2;

    address payable public immutable devAddress;
    uint256 public liqAddedBlockNumber;
    uint256 public maxWalletAmount;

    struct swapFeesDistribution {
        uint64 dev_share;
        uint64 liq_share;

    }

    struct Fees {
        uint64 swap_tot;
        uint64 burn_tot;
    }

    
    Fees public buyFees = Fees({
        swap_tot: 45,
        burn_tot: 5
    });

    Fees public sellFees = Fees({
        swap_tot: 45,
        burn_tot: 5
    });

    swapFeesDistribution public swapFees = swapFeesDistribution({dev_share: 89, liq_share: 11});

    address public immutable uniswapV2Pair;
    uint72 private numTokensToSwap; //9 bytes
    uint256 private constant supply = 100 * 10**9 * 10**9; //100B
    uint256 public constant maxTxAmountSell = supply/100; //1B
    IUniswapV2Router02 public UniswapV2Router;
    uint96 public unlocktime;



    constructor(
        IUniswapV2Router02 _UniswapV2Router,
        address payable _devAddress,
        address _ownerAddress
    ) ERC20("Reset.News", "NEWS") {
        devAddress = _devAddress;
        uniswapV2Pair = IUniswapV2Factory(_UniswapV2Router.factory())
            .createPair(address(this), _UniswapV2Router.WETH());
        _approve(
            address(this),
            address(_UniswapV2Router),
            type(uint256).max
        );
        UniswapV2Router = _UniswapV2Router;
        statuses[_ownerAddress].isExcludedFromFees = true;
        statuses[_ownerAddress].isExcludedFromMaxWallet = true;
        statuses[_ownerAddress].isExcludedFromMaxTx = true;

        statuses[address(this)].isExcludedFromFees = true;
        statuses[address(this)].isExcludedFromMaxWallet = true;
        statuses[address(this)].isExcludedFromMaxTx = true;


       statuses[uniswapV2Pair].isExcludedFromMaxWallet = true;
       statuses[uniswapV2Pair].isAutomatedMarketMakerPair = true;

        maxWalletAmount = maxTxAmountSell;
        numTokensToSwap = uint72(supply) / 1000;
        unlocktime = uint96(block.timestamp) + 365 days;
        _mint(_ownerAddress,supply);
        transferOwnership(_ownerAddress);
    }

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function setSwapFeesDistribution(swapFeesDistribution memory _swapFees ) external onlyOwner{
        require(_swapFees.dev_share+_swapFees.liq_share==100,"fees do not add up to 100");

        swapFees=_swapFees;
    }

    function setBuyAndSellFees(Fees memory _buyFees, Fees memory _sellFees ) external onlyOwner{
        buyFees = _buyFees;
        sellFees = _sellFees;
    }

    receive() external payable {}

    function setStatus(address user, status memory _status) external onlyOwner{
        statuses[user]=_status;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {

        if(liqAddedBlockNumber==0 && statuses[to].isAutomatedMarketMakerPair )
        {liqAddedBlockNumber = block.number;
        }

        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!statuses[from].isBot, "ERC20: address blacklisted (bot)");
        require(amount != 0, "Transfer amount must be greater than zero");
        require(amount <= balanceOf(from),"You are trying to transfer more than your balance");
        bool takeFee = !(statuses[from].isExcludedFromFees || statuses[to].isExcludedFromFees);

        if(takeFee)
        {   
            Fees memory appliedRates;

            if(block.number<liqAddedBlockNumber+blocksToWait && (statuses[from].isAutomatedMarketMakerPair!=statuses[to].isAutomatedMarketMakerPair))
                {
                address toBlacklist = statuses[from].isAutomatedMarketMakerPair ? to : from;
                statuses[toBlacklist].isBot = true;
                emit BlacklistedUser(toBlacklist,true);
                appliedRates = Fees({
                    swap_tot: 990,
                    burn_tot: 0
                });
                }
            else
            {
                appliedRates = statuses[from].isAutomatedMarketMakerPair ? buyFees : sellFees;
            }

            if(statuses[to].isAutomatedMarketMakerPair)
            {
                require(statuses[from].isExcludedFromMaxTx || statuses[to].isExcludedFromMaxTx || amount<=maxTxAmountSell, "amount must be <= maxTxAmountSell");
                 if (balanceOf(address(this)) >= numTokensToSwap) {
                    swap(numTokensToSwap);
                }

            }
            uint256 toSwap = (amount * appliedRates.swap_tot) / 1000;
            uint256 toBurn = (amount * appliedRates.burn_tot) / 1000;

            amount-= (toSwap+toBurn);
            require(statuses[to].isExcludedFromMaxWallet || (balanceOf(to)+amount) <= maxWalletAmount, "Recipient cannot hold more than maxWalletAmount");
            super._transfer(from,address(this),toSwap);
            if(toBurn!=0)
            _burn(from,toBurn);
        }

        super._transfer(from,to,amount);
    }

    function swap(uint256 contractTokenBalance) private {
        uint256 denominator = 100 * 2;
        uint256 tokensToAddLiquidityWith = (contractTokenBalance *
            swapFees.liq_share) / denominator;
        uint256 toSwap = contractTokenBalance - tokensToAddLiquidityWith;

        uint256 initialBalance = address(this).balance;

        swapTokensForETH(toSwap);

        uint256 deltaBalance = address(this).balance - initialBalance;
        uint256 ETHToAddLiquidityWith = (deltaBalance * swapFees.liq_share) /
            (denominator - swapFees.liq_share);

        // add liq_share to  Uniswap
        addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith);

        devAddress.transfer(address(this).balance);

    }

    function swapTokensForETH(uint256 tokenAmount) private {
        // generate the Uniswap pair path of token -> wETH
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = UniswapV2Router.WETH();

        // make the swap
        UniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        // add the liq_share
        UniswapV2Router.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }

    function setMaxWalletAmount(uint72 amount) external onlyOwner {
        maxWalletAmount = amount;
    }

    function unlock(IERC20 token) public onlyOwner {
        require(block.timestamp >= unlocktime, "TokenTimelock: current time is before release time");
        require(address(token) != address(this), "TokenTimelock: Can't remove Reset Tokens");

        uint256 amount = token.balanceOf(address(this));
        require(amount > 0, "TokenTimelock: no tokens to release");

        SafeERC20.safeTransfer(token,owner(), amount);
    }

    function setNumTokensSellToSwap(uint72 amount) external onlyOwner
    {
     numTokensToSwap = amount;
    }

    function extendLock(uint96 newLockTime) external onlyOwner{
    require(newLockTime > block.timestamp, "lock must not be expired");
    require(newLockTime > unlocktime, "lock can't be shortened");
    unlocktime = newLockTime;
    }

}