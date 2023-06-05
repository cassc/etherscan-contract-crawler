// SPDX-License-Identifier: MIT
// Contract developed and tested by CPI Technologies GmbH (cpitech.io)

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract SuriFrey is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Address for address payable;

    event Mint(uint256 tokenId);
    event PriceChanged(uint256 newPrice);
    event TemporarySupplyLimitChanged(uint256 newLimit);
    event MetadataFrozen();
    event ProductIDSet(uint256 tokenId, string productID);

    Counters.Counter private _tokenIdCounter;

    // Total supply limit
    uint256 private constant TOTAL_SUPPLY_LIMIT = 4200;

    // Mapping from token ID to product ID
    mapping (uint256 => string) private _tokenProductIDs;

    // Mapping from address to number of minted tokens
    mapping (address => uint256) private _mintedTokens;

    // Base URI
    string private _baseURIextended;

    // Metadata frozen flag
    bool private _metadataFrozen = false;

    // Minting limit per address
    uint256 private _mintingLimitPerAddress = 2;

    // Temporary supply limit - used for different phases of the offering
    uint256 public temporarySupplyLimit = TOTAL_SUPPLY_LIMIT;

    // Price to mint an NFT
    uint256 public price = 0.001 ether;

    // Fee receiver
    address payable public feeReceiver;


    constructor(string memory name_, string memory symbol_, string memory baseURI_, address feeReceiver_) ERC721(name_, symbol_) {
        _baseURIextended = baseURI_;
        feeReceiver = payable(feeReceiver_);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function baseURI() external view returns (string memory) {
        return _baseURIextended;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        require(!_metadataFrozen, "Metadata is frozen");
        _baseURIextended = baseURI_;
    }

    function totalSupply() public view returns (uint256) {
        return TOTAL_SUPPLY_LIMIT;
    }

    function freezeMetadata() public onlyOwner {
        _metadataFrozen = true;
        emit MetadataFrozen();
    }

    function setProductID(uint256 tokenId, string memory productID) public onlyOwner {
        require(bytes(_tokenProductIDs[tokenId]).length == 0, "Product ID already set");
        require(tokenId <= _tokenIdCounter.current(), "Token ID does not exist");

        _tokenProductIDs[tokenId] = productID;
        emit ProductIDSet(tokenId, productID);
    }

    function tokenProductID(uint256 tokenId) public view returns (string memory) {
        return _tokenProductIDs[tokenId];
    }

    function changePrice(uint256 newPrice) public onlyOwner {
        require(newPrice >= 0, "Price must be greater than zero");

        price = newPrice;
        emit PriceChanged(newPrice);
    }

    function setTemporarySupplyLimit(uint256 newLimit) public onlyOwner {
        require(newLimit <= TOTAL_SUPPLY_LIMIT, "Temporary supply limit exceeds total supply limit");
        temporarySupplyLimit = newLimit;
        emit TemporarySupplyLimitChanged(newLimit);
    }

    function getMintableCount() public view returns (uint256) {
        if (_tokenIdCounter.current() < temporarySupplyLimit) {
            return temporarySupplyLimit - _tokenIdCounter.current();
        } else {
            return 0;
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(_baseURI()).length > 0 ? string(abi.encodePacked(_baseURI(), _toString(tokenId), ".json")) : "";
    }

    function mint(address _to, uint256 _quantity) external payable {
        require(_tokenIdCounter.current() + _quantity <= temporarySupplyLimit, "Exceeds temporary supply limit");
        require(_mintedTokens[_to] + _quantity <= _mintingLimitPerAddress, "Exceeds minting limit per address");
        require(msg.value == price * _quantity, "Ether value sent is not correct");

        for (uint256 i = 0; i < _quantity; i++) {
            _tokenIdCounter.increment();
            uint256 tokenId = _tokenIdCounter.current();
            _mint(_to, tokenId);
            _mintedTokens[_to] += 1;
            emit Mint(tokenId);
        }
    }

    function withdraw() public onlyOwner {
        feeReceiver.sendValue(address(this).balance);
    }

    function setMintingLimitPerAddress(uint256 newLimit) public onlyOwner {
        _mintingLimitPerAddress = newLimit;
    }

    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}