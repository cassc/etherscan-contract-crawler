//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "./ERC721Test1.sol";

import {ISplitMain} from "splits-utils/src/interfaces/ISplitMain.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

import "hardhat/console.sol";

contract TestDeployer1 {
    address[] public remixContractArray;
    ISplitMain public immutable splitMain;
    address public controller; // TODO: don't set controller for splits

    address immutable remixImplementation;

    event PublishedRemix(
        address indexed creator,
        address remixContractAddress,
        address creatorProceedRecipient,
        address derivativeFeeRecipient
    );

    constructor(address _splitMainAddress, address _controller, address _implementation) {
        splitMain = ISplitMain(_splitMainAddress);
        controller = _controller;
        remixImplementation = _implementation;
    }

    function publishRemix(
        address _creator,
        string memory _name,
        string memory _symbol, 
        string memory _uri, 
        address[] memory creatorProceedAccounts, 
        uint32[] memory creatorProceedAllocations,
        address[] memory derivativeFeeAccounts, 
        uint32[] memory derivativeFeeAllocations,
        uint256 _price,
        uint256 _maxSupply,
        uint256 _mintLimitPerWallet,
        uint256 _saleEndTime
    ) public {

        require(creatorProceedAccounts.length > 0, "Empty proceeds array");
        require(creatorProceedAccounts.length == creatorProceedAllocations.length, "Mismatched proceeds array lengths");
        require(derivativeFeeAccounts.length > 0, "Empty fee array");
        require(derivativeFeeAccounts.length == derivativeFeeAllocations.length, "Mismatched fee array lenghts");


        address proceedRecipient;
        if (creatorProceedAccounts.length == 1) {
            proceedRecipient = creatorProceedAccounts[0];
        } else {
            address creatorSplit = splitMain.createSplit({
                accounts: creatorProceedAccounts,
                percentAllocations: creatorProceedAllocations,
                distributorFee: 0,
                controller: controller
            });
            proceedRecipient = creatorSplit;
        }

        address feeRecipient;
        if (derivativeFeeAccounts.length == 1) {
            feeRecipient = derivativeFeeAccounts[0];
        } else {
            address derivativeFeeSplit = splitMain.createSplit({
                accounts: derivativeFeeAccounts,
                percentAllocations: derivativeFeeAllocations,
                distributorFee: 0,
                controller: controller
            });
            feeRecipient = derivativeFeeSplit;
        }
        

        address remixClone = Clones.clone(remixImplementation);
        ERC721Test1(remixClone).initialize(_creator, _name, _symbol, _uri, proceedRecipient, feeRecipient, _price, _maxSupply, _mintLimitPerWallet, _saleEndTime);
        remixContractArray.push(remixClone);

        emit PublishedRemix({
            creator: msg.sender,
            remixContractAddress: remixClone,
            creatorProceedRecipient: proceedRecipient,
            derivativeFeeRecipient: feeRecipient
        });
    }
}