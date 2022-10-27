// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./TrashBase.sol";

contract TrashRefund is Ownable {

    TrashBase public trashNFT;
    uint256 public lastId;
    uint256 public refundValue; // 330000000000000 for tx fees, 2934000000000000 per paid NFT
    address payable public devWallet;

    event Refund(uint256 start, uint256 end);
    event Skip(uint256 id);
    event SetId(uint256 newId);
    event SetValue(uint256 newValue);

    constructor(address _token, uint256 initialId, uint256 initialValue) {
        trashNFT = TrashBase(_token);
        devWallet = payable(msg.sender);
        lastId = initialId;
        refundValue = initialValue;
        emit SetId(lastId);
        emit SetValue(initialValue);
    }

    receive() external payable {
    }

    function setDevWallet(address payable _dev) external onlyOwner {
        devWallet = _dev;
    }

    function withdraw() external onlyOwner {
        payable(devWallet).transfer(payable(address(this)).balance);
    }

    function setId(uint256 newid) external onlyOwner {
        lastId = newid;
        emit SetId(newid);
    }

    function setValue(uint256 value) external onlyOwner {
        refundValue = value;
        emit SetValue(value);
    }

    // Refund NFT buyer
    function refund(uint256 amount) external onlyOwner {
        uint256 end = lastId + amount;
        uint256 i = lastId;
        for (i; i <= end; i++) {
            try trashNFT.ownerOf(lastId) returns (address ownerAddr){
                payable(ownerAddr).transfer(refundValue);
            } catch {
                emit Skip(lastId);
                continue;
            }
        }
        emit Refund(lastId, end);
        lastId = i;
    }
}