// SPDX-License-Identifier: Unlicensed
/*
                                                                                                                                                                 
                                                                                                                                                                 
RRRRRRRRRRRRRRRRR   IIIIIIIIII      CCCCCCCCCCCCCHHHHHHHHH     HHHHHHHHH     PPPPPPPPPPPPPPPPP   EEEEEEEEEEEEEEEEEEEEEEPPPPPPPPPPPPPPPPP   EEEEEEEEEEEEEEEEEEEEEE
R::::::::::::::::R  I::::::::I   CCC::::::::::::CH:::::::H     H:::::::H     P::::::::::::::::P  E::::::::::::::::::::EP::::::::::::::::P  E::::::::::::::::::::E
R::::::RRRRRR:::::R I::::::::I CC:::::::::::::::CH:::::::H     H:::::::H     P::::::PPPPPP:::::P E::::::::::::::::::::EP::::::PPPPPP:::::P E::::::::::::::::::::E
RR:::::R     R:::::RII::::::IIC:::::CCCCCCCC::::CHH::::::H     H::::::HH     PP:::::P     P:::::PEE::::::EEEEEEEEE::::EPP:::::P     P:::::PEE::::::EEEEEEEEE::::E
  R::::R     R:::::R  I::::I C:::::C       CCCCCC  H:::::H     H:::::H         P::::P     P:::::P  E:::::E       EEEEEE  P::::P     P:::::P  E:::::E       EEEEEE
  R::::R     R:::::R  I::::IC:::::C                H:::::H     H:::::H         P::::P     P:::::P  E:::::E               P::::P     P:::::P  E:::::E             
  R::::RRRRRR:::::R   I::::IC:::::C                H::::::HHHHH::::::H         P::::PPPPPP:::::P   E::::::EEEEEEEEEE     P::::PPPPPP:::::P   E::::::EEEEEEEEEE   
  R:::::::::::::RR    I::::IC:::::C                H:::::::::::::::::H         P:::::::::::::PP    E:::::::::::::::E     P:::::::::::::PP    E:::::::::::::::E   
  R::::RRRRRR:::::R   I::::IC:::::C                H:::::::::::::::::H         P::::PPPPPPPPP      E:::::::::::::::E     P::::PPPPPPPPP      E:::::::::::::::E   
  R::::R     R:::::R  I::::IC:::::C                H::::::HHHHH::::::H         P::::P              E::::::EEEEEEEEEE     P::::P              E::::::EEEEEEEEEE   
  R::::R     R:::::R  I::::IC:::::C                H:::::H     H:::::H         P::::P              E:::::E               P::::P              E:::::E             
  R::::R     R:::::R  I::::I C:::::C       CCCCCC  H:::::H     H:::::H         P::::P              E:::::E       EEEEEE  P::::P              E:::::E       EEEEEE
RR:::::R     R:::::RII::::::IIC:::::CCCCCCCC::::CHH::::::H     H::::::HH     PP::::::PP          EE::::::EEEEEEEE:::::EPP::::::PP          EE::::::EEEEEEEE:::::E
R::::::R     R:::::RI::::::::I CC:::::::::::::::CH:::::::H     H:::::::H     P::::::::P          E::::::::::::::::::::EP::::::::P          E::::::::::::::::::::E
R::::::R     R:::::RI::::::::I   CCC::::::::::::CH:::::::H     H:::::::H     P::::::::P          E::::::::::::::::::::EP::::::::P          E::::::::::::::::::::E
RRRRRRRR     RRRRRRRIIIIIIIIII      CCCCCCCCCCCCCHHHHHHHHH     HHHHHHHHH     PPPPPPPPPP          EEEEEEEEEEEEEEEEEEEEEEPPPPPPPPPP          EEEEEEEEEEEEEEEEEEEEEE
                                                                                                                                                                 
Web: https://richpepe.com/
Twitter: https://twitter.com/RichPepeCoin
Telegram: https://t.me/RichPepeCoin

*/                                                                                                                                                                                                                                                                           
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract RichPepeDeployer is ERC20 {


    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }


}