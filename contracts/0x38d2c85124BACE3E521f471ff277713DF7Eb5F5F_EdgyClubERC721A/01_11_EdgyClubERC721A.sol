//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

//@author Skroxx_nft https://twitter.com/skroxx_nft

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A.sol";



contract EdgyClubERC721A is Ownable, ERC721A, PaymentSplitter {

    using Strings for uint;

    enum Step {
        Before,
        WhitelistSale,
        PublicSale,
        SoldOut,
        RevEAl
    }
    Step public sellingStep;

    uint private constant MAX_SUPPLY = 10000;
    uint private constant MAX_GIFT = 100;
    uint private constant MAX_WHITELIST = 2000;
    uint private constant Max_PUBLIC = 8000;
    uint private constant MAX_SUPPLY_MINUS_GIFT = MAX_SUPPLY - MAX_GIFT;

    uint public wlSalePrice = 0.08 ether;
    uint public publicSalePrice = 0.1 ether;

    uint public saleStartTime = 1654250400;

    bytes32 public merkleRoot;

    string public baseURI;
    mapping(address => uint) amountNFTperWalletWhitelistSale;
    mapping(address => uint) amountNFTperWalletPublicSale;

    uint private constant maxPerAdressDuringWhitelistMint = 100;
    uint private constant maxPerAdressDuringPublicSale = 100;

    bool public isPaused;

    uint private teamLength;
    address[] private _team = [
        0x986F925A95615A43e88e1a9CA39c477b7DDa37C6,
        0x718A53204E7a0B270eC192279aaBE5a7dD1404Ad
    ];

    uint[] private _teamShares = [
    500,
    500
    ];

    //Constructor
    constructor(bytes32 _merkleRoot, string memory _baseURI)
    ERC721A("Edgy Eagle", "EE")
    PaymentSplitter(_team, _teamShares) {
        merkleRoot = _merkleRoot;
        baseURI = _baseURI;
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
    * @notice Mint function for the whitelist Sale
    * @param _account Acccount wich will receive the NFTs
    * @param _quantity amountof NFTs ther user wants to mint
    * @param _proof The Merkle Proof
    */
    function whitelistMint(address _account, uint _quantity, bytes32[] calldata _proof) external payable callerIsUser{
        require(!isPaused, "Contract is paused");
        require(currentTime() >= saleStartTime, "Sale has not started yet");
        require(currentTime() < saleStartTime + 72 hours, "Sale is finished");
        uint price = wlSalePrice;
        require(price != 0,"price is 0");
        require( sellingStep == Step.WhitelistSale, "whitelist sale is not activated");
        require(isWhitelisted(msg.sender, _proof), "Not whitelisted");
        require(amountNFTperWalletWhitelistSale[msg.sender] + _quantity <= maxPerAdressDuringWhitelistMint, "You can only get NFT on the whitelist Sale");
        require(totalSupply() + _quantity <= MAX_WHITELIST, "Max supply exceeded");
        require(msg.value >= price * _quantity, "Not enought funds");
        amountNFTperWalletWhitelistSale[msg.sender] += _quantity;
        _safeMint(_account, _quantity);
    }
    /**
    * @notice Mint function for the Public Sale
    * @param _account Acccount wich will receive the NFTs
    * @param _quantity amountof NFTs ther user wants to mint
    */
    function publicMint(address _account, uint _quantity) external payable callerIsUser {
        require(!isPaused, "Contract is Paused");
        require(currentTime() >= saleStartTime + 24 hours, "Public sale has not started yet");
        require(currentTime() < saleStartTime + 96 hours, "Public Sale is finished");
        uint price = publicSalePrice;
        require (price != 0, "Price is 0");
        require(sellingStep == Step.PublicSale, "Public sale is not activated");
        require(amountNFTperWalletPublicSale[msg.sender] + _quantity <= maxPerAdressDuringWhitelistMint, "You can only get NFTs on the whitelist Sale");
        require(totalSupply() + _quantity <= MAX_SUPPLY_MINUS_GIFT, "Max supply exceeded");
        require(msg.value >= price * _quantity,"Not enought funds");
        amountNFTperWalletPublicSale[msg.sender] += _quantity;
        _safeMint(_account, _quantity);
    }
    /**
    * @notice Allow the owner to gift NFTs
    *
    * @param _to The adress of the receiver
    * @param _quantity Amount of NFTs the owner wants to gift
    *
    */
    function gift(address _to, uint _quantity) external onlyOwner {
        require(sellingStep > Step.PublicSale, "Gift is after the public sale");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Reached max supply");
        _safeMint(_to, _quantity);
    }

    /**
    * @notice Get the token URI of an NFT by is ID
    *
    * @param _tokenId the of the NFT you want to have the URI of the metadatas
    *
    *@return the token URI of an NFT by his ID
    */
    function tokenURI(uint _tokenId) public view virtual override returns(string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");

        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    /**
    * @notice allows to set the whitelist sale price
    *
    * @param _wlSalePrice The new price of one NFT during the whitelist sale
    */
    function setWlSalePrice(uint _wlSalePrice) external onlyOwner {
        wlSalePrice = _wlSalePrice;
    }
    /**
    * @notice allows to set the public sale price
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
    *@return the current timestamp
     */
    function currentTime() internal view returns(uint) {
        return block.timestamp;
    }
    /**
    * @notice Change the step of the sale
    *
    *@param _step The new step of the sale
     */
    function setStep(uint _step) external onlyOwner {
        sellingStep = Step(_step);
    }
    /**
    * @notice Pause or unpause the smart contract
    *
    *@param _isPaused true or false if we want to pause or unpause the contract
     */
    function setPaused(bool _isPaused) external onlyOwner {
        isPaused = _isPaused;
    }
    /**
    * @notice Change the base URI of the NFTs
    *
    *@param _baseURI The new base URI of the NFTs
     */
    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }
    /**
    * @notice Change the merkle root
    *
    *@param _merkleRoot The new base merkle root
    */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }
    /**
    * @notice Hash an adress
    *
    *@param _account The adress to be hashed
    *
    *@return bytes32 the hashed adress
    */
    function leaf(address _account) internal pure  returns(bytes32){
        return keccak256(abi.encodePacked(_account));
    }
    /**
    * @notice Returns true if a leaf can be proved to be a part of a merkle tree defined by root
    *
    *@param _leaf the leaf
    *@param _proof the Merkle Proof
    *
    *@return True if a leaf can be proved to be a part of a merkle tree defined by root
    */
    function _verify(bytes32 _leaf, bytes32[] memory _proof) internal view returns(bool){
        return MerkleProof.verify(_proof, merkleRoot, _leaf);
    }
    /**
    * @notice Check if an address is whitelisted or not
    *
    *@param _account the account checked
    *@param _proof the Merkle Proof
    *
    *@return bool return true if the address is whitelisted, false otherwise
    */
    function isWhitelisted(address _account, bytes32[] calldata _proof) internal view returns(bool){
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
    //Not allowing receiving ethers outside
    receive() override external payable {
        revert('only if you mint');
    }
}