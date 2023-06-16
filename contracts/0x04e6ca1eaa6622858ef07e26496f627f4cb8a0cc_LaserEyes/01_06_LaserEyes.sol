//                                                                          .                         
//                                                                       .JB#BPJ~.                    
//                                                                       ^[email protected]@@@@@&GY!:                
//                           .:~!?JJ?:                                     ~?5B&@@@@@&BY!:            
//                     .~7YPB#&@@@@@@#.                                        :~JP#@@@@@&GJ^         
//                  ^?P&@@@@@@@@@&#B5!                                             .^?5B&@@@@5:       
//               :[email protected]@@@@&#BPJ7~^:.                                                     :!5#@@&?      
//             ^Y&@@@#57~:.                                                                .?#@@P.    
//           ^5&@@#Y~.                                                                       [email protected]@5    
//         ^[email protected]@@#J.                                                            :75GB##BBGG5J!. ~PG.   
//       ^[email protected]@@#J.                                                           :?G#BP5JJYYYYY5PGG~       
//     [email protected]@@G7.                                                            !#P7?PB&[email protected]&&&&#GPJ:       
//    ^[email protected]@G~                ..:^^^^^:.                                     ..^[email protected]@#P:[email protected]@@@@@@@@B~      
//   ^&@G!           :~?YPGBB####&&&&&P                                    [email protected]@@#.  [email protected]@@@@@&[email protected]@~     
//   ^5?         :?PB#BGP5JJ7!~^:..:^~^                                   :[email protected]@@@B    [email protected]@@@@@&:#@&~    
//             7G&B55PGB#&&&@@&#BPJ~                                      [email protected]@@@@@7. :[email protected]@@@@@#:&@@&:   
//             ?Y7 [email protected]@@@@@@@@@@#J:                                  :@@&@@@@@#B&@@@@@@@[email protected]~&Y   
//           [email protected]      [email protected]@@@@@@@@@@@&?                                 [email protected]@[email protected]@@@@@@@@@@@@@7.B7 ..   
//         :J#@@@@@G?:.  [email protected]@@@@@@@@@@@@@P.                               ~!! [email protected]@@@@@@@@@@@@&:^!.      
//        J&@@@[email protected]@@@&#B#@@@@@@@@@@@@@@@@5                               [email protected]#. [email protected]@@@@@@@@@@@J B#       
//       [email protected]@@P!..#@@@@@@@@@@@@@@@@@@@@@@@&:                              [email protected]#. [email protected]@@@@@@@@@@B [email protected]       
//      [email protected]@P^^57 ^&@@@@@@@@@@@@@@@@@@@[email protected]@J                              [email protected]&:  !&@@@@@@@@&~ [email protected]:       
//      [email protected]  [email protected]  ~&@@@@@@@@@@@@@@@@@@:^@@B                               [email protected]?   ^[email protected]@@@@#Y: [email protected]?        
//     ^@B   [email protected]@~  ^#@@@@@@@@@@@@@@@@?  7??.                              ^#@7    ~JYJ~.  [email protected]         
//     !#~    [email protected]  :[email protected]@@@@@@@@@@@@&7  .PGY                                .Y&G?^.       J&?          
//            :#@P.   [email protected]@@@@@@@@@G^   [email protected]@5                                  :?G&&BY7~:7J:.           
//             :[email protected]#!    ^?5GBBGY7^    !&@B.                                     .!5B&@@@@PG#~         
//               ?#@G~             [email protected]@B:                                          .^~!!??7:         
//                [email protected]~.        [email protected]@@5.                                                             
//                   :?PB#PJ!^:~JP?^7J^                                                               
//                   [email protected]@@@@@&#GY^                                                                  
//                   .JBBGP5?7~:.                                                                     
//                                                                                                    
//                                                                                                    
//                                                                 .!.                                
//                                                       ^J7~^^:^!?J!                                 
//                                                        .^~!!!!~:                                   
//                                                                                                    
//                                                                                                    
//                             ✧・ﾟ:𝓁𝒶𝓈𝑒𝓇𝓈 are coming out of my eyes:・ﾟ✧                                     
//                                            $LASEREYES
//                                  https://bitcoinmiladys.com/token
//                                  Smart Contract by @shrimpyuk :^)
//
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LaserEyes is Ownable, ERC20 {
    bool isDeployed = false;                        //If the contract is deployed
    address public liqudityPoolSwapPair;            //Address of our initial Liquidity Pool


    uint256 public constant SUPPLY_CAP = 10_000_000_000 * 1 ether; //10,000,000,000 supply cap

    //Important Wallets
    address constant teamWallet = 0x532ee831bb3C2Bbe6F60f4Fd523F912699152905;
    address constant marketingWallet = 0x9A0F96122249C72bDE40A68325bDd20Cd962ac4D;
    address constant cexWallet = 0x86E5Ad1cC2e3E4f580C30C61551068B8061B8DD0;
    address constant developerWallet = 0xff955eFf3d270D44B39D228F7ECdfe41aD5760B3;

    // Supply Distribution:
    // 62.5%   Contributors Allocation
    uint constant contributorsAllocation = ((SUPPLY_CAP / 1000)*625); //62.5%
    // 10%     Holders Allocation
    uint constant holdersAllocation = ((SUPPLY_CAP / 1000)*100); //10%
    // 12.5%   Liquidity Pool Allocation
    uint constant liquidityAllocation = ((SUPPLY_CAP / 1000)*125); //12.5%
    // 7.5%    CEX Allocation
    uint constant cexAllocation = ((SUPPLY_CAP / 1000)*75); //7.5%
    // 5%      Marketing Allocation
    uint constant marketingAllocation = ((SUPPLY_CAP / 1000)*50); //5%
    // 2.3%    Team Allocation
    uint constant teamAllocation = ((SUPPLY_CAP / 1000)*23); //2.3%
    // 0.2%    Developer Allocation
    uint constant developerAllocation = ((SUPPLY_CAP / 1000)*2); //0.2%

    constructor() ERC20("Laser Eyes", "LASEREYES") {
        //Mint the Contributor + Holder + Liquidity + Team Allocation to Team Wallet.
        //This is to allow the team to distribute the tokens to the correct places.
        _mint(teamWallet, contributorsAllocation+holdersAllocation+liquidityAllocation+teamAllocation);

        //Mint the Marketing Allocation to the Marketing Wallet.
        _mint(marketingWallet, marketingAllocation);
    
        //Mint the CEX Allocation to the CEX Wallet.
        _mint(cexWallet, cexAllocation);

        //Mint the Developer's Fee to the Developer's Wallet
        _mint(developerWallet, developerAllocation);

        isDeployed = true;

        //Transfer Ownership to the Team. This is to be later renounced.
        _transferOwnership(teamWallet);
    }

    /// @notice Set them tokens on fire
    /// @param value How many tokens to burn
    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }

    /// @notice Set Liquidity Pool to Enable Trading
    /// @param _tokenSwapPair Address of the Token Swap Pair e.g. Uniswap
    function setLiquidityPool(address _tokenSwapPair) external onlyOwner {
        liqudityPoolSwapPair = _tokenSwapPair;
    }

    //Enforce Ruleset
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) override internal virtual {
        // Exclude Pre-Liqudity Trading (Aside from Owner Wallet and WenTokens to allow Airdrop)
        if (liqudityPoolSwapPair == address(0) && isDeployed) {
                require(from == owner() || to == owner() || to == 0x2c952eE289BbDB3aEbA329a4c41AE4C836bcc231 || from == 0x2c952eE289BbDB3aEbA329a4c41AE4C836bcc231, "Trading has not yet started");
            return;
        }
    }
}