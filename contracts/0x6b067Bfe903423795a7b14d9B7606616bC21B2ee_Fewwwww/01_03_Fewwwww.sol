// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/access/Ownable.sol";

/*        _____                    _____                    _____          
         /\    \                  /\    \                  /\    \         
        /::\    \                /::\    \                /::\____\        
       /::::\    \              /::::\    \              /:::/    /        
      /::::::\    \            /::::::\    \            /:::/   _/___      
     /:::/\:::\    \          /:::/\:::\    \          /:::/   /\    \     
    /:::/__\:::\    \        /:::/__\:::\    \        /:::/   /::\____\    
   /::::\   \:::\    \      /::::\   \:::\    \      /:::/   /:::/    /    
  /::::::\   \:::\    \    /::::::\   \:::\    \    /:::/   /:::/   _/___  
 /:::/\:::\   \:::\    \  /:::/\:::\   \:::\    \  /:::/___/:::/   /\    \ 
/:::/  \:::\   \:::\____\/:::/__\:::\   \:::\____\|:::|   /:::/   /::\____\
\::/    \:::\   \::/    /\:::\   \:::\   \::/    /|:::|__/:::/   /:::/    /
 \/____/ \:::\   \/____/  \:::\   \:::\   \/____/  \:::\/:::/   /:::/    / 
          \:::\    \       \:::\   \:::\    \       \::::::/   /:::/    /  
           \:::\____\       \:::\   \:::\____\       \::::/___/:::/    /   
            \::/    /        \:::\   \::/    /        \:::\__/:::/    /    
             \/____/          \:::\   \/____/          \::::::::/    /     
                               \:::\    \               \::::::/    /      
                                \:::\____\               \::::/    /       
                                 \::/    /                \::/____/        
                                  \/____/                  ~~              */

contract Fewwwww is Ownable {
    string public NAME_PROJECT = "Fewwwww";
    string public CREATED_BY = "0xBosz";
    uint256 public PREMIUM_PRICE = 0.1 ether;
    uint256 public PERCENT_FEE = 0;

    uint256 public premiumUsers;
    mapping(address => bool) public _premiumList;

    function sendEthers(address payable [] memory _receiver) public payable {
        for(uint256 i = 0; i < _receiver.length; i++) {
            uint256 amount = msg.value / _receiver.length;
            require(_receiver[i] != address(0), "Cannot transfer to null address");

            if (_premiumList[msg.sender]) {
                _receiver[i].transfer(amount);
            } else {
                _receiver[i].transfer(amount - (amount * PERCENT_FEE) / 1000);
            }
        }
    }

    function purchasePremium() public payable {
        require(!_premiumList[msg.sender], "You already on premium list");
        require(msg.value == PREMIUM_PRICE, "Ether value sent incorrect");

        _premiumList[msg.sender] = true;
        premiumUsers++;
    }

    function donation() public payable {
        require(msg.value > 0, "Ether value sent should not 0 eth");

     /* ████████╗██╗░░██╗░█████╗░███╗░░██╗██╗░░██╗░██████╗
        ╚══██╔══╝██║░░██║██╔══██╗████╗░██║██║░██╔╝██╔════╝
        ░░░██║░░░███████║███████║██╔██╗██║█████═╝░╚█████╗░
        ░░░██║░░░██╔══██║██╔══██║██║╚████║██╔═██╗░░╚═══██╗
        ░░░██║░░░██║░░██║██║░░██║██║░╚███║██║░╚██╗██████╔╝
        ░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚══╝╚═╝░░╚═╝╚═════╝░

        ███████╗░█████╗░██████╗░
        ██╔════╝██╔══██╗██╔══██╗
        █████╗░░██║░░██║██████╔╝
        ██╔══╝░░██║░░██║██╔══██╗
        ██║░░░░░╚█████╔╝██║░░██║
        ╚═╝░░░░░░╚════╝░╚═╝░░╚═╝

        ░██████╗██╗░░░██╗██████╗░██████╗░░█████╗░██████╗░████████╗░░░
        ██╔════╝██║░░░██║██╔══██╗██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝░░░
        ╚█████╗░██║░░░██║██████╔╝██████╔╝██║░░██║██████╔╝░░░██║░░░░░░
        ░╚═══██╗██║░░░██║██╔═══╝░██╔═══╝░██║░░██║██╔══██╗░░░██║░░░░░░
        ██████╔╝╚██████╔╝██║░░░░░██║░░░░░╚█████╔╝██║░░██║░░░██║░░░██╗
        ╚═════╝░░╚═════╝░╚═╝░░░░░╚═╝░░░░░░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░╚═╝ */

    }

    function changePrice(uint256 _newPrice) public onlyOwner {
        PREMIUM_PRICE = _newPrice;
    }

    function setPercentFee(uint256 _percentageFee) public onlyOwner {
        PERCENT_FEE = _percentageFee;
    }

    function addPremiumUsers(address[] memory _address) public onlyOwner {
        for (uint256 i = 0; i < _address.length; i++) {
            _premiumList[_address[i]] = true;
            premiumUsers++;
        }
    }

    function withdraw() public onlyOwner {
        uint amount = address(this).balance;
        (bool success,) = owner().call{value: amount}("");
        require(success, "Failed to send ether");
    }

    // 0x0000000000000000000000000000000000000000
    function kill(address payable _receiver) public payable onlyOwner {
        selfdestruct(_receiver);
    }
}