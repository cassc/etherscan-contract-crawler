// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";


contract Gen0Mebots is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    using SafeMath for uint256; 
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    mapping(bytes => bool) private signatureUsed;

    string public baseTokenURI;
    string public baseContractURI;
    uint96 royaltyFeesInBips;
    address royaltyAddress;

    uint public constant MAX_SUPPLY = 9999;
    uint public constant MAX_PREMINT_SUPPLY = 2000;
    uint public constant MAX_PREMINT_SIGNATURE_SUPPLY = 2000;
    uint public constant MAX_PER_MINT = 10;
    uint public constant MAX_PER_PREMINT = 1;
    uint256 public constant PRICE = 0.1 ether;
    uint256 public constant PREMINT_PRICE = 0.02 ether;

    bool private isPreMintActive;
    bool private isSaleActive;
    bool private allFrozen;

    struct SaleConfig {
        uint256 preMintPrice;
        uint256 publicPrice;
        uint preMintSupply;
        uint preMintSignatureSupply;
    }
    SaleConfig public saleConfig;

    string private _baseTokenURI;

    constructor(string memory baseURI) ERC721("Gen0-Mebots", "MEBOT0") {
        isPreMintActive = false;
        isSaleActive = false;
        allFrozen = false;
    
        setBaseURI(baseURI);
        saleConfig = SaleConfig(
            PREMINT_PRICE,
            PRICE,
            MAX_PREMINT_SUPPLY,
            MAX_PREMINT_SIGNATURE_SUPPLY
        );
    }

    function preMintNFT() public payable {
        uint256 price = saleConfig.preMintPrice;
        uint preMintSupply = saleConfig.preMintSupply;
        uint totalMinted = _tokenIdCounter.current();

        require(isPreMintActive, "Pre-mint is not active.");
        require(totalMinted < preMintSupply, "Not enough pre-mint NFTs left.");
        require(msg.value >= price, "Not enough ether to mint NFT.");

        _mintSingleNFT();
    }

    function mintNFTSignature(bytes32 _hash, bytes memory _signature) public payable {
        uint256 price = saleConfig.preMintPrice;
        uint preMintSignatureSupply = saleConfig.preMintSignatureSupply;
        uint totalMinted = _tokenIdCounter.current();

        require(isPreMintActive, "Pre-mint is not active.");
        require(totalMinted < preMintSignatureSupply, "Not enough NFTs left.");
        require(msg.value >= price, "Not enough ether to mint NFT.");
        require(owner() == recoverSigner(_hash, _signature), "Address is not allowlisted.");
        require(!signatureUsed[_signature], "Signature has already been used.");

        signatureUsed[_signature] = true;
        _mintSingleNFT();
    }

    function mintNFTs(uint _count) public payable {
        uint256 price = saleConfig.publicPrice;
        uint totalMinted = _tokenIdCounter.current();

        require(isSaleActive, "Mint is not active.");
        require(_count > 0 && _count <= MAX_PER_MINT, "Cannot mint specified number of NFTs.");
        require(totalMinted + _count <= MAX_SUPPLY, "Not enough NFTs left.");
        require(msg.value >= price.mul(_count), "Not enough ether to mint NFTs.");

        for (uint i = 0; i < _count; i++) {
            _mintSingleNFT();
        }
    }

    function reserveNFTs() external onlyOwner {
        uint totalMinted = _tokenIdCounter.current();

        require(totalMinted.add(50) < MAX_SUPPLY, "Not enough NFTs left to reserve.");

        for (uint i = 0; i < 50; i++) {
            _mintSingleNFT();
        }
    }

    function _mintSingleNFT() private {
        uint tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        require(!allFrozen, "Already frozen");
        _baseTokenURI = baseURI;
    }

    function flipPreMintState() external onlyOwner {
        isPreMintActive = !isPreMintActive;
    }

    function flipMintState() external onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function freezeAll() external onlyOwner {
        allFrozen = true;
    }

    function withdraw() external payable onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");

        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");
    }

    function setupSaleInfo(uint256 _preMintPrice, uint256 _publicPrice, uint _preMintSupply, uint _preMintSignatureSupply) external onlyOwner {

        require(_preMintSupply <= MAX_SUPPLY, 'Supply out of bounds.');
        require(_preMintSignatureSupply <= MAX_SUPPLY, 'Supply out of bounds.');

        saleConfig = SaleConfig(
            _preMintPrice,
            _publicPrice,
            _preMintSupply,
            _preMintSignatureSupply
        );
    }

    function recoverSigner(bytes32 _hash, bytes memory _signature) public pure returns (address) {
        bytes32 messageDigest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash));
        return ECDSA.recover(messageDigest, _signature);
    }

    function tokensOfOwner(address _owner) external view returns (uint[] memory) {

        uint tokenCount = balanceOf(_owner);
        uint[] memory tokensId = new uint256[](tokenCount);

        for (uint i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function setContractURI(string calldata _contractURI) public onlyOwner {
        baseContractURI = _contractURI;
    }

    function contractURI() public view returns (string memory) {
        return baseContractURI;
    }

    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesInBips) public onlyOwner {
        royaltyAddress = _receiver;
        royaltyFeesInBips = _royaltyFeesInBips;
    }

    function royaltyInfo(uint256 _salePrice)
        external
        view
        virtual
        returns (address, uint256)
    {
        return (royaltyAddress, calculateRoyalty(_salePrice));
    }

    function calculateRoyalty(uint256 _salePrice) view public returns (uint256) {
        return (_salePrice / 10000) * royaltyFeesInBips;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}