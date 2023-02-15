// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import './payments.sol';


contract RoyalitySplitterFactory is Initializable, UUPSUpgradeable, Ownable {



    function initialize() initializer public {
        __UUPSUpgradeable_init();
    }


    event Log(address message);

    struct ContractAddresses {

        address[] SplitterContractAddress;
    
    }

    struct ContractDetails {
        string NameSplit;
        address CreatedBy;
        uint TimeStamp;


    }

    mapping(address => ContractAddresses) private SplitterContractRecords;
    mapping(address => ContractDetails) private ContractInformation;



    function Create_PaymentSplitter(address[] memory _payees, uint256[] memory _shares, string memory name) public returns (address) {
        RoyalitySplitter splitter =new RoyalitySplitter(_payees,_shares, name);
        SplitterContractRecords[address(msg.sender)].SplitterContractAddress.push(address(splitter));
        emit Log(address(splitter));
        ContractInformation[address(splitter)] = ContractDetails(name, address(msg.sender), block.timestamp);

        return address(splitter);
    }

    function CollectionRecordsCreated() external view returns (ContractAddresses memory) {
        ContractAddresses storage spiltercontracts = SplitterContractRecords[address(msg.sender)];
        return spiltercontracts;
    }

    function SplitContractInformation(address contractAddress) external view returns (ContractDetails memory) {
        ContractDetails storage contractInfo = ContractInformation[contractAddress];
        return contractInfo;
    }


    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

}