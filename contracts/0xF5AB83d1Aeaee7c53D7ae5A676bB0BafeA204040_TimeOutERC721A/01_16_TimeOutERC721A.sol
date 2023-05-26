// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// @author CryptoEdge

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A.sol";

contract TimeOutERC721A is Ownable, ERC721A, PaymentSplitter {

    using Strings for uint;

    enum Step {
        Before,
        WhitelistSale,
        PublicSale,
        SoldOut,
        Reveal
    }

    Step public sellingStep;

    uint private constant MAX_SUPPLY = 7777;
    uint private constant MAX_GIFT = 250;
    uint private constant MAX_WHITELIST = 777;
    uint private constant MAX_PUBLIC = 6750;
    uint private constant MAX_SUPPLY_MINUS_GIFT = MAX_SUPPLY - MAX_GIFT;

    uint public wlSalePrice = 0.1 ether;
    uint public publicSalePrice = 0.15 ether;

    uint public saleStartTime = 1652029200;

    bytes32 public merkleRoot;

    string public baseURI;

    mapping(address => uint) amountNFTperWalletWhitelistSale;
    mapping(address => uint) amountNFTperWalletPublicSale;

    uint private constant maxPerAddressDuringWhitelistMint = 7;
    uint private constant maxPerAddressDuringPublicMint = 100;

    bool public isPaused;

    uint private teamLength;

    address[] private _team = [
        0xf05cD4d6a1B98D102644056c9a81272002C712F8,
        0xB00DbfB0FB1a80960b29179Eb2E96106E6426efD
    ];

    uint[] private _teamShares = [
        999,
        1
    ];

    //Constructor
    constructor(bytes32 _merkleRoot, string memory _baseURI)
    ERC721A("Time Out", "TO") 
    PaymentSplitter(_team, _teamShares) {
        merkleRoot = _merkleRoot;
        baseURI= _baseURI;
        teamLength = _team.length;
    }

    /**
    * @notice This contract can't be called by other contracts
    */
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    /**
    * @notice Mint function for the Whitelist Sale
    *
    * @param _account Account which will receive the NFT
    * @param _quantity Amount of NFTs ther user wants to mint
    * @param _proof The Merkle Proof
    **/
    function whitelistMint(address _account, uint _quantity, bytes32[] calldata _proof) external payable callerIsUser{
        require(!isPaused, "Contract is paused");
        require(currentTime() >= saleStartTime, "Sale has not started yet");
        require(currentTime() < saleStartTime +77 minutes, "Sale is finished");
        uint price = wlSalePrice;
        require(price != 0, "Price is 0");
        require(sellingStep == Step.WhitelistSale, "Whitelist sale is not activated");
        require(isWhitelisted(msg.sender, _proof), "Not whitelisted");
        require(amountNFTperWalletWhitelistSale[msg.sender] + _quantity <= maxPerAddressDuringWhitelistMint, "You can only get 2 NFT on the Whitelist Sale");
        require(totalSupply() + _quantity <= MAX_WHITELIST, "Max supply exceeded");
        require(msg.value >= price * _quantity, "Not enought funds");
        amountNFTperWalletWhitelistSale[msg.sender] += _quantity;
        _safeMint(_account, _quantity);
    }

    /**
    * @notice Mint function for the Public Sale
    *
    * @param _account Account which will receive the NFTs
    * @param _quantity Amount of NFTs the user wants to mint
    **/
    function publicMint(address _account, uint _quantity) external payable callerIsUser {
        require(!isPaused, "Contract is Paused");
        require(currentTime() >= saleStartTime + 77 minutes, "Public sale has not started yet");
        require(currentTime() < saleStartTime + 169 hours, "Public Sale is finished");
        uint price = publicSalePrice;
        require(price != 0, "Price is 0");
        require(sellingStep == Step.PublicSale, "Public sale is not activated");
        require(amountNFTperWalletPublicSale[msg.sender] + _quantity <= maxPerAddressDuringPublicMint, "You can only get 3 NFTs on the Public Sale");
        require(totalSupply() + _quantity <= MAX_SUPPLY_MINUS_GIFT, "Max supply exceeded");
        require(msg.value >= price * _quantity, "Not enought funds");
        amountNFTperWalletPublicSale[msg.sender] += _quantity;
        _safeMint(_account, _quantity);
    }

    /**
    * @notice Allows the owner to gift NFTs
    *
    * @param _to The address of the receiver
    * @param _quantity Amount of NFTs the owner wants to gift
    **/
    function gift(address _to, uint _quantity) external onlyOwner {
        require(sellingStep > Step.PublicSale, "Gift is after the public sale");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Reached max supply");
        _safeMint(_to, _quantity);
    }
    /**
    * @notice Get the token URI of an NFT by his ID
    *
    * @param _tokenId The ID of the NFT you want to have the URI of the metadatas
    *
    * @return the token URI of an NFT by his ID
    */
    function tokenURI(uint _tokenId) public view virtual override returns(string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");

        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }
    /**
    * @notice Allows to set the whitelist sale price
    *
    * @param _wlSalePrice The new price of one NFT during the whitelist sale
    */
    function setWlSalePrice(uint _wlSalePrice) external onlyOwner {
        wlSalePrice = _wlSalePrice;
    }

    /**
    * @notice Allows to set the public sale price
    *
    * @param _publicSalePrice The new price of one NFT during the public sale
    */
    function setPublicSalePrice(uint _publicSalePrice) external onlyOwner {
        publicSalePrice = _publicSalePrice;
    }

    /**
    * @notice Change the starting time (timestamp) of the whitelist sale
    *
    * @param _saleStartTime The new starting timestamp of the whitelist sale
    */
    function setSaleStartTime(uint _saleStartTime) external onlyOwner {
        saleStartTime = _saleStartTime;
    }

    /**
    * @notice Get the current timestamp
    *
    * @return the current timestamp
    */
    function currentTime() internal view returns(uint) {
        return block.timestamp;
    }

    /**
    * @notice Change the step of the sale
    *
    * @param _step The new step of the sale
    */
    function setStep(uint _step) external onlyOwner {
        sellingStep = Step(_step);
    }

    /**
    * @notice Pause or unpause the smart contract
    *
    * @param _isPaused true or false if we want to pause or unpause the contract
    */
    function setPaused(bool _isPaused) external onlyOwner {
        isPaused = _isPaused;
    }

    /**
    * @notice Change the base URI of the NFTs
    *
    * @param _baseURI the new base URI of the NFTs
    */
    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /**
    * @notice Change the merkle root
    *
    * @param _merkleRoot the new MerkleRoot
    */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }  

    /**
    * @notice Hash an address
    *
    * @param _account The address to be hashed
    *
    * @return bytes32 The hashed address
    */
    function leaf(address _account) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(_account));
    }

    /**
    * @notice Returns true if a leaf can be proved to be a part of a merkle tree defined by root
    *
    * @param _leaf The leaf
    * @param _proof The Merkle Proof
    *
    * @return True if a leaf can be proved to be a part of a merkle tree defined by root
    */
    function _verify(bytes32 _leaf, bytes32[] memory _proof) internal view returns(bool) {
        return MerkleProof.verify(_proof, merkleRoot, _leaf);
    }

    /**
    * @notice Check if an address is whitelisted or not
    *
    * @param _account The account checked
    * @param _proof The Merkle Proof
    *
    * @return bool return true if the address is whitelisted, false otherwise
    */
    function isWhitelisted(address _account, bytes32[] calldata _proof) internal view returns(bool) {
        return _verify(leaf(_account), _proof);
    }


    /**
    * @notice Release the gains on every accounts
    */
    function releaseAll() external {
        for(uint i = 0 ; i < teamLength ; i++) {
            release(payable(payee(i)));
        }
    }

    //Not allowing receiving ethers outside minting functions
    receive() override external payable {
        revert('Only if you mint');
    }

 }