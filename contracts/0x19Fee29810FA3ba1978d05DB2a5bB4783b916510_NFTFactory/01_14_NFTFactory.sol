// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./NFTContract.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract NFTFactory is Ownable {

    using Counters for Counters.Counter;
    Counters.Counter private _index;

        ///DATABASE CODE

    //initializes the NFTContract Database strucutre
    // struct NFTContractInfo
    // {
    //     uint256 index;
    //     string assetName;
    //     address theNFTContract;
    // }

    // mapping(uint256 => NFTContractInfo[]) database;

    uint256 private contract_creation_fee = 1 * 10**16; //0.01 ETH
    uint256 private tax_rate = 1; //1% 0.01
    address private tax_man = 0xf9DEB97CcA539576CD582A785465eB9088f36696;

    ////////////////////////////
    //viewable functions

        ///DATABASE CODE

    // //view contract info by key
    // function getNFTContractInfo(uint256 key)
    //     public
    //     view
    //     returns (NFTContractInfo[] memory)
    //     {
    //         return database[key];
    //     }

    //view contract creation fee
    function getContractCreationFee()
        public
        view 
        returns (uint256)
        {
            return(contract_creation_fee);
        }

    //view tax rate
    function getTaxRate()
        public
        view
        returns (uint256)
        {
            return(tax_rate);
        }

    /////////////////////////////////
    //owner only functions

    //change the contract creation fee (IN ETHEREUM)
    function changeContractCreationFee(uint256 newFee)
        public
        onlyOwner
        {
            contract_creation_fee = newFee;
        }

    //change the tax rate (enter a perecentage, ie. 1%)
    function changeTaxRate(uint256 newRate)
        public
        onlyOwner
        {
            tax_rate = newRate;
        }

    //changes the tax_man
    function changeTaxMan(address new_tax_man)
        public
        onlyOwner
        {
            tax_man = new_tax_man;
        }

    //withdraws money
    function withdrawMoney()
        public
        onlyOwner
        payable
        {
            payable(msg.sender).transfer(address(this).balance);
        }

    /////////////////////////////////
    //public functions

    //function to create a NFTContract
    function createNFTProject(uint256 _maxTokens, string memory _assetName, string memory _ticker,
                              uint256 _price, uint256 _preSalePrice, address _verifyingAccount) 
        public
        payable
        returns (NFTContract)
    {
        //makes sure we get paid
        require(msg.value >= contract_creation_fee);

        ///DATABASE CODE
        // //increases the index
        // _index.increment();

        // uint256 key = _index.current();

        //creates the new NFTContract
        NFTContract newNFTContract = new NFTContract(_maxTokens, _assetName, _ticker, _price, 
                                                     _preSalePrice, _verifyingAccount, msg.sender, 
                                                      tax_rate, tax_man);


        ///DATABASE CODE

        //adds it to the database

        // NFTContractInfo memory newNFTContractInfo = NFTContractInfo(
        // {
        //     index: key,
        //     assetName: _assetName,
        //     theNFTContract: address(newNFTContract)
        // });

        // database[key].push(newNFTContractInfo);

        //completes the function
    	return newNFTContract;
    }



}