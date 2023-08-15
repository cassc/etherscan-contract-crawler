// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
    ERC721 Smart Contract
*/

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract SocietyCertificate is ERC721, Ownable, AccessControl
{
    using Strings for string;
    using Counters for Counters.Counter;

    uint public constant NUMBER_RESERVED_TOKENS = 3150;
    uint256 public price = 1e18; // The initial price to mint in WEI.
    uint256 public discount = 0;

    uint public currentSaleMaxTokens = 1;
    uint public perWalletMaxTokens = 6;

    bytes32 public merkleRoot;
    address[2] public winterWallets = [ 0xd541da4C37e268b9eC4d7D541Df19AdCf564c6A9, 0xe0CB05cBf3dBeb647394905848d9361Daa99dE28 ]; // usewinter.com, mainnet and testnet
    address public discountContract = 0xf6d7b55779eC71381e09eb1781bA7f0B6066da42;
    // Create a new role identifier for the roles
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");
    bytes32 public constant SALES_ROLE = keccak256("SALES_ROLE");

    bool public saleIsActive = false;
    bool public saleMaxLock = false;
    bool[] public discountUsed;

    Counters.Counter private _reservedSupply;
    Counters.Counter private _tokenSupply;
    string private _baseTokenURI; //The Base URI is the link to IPFS Folder holding the collections json files

    constructor() ERC721("Female Pleasure Society", "FPS") {  //Name of Project and Token "Ticker"
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(WITHDRAW_ROLE, msg.sender);
        _setupRole(SALES_ROLE, msg.sender);
    }  //Name of Project and Token "Ticker"

    function mintW(uint256 amount, address to) external payable //This function is for usewwinter.com Mint
    {
        require(to != address(0), "to missing!");
        require(msg.sender == winterWallets[0] || msg.sender == winterWallets[1], "invalid source Wallet");
        require(msg.sender == tx.origin, "No contracts!");
        require(saleIsActive, "Sale not active");
        require(msg.value >= price * amount, "Not enough ETH");
        require(_tokenSupply.current() + amount <= currentSaleMaxTokens, "Current Supply reached");
        require(balanceOf(to) + amount <= perWalletMaxTokens || to == winterWallets[0] || to == winterWallets[1], "reached per wallet limit!");

        for (uint i = 0; i < amount; i++)
        {
            _safeMint(to, _tokenSupply.current() + 1);
            _tokenSupply.increment();
        }
    }

    function mint(uint256 amount, address to, bytes32[] calldata proof, uint256 discountTokenId) external payable
    {
        require(to != address(0), "to missing!");
        require(msg.sender == tx.origin, "No contracts!");
        require(saleIsActive, "Sale not active");
        require(_tokenSupply.current() + amount <= currentSaleMaxTokens, "Current Supply reached");
        require( balanceOf(to) + amount <= perWalletMaxTokens, "reached per wallet limit!");
        require((merkleRoot == 0 || _verify(_leaf(msg.sender), proof)|| _verify(_leaf(to), proof)), "invalid merkle proof");
        require(discountTokenId <= discountUsed.length, "discountTokenId is out of range");
        require(_checkPrice(amount, discountTokenId), "Not enough ETH");

    for (uint i = 0; i < amount; i++)
        {
            _safeMint(to, _tokenSupply.current() + 1);
            _tokenSupply.increment();
        }
    }

    function flipSaleState() external onlyRole(SALES_ROLE){
        saleIsActive = !saleIsActive;
    }

    function mintReservedTokens(uint256 amount, address to) external onlyRole(SALES_ROLE){
        require(_reservedSupply.current() + amount <= NUMBER_RESERVED_TOKENS, "This amount is more than max allowed");
        require(to != address(0));
        for (uint i = 0; i < amount; i++)
        {
            _safeMint(to, _tokenSupply.current() + 1);
            _tokenSupply.increment();
            _reservedSupply.increment();
        }
    }

    function withdraw() external onlyRole(WITHDRAW_ROLE){
        payable(owner()).transfer(address(this).balance);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view
        override(ERC721, AccessControl) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyRole(ADMIN_ROLE){
            merkleRoot = _merkleRoot;
    }

    function setSaleMax(uint32 _limit, bool lockAfterUpdate) external onlyRole(SALES_ROLE){
        require(saleMaxLock == false , "saleMaxLock is set");
        saleMaxLock = lockAfterUpdate;
        currentSaleMaxTokens = _limit;
    }

    function setPrice(uint256 _price) external onlyRole(SALES_ROLE){
        price = _price;
    }

    function setWalletMax(uint16 _walletLimit) external onlyRole(SALES_ROLE){
        perWalletMaxTokens = _walletLimit;
    }

    function _setBaseURI(string memory baseURI) internal virtual {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _setBaseURI(baseURI);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        string memory _tokenURI = super.tokenURI(tokenId);
        return bytes(_tokenURI).length > 0 ? string(abi.encodePacked(_tokenURI, ".json")) : "";
    }

    function supply() external view returns (uint256) {
        return _tokenSupply.current();
    }

    function reservedTokensMinted() external view returns (uint256) {
        return _reservedSupply.current();
    }

    function _leaf(address account)
    internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(account));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof)
    internal view returns (bool)
    {
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    function _checkPrice(uint256 amount, uint256 discountTokenId)
    internal returns (bool)
    {
        if (msg.value >= price * amount) {
            return true;
        } else if (discountTokenId > 0 && discountTokenId <= discountUsed.length && amount == 1 && _walletHoldsUnusedDiscountToken(msg.sender, discountContract, discountTokenId)) {
            uint256 discountedPrice = price - discount; // discount in wei
            if (msg.value >= discountedPrice) {
                discountUsed[discountTokenId - 1] = true;
                return true;
            }
        }
        return false;
    }

    function _walletHoldsUnusedDiscountToken(address _wallet, address _contract, uint256 discountTokenId) internal view returns (bool) {
        if ((discountTokenId <= discountUsed.length || discountUsed[discountTokenId - 1] == false) && IERC721(_contract).ownerOf(discountTokenId) == _wallet) {
            return true;
        }
        return false;
    }

    function setDiscountContract(address _discountContract, uint256 _maxTokenId, uint256 _discount) external onlyRole(ADMIN_ROLE) {
        if (discountContract != _discountContract) {
            // reset all tokenId states to false
            discountUsed = new bool[](_maxTokenId);
        }
        discountContract = _discountContract;
        discount = _discount;
    }
}