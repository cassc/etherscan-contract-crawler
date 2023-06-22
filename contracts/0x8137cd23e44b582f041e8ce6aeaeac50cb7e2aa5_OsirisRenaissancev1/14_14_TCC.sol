// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import { IERC2981, IERC165 } from "./IERC2981.sol";
import "./ERC165.sol";
import "./ERC721.sol";

contract OsirisRenaissancev1 is ERC721, IERC2981, Ownable, ReentrancyGuard {
    // Declarations
    using Strings for uint256;
    uint256 private MAX_SUPPLY = 100;
    uint256 private _currentId;
    uint256 public totalBatches;
    string public baseURI;
    string private _contractURI;
    bool public isActive = false;
    bool public isWLActive = false;
    address public beneficiary;
    address public royalties;

    constructor(
        address _beneficiary,
        address _royalties,
        string memory _initialBaseURI,
        string memory _initialContractURI
    ) ERC721("Joey Capitano", "JCM") {
        beneficiary = _beneficiary;
        royalties = _royalties;
        baseURI = _initialBaseURI;
        _contractURI = _initialContractURI;
    }

    struct Batch {
        string name;
        uint256 maxSupply;
        uint256 currentSupply;
        uint256 price;
        bool isActive;
    }

    // Mappings
    // Add a mapping to store Allowed Minters
    mapping(address => uint256) public allowedMinters;

    // Add a mapping to store the Batchs
    mapping(uint256 => Batch) public Batchs;

    // Add a nested mapping to store the whitelisted addresses for each Batch
    mapping(uint256 => mapping(address => uint256)) public whitelisted;

    // Add a mapping to store the batchOfToken
    mapping(uint256 => uint256) public batchOfToken;

    // Add a mapping for the blacklist
    mapping(uint256 => bool) public blacklistedTokens;
    mapping(address => bool) public blacklistedAddresses;
    event TokenURICreated(uint256 indexed tokenId, string uri);
    event TokenRemovedFromBlacklist(uint256 indexed tokenId);

    // Accessors

    function setBeneficiary(address _beneficiary) public onlyOwner {
        beneficiary = _beneficiary;
    }

    // Royalty percentage, initially set to 10%
    uint256 public royaltyPercentage = 10;

    function setRoyalties(address _royalties) public onlyOwner {
        royalties = _royalties;
    }

    // Set royalty percentage
    function setRoyaltyPercentage(uint256 _royaltyPercentage) public onlyOwner {
        require(_royaltyPercentage >= 0 && _royaltyPercentage <= 100, "Invalid royalty percentage");
        royaltyPercentage = _royaltyPercentage;
    }

    function setPublicActive(bool _isActive) public onlyOwner {
        isActive = _isActive;
    }

    function setWLActive(bool _isWLActive) public onlyOwner {
        isWLActive = _isWLActive;
    }

    function totalSupply() public view returns (uint256) {
        return _currentId;
    }

    // Metadata

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        require(_maxSupply > 0, "Max supply cannot be 0");
        require(_maxSupply > _currentId, "Max supply cannot be less than current supply");
        MAX_SUPPLY = _maxSupply;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string memory uri) public onlyOwner {
        _contractURI = uri;
    }

    // Minting
    // Whitelist Minting
    function mint(uint256 BatchId, uint256 amount, bool isWhitelisted) public payable nonReentrant {
        address sender = _msgSender();
        require(!blacklistedAddresses[sender], "Transfer to a blacklisted address is not allowed");
        require(Batchs[BatchId].isActive, "Batch is closed");
        require(_currentId + amount <= MAX_SUPPLY, "Insufficient mints left");
        require(msg.value == Batchs[BatchId].price * amount, "Incorrect payable amount");

        if (isWLActive) {
            require(isWhitelisted, "Whitelist mint is not active");
            require(whitelisted[BatchId][sender] >= amount, "Not allowed to mint this amount");
            whitelisted[BatchId][sender] -= amount;
        } else {
            require(isActive, "Public mint is not active at the moment.");
        }

        uint256 SpotId = Batchs[BatchId].currentSupply + 1;
        _internalMint(sender, amount, BatchId, SpotId);
    }

    // Owner Minting
    function ownerMint(uint256 BatchId, uint256 amount) public onlyOwner nonReentrant {
        require(Batchs[BatchId].isActive, "Batch is closed");
        require(_currentId + amount <= MAX_SUPPLY, "Insufficient mints left");

        uint256 SpotId = Batchs[BatchId].currentSupply + 1;
        _internalMint(owner(), amount, BatchId, SpotId);
    }

    // Withdrawal
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        uint256 royaltyAmount;
        uint256 beneficiaryAmount;

        // Check if royalty account address is the same as the beneficiary address
        if (royalties == beneficiary) {
            // Send everything to the beneficiary
            beneficiaryAmount = balance;
        } else {
            // Calculate the royalty based on the royalty percentage and the amount for the beneficiary
            royaltyAmount = balance * royaltyPercentage / 100;
            beneficiaryAmount = balance - royaltyAmount;
            payable(royalties).transfer(royaltyAmount); // Transfer royalty to the royalty account
        }
        payable(beneficiary).transfer(beneficiaryAmount); // Transfer the remaining amount to the beneficiary
    }

    // Disburse Abritrary Revenue To Token Owner
    function disburseRevenue(uint256 tokenId) public onlyOwner payable {
        address tokenOwner = ownerOf(tokenId);
        require(!blacklistedAddresses[tokenOwner], "Transfer to a blacklisted address is not allowed");
        payable(tokenOwner).transfer(msg.value);
    }

    // Override Token URI Function
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (blacklistedTokens[tokenId]) {
            return string(abi.encodePacked(baseURI, "/blacklisted"));
        }

        uint256 batchId = batchOfToken[tokenId];
        uint256 spotId;

        string memory batchName = Batchs[batchId].name;

        if (batchId == 1) {
            spotId = tokenId;
        } else {
            uint256 previousBatchesMaxSupply = 0;
            for (uint256 i = 1; i < batchId; i++) {
                previousBatchesMaxSupply += Batchs[i].maxSupply;
            }
            spotId = tokenId - previousBatchesMaxSupply;
        }

        return string(abi.encodePacked(baseURI, "/", batchName, "/", spotId.toString(), "/metadata.json"));
    }

    function checkTokensByOwner(address wallet) public view returns (bool, uint256[] memory) {
        uint256[] memory ownedTokens;
        uint256 tokenCount = 0;

        for (uint256 batchId = 1; batchId <= totalBatches; batchId++) {
            uint256 batchStartId = getBatchStartId(batchId);
            uint256 batchEndId = getBatchEndId(batchId);

            for (uint256 tokenId = batchStartId; tokenId <= batchEndId; tokenId++) {
                try this.ownerOf(tokenId) returns (address owner) {
                    if (owner == wallet) {
                        tokenCount++;
                        // Resize the array and add the token ID
                        ownedTokens = resizeAndAddToArray(ownedTokens, tokenId);
                    }
                } catch {
                    // Error occurred, continue to the next token ID
                }
            }
        }

        return (tokenCount > 0, ownedTokens);
    }

    function resizeAndAddToArray(uint256[] memory array, uint256 newElement) private pure returns (uint256[] memory) {
        uint256[] memory resizedArray = new uint256[](array.length + 1);
        for (uint256 i = 0; i < array.length; i++) {
            resizedArray[i] = array[i];
        }
        resizedArray[array.length] = newElement;
        return resizedArray;
    }


    function getBatchStartId(uint256 batchId) private view returns (uint256) {
        uint256 previousBatchesMaxSupply = 0;
        for (uint256 i = 1; i < batchId; i++) {
            previousBatchesMaxSupply += Batchs[i].maxSupply;
        }
        return previousBatchesMaxSupply + 1;
    }

    function getBatchEndId(uint256 batchId) private view returns (uint256) {
        uint256 batchStartId = getBatchStartId(batchId);
        return batchStartId + Batchs[batchId].currentSupply - 1;
    }


    // Add Batch
    function addBatch(uint256 batchId, string memory batchName, uint256 maxSupply, uint256 price) public onlyOwner {
        require(batchId > 0, "Batch ID must be greater than 0");

        // Calculate the total max supply after adding this batch
        uint256 newTotalMaxSupply = 0;
        for (uint256 i = 1; i < batchId; i++) {
            newTotalMaxSupply += Batchs[i].maxSupply;
        }
        newTotalMaxSupply += maxSupply;

        require(newTotalMaxSupply <= MAX_SUPPLY, "Adding this batch would exceed the max supply of the contract");

        Batchs[batchId] = Batch(batchName, maxSupply, 0, price, false);
        totalBatches++;
    }

    // Set Batch to Active
    function setBatchActive(uint256 BatchId, bool _isActive) public onlyOwner {
        Batchs[BatchId].isActive = _isActive;
    }

    // Add functions to manage the whitelist
    // Add to Whitelist
    function addToWhitelist(uint256 BatchId, address user, uint256 amount) public onlyOwner {
        whitelisted[BatchId][user] = amount;
    }

    // Remove from Whitelist
    function removeFromWhitelist(uint256 BatchId, address user) public onlyOwner {
        delete whitelisted[BatchId][user];
    }

    // Private
    // Internal Mint Function
    function _internalMint(address to, uint256 amount, uint256 BatchId, uint256 SpotId) private {
        require(BatchId > 0 && BatchId <= totalBatches, "Invalid BatchId");
        require(_currentId + amount <= MAX_SUPPLY, "Will exceed maximum supply");
        require(Batchs[BatchId].currentSupply + amount <= Batchs[BatchId].maxSupply, "Exceeds Batch maximum supply");

        for (uint256 i = 0; i < amount; i++) {
            uint256 previousBatchesMaxSupply = 0;
            for (uint256 j = 1; j < BatchId; j++) {
                previousBatchesMaxSupply += Batchs[j].maxSupply;
            }
            uint256 tokenId = previousBatchesMaxSupply + SpotId + i;

            _safeMint(to, tokenId);
            batchOfToken[tokenId] = BatchId;
            string memory uri = tokenURI(tokenId);
            emit TokenURICreated(tokenId, uri);
        }

        _currentId += amount;
        Batchs[BatchId].currentSupply += amount;
    }

    // Add functions to manage the blacklist
    // Add to Blacklist
    function blacklistToken(uint256 tokenId) public onlyOwner {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        address tokenOwner = ownerOf(tokenId);
        require(tokenOwner != owner(), "Cannot blacklist the contract owner");
        blacklistedTokens[tokenId] = true;
        blacklistedAddresses[tokenOwner] = true;
        string memory uri = tokenURI(tokenId);
        emit TokenURICreated(tokenId, uri);
    }

    // Reissue Blacklisted Token to Previous Owner
    function reissueBlacklistedToken(uint256 tokenId, address newOwner) public onlyOwner {
        require(blacklistedTokens[tokenId], "Token is not blacklisted");
        blacklistedTokens[tokenId] = false;
        _transfer(ownerOf(tokenId), newOwner, tokenId);
    }

    // Remove from Blacklist
    function removeFromBlacklist(uint256 tokenId) public onlyOwner {
        require(blacklistedTokens[tokenId], "Token is not blacklisted");
        blacklistedTokens[tokenId] = false;
        address tokenOwner = ownerOf(tokenId);
        blacklistedAddresses[tokenOwner] = false;
        emit TokenRemovedFromBlacklist(tokenId);
    }

    // Override Transfer Function
    function _transfer(address from, address to, uint256 tokenId) internal override {
        require(!blacklistedAddresses[to], "Transfer to a blacklisted address is not allowed");
        super._transfer(from, to, tokenId);
    }

    // ERC165
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165) returns (bool) {
    return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    // IERC2981
    // Royalty
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override returns (address, uint256 royaltyAmount) {
        _tokenId; // silence solc warning
        royaltyAmount = (_salePrice * royaltyPercentage) / 100;
        return (royalties, royaltyAmount);
    }
}