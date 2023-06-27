// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./ERC721Full.sol";
import "./MarsGenesisMartiansWallet.sol";

/// @title MarsGenesis Martians Auction Base Contract
/// @author MarsGenesis
/// @notice Serves as the base for MarsGenesisMartiansAuction contract
contract MarsGenesisMartiansAuctionBase is ERC165 {

    /// @dev Interface signatures
    bytes4 constant InterfaceSignature_ERC721 = bytes4(0x80ac58cd);
    bytes4 constant InterfaceSignature_ERC721_Metadata = bytes4(0x5b5e139f);
    bytes4 constant InterfaceSignature_ERC721_Enumerable = bytes4(0x780e9d63);
    bytes4 constant InterfaceSignature_MarsGenesisMartiansAuction =
        bytes4(keccak256('martianIdIsForSale(uint256 tokenId)')) ^
        bytes4(keccak256('martianNoLongerForSale(uint256)'));

    /// @dev Contract owner balance
    uint public ownerBalance;

    /// @dev Contract owner tax on sales
    uint256 public ownerCut;

    /// @dev Reference to main contract that implements ERC721
    ERC721Full nonFungibleContract; 

    /// @dev Auction contract address
    MarsGenesisMartiansWallet walletContract;

    /// @dev Address of the deployer account
    address _deployerAddress;


    /// @notice Inits the contract 
    /// @dev The main contract should support specific interfaces
    /// @param _erc721Address The address of the main MarsGenesisMartians contract
    /// @param _walletAddress The address of the wallet of MarsGenesisMartians contract
    /// @param _cut The contract owner tax on sales
    constructor (address _erc721Address, address payable _walletAddress, uint256 _cut) {
        require(_cut <= 100, "INVALID_OWNER_CUT");
        ownerCut = _cut;

        _deployerAddress = msg.sender;

        ERC721Full candidateContract = ERC721Full(_erc721Address);
        
        require(candidateContract.supportsInterface(InterfaceSignature_ERC721), "ERC721 not supported");
        require(candidateContract.supportsInterface(InterfaceSignature_ERC721_Metadata), "ERC721Metadata not supported");
        require(candidateContract.supportsInterface(InterfaceSignature_ERC721_Enumerable), "ERC721Enumerable not supported");

        nonFungibleContract = candidateContract;
        walletContract = MarsGenesisMartiansWallet(_walletAddress);
    }
    

    /*** EVENTS ***/

    /// @dev Event fired when a martian is offered for sale
    event MartianOffered(uint indexed tokenId, uint minValue, address indexed from);

    /// @dev Event fired when a user bids on a martian
    event MartianBidEntered(uint indexed tokenId, uint value, address indexed from);

    /// @dev Event fired when a bid is withdrawn
    event MartianBidWithdrawn(uint indexed tokenId, uint value, address indexed from);

    /// @dev Event fired when a martian is bought via auctioning or direct sale
    event MartianBought(uint indexed tokenId, uint value, address indexed from, address indexed to);

    /// @dev Event fired when a martian is no longer for sale
    event MartianNoLongerForSale(uint indexed tokenId, address indexed from);
    

    /*** STORAGE ***/

    /// @dev The main Offer struct for auctioning
    struct Offer {
        bool isForSale;
        uint tokenId;
        address seller;
        uint minValue; 
    }

    /// @dev The main Bid struct for auctioning
    struct Bid {
        bool hasBid;
        uint tokenId;
        address bidder;
        uint value;
    }

    /// @dev A mapping of martians that are offered for sale at a specific minimum value
    mapping (uint => Offer) public martianIdToOfferForSale;

    /// @dev A mapping of the martianId to its highest bid
    mapping (uint => Bid) public martianIdToBids;

    /// @dev A mapping of address to their pending withdrawal
    mapping (address => uint) public addressToPendingWithdrawal;

    /*** ERC165 ***/

    /// @notice Checks for interface support
    /// @param interfaceId The interfaceId bytes
    /// @return bool, true or false for the support
    function supportsInterface(bytes4 interfaceId) public override pure returns (bool) {
        return interfaceId == InterfaceSignature_MarsGenesisMartiansAuction;
    }
}