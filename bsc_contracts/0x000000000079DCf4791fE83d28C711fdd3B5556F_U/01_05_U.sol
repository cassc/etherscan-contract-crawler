/*

                                   %%      % %                                  
                          % %     %  #*   %  %      &%                          
                           %                         %                          
                   % %%                                   %& &                  
                    %                                       %                   
             %%        %%%%%%%%%%               &&&&&&&&&&        %             
              %        %%%%%%%%%%               &&&&&&&&&&       %              
                       %%%%%%%%%%               &&&&&&&&&&                      
                       %%%%%%%%%%               &&&&&&&&&&           %%         
          %%           %%%%%%%%%%               &&&&&&&&&&         % %%         
            ###########%%%%%%%%%%###############%%%%%%%%%%###########           
       #########****###%@@@@%%%*,,,####%%%%###%#%%%%%%....###.#..#########      
       ################%%%%%%%%%%###############%%%%%%%%%%################      
       ############(//*%%%*#**%%##(//(###/#**##%%((((%%%%################      
       ################%%%%%%%%%%###############%%%%%%%%%%################      
        %%%#%          %%%%%%%%%%,   .,***,.   ,&&&&&&&&&#          %%%%%       
        %%%            #%%%%%%%%%%             &&&&&&&&&&            %%%%       
                        %%%%%%%%%%#           &&&&&&&&&&&                       
              %          %%%%%%%%%%%(       &&&&&&&&&&&&         %%             
            *%            %%%%%%%%%%%%%%&&&&&&&&&&&&&&&         #%%  *          
                           /%%%%%%%%%%%%&&&&&&&&&&&&&                           
                 .%  %        #%%%%%%%%%&&&&&&&&&&         % %                  
                 #%%                  /%&(.                 % %                 
                         %  %                      %                            
                        #%.%      % %      % %      % (%                        
                                 %  %      %  %                

Sou Nakamoto(03/Jan/2009)
The Times 03/Jan/2009 Chancellor on brink of second bailout for banks.

Fed Chair Powell calls for tighter regulation of crypto assets like USDT (15/07/2021)
On July 15, Powell said that it has not yet been decided whether the benefits of central bank digital currencies outweigh the disadvantages. A more direct approach would be to properly regulate stablecoins. The Fed wants Congress to support central bank digital currencies. "Our responsibility is to explore technical and policy issues and make informed recommendations on central bank digital currencies. We are open to the issue of central bank digital currencies."

USDT destroy funds function: https://etherscan.io/token/0xdac17f958d2ee523a2206206994597c13d831ec7#writeContract#F13
This will bring security threats to the entire cryptocurrency ecosystem, as Owner can destroy USDT arbitrarily;

USDT contract is complex and potentially dangerous:
https://etherscan.io/token/0xdac17f958d2ee523a2206206994597c13d831ec7#writeContract
USDT writing function: addBLackList, the contract owner can blacklist any address arbitrarily, so that the address cannot interact with the USDT contract;
USDT writing function: pause, the contract owner can pause the USDT contract arbitrarily, so that nobody can interact with the USDT contract;
USDT writing function: issue, the contract owner can over-issue USDT arbitrarily;

Biden administration expands sanctions against Russia, cutting off U.S. transactions with central bank. (28/Feb/2022)


USDC's blacklist system:
Circle CEO Jeremy Allaire confirmed that USDC does have a blacklist feature that blocks certain addresses if enforced by law. USDC's blacklist policy states that once an address is blacklisted, it cannot receive or transfer USDC anymore. This means that any funds held at the blacklisted addresses will be frozen indefinitely.
Tornado Cash co-founder Roman Semenov revealed that his Github account was also suspended after the sanctions were announced.

We are anonymous,
We support the decentralized Sou Nakamoto belief;
Security is the first element, or even the only element, for the development of stablecoins;
This world should have stablecoins with no owner, no blacklist function, no additional issuance function, and no unlimited restrictive protocol;
And through the cross-chain bridge, everything is connected together with the cost of 0 cross-chain fee;

Total supply: 10000000000000 U
Openly and fairly issued in 10 decentralized contract systems to create a new, fairer and more powerful new economy;
USDT/U: 700000000000U 7%
USDC/U: 700000000000U 7%
GOLD/U: 3000000000000U 30%
(We will use gold as the standard currency to create a fairer and decentralized wbe3 transaction order)
Token/U e-commerce: 2000000000000U 20%
(Supported by real goods and services to create a decentralized e-commerce ecosystem)
STO Enterprise: 1500000000000U 15%
Tech DAO: 600000000000U 6%
Marketing DAO: 300000000000U 3%
ETH2 Staking DAO: 1200000000000U 12%

Advantages: 
No special functions, completely decentralized and DAO community driven;
0x0000000000 leading 0s makes gas fee lower when interacting with the contract;
No contract owners to blacklist users. 

The issuance and operation of U has profound philosophical connotations, and I hope it can become a tool to help the world further realize democracy and freedom.
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract U is ERC20{
    constructor() ERC20("U", "U"){
        _mint(0x03AE3D59415900Df417C300Df9FA55E9d7215708,10000000000000*10**18);
    }
}