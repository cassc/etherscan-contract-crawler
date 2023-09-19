/*
Insider Trading Bot ($INS)

 .----------------.  .-----------------. .----------------.  .----------------.  .----------------.  .----------------.  .----------------. 
| .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. |
| |     _____    | || | ____  _____  | || |    _______   | || |     _____    | || |  ________    | || |  _________   | || |  _______     | |
| |    |_   _|   | || ||_   \|_   _| | || |   /  ___  |  | || |    |_   _|   | || | |_   ___ `.  | || | |_   ___  |  | || | |_   __ \    | |
| |      | |     | || |  |   \ | |   | || |  |  (__ \_|  | || |      | |     | || |   | |   `. \ | || |   | |_  \_|  | || |   | |__) |   | |
| |      | |     | || |  | |\ \| |   | || |   '.___`-.   | || |      | |     | || |   | |    | | | || |   |  _|  _   | || |   |  __ /    | |
| |     _| |_    | || | _| |_\   |_  | || |  |`\____) |  | || |     _| |_    | || |  _| |___.' / | || |  _| |___/ |  | || |  _| |  \ \_  | |
| |    |_____|   | || ||_____|\____| | || |  |_______.'  | || |    |_____|   | || | |________.'  | || | |_________|  | || | |____| |___| | |
| |              | || |              | || |              | || |              | || |              | || |              | || |              | |
| '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' |
 '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------' 
 .----------------.  .----------------.  .----------------.  .----------------.  .----------------.  .-----------------. .----------------. 
| .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. |
| |  _________   | || |  _______     | || |      __      | || |  ________    | || |     _____    | || | ____  _____  | || |    ______    | |
| | |  _   _  |  | || | |_   __ \    | || |     /  \     | || | |_   ___ `.  | || |    |_   _|   | || ||_   \|_   _| | || |  .' ___  |   | |
| | |_/ | | \_|  | || |   | |__) |   | || |    / /\ \    | || |   | |   `. \ | || |      | |     | || |  |   \ | |   | || | / .'   \_|   | |
| |     | |      | || |   |  __ /    | || |   / ____ \   | || |   | |    | | | || |      | |     | || |  | |\ \| |   | || | | |    ____  | |
| |    _| |_     | || |  _| |  \ \_  | || | _/ /    \ \_ | || |  _| |___.' / | || |     _| |_    | || | _| |_\   |_  | || | \ `.___]  _| | |
| |   |_____|    | || | |____| |___| | || ||____|  |____|| || | |________.'  | || |    |_____|   | || ||_____|\____| | || |  `._____.'   | |
| |              | || |              | || |              | || |              | || |              | || |              | || |              | |
| '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' |
 '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------' 
 .----------------.  .----------------.  .----------------.                                                                                 
| .--------------. || .--------------. || .--------------. |                                                                                
| |   ______     | || |     ____     | || |  _________   | |                                                                                
| |  |_   _ \    | || |   .'    `.   | || | |  _   _  |  | |                                                                                
| |    | |_) |   | || |  /  .--.  \  | || | |_/ | | \_|  | |                                                                                
| |    |  __'.   | || |  | |    | |  | || |     | |      | |                                                                                
| |   _| |__) |  | || |  \  `--'  /  | || |    _| |_     | |                                                                                
| |  |_______/   | || |   `.____.'   | || |   |_____|    | |                                                                                
| |              | || |              | || |              | |                                                                                
| '--------------' || '--------------' || '--------------' |                                                                                
 '----------------'  '----------------'  '----------------'                                                                                 


Unveil Exclusive Insights And Maximize Opportunities, INS provides users a unique platform that empowers users with exclusive insights and profitable opportunities. 
Step into a world where transparency merges with profitability, and verified actions drive informed decisions. 
INS redefines the landscape of trading, offering a unique blend of verified wallet ownership, transaction insights, and premium access for enhanced value.

INS's tokenomics
-NO TAX
To promote the fair trade and ownership

-90% Liquidity
Ensuring seamless transactions and sustained liquidity for a thriving ecosystem.

-5% Partnership Synergy
Forge strategic alliances to expand visibility and utility, amplifying growth.

-5% Continuous Development
Fuel ongoing enhancements, security measures, and user experience.

Insider Trading Bot: Reveal Insights, Maximize Potential

Follow us below! 
https://insidertradingbot.com
https://t.me/InsiderTradingBotPortal
https://twitter.com/InsiderTradiBot
https://insidertradingbot.com/wp-content/uploads/2023/08/whitepaper-3.pdf-3.pdf
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract InsiderTradingBot is ERC20 {
    constructor() ERC20("Insider Trading Bot", "INS") {
        _mint(msg.sender, 1_000_000_000 * 10**18);
    }
}