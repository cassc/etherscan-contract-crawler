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

    // function getUsersDegens(
    //     address account
    // ) public view returns (string[] memory) {
    //     string[] memory uriList;
    //     MythDegen mythDegen = MythDegen(degensAddress);
    //     uint256 userCount = mythDegen.balanceOf(account);
    //     uint256 counter = 1;
    //     uint256 arrayCounter = 0;
    //     while (true) {
    //         if (userCount == 0) {
    //             return uriList;
    //         }
    //         if (mythDegen.ownerOf(counter) == account) {
    //             uriList[arrayCounter] = (mythDegen.tokenURI(counter));
    //             arrayCounter += 1;
    //             userCount -= 1;
    //         }
    //         counter += 1;
    //     }
    // }

    function getUsersDegenssss() public view returns (string[] memory) {
        string[] memory uriList;
        MythDegen mythDegen = MythDegen(degensAddress);
        string memory first = mythDegen.tokenURI(1);
        string memory second = mythDegen.tokenURI(2);
        uriList[0] = first;
        uriList[1] = second;
        return uriList;
    }

    // function getUsersDegen(
    //     address account
    // ) public view returns (string memory) {
    //     string memory uriList;
    //     MythDegen mythDegen = MythDegen(degensAddress);
    //     uint256 userCount = mythDegen.balanceOf(account);
    //     uint256 counter = 1;
    //     uint256 arrayCounter = 0;
    //     while (true) {
    //         if (userCount == 0) {
    //             return uriList;
    //         }
    //         if (mythDegen.ownerOf(counter) == account) {
    //             uriList = (mythDegen.tokenURI(counter));

    //             arrayCounter += 1;
    //             userCount -= 1;
    //         }
    //         counter += 1;
    //     }
    // }
}