// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

interface IAutoMinterFactory
{
    /* Create an NFT Collection and pay the fee */
    function create(string memory name_,
        string memory symbol_,
        string memory baseURI_,
        string memory appId_,
        uint256 mintFee_,
        uint256 size_,
        bool mintSelectionEnabled_,
        bool mintRandomEnabled_,
        address whiteListSignerAddress_,
        uint256 mintLimit_,
        uint256 royaltyBasis_,
        string memory placeholderImage_) payable external;
    
    /* Create an NFT Collection and pay the fee */
    function createConsecutive(string memory name_,
        string memory symbol_,
        string memory baseURI_,
        string memory appId_,
        uint256 mintFee_,
        uint256 size_,
        address whiteListSignerAddress_,
        uint256 mintLimit_,
        uint256 royaltyBasis_,
        string memory placeholderImage_) payable external;
    
    /* Change the fee charged for creating contracts */
    function changeFee(uint256 newFee) external;
    function addExistingCollection(address collectionAddress, address owner, string memory appId) external;
    function transferBalance(address payable to, uint256 ammount) external;
    
    function version() external pure returns (string memory);

    function setERC721Implementation(address payable implementationContract) external;
    function setERC721AImplementation(address payable implementationContract) external;
    function isCollectionValid(address collectionAddress) external view returns (bool);
}