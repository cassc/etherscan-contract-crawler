//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";

contract EBBSPLITER is Ownable {
    mapping(address => mapping(address => uint256)) private affiliateShares;
    mapping(address => address[]) private senderAffiliates;

    function setShares(address sender, address[] memory affiliates, uint256[] memory newShares) external onlyOwner {
        require(affiliates.length == newShares.length, "length mismatch");

        uint256 totalShares = 0;
        for (uint256 i = 0; i < newShares.length; ++i) {
            totalShares += newShares[i];
        }

        require(totalShares == 1000, "Sum error");

        for (uint256 i = 0; i < affiliates.length; ++i) {
            address affiliate = affiliates[i];
            uint256 shares = newShares[i];

            if (affiliateShares[sender][affiliate] == 0 && shares > 0) {
                senderAffiliates[sender].push(affiliate);
            }
            affiliateShares[sender][affiliate] = shares;
        }
    }

    function collectdust() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function getAffiliateShares(address sender, address affiliate) external view returns (uint256) {
        return affiliateShares[sender][affiliate];
    }

    function getSenderAffiliates(address sender) external view returns (address[] memory) {
        return senderAffiliates[sender];
    }

    receive() external payable {
        uint256 receivedAmount = msg.value;
        require(receivedAmount > 0, "No value sent");
        address sender = msg.sender;
        uint256 affiliateLength = senderAffiliates[sender].length;
        require(affiliateLength > 0, "No affiliates");

        for (uint256 i = 0; i < affiliateLength; ++i) {
            address affiliate = senderAffiliates[sender][i];
            uint256 affiliateShare = affiliateShares[sender][affiliate];
            uint256 dividend = (receivedAmount * affiliateShare) / 1000;
            payable(affiliate).transfer(dividend);
        }
    }
}