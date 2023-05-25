pragma solidity 0.8.19;

    /*
    $$\      $$\                                   $$$$$$$$\ $$\ 
    $$$\    $$$ |                                  $$  _____|\__|
    $$$$\  $$$$ | $$$$$$\  $$$$$$\$$$$\   $$$$$$\  $$ |      $$\ 
    $$\$$\$$ $$ |$$  __$$\ $$  _$$  _$$\ $$  __$$\ $$$$$\    $$ |
    $$ \$$$  $$ |$$$$$$$$ |$$ / $$ / $$ |$$$$$$$$ |$$  __|   $$ |
    $$ |\$  /$$ |$$   ____|$$ | $$ | $$ |$$   ____|$$ |      $$ |
    $$ | \_/ $$ |\$$$$$$$\ $$ | $$ | $$ |\$$$$$$$\ $$ |      $$ |
    \__|     \__| \_______|\__| \__| \__| \_______|\__|      \__|
                                                              */
                                                              /*
    This contract was never owned, and never will be.
    The liquidity is entirely owned by the community.
    The liquidity lock is entirely maintained by the community.
    There is community. You are the community. 
    We, together, are MemeFi.

    https://memefi.wtf
    https://twitter.com/MemeFi__

    There are three stages to this contract.

        1. Liquidity Generation Event
        2. Trading
        3. Unlocking

    It is up to us to determine the best way to transition between these stages.
    It is up to us to determine the duration of the liquidity generation event.
    MemeFi your life. MemeFi your world. MemeFi your future.

    We start with a liquidity generation event. It accepts all ETH above 0.03.
    If the amount is 0.1 ETH or grater, it increases the duration of the LGE by 300 blocks. 
    If it stalls for 300 blocks, we can list it.
    At that point the LGE is over and we begin trading.
    
        * 100% of the circulating supply and 100% of the ETH raised in the LGE will be added to a Uniswap V2 Listing.
        * Selling the token incurs a 1% transaction fee that's given to LP providers to help combat IL.
        * During trading, liquidity can be locked in a rolling ~30 day period (198250 blocks).
        * Once LP Tokens are unlocked, providers are able to remove/sell freely.
        * At any point during the unlock period the 30 day rolling lock is able to be reactivated.

    During trading, the way to lock liquidity is to send an amount of MEFI greater than or equal to the reset amount.
    The first payment to lock liquidity will be 13374.20697 MEFI.

        * 80% of the payment is burned.
        * 20% is sent to the governor.

    If/when the liquidity unlocks, you simply send 0 ETH to the contract to receive your proportional LP Tokens.
    Governor can be renounced at any time to a community controlled contract or even the dEaD address.
                                                  \*/

import "lib/solmate/src/tokens/ERC20.sol";
import "lib/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "lib/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "lib/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

error ContributionTooLow();
error ListingDelayNotElapsed();
error UnlockDelayNotElapsed();
error CanOnlyUnlock();
error LGEEnded();
error NotGovernor();
error ZeroContribution();
error NotZeroAddress();
error LGEHasNotBegun();
error NotDuringLGE();

contract MemeFi is ERC20 {
    address public uniswapV2Pair;
    address payable public governor;

    bool public lgeActive = true;

    uint256 public totalContributions;
    uint256 public listingLPBalance;
    uint256 public lastLockContribution;

    mapping(address => uint256) public contributions;

    uint256 public immutable unlockBlockDelay = 198250;
    uint256 public immutable fee_divisor = 100;
    uint256 public immutable MAXIMUM_CIRCULATING_SUPPLY = 1_337_420_697 ether;
    uint256 public immutable BURN_PERCENTAGE = 80;
    uint256 public immutable blockListingDelay = 300;

    event Contribution(address indexed sender, uint256 amount);
    event Listing(
        address lister,
        uint256 totalContributions,
        uint256 listingLPBalance
    );
    event Unlock(address indexed sender, uint256 amount);
    event LiquidityLockReset(
        address indexed sender,
        uint new_amount,
        uint old_amount,
        uint treasury
    );

    receive() external payable {
        if (!lgeActive) {
            if (contributions[msg.sender] == 0) revert ZeroContribution();
            if (block.number < lastLockContribution + unlockBlockDelay)
                revert UnlockDelayNotElapsed();

            uint256 amount = (listingLPBalance * contributions[msg.sender]) /
                totalContributions;

            contributions[msg.sender] = 0;
            ERC20(uniswapV2Pair).transfer(msg.sender, amount);

            emit Unlock(msg.sender, amount);
        } else {
            if (msg.value < 0.03 ether) revert ContributionTooLow();
            if (msg.value >= 0.1 ether) lastLockContribution = block.number;
            contributions[msg.sender] += msg.value;
            emit Contribution(msg.sender, msg.value);
        }
    }

    constructor() ERC20("MemeFi", "MEFI", 18) {
        lastLockContribution = block.number;
        uniswapV2Pair = IUniswapV2Factory(
            0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f
        ).createPair(address(this), 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

        _mint(address(this), MAXIMUM_CIRCULATING_SUPPLY);
        governor = payable(msg.sender);
    }

    function list() external {
        if (lastLockContribution == 0) revert LGEHasNotBegun();
        if (block.number < lastLockContribution + blockListingDelay)
            revert ListingDelayNotElapsed();
        totalContributions = address(this).balance;
        ERC20(address(this)).approve(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D,
            MAXIMUM_CIRCULATING_SUPPLY
        );
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D)
            .addLiquidityETH{value: address(this).balance}(
            address(this),
            MAXIMUM_CIRCULATING_SUPPLY,
            0,
            0,
            address(this),
            block.timestamp
        );
        listingLPBalance = IUniswapV2Pair(uniswapV2Pair).balanceOf(
            address(this)
        );
        lgeActive = false;
        emit Listing(msg.sender, totalContributions, listingLPBalance);
    }

    function recover(address token) external {
        if (lgeActive) revert NotDuringLGE();
        if (token == uniswapV2Pair) revert CanOnlyUnlock();
        if (token == address(0)) {
            governor.transfer(address(this).balance);
        } else {
            ERC20(token).transfer(
                governor,
                ERC20(token).balanceOf(address(this))
            );
        }
    }

    function renounce(address _new_governor) external {
        if (msg.sender != governor) revert NotGovernor();
        if (_new_governor == address(0)) revert NotZeroAddress();
        governor = payable(_new_governor);
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        if (to == address(this) && amount >= requiredResetAmount()) {
            uint256 treasury = (amount * (100 - BURN_PERCENTAGE)) / 100;
            lastLockContribution = block.number;
            _burn(msg.sender, amount - treasury);
            emit LiquidityLockReset(
                msg.sender,
                requiredResetAmount(),
                amount,
                treasury
            );
            return super.transfer(governor, treasury);
        }
        return super.transfer(to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        uint256 fee = 0;
        if (to == uniswapV2Pair && !lgeActive) {
            fee = amount / fee_divisor;
            super.transferFrom(from, uniswapV2Pair, fee);
            IUniswapV2Pair(uniswapV2Pair).sync();
        }
        super.transferFrom(from, to, amount - fee);
        return true;
    }

    function requiredResetAmount() public view returns (uint256) {
        return totalSupply() / 10 ** 5;
    }
}