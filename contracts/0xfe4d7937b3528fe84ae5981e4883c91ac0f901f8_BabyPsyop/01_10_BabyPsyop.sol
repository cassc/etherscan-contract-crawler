/* 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&BB##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&BY??YG#&P5PGB#&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@&B&BYJJJ5GGY7?JPG7.::^^~7J5G#&@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@#PJ!~:?PBG5Y?7?5P??JYB5^::...:::^~?5B&@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@BY7^:::.::~?G#GYJ?7?J7???5P55J?~^:::::::~JG&@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@&P!:.::::^7YPP5YJ?777777777777?J5PGGPJ!:.:::.:~JB@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@#Y~..::::7PG5J7777777777777777777777?JYPGGY!:::::.:7G@@@@@@@@@@@@@
@@@@@@@@@@@@&Y^.:::::7GGJ77777777777JY5YYY55J77777777?JY5BP7:::::::7B@@@@@@@@@@@
@@@@@@@@@@@G~.:::::^5#Y77777777777YPJ~.....^?PY7777777?JJJ5BP~:::::.:J&@@@@@@@@@
@@@@@@@@@&J:::::^^~BB777777777777YG^  !JY5J: .P5!777777?JJJJGB7^^::::.~G@@@@@@@@
@@@@@@@@#7.::::^^~GG7777777777777B!  :#GB&@5  ^#?7777777?JJJJP#7^^::::::5@@@@@@@
@@@@@@@#!.::::^^^5#77??JJJJJ?7777GJ   7PBB5^  !B77777????YJJJJP#!^^^:::::5@@@@@@
@@@@@@&!.::::^^^7&J77?GGPPPPGG?77JBJ:       :?BJ777YBGPGGGBPJJJBG^^^^:::::5@@@@@
@@@@@&?.::::^^^^GB??J?JYYYYYYJ7777?5P5?7!!?YP5?7777?YY55PPP5YYY5&7^^^^::::^B@@@@
@@@@@G:::::~?5PPBGGGGGGGGGGGGP55J7777JYYYYJ?77!7JY5PPGGGGGGGGGGGBGP5J!^:::.7&@@@
@@@@&7.:::7BBY?5P5YJ?77!!!77J5PPPPY7777!!!!777YP5PG5Y?7!!!77?JY5PP5?5#5:::::B@@@
@@@@#^::::5&G5JG5:::::::::::::JPG5GP?JYYYYYJ?PP5GGP~::::::::::::~PPY5B#^:::.Y@@@
@@@@G:::::~?G#5B!::::::::::::!!:7G5BGPPPPPPPBGYG77^~:::::::::::::JGP#5!^::::7&@@
@@@@P:::::^^J&PG?::::::::::::7^::G5GGY5PPP55BPP5:~:~:::::::::::::5PG&~^^::::!&@@
@@@@P:::::^^~#BPP:::::::::::::::^B5G#G5Y55PB#P5P::::::::::::::::^GP#G^^^::::7&@@
@@@@B:::::^^^J&GG5~::::::::::::^5P5#PJ~^~!?5GB5BY::::::::::::::~PGB#7^^^:::.?@@@
@@@@&!::::^^^^Y#BGGY?~^^:::^~!JGG5PJ~~~~~~!!!JPPBGJ!^::::::^~?5GB&B7^^^::::.5@@@
@@@@@5.::::^^^^7G&#BBBBGPPGGBBG5YJ?JYJJJ???JJJJYYPGBGGPPPPGGBBB&&5~^^^^::::~#@@@
@@@@@&!::::^^^^^^?GB5YJ5PPP555Y555GP5J?7777?Y5PGP555PPPGGPP55G#P!^^^^^::::.5@@@@
@@@@@@G:::::^^^^^^^?5GPYJJ???777777?JYY5YYYYJJ???????JJJYYPGGY!^^^^^^::::.7&@@@@
@@@@@@@P::::::^^^^^^^~?YPGGP5YYJ???????????????JJJYY5PGGGPY7~^^^^^^^::::.~#@@@@@
@@@@@@@@P^:::::^^^^^^^^^^~!?JY5B###BG5YJJJYY5G#####5J?7!~^^^^^^^^^:::::.~B@@@@@@
@@@@@@@@@B~.:::::^^^^^^^^^^^!YGGB57^.        .^?PBGG5!^^^^^^^^^^^:::::.7#@@@@@@@
@@@@@@@@@@&J:.:::::^^!YY!~?PB5JG7               .?BJ5BG?^7Y?^^::::::.:Y&@@@@@@@@
@@@@@@@@@@@@G!::::::~#BGB##G#PP!                 :?GP#BBB#G&5:.:::::7B@@@@@@@@@@
@@@@@@@@@@@@@@P!:.:YGG7~!J5PP#B                  ^^##PP5J!~JGGJ:.:7G@@@@@@@@@@@@
@@@@@@@@@@@@@@@@G77@5?J?~~!7!5&~                :^?&J~7!~!?J?G#~?G@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@#&G!!JY!~~~?&J              .:^:P#!!~!?YJ!7B&#@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@G?!7Y?!~7BG~.      ....::^:^7#P~~!JY7!?B@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@&#BBGPP5Y5BGY??J77#B#GY7~^^^:^^^^~7YGB#G77J??YGG555PGB##&@@@@@@@@@@@
@@@@@@@@@@@5?!!~~~~~!!!?5GGPPGB5Y?Y5PPPP5555PPP5?JYBGPPGG5?!~~~~~~!!?Y#@@@@@@@@@
@@@@@@@@@@@&#BGPP5YYJJ??777???!!!!!!!!777?777!!!!!!!7???77?JJYY5PPGB#&@@@@@@@@@@

BabyPsyop is a deflationary token that rewards holders with ETH.
$BPSYOP Twitter: https://twitter.com/bpsyopeth
$BPSYOP Telegram: https://t.me/bpsyoptoken
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract BabyPsyop is ERC20, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    address constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO_ADDRESS = address(0);
    address constant MARKETING_ADDRESS = 0x49B8bEbfB16427eE7189E889685f8f7e530f33A3;
    address constant ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    uint256 constant MAGNITUDE = 2 ** 128;

    IUniswapV2Router02 immutable ROUTER;
    address immutable WETH_ADDRESS;
    address immutable PAIR_ADDRESS;

    /**
     * Initializes the contract upon deployment.
     * Mints an initial supply of 100,000,000,000 BPSYOP tokens to the deployer's address.
     * Sets up the Uniswap router and retrieves the WETH address.
     * Creates a Uniswap pair for BPSYOP tokens and WETH.
     */
    constructor() payable ERC20("Baby Psyop", "BPSYOP") {
        _mint(msg.sender, 100_000_000_000 * 1e18);
        ROUTER = IUniswapV2Router02(ROUTER_ADDRESS);
        WETH_ADDRESS = ROUTER.WETH();
        PAIR_ADDRESS = IUniswapV2Factory(ROUTER.factory()).createPair(address(this), WETH_ADDRESS);

        address contractAddress = address(this);
        isExcludedFromTaxes[msg.sender] = true;
        isExcludedFromTaxes[contractAddress] = true;
        isExcludedFromTaxes[MARKETING_ADDRESS] = true;
        isExcludedFromRewards.add(msg.sender);
        isExcludedFromRewards.add(contractAddress);
        isExcludedFromRewards.add(MARKETING_ADDRESS);
        isExcludedFromRewards.add(PAIR_ADDRESS);
        isExcludedFromRewards.add(ROUTER_ADDRESS);
    }

    struct Rewards {
        uint256 lifetimeRewards;
        uint256 lastRewardBalance;
    }

    bool public tradingEnabled;
    mapping(address => bool) isExcludedFromTaxes;
    EnumerableSet.AddressSet isExcludedFromRewards;
    mapping(address => Rewards) public rewards;
    uint256 public lifetimeRewardBalance;
    uint256 public marketingBalance;

    error Blocked();

    /**
     * Hook function called before every token transfer.
     * Overrides the same function from the inherited ERC20 contract.
     * Checks if the transfer amount is zero and if the receiver has a zero balance to update their last reward balance.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        if (amount == 0) {
            revert Blocked();
        }
        if (balanceOf(to) == 0) {
            rewards[to].lastRewardBalance = lifetimeRewardBalance;
        }
    }

    /*
     * Hook function called during token transfers.
     * Overrides the same function from the inherited ERC20 contract.
     * Handles the logic for token transfers, including buy, sell, and regular transfers.
     * Applies a 2% tax to transfers, splits the taxed tokens between lifetime rewards and marketing, and processes rewards for sellers if applicable.
     */
    function _transfer(address from, address to, uint256 amount) internal override {
        bool isBuy = from == PAIR_ADDRESS;
        bool isSell = to == PAIR_ADDRESS;
        bool isTransfer = !isBuy && !isSell;

        if (isExcludedFromTaxes[from] || isExcludedFromTaxes[to]) {
            super._transfer(from, to, amount);
            return;
        }

        if (!tradingEnabled) {
            revert Blocked();
        }

        if (isTransfer) {
            super._transfer(from, to, amount);
            return;
        }
        
        uint256 taxedTokensAmount = (amount * 2) / 100;
        amount -= taxedTokensAmount;
        uint256 split = taxedTokensAmount / 2;
        lifetimeRewardBalance += split;
        marketingBalance += split;
        super._transfer(from, address(this), taxedTokensAmount);

       if (isSell && !isExcludedFromRewards.contains(from)) {
            processRewards(from, balanceOf(from), rewards[from], getAdjustedSupply());
            if (marketingBalance > 0) {
                swapTokensForETH(MARKETING_ADDRESS, marketingBalance);
                marketingBalance = 0;
            }
        }

        super._transfer(from, to, amount);
    }

    /*
     * Calculates and distributes pending rewards to a user based on their balance, eligible rewards, and adjusted supply.
     * Swaps the rewarded tokens for ETH using Uniswap's router.
     */
    function processRewards(address _address, uint256 balance, Rewards storage reward, uint256 adjustedSupply) internal {
        uint256 pendingRewards;
        if (balance != 0) {
            // Calculates the eligible balance by subtracting the user's last recorded reward balance
            // from the current lifetime reward balance (lifetimeRewardBalance - reward.lastRewardBalance).
            uint256 eligibleBalance = lifetimeRewardBalance - reward.lastRewardBalance;
            if (eligibleBalance != 0) {
                // Multiplies the user's token balance by the MAGNITUDE constant (balance * MAGNITUDE).
                uint256 magnifiedBalance = balance * MAGNITUDE;
                // Calculates the percentage of the user's magnified balance relative to the adjusted supply.
                // It divides magnifiedBalance by adjustedSupply, then multiplies by 100 to get a percentage (((magnifiedBalance / adjustedSupply) * 100) / MAGNITUDE).
                uint256 percent = ((magnifiedBalance / adjustedSupply) * 100) / MAGNITUDE;
                // Calculates the pending rewards by multiplying the eligible balance by the calculated percentage (eligibleBalance * percent / 100).
                pendingRewards = (eligibleBalance * percent) / 100;
            }
        }
        // Updates the user's lastRewardBalance to the current lifetimeRewardBalance.
        reward.lastRewardBalance = lifetimeRewardBalance;
        // Retrieves the current balance of the contract.
        uint256 contractBalance = balanceOf(address(this));
        // Checks if the pending rewards exceed the contract's balance.
        if (pendingRewards > contractBalance) {
            // If the pending rewards exceed the contract's balance, sets the pending rewards to be equal to the contract's balance.
            pendingRewards = contractBalance;
        }
        // If there are no pending rewards (pendingRewards == 0), the function returns early.
        if (pendingRewards == 0) {
            return;
        }
        // Adds the pending rewards to the user's lifetime rewards.
        reward.lifetimeRewards += pendingRewards;
        // Calls swapTokensForETH to swap the rewarded tokens for ETH.
        swapTokensForETH(_address, pendingRewards);
    }

    /**
     * ProcessRewards Review:
     * The function uses safe integer arithmetic since it performs multiplication and division on uint256 variables, which do not suffer from overflow or underflow issues.
     * Division is performed in a safe manner. The divisor (100 and MAGNITUDE) is not zero, so no division-by-zero errors should occur.
     * The logic flow appears to handle all possible cases and returns early if there are no pending rewards.
     */

    /*
     * Swaps the specified amount of BPSYOP tokens for ETH using Uniswap's router.
     * Transfers the obtained ETH to the specified recipient address.
     */
    function swapTokensForETH(address to, uint256 tokenAmount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH_ADDRESS;
        _approve(address(this), ROUTER_ADDRESS, tokenAmount);
        ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, to, block.timestamp);
    }

    /*
     * Allows the contract owner to perform a batch transfer of tokens to multiple addresses.
     * Requires the caller to be the contract owner (onlyOwner modifier).
     * Accepts an array of recipient addresses and an array of corresponding token amounts to transfer.
     */
    function drop(address[] calldata addresses, uint256[] calldata amounts) external onlyOwner {
        uint256 length = addresses.length;
        if (length != amounts.length) {
            revert Blocked();
        }
        for (uint256 i = 0; i < length; i++) {
            super.transfer(addresses[i], amounts[i] * 1 ether);
        }
    }

    /*
     * Calculates the adjusted token supply by subtracting the balance of excluded addresses from the total supply.
     * Excluded addresses are those added to the isExcludedFromRewards set.
     */
    function getAdjustedSupply() internal view returns (uint256) {
        uint256 length = isExcludedFromRewards.length();
        uint256 excludedBalance;
        for (uint256 i = 0; i < length; i++) {
            excludedBalance += balanceOf(isExcludedFromRewards.at(i));
        }
        return totalSupply() - excludedBalance;
    }

    /*
     * Allows users to claim their pending rewards if they are not excluded from rewards.
     * Calls the internal processRewards function to calculate and distribute rewards based on the user's balance, eligible rewards, and adjusted supply.
     */
    function claim() external {
        if (isExcludedFromRewards.contains(msg.sender)) {
            revert Blocked();
        }
        processRewards(msg.sender, balanceOf(msg.sender), rewards[msg.sender], getAdjustedSupply());
    }

    function release() external onlyOwner {
        tradingEnabled = true;
    }
}