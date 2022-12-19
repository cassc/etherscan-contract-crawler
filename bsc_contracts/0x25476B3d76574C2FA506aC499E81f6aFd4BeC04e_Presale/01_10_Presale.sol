pragma solidity 0.8.17;

import "./RabBitcoin.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Presale is Ownable {
    uint256 public coinsPerBNB;

    address public developerWallet;
 
    RabBitcoin public RBTc;

    constructor(address payable _RBTc, address _developerWallet, uint256 _coinsPerBNB) {
        RBTc = RabBitcoin(_RBTc);
        developerWallet = _developerWallet;
        coinsPerBNB = _coinsPerBNB;
    }

    receive() external payable {
        require(msg.value >= 1 ether , "sent less than 1 bnb");
        uint256 bnbBonus;

        if (msg.value >= 4 ether && msg.value < 8 ether) {
            bnbBonus = 0.4 ether;

        } else if (msg.value >= 8 ether && msg.value < 12 ether) {
            bnbBonus = 1 ether;

        } else if (msg.value >= 12 ether) {
            bnbBonus = 2 ether;
        }

        RBTc.transfer(msg.sender, msg.value * coinsPerBNB);
        if (bnbBonus != 0) {
            payable(msg.sender).transfer(bnbBonus);
        }
        payable(developerWallet).transfer(address(this).balance);
    }

    function destroyPresale() onlyOwner external {
        RBTc.burn(RBTc.balanceOf(address(this)));

        selfdestruct(payable(msg.sender));
    }
}