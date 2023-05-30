// SPDX-License-Identifier: MIT   
//                                                                                                                                                                                                                                                           
//           ..                                                                                        
//          !57       ^.                                                                                 
//      .:?PB&BPP5J: :75!77?777~^:.        .....     :: .                   .   .....:^~~!!!~:..        
//      ~J###&PYPBY ^5B#GPB##BP5J!.   .~?5G##BPY:    ^?Y5      .::..      ..7. .7PBB#&#&&@&&&G7^.       
//      :J#GG#!  :.  J#BJ7~~^^^^::: ^?P&@##BBP5G?    .5G#!.:^7YG##5^      ?5G^  .!7?Y#&?^^::::.         
//       ^Y&&#^     .JBB:          :P#B&Y7!!~^:.      ?&#GYG#@@#Y~.       [email protected]@!      ^#@!                 
//        .?#@5:    ^P#&P555YYJ~:  ^GP#J              [email protected]&&#G5?^.          [email protected]&!      ~#@7             
//         .5&&#7   7GGG5YYYJJ?!.  :GG#J.             J#&BPGJ^.           J&&~      [email protected]#^                
//        7#B!#&7  7PGP:           ?#&Y~.           .?B#GGB&&BJ~.        ~B&^     .G#B^            
//     ^^::Y&#J#&P..JB&P:           .5B&5J~          .?#@P.!5GPBBP?.      J&#.     ~GBB.          
//    :YB#B&@#P57: :G&G~             :?G&#B5YY5JJ?.  :P&#5   :^JG&#P^     P#P      !PG5         
//     .^^^5B!      75Y:              .^7GBB&###G?^  :JP7^      :!^??.   ^JJ^      ^?!.         
//         :~:      .:                   .^!?J?YY~.    !.       
//
//                            $FCKIT ~ https://twitter.com/FCKITCOIN
//                             Contract developed by @shrimpyuk :^)                         


pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FCKIT is Ownable, ERC20 {
    bool isDeployed = false;                        //If the contract is deployed
    bool public isLimited;                  //Enabled to deter Token Hoarding + MEV Sniping during our launch. Limits slowly raised then dropped to ensure smooth and fair release.
    uint256 public maxHoldAmount;           //Maximum Balance to be able to trade in Limited Trading Phase. Used to deter Token Hoarding + MEV Sniping during our launch.
    uint256 public minHoldAmount;           //Minimum Balance to be able to trade in Limited Trading Phase. Used to deter Token Hoarding + MEV Sniping during our launch.
    address public liqudityPoolSwapPair;    //Address of our initial Liquidity Pool

    mapping(address => bool) public hasFuckedAround; //Blacklisted Address Map. Fuck Around => Find Out
    
    uint256 public constant SUPPLY_CAP = 42_690_000_000 * 1 ether; //42,690,000,000 supply cap

    //Important Wallets
    address constant cexReserveWallet = 0xCdA13fE7AEa02AD5740E3Fd48913A24b83976C60; 
    address constant managementWallet = 0x5346ffCc2291A9d555E8B860A263B94338E043be;

    // Supply Distribution:
    // 10%      Team Allocation
    uint constant teamAllocation = ((SUPPLY_CAP / 1000)*100); //10%
    // 22.5%    Liquidity Pool
    uint constant liquidityPoolAllocation = ((SUPPLY_CAP / 1000)*225); //22.5%
    // 10%      Developments Reserve
    // Used for CEX Liquidity + Emergency Use
    uint constant cexReserveAllocation = ((SUPPLY_CAP / 1000)*250); //25%
    // 0.2%     Airdrop (Freebies)
    uint constant airdropAllocation = ((SUPPLY_CAP / 1000)*2); //0.2%
    // 42.3%    Presale Allocation
    uint constant presaleAllocation = ((SUPPLY_CAP / 1000)*423); //42.3%

    // Wallets for locking funds
    address[4] public lockedWallets;
    uint256[4] public walletAllocations;

    uint256 public LOCK_DURATION = 14 days;

    // Team Wallets
    address constant teamWallet1 = 0xF3bb77973f7F1de2fC99fCAE3AF66b56e5df5114;
    address constant teamWallet2 = 0xc4AAeE79cC0a7c5d4EC3F4f8279f31Ba15055e6B;
    address constant teamWallet3 = 0x3a1c2AA33BC5522D59cF729e701C31cc4B8F0037;
    address constant teamWallet4 = 0xff955eFf3d270D44B39D228F7ECdfe41aD5760B3;

    constructor() ERC20("FCKIT", "FCKIT") {
        // Mint tokens to gnosis safes
        _mint(cexReserveWallet, cexReserveAllocation);
        _mint(managementWallet, liquidityPoolAllocation+airdropAllocation+presaleAllocation);

        // Assign Team Allocations
        walletAllocations[0] = ((teamAllocation / 100) * 50); // 50% of team allocation for wallet 1
        walletAllocations[1] = ((teamAllocation / 100) * 20); // 20% of team allocation for wallet 2
        walletAllocations[2] = ((teamAllocation / 100) * 20); // 20% of team allocation for wallet 3
        walletAllocations[3] = ((teamAllocation / 100) * 10); // 10% of team allocation for wallet 4

        // Lock Wallets
        lockedWallets[0] = teamWallet1;
        lockedWallets[1] = teamWallet2;
        lockedWallets[2] = teamWallet3;
        lockedWallets[3] = teamWallet4;

        // Mint 10% of Team's Allocation
        for (uint i = 0; i < walletAllocations.length; i++) {
            uint256 allocation = walletAllocations[i];
            uint256 initial = allocation / 10;
            walletAllocations[i] = allocation - initial;
            _mint(lockedWallets[i], initial);
        }
        
        // Apply 14 Day Lock to remainder 90% of Team's Allocation
        setLockDuration(block.timestamp + (14 days));

        isDeployed = true;
        _transferOwnership(managementWallet);
    }

    // Sets the lock duration of funds. Can only be called internally and once, via the initializer.
    function setLockDuration(uint256 duration) internal {
        require(!isDeployed, "Lock duration can only be set before deployment");
        LOCK_DURATION = duration;
    }

    // @notice Withdraw Team's Allocation after 14 Day Lock
    function withdrawLockedFunds() external {
        require(block.timestamp >= LOCK_DURATION, "Funds are still locked");
        for (uint i = 0; i < lockedWallets.length; i++) {
            address wallet = lockedWallets[i];
            uint256 allocation = walletAllocations[i];
            if (allocation > 0) {
                walletAllocations[i] = 0;
                _mint(wallet, allocation);
            }
        }
    }

    /// @notice Blacklist/Unblacklist a Wallet
    /// @param _address The Address of the wallet to modify
    /// @param _hasFuckedAround If they are blacklisted or not
    function foundOut(address _address, bool _hasFuckedAround) external onlyOwner {
        hasFuckedAround[_address] = _hasFuckedAround;
    }

    /// @notice Set temporary trading rules to ensure a smooth launch detering token hoarding + MEV sniping.
    /// @param _isLimited If the temporary trading rules should apply
    /// @param _tokenSwapPair Address of the Token Swap Pair e.g. Uniswap
    /// @param _maxHoldAmount Maximum amount of tokens that can be held to interact with the Liquduity Pool during the limited phase
    /// @param _minHoldAmount Minimum amount of tokens that can be held to interact with the Liquduity Pool during the limited phase
    function setRules(bool _isLimited, address _tokenSwapPair, uint256 _maxHoldAmount, uint256 _minHoldAmount) external onlyOwner {
        isLimited = _isLimited;
        liqudityPoolSwapPair = _tokenSwapPair;
        maxHoldAmount = _maxHoldAmount;
        minHoldAmount = _minHoldAmount;
    }

    /// @notice Set them tokens on fire
    /// @param value How many tokens to burn
    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }

     //Enforce Ruleset
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) override internal virtual {
        // Blacklist Ruleset
        require(!hasFuckedAround[to] && !hasFuckedAround[from], "Fucked Around & Found Out");

        // Exclude Pre-Liqudity Trading (Aside from Owner Wallet)
        if (liqudityPoolSwapPair == address(0) && isDeployed) {
            require(from == owner() || to == owner(), "Trading has not yet started");
            return;
        }

        //Extra rules to keep a fair and smooth release :)
        if (isLimited && from == liqudityPoolSwapPair) {
            require(super.balanceOf(to) + amount <= maxHoldAmount && super.balanceOf(to) + amount >= minHoldAmount, "Forbidden");
        }
    }
}