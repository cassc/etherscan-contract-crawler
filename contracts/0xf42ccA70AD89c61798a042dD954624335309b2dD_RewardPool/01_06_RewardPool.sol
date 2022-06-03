// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./utils/TimeUtil.sol";

interface TheRabbitNFT {
    function ownerOf(uint256 tokenId) external view returns (address);
    function getWinnerTokenIds(uint luckyNum) external view returns (uint[] memory tokenIds);
}


/**
    code    |	 meaning
    104	    |    Time is illegal
 */
contract RewardPool is Ownable {
    using ECDSA for bytes32;

    uint public lastBalance;
    uint public rewardPoolBalance;
    uint private lastSalt;
    bool public isOpen;
    uint public minBalance = 0.5 ether;
    uint public minValidPrice;

    address private rewardSigner;
    TheRabbitNFT private rabbitContractAddress;
    mapping(uint => mapping(uint => bool)) public rewardRecord; // key1:theDay  key2:tokenId

    constructor (address contractAddress, address _rewardSigner) {
        require(_rewardSigner != address(0), "400");
        rewardSigner = _rewardSigner;
        rabbitContractAddress = TheRabbitNFT(contractAddress);
        lastSalt = uint256(keccak256(abi.encodePacked(msg.sender, contractAddress, address(this), _rewardSigner)));
    }

    // thank you
    function supplementRewardPool() external payable {
        uint theLastBalance = address(this).balance - msg.value;
        uint royalty = theLastBalance - lastBalance;
        rewardPoolBalance += msg.value;
        if (royalty > 0) {
            rewardPoolBalance += (royalty / 3);
        }
        lastBalance = address(this).balance;
    }

    // Set the signer
    function setRewardSigner(address newSigner) external onlyOwner {
        require(newSigner != address(0), "400");
        rewardSigner = newSigner;
    }
    // Set status
    function setOpenStatus(bool _isOpen) external onlyOwner {
        isOpen = _isOpen;
    }
    // The min value with open, wei
    function setMinBalance(uint _minBalance) external onlyOwner {
        minBalance = _minBalance;
    }
    // The min valid price with transfer, wei
    function setMinValidPrice(uint _minValidPrice) external onlyOwner {
        minValidPrice = _minValidPrice;
    }

    // List of awards received
    function getAlreadyRewardTokenIds(uint luckyItem) view external returns (uint[] memory tokenIds) {
        uint[] memory allTokenIds = rabbitContractAddress.getWinnerTokenIds(luckyItem);
        if (allTokenIds.length == 0) return tokenIds;
        uint theDay = getDaysFrom1970();
        uint count = 0;
        tokenIds = new uint[](allTokenIds.length);
        for (uint index = 0; index < allTokenIds.length; index++) {
            if (rewardRecord[theDay][allTokenIds[index]]) tokenIds[count++] = allTokenIds[index];
        }
        if (count == allTokenIds.length) return tokenIds;
        uint[] memory realTokenIds = new uint[](count);
        for (uint j = 0; j < count; j++) {
            realTokenIds[j] = tokenIds[j];
        }
        return realTokenIds;
    }

    // Pool balance, wei
    function getRewardPoolBalance() public view returns (uint count){
        count = rewardPoolBalance;
        if (address(this).balance > lastBalance) {
            uint royalty = address(this).balance - lastBalance;
            count += (royalty / 3);
        }
    }

    event RewardSucceed(address indexed to, uint amount);
    // Do reward
    function reward(
        bytes memory salt, bytes memory token, uint[] calldata tokenIds,
        uint validDay, uint unitPrice
        ) external {
        require(_recover(_hash(salt, tokenIds, validDay, unitPrice), token) == rewardSigner, "400");
        uint theDay = getDaysFrom1970();
        require(theDay == validDay, "104");

        uint count = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            if (!rewardRecord[theDay][tokenIds[i]] && rabbitContractAddress.ownerOf(tokenIds[i]) == msg.sender) {
                count++;
                rewardRecord[theDay][tokenIds[i]] = true;
            }
        }
        if (count == 0) return;

        if (rewardPoolBalance > address(this).balance) {
            rewardPoolBalance = address(this).balance;
            lastBalance = address(this).balance;
        }

        if (address(this).balance > lastBalance) {
            // handle the royalty
            uint royalty = address(this).balance - lastBalance;
            rewardPoolBalance += (royalty / 3);
            lastBalance = address(this).balance;
        }

        uint paymentAmount = count * unitPrice * 10**9;
        lastBalance = address(this).balance - paymentAmount;
        rewardPoolBalance -= paymentAmount;
        payable(msg.sender).transfer(paymentAmount);
        emit RewardSucceed(msg.sender, paymentAmount);
    }

    // The lucky num today
    // 0:not open
    // >=2:the num
    function getLuckyItem() view external returns (uint luckyItem, uint poolBalance) {
        if (!isOpen) {
            return (0, getRewardPoolBalance() / 10 ** 9);
        }
        poolBalance = getRewardPoolBalance() / 10 ** 9;
        uint theDay = getDaysFrom1970();
        // !hOphOp! Happy Eureka Day! 
        if (theDay % 7 != 6) return (0, poolBalance);
        uint royalty = address(this).balance - lastBalance;

        bool _isOpen = false;
        if (royalty > 0) {
            if (rewardPoolBalance + (royalty / 3) >= minBalance) {
                _isOpen = true;
            }
        } else {
            if (rewardPoolBalance >= minBalance) {
                _isOpen = true;
            }
        }

        if (_isOpen) {
            return ((uint256(keccak256(abi.encodePacked(theDay, lastSalt))) % 78) + 2, poolBalance);
        }
        return (0, poolBalance);
    }

    event Received(address, uint);
    receive() external payable {
        // 1.the royalty
        // 2.player do this and thank you very match
        emit Received(msg.sender, msg.value);
    }
    // Only draw money from outside the pool
    function withdrawFunds() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance - rewardPoolBalance);
        rewardPoolBalance = lastBalance = address(this).balance;
    }
    function getMinPriceInfo() external view returns(uint _minBalance, uint _minValidPrice) {
        return (minBalance / 10 ** 9, minValidPrice / 10 ** 9);
    }

    // tools
    function _hash(bytes memory salt, uint[] calldata tokenIds, uint validDay, uint unitPrice)
    private view returns (bytes32) {
        return keccak256(abi.encodePacked(salt, address(this), tokenIds, validDay, unitPrice));
    }
    function _recover(bytes32 hash, bytes memory token) private pure returns (address) {
        return hash.toEthSignedMessageHash().recover(token);
    }

    function getDaysFrom1970() public view returns (uint _days) {
        _days = TimeUtil.currentTime() / 86400;
    }

}