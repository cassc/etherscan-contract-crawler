// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
        
contract BosoTokyoPreSale is Ownable {
    using SafeMath for uint256;

    //Config
    uint256 public price = 0.4 ether;
    uint256 public totalInventory = 3_000;

    mapping(address => bool) public whitelisted;
    mapping(address => uint256) public numPaidByAddress;
    uint256 public maxPerAddress = 3;
    uint256 public numWhitelisted;
    uint256 public numPaid;
    address public beneficiary;
    bool public paused = true;

    event Purchase(address applicant, uint256 number);

    modifier whenNotPaused{
        require(!paused, "BotsoTokyo: Sale is not open.");
        _;
    }

    constructor (address _beneficiary){
        beneficiary = _beneficiary;
    }

    function purchase() external payable whenNotPaused {
        require(numPaid < totalInventory, "BosoTokyo: Already sold out.");
        require(whitelisted[msg.sender], "BosoTokyo: Only whitelisted addresses can enter the sale.");
        require(numPaidByAddress[msg.sender] < maxPerAddress, "BosoTokyo: Already reached the limit for purchase.");

        uint256 cost = price;
        require(msg.value >= cost, "BosoTokyo: Not enough value.");
        (bool success, ) = payable(beneficiary).call{value: cost}("");
        require(success, "BosoTokyo: unable to send value, recipient may have reverted");

        numPaidByAddress[msg.sender] = numPaidByAddress[msg.sender].add(1);
        numPaid = numPaid.add(1);

        emit Purchase(msg.sender, 1);

        if (msg.value > cost) {
            uint256 refund = msg.value - cost;
            (bool refundSuccess, ) = payable(msg.sender).call{value: refund}("");
            require(refundSuccess, "BosoTokyo: unable to send value, recipient may have reverted");
        }
    }

    function addToWhitelist(address[] calldata _wlist) external onlyOwner{
        for(uint256 i=0; i<_wlist.length; i++){
            numWhitelisted = whitelisted[_wlist[i]] ? numWhitelisted : numWhitelisted.add(1);
            whitelisted[_wlist[i]] = true;
        }
    }

    function revokeFromWhitelist(address[] calldata _wlist) external onlyOwner{
        for(uint256 i=0; i<_wlist.length; i++){
            numWhitelisted = whitelisted[_wlist[i]] ? numWhitelisted.sub(1) : numWhitelisted;
            whitelisted[_wlist[i]] = false;
        }
    }

    function setPause(bool _paused) external onlyOwner{
        paused = _paused;
    }

    function setPrice(uint256 _price) external onlyOwner {
        require(_price > 0, "Price must be > 0.");
        price = _price;
    }

    function emergencyWithdraw() external onlyOwner {
        (bool success, ) = payable(beneficiary).call{value:(address(this).balance)}("");
        require(success, "BosoTokyo: unable to send value, recipient may have reverted");
    }
 
}