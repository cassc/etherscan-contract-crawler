// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "Degen.sol";

contract MythReader {
    address payable public owner;
    address public degensAddress;

    constructor(address degen) {
        owner = payable(msg.sender);
        degensAddress = degen;
    }

    function getUsersDegens(
        address account
    ) public view returns (uint256[] memory) {
        MythDegen mythDegen = MythDegen(degensAddress);
        uint256 tokenCount = mythDegen.tokenCount();
        uint256 userCount = mythDegen.balanceOf(account);
        uint256[] memory uriList = new uint256[](userCount);
        uint256 arrayCounter = 0;
        for (uint256 i = 1; i < tokenCount; i++) {
            if (userCount == 0) {
                return uriList;
            }
            if (mythDegen.ownerOf(i) == account) {
                uriList[arrayCounter] = i;
                arrayCounter += 1;
                userCount -= 1;
            }
        }
        return uriList;
    }
}