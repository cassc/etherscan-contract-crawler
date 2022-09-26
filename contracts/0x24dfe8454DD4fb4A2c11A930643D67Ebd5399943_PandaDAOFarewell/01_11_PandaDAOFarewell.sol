/*
 **                                                                                                                                                              
 **                                                                   dddddddd                                                                                   
 **  PPPPPPPPPPPPPPPPP                                                d::::::d                  DDDDDDDDDDDDD                  AAA                 OOOOOOOOO     
 **  P::::::::::::::::P                                               d::::::d                  D::::::::::::DDD              A:::A              OO:::::::::OO   
 **  P::::::PPPPPP:::::P                                              d::::::d                  D:::::::::::::::DD           A:::::A           OO:::::::::::::OO 
 **  PP:::::P     P:::::P                                             d:::::d                   DDD:::::DDDDD:::::D         A:::::::A         O:::::::OOO:::::::O
 **    P::::P     P:::::Paaaaaaaaaaaaa  nnnn  nnnnnnnn        ddddddddd:::::d   aaaaaaaaaaaaa     D:::::D    D:::::D       A:::::::::A        O::::::O   O::::::O
 **    P::::P     P:::::Pa::::::::::::a n:::nn::::::::nn    dd::::::::::::::d   a::::::::::::a    D:::::D     D:::::D     A:::::A:::::A       O:::::O     O:::::O
 **    P::::PPPPPP:::::P aaaaaaaaa:::::an::::::::::::::nn  d::::::::::::::::d   aaaaaaaaa:::::a   D:::::D     D:::::D    A:::::A A:::::A      O:::::O     O:::::O
 **    P:::::::::::::PP           a::::ann:::::::::::::::nd:::::::ddddd:::::d            a::::a   D:::::D     D:::::D   A:::::A   A:::::A     O:::::O     O:::::O
 **    P::::PPPPPPPPP      aaaaaaa:::::a  n:::::nnnn:::::nd::::::d    d:::::d     aaaaaaa:::::a   D:::::D     D:::::D  A:::::A     A:::::A    O:::::O     O:::::O
 **    P::::P            aa::::::::::::a  n::::n    n::::nd:::::d     d:::::d   aa::::::::::::a   D:::::D     D:::::D A:::::AAAAAAAAA:::::A   O:::::O     O:::::O
 **    P::::P           a::::aaaa::::::a  n::::n    n::::nd:::::d     d:::::d  a::::aaaa::::::a   D:::::D     D:::::DA:::::::::::::::::::::A  O:::::O     O:::::O
 **    P::::P          a::::a    a:::::a  n::::n    n::::nd:::::d     d:::::d a::::a    a:::::a   D:::::D    D:::::DA:::::AAAAAAAAAAAAA:::::A O::::::O   O::::::O
 **  PP::::::PP        a::::a    a:::::a  n::::n    n::::nd::::::ddddd::::::dda::::a    a:::::a DDD:::::DDDDD:::::DA:::::A             A:::::AO:::::::OOO:::::::O
 **  P::::::::P        a:::::aaaa::::::a  n::::n    n::::n d:::::::::::::::::da:::::aaaa::::::a D:::::::::::::::DDA:::::A               A:::::AOO:::::::::::::OO 
 **  P::::::::P         a::::::::::aa:::a n::::n    n::::n  d:::::::::ddd::::d a::::::::::aa:::aD::::::::::::DDD A:::::A                 A:::::A OO:::::::::OO   
 **  PPPPPPPPPP          aaaaaaaaaa  aaaa nnnnnn    nnnnnn   ddddddddd   ddddd  aaaaaaaaaa  aaaaDDDDDDDDDDDDD   AAAAAAA                   AAAAAAA  OOOOOOOOO     
 **  
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Operations.sol";
import "./ITerminalV1_1.sol";


contract PandaDAOFarewell is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public pandaToken;
    ITerminalV1_1  public terminalv1_1;
    bool public openRefund = true;
    uint256[] private operationsRedeem = [Operations.Redeem];
    mapping(address => uint256) public refundMap;
    uint256 public constant PANDADAO_PROJECT_ID = 409;
    
    
    event Redeem(address indexed recipient, uint256 tokenAmount, uint256 receiveEther);
    event RefundOpenChanged(bool open);
    event WithdrawERC20(address recipient, address tokenAddress, uint256 tokenAmount);
    event WithdrawEther(address recipient, uint256 amount);


    modifier refundOpenning() {
        require(openRefund, "PandaDAO: refund close.");
        _;
    }

    modifier assertNotContract(
        address addr_
    ) {
        require (addr_ == tx.origin, "Smart contract caller not allowed");
        _;
    }



    /**
     * @dev Constructor.
     */
    constructor(
        address pandaToken_,
        address terminalv1_1_
    )
    {
        pandaToken = IERC20(pandaToken_);
        terminalv1_1 = ITerminalV1_1(terminalv1_1_);
    }


    /**
     * @dev redeem $PANDA  tokens.
     * @param amount The amount of the $PANDA.
     */
    function redeem(uint256 amount) external assertNotContract(msg.sender) nonReentrant refundOpenning {
        require(amount > 0, "PandaDAO: Invalid amount required.");
        require(pandaToken.balanceOf(msg.sender) >= amount, "PandaDAO: you do not have enough PandaToken.");

        uint256 etherBalance = address(this).balance;
        uint256 etherAmount = amount * etherBalance / pandaToken.totalSupply();
        require(etherBalance >= etherAmount, "PandaDAO: Refund Contract dont have enough ether!");

        refundMap[msg.sender] = refundMap[msg.sender] + amount;

        terminalv1_1.redeem(msg.sender, PANDADAO_PROJECT_ID, amount, 0, payable(msg.sender), false);

        
        (bool success,) = msg.sender.call{value:etherAmount}("");
        require(success, "redeem ether fail!");
        emit Redeem(msg.sender, amount, etherAmount);
    }


    function setRefundOpen(bool open_) external onlyOwner {
        openRefund = open_;
        emit RefundOpenChanged(open_);
    }


    /**
     * @dev withdrawERC20  tokens.
     * @param tokenAddress  token
     * @param tokenAmount amount
     */
    function withdrawERC20(
        address tokenAddress, 
        uint256 tokenAmount
    ) external onlyOwner 
    {
        require(tokenAddress != address(0), "Zero Token address!");
        IERC20(tokenAddress).transfer(msg.sender, tokenAmount);

        emit WithdrawERC20(msg.sender, tokenAddress, tokenAmount);
    }

    

    /**
     * @dev withdraw Ether.
     * @param amount amount
     */
    function withdrawEther(uint256 amount) external onlyOwner {
        (bool success,) = msg.sender.call{value:amount}("");
        require(success, "withdrawEther fail!");
        emit WithdrawEther(msg.sender, amount);
    }

    fallback () external payable {}

    receive () external payable {}

}