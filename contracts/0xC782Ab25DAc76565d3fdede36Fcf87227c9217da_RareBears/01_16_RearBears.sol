// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract RareBears is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using ECDSA for bytes32;
    using Counters for Counters.Counter;

    Counters.Counter public _tokenIdCounter;

    string private _baseTokenURI;
    string private _contractURI;

    uint256 public maxSupply;

    mapping(string => uint256) private maxMintQty;

    mapping(address => uint256) private mintedPresaleAddresses;
    mapping(address => uint256) private mintedPublicsaleAddresses;

    address private _internalSignerAddress;
    address private _withdrawalAddress;

    uint256 public pricePerToken;
    bool public metadataIsLocked;
    bool public publicSaleLive;
    bool public presaleLive;

    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        address internalSignerAddress,
        address withdrawalAddress,
        string memory initContractURI,
        string memory initBaseTokenURI
    ) ERC721(tokenName, tokenSymbol) {
        _internalSignerAddress = internalSignerAddress;
        _withdrawalAddress = withdrawalAddress;
        _contractURI = initContractURI;
        _baseTokenURI = initBaseTokenURI;
        _tokenIdCounter.increment();
        maxSupply = 7777;
        maxMintQty["whitelist"] = 2;
        maxMintQty["og"] = 3;
        maxMintQty["public"] = 3;
        maxMintQty["mod1"] = 5;
        maxMintQty["mod2"] = 4;
        maxMintQty["mod3"] = 3;
        pricePerToken = 0.18 ether;
        metadataIsLocked = false;
        publicSaleLive = false;
        presaleLive = false;
    }

    function mint(uint256 qty) external payable nonReentrant {
        uint256 mintedAmount = mintedPublicsaleAddresses[msg.sender];

        require(publicSaleLive, "Public Sale not live");
        require(
            mintedAmount + qty <= maxMintQty["public"],
            "Exceeded maximum quantity"
        );
        require(_tokenIdCounter.current() + qty <= maxSupply, "Out of stock");
        require(pricePerToken * qty == msg.value, "Invalid value");

        for (uint256 i = 0; i < qty; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenId);
        }
        mintedPublicsaleAddresses[msg.sender] = mintedAmount + qty;
    }

    function presaleMint(
        bytes32 hash,
        bytes memory sig,
        uint256 qty,
        string memory mintType
    ) external payable nonReentrant {
        uint256 mintedAmount = mintedPresaleAddresses[msg.sender];

        require(presaleLive, "Presale not live");
        require(hashData(msg.sender, mintType) == hash, "Hash check failed");
        require(
            mintedAmount + qty <= maxMintQty[mintType],
            "Exceeded maximum quantity"
        );
        require(isInternalSigner(hash, sig), "Direct mint unavailable");
        require(pricePerToken * qty == msg.value, "Invalid value");

        for (uint256 i = 0; i < qty; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenId);
        }
        mintedPresaleAddresses[msg.sender] = mintedAmount + qty;
    }

    function adminMint(uint256 qty, address to) external payable onlyOwner {
        require(qty > 0, "minimum 1 token");
        require(_tokenIdCounter.current() + qty <= maxSupply, "Out of stock");
        for (uint256 i = 0; i < qty; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(to, tokenId);
        }
    }

    function burn(uint256 tokenId) public virtual {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "caller is not owner nor approved"
        );
        _burn(tokenId);
    }

    function tokenExists(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }

    function isApprovedOrOwner(address _spender, uint256 _tokenId)
        external
        view
        returns (bool)
    {
        return _isApprovedOrOwner(_spender, _tokenId);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            string(
                abi.encodePacked(_baseTokenURI, _tokenId.toString(), ".json")
            );
    }

    function withdrawEarnings() external onlyOwner {
        (bool success, ) = payable(_withdrawalAddress).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }

    function changePrice(uint256 newPrice) external onlyOwner {
        pricePerToken = newPrice;
    }

    function togglePresaleStatus() external onlyOwner {
        presaleLive = !presaleLive;
    }

    function togglePublicSaleStatus() external onlyOwner {
        publicSaleLive = !publicSaleLive;
    }

    function changeMaxMintQty(string memory mintType, uint256 qty)
        external
        onlyOwner
    {
        maxMintQty[mintType] = qty;
    }

    function getMaxMintQty(string memory mintType)
        external
        view
        returns (uint256)
    {
        return maxMintQty[mintType];
    }

    function getMintedPresaleAddresses(address _address)
        external
        view
        returns (uint256)
    {
        return mintedPresaleAddresses[_address];
    }

    function getMintedPublicsaleAddresses(address _address)
        external
        view
        returns (uint256)
    {
        return mintedPublicsaleAddresses[_address];
    }

    function setNewMaxSupply(uint256 newMaxSupply) external onlyOwner {
        require(newMaxSupply < maxSupply, "you can only decrease it");
        maxSupply = newMaxSupply;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        require(!metadataIsLocked, "Metadata is locked");
        _baseTokenURI = newBaseURI;
    }

    function setContractURI(string memory newuri) external onlyOwner {
        require(!metadataIsLocked, "Metadata is locked");
        _contractURI = newuri;
    }

    function setWithdrawalAddress(address withdrawalAddress)
        external
        onlyOwner
    {
        _withdrawalAddress = withdrawalAddress;
    }

    function hashData(address sender, string memory transactionType)
        private
        pure
        returns (bytes32)
    {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encode(sender, transactionType))
            )
        );
        return hash;
    }

    function isInternalSigner(bytes32 hash, bytes memory signature)
        private
        view
        returns (bool)
    {
        return _internalSignerAddress == hash.recover(signature);
    }

    function setInternalSigner(address addr) external onlyOwner {
        _internalSignerAddress = addr;
    }

    function getInternalSigner() external view onlyOwner returns (address) {
        return _internalSignerAddress;
    }

    function getWithdrawalAddress() external view onlyOwner returns (address) {
        return _withdrawalAddress;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function lockMetaData() external onlyOwner {
        metadataIsLocked = true;
    }
}