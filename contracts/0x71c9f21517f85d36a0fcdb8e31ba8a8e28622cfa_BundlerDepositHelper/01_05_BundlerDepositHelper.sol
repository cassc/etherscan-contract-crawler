// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IStorage.sol";
import "../interfaces/IStakeManager.sol";

contract BundlerDepositHelper is Ownable {
    mapping(address => bool) public vaildEntryPoint;

    constructor(address _owner) {
        _transferOwnership(_owner);
    }

    function setValidEntryPoint(
        address entryPoint,
        bool isValid
    ) public onlyOwner {
        vaildEntryPoint[entryPoint] = isValid;
    }

    function batchDepositForBundler(
        address entryPoint,
        address[] memory bundlers,
        uint256[] memory amounts
    ) public payable {
        uint256 loopLength = bundlers.length;

        require(
            vaildEntryPoint[entryPoint],
            "BundlerDepositHelper: Invalid EntryPoint"
        );
        require(
            loopLength == amounts.length,
            "BundlerDepositHelper: Invalid input"
        );

        for (uint256 i = 0; i < loopLength; i++) {
            address bundler = bundlers[i];
            uint256 amount = amounts[i];

            require(
                IStorage(entryPoint).officialBundlerWhiteList(bundler),
                "BundlerDepositHelper: Invalid bundler"
            );

            payable(bundler).transfer(amount);
        }

        require(
            address(this).balance == 0,
            "BundlerDepositHelper: Invalid value"
        );
    }
}