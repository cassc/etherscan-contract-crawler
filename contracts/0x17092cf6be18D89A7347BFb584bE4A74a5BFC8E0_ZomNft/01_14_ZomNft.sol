/* SPDX-License-Identifier: MIT



 [][][][][][][]]     [[][][][][]]     [][]]      [[][]
[[][][][][][][]     [][][][][][][]    [][][]]  [[][][]
          [][]      [][]      [][]    [][] [][][] [][]
        [][]        [][]      [][]    [][]  [][]  [][]
      [][]          [][]      [][]    [][]   []   [][]
    [][]            [][]      [][]    [][]        [][]
  [][]              [][]      [][]    [][]        [][]
 [][][][][][][]]    [][][][][][][]    [][]        [][]
[[][][][][][][]      [[][][][][]]      []          []

[][][]      [][]    [][][][][][][]    [][][][][][][][]
[][][]]     [][]    [][][][][][][]     [[][][][][][]]
[][][][]    [][]    [][]                    [][]      
[][] [][]   [][]    [][]                    [][]
[][]  [][]  [][]    [][][][][][]            [][]
[][]   [][] [][]    [][][][][][]            [][]
[][]    [][][][]    [][]                    [][]
[][]     [[][][]    [][]                    [][]
[][]      [][][]    [][]                     []



* Generated by Cyberscape Labs
* Email [email protected] for your NFT launch needs


*/


pragma solidity ^0.8.13; 

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";


/*//////////////////////////////////////
            CUSTOM ERRORS
//////////////////////////////////////*/
/// @notice Thrown when completing transaction will exceed collection supply
error ExceededMintSupply();
/// @notice Thrown when transaction sender is not on whitelist
error NotOnMintList();
/// @notice Thrown when the attempted sale is not actve
error SaleNotActive();
/// @notice Thrown when the message value is less than the required amount
error ValueTooLow();
/// @notice Thrown when the amount minted exceeds max allowed per txn
error MintingTooMany();
/// @notice Thrown when the input address is 0
error ZeroAddress();
/// @notice Thrown when input data does not equal what was required
error InvalidData();


/**
    @title Zom NFT
    @author @0x_digitalnomad with Cyberscape Labs
*/

contract ZomNft is ERC721A, Ownable, ReentrancyGuard { 

    using Strings for uint256;

    /*//////////////////////////////////////
                STATE VARIABLES
    //////////////////////////////////////*/
    enum MintStatus {
        CLOSED,
        PRESALE,
        PUBLIC,
        SOLDOUT
    }
    MintStatus public mintStatus = MintStatus.CLOSED;

    uint256 public collectionSize;
    uint256 public maxAvailableSupply;
    uint256 public reserveSupply;
    uint256 public maxPerTxn;
    uint256 public presalePrice = 0.06 ether;
    uint256 public salePrice = 0.08 ether;
    uint256 private mintData;
    string private baseURI;
    string private unrevealedURI;
    bool public revealed = false;

    mapping(address => bool) private mintList;
    bytes32 public merkleRoot = 
        0xd8d7f90e32d38f901b93dbf1da9d0d79b61caf0e42baeac651752cd1635241fd;

    address private devWallet;
    address private partnerWallet;


    /*//////////////////////////////////////
                EVENTS
    //////////////////////////////////////*/
    event ChangeBaseURI(string _baseURI);
    event UpdateSaleState(string _sale);
    event Mint(address _minter, uint256 _amount, string _type);

    /*//////////////////////////////////////
                CONSTRUCTOR
    //////////////////////////////////////*/
    constructor(
        uint collectionSize_,
        uint reserveSupply_,
        uint maxTxn_,
        uint mintData_,
        address devWallet_,
        address partnerWallet_
    ) ERC721A("Zom NFT", "ZOM") {
        collectionSize = collectionSize_;
        reserveSupply = reserveSupply_;
        maxPerTxn = maxTxn_;
        mintData = mintData_;
        devWallet = devWallet_;
        partnerWallet = partnerWallet_;
        
        maxAvailableSupply = collectionSize - reserveSupply;
    }

    /*//////////////////////////////////////
                MODIFIERS
    //////////////////////////////////////*/
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Caller is another contract");
        _;
    }

    /*//////////////////////////////////////
                MINTING FUNCTIONS
    //////////////////////////////////////*/

    /**
        Dev mint function to reserve a supply for giveaways, collaborations, and marketing
        @param _address The address to mint to
        @param _amount The amount to mint
    */
    function mint_(address _address, uint256 _amount)
        external
        onlyOwner
    {
        if (_address == address(0)) revert ZeroAddress();
        if (_amount + totalSupply() > collectionSize) revert ExceededMintSupply();

        _safeMint(_address, _amount);
        emit Mint(_address, _amount, "Dev");
    }

    /**
        Presale mint function using merkle proofs
        @param _proof An array of bytes representing the merkle proof for the sender's address
        @param _amount The amount to mint
    */
    function mintPresale(bytes32[] memory _proof, uint256 _amount)
        external
        payable
        callerIsUser
        nonReentrant
    {
        if (mintStatus != MintStatus.PRESALE) revert SaleNotActive();
        if (_amount > maxPerTxn) revert MintingTooMany();
        if (_amount + totalSupply() > maxAvailableSupply) revert ExceededMintSupply();
        if (!MerkleProof.verify(_proof, merkleRoot, keccak256(abi.encodePacked(msg.sender)))) revert NotOnMintList();
        if (msg.value != presalePrice * _amount) revert ValueTooLow();

        _safeMint(msg.sender, _amount);
        emit Mint(msg.sender, _amount, "Presale");
    }

    /**
        Public minting function and presale backup
        @param _amount The amount to mint
        @param _data Private data required to mint
    */
    function mint(uint256 _amount, uint256 _data)
        external
        payable
        callerIsUser
        nonReentrant
    {
        if (mintStatus != MintStatus.PRESALE && mintStatus != MintStatus.PUBLIC) revert SaleNotActive();
        if (_data != mintData) revert InvalidData();
        if (_amount > maxPerTxn) revert MintingTooMany();
        if (_amount + totalSupply() > maxAvailableSupply) revert ExceededMintSupply();

        if (mintStatus == MintStatus.PRESALE) {
            if (!mintList[msg.sender]) revert NotOnMintList();
            if (msg.value != presalePrice * _amount) revert ValueTooLow();

            _safeMint(msg.sender, _amount);
            emit Mint(msg.sender, _amount, "Presale");
        } else if (mintStatus == MintStatus.PUBLIC){
            if (msg.value != salePrice * _amount) revert ValueTooLow();

            _safeMint(msg.sender, _amount);
            emit Mint(msg.sender, _amount, "Public");
        }
    }

    
    /*//////////////////////////////////////
                SETTERS
    //////////////////////////////////////*/
    function setUnrevealedURI(string calldata _unrevealedURI)
        external
        onlyOwner
    {
        unrevealedURI = _unrevealedURI;
    }

    function setBaseURI(string calldata _tokenBaseURI)
        external
        onlyOwner
    {
        baseURI = _tokenBaseURI;
        emit ChangeBaseURI(_tokenBaseURI);
    }

    /**
        Update the price for the public sale or presale.
        @param _saleType Either "presale" for presalePrice or "public" for salePrice
        @param _price The new price in gwei
    */
    function setPrice(string calldata _saleType, uint256 _price)
        external
        onlyOwner
    {
        if (keccak256(abi.encodePacked(_saleType)) == keccak256(abi.encodePacked("presale"))) {
            presalePrice = _price;
        } else if (keccak256(abi.encodePacked(_saleType)) == keccak256(abi.encodePacked("public"))) {
            salePrice = _price;
        } else {
            revert InvalidData();
        }
    }

    function setMaxTxn(uint256 _max)
        external
        onlyOwner
    {
        maxPerTxn = _max;
    }

    function setMintData(uint256 _data)
        external
        onlyOwner
    {
        mintData = _data;
    }

    function setMerkleRoot(bytes32 _merkleRoot)
        external
        onlyOwner
    {
        merkleRoot = _merkleRoot;
    }

    /*//////////////////////////////////////
                GETTERS
    //////////////////////////////////////*/
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");
        
        if (revealed == false) {
            return unrevealedURI;
        } else {
            return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), '.json')) : '';
        }
    }

    function getMintStatus()
        external
        view
        returns(string memory)
    {
        if (mintStatus == MintStatus.CLOSED) {
            return "Closed";
        } else if (mintStatus == MintStatus.PRESALE){
            return "Presale";
        } else if (mintStatus == MintStatus.PUBLIC) {
            return "Public Sale";
        } else { //mintStatus == MintStatus.SoldOut
            return "Sold Out";
        }
    }

    function getMintList(address _addr)
        external
        view
        returns(bool)
    {
        return mintList[_addr];
    }

    /*//////////////////////////////////////
                MISC
    //////////////////////////////////////*/
    function addToMintList(address[] calldata _addresses)
        external
        onlyOwner
    {
        for (uint i = 0; i < _addresses.length; i++) {
            if (_addresses[i] == address(0)) revert ZeroAddress();
            mintList[_addresses[i]] = true;
        }
    }

    function removeFromMintList(address[] calldata _addresses)
        external
        onlyOwner
    {
        for (uint i = 0; i < _addresses.length; i++) {
            if (_addresses[i] == address(0)) revert ZeroAddress();
            mintList[_addresses[i]] = false;
        }
    }
    
    function reveal(bool _reveal) external onlyOwner {
        revealed = _reveal;
    }

    function closeSale() external onlyOwner {
        if (totalSupply() == collectionSize) {
            mintStatus = MintStatus.SOLDOUT;
            emit UpdateSaleState("Sold Out");
        } else {
            mintStatus = MintStatus.CLOSED;
            emit UpdateSaleState("Closed");
        }
    }

    function startPresale() external onlyOwner {
        mintStatus = MintStatus.PRESALE;
        emit UpdateSaleState("Presale");
    }

    function startPublicSale() external onlyOwner {
        mintStatus = MintStatus.PUBLIC;
        emit UpdateSaleState("Public");
    }

    function withdrawl() external onlyOwner {
        uint totalBalance = address(this).balance;
        payable(devWallet).transfer(totalBalance * 35 / 1000);
        payable(partnerWallet).transfer(totalBalance * 60 / 1000);
        payable(msg.sender).transfer(totalBalance * 905 / 1000);
    }
}