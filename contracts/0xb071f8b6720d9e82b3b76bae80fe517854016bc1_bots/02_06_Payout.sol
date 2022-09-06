//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;
import '@openzeppelin/contracts/access/Ownable.sol';

contract Payout is Ownable {
    uint256 public totalWeight;
    bool entered;

    modifier nonReentrant() {
        require(!entered);
        entered = true;
        _;
        entered = false;
    }

    mapping(address => uint256) public weight;
    address payable[] public recipients;

    constructor() {
        addRecipient(
            payable(0xa5c8622C6569383c318F750F343a5e40E3Ea26EB),
            6000
        );
        addRecipient(
            payable(0x134cA981eC91fAb7481c7ea8933A917BE86Db64b),
            1000
        );
        addRecipient(
            payable(0x87900Da3fa50c9F5E64B4820183037e34A8C2AfF),
            1000
        );
        addRecipient(
            payable(0x7886802747d02ce929C631B25eEd6D5d04F41E75),
            1000
        );                
        addRecipient(
            payable(0x5926502f96f05c6b28Bb9DFFCf4f4Cf86A5Edae8),
            500
        );
        addRecipient(
            payable(0x188a9e36a0e559F36E0cc132d7eC3e89cB2397b3),
            500
        );        
    }

    function addRecipient(address payable recipient_, uint256 weight_)
        internal
    {
        if (weight[recipient_] == 0) {
            recipients.push(recipient_);
        }
        totalWeight = totalWeight - weight[recipient_] + weight_;
        weight[recipient_] = weight_;
        return;
    }

    receive() external payable nonReentrant {
        uint256 _amount = address(this).balance;
        for (uint8 i = 0; i < recipients.length; i++) {
            recipients[i].transfer(payout(recipients[i], _amount));
        }
    }

    function payout(address payable recipient_, uint256 amount_)
        public
        view
        returns (uint256)
    {
        return (amount_ * weight[recipient_]) / totalWeight;
    }
}