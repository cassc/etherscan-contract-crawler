// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../erc721-pepe/v2/interfaces/IERC721PepeV2.sol";
import "./interfaces/IGoldenTicket.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
contract GoldenTicket is IERC165, ERC721Enumerable, IGoldenTicket, Ownable {
    using Strings for uint256;

    uint256 public price = 1 ether / 50; // 0.02
    uint256 public burnAmount = 2;

    uint256 public deadline;
    uint256 public maxSupply;

    IERC721PepeV2 public erc721PepeContract;

    uint256 public nextTokenId = 1;
    string public baseURI = "";

    event PepeUpdate(address _pepeContract);
    event BaseUriUpdate(string _baseUri);
    event PriceUpdate(uint256 _price);
    event DeadlineUpdate(uint256 _deadline);
    event MaxSupplyUpdate(uint256 _maxSupply);
    event MetadataUpdate(uint256 _tokenId);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    constructor(string memory name_, string memory symbol_, address _erc721PepeContractAddress, string memory uri, uint256 _deadline, uint256 _maxSupply) ERC721(name_, symbol_) {
        erc721PepeContract = IERC721PepeV2(_erc721PepeContractAddress);
        baseURI = uri;
        deadline = _deadline;
        maxSupply = _maxSupply;
    }

    function setErc721Pepe(address _erc721PepeContractAddress) external override onlyOwner {
        erc721PepeContract = IERC721PepeV2(_erc721PepeContractAddress);
        emit PepeUpdate(_erc721PepeContractAddress);
    }

    function setBaseURI(string memory uri) external override onlyOwner {
        baseURI = uri;
        emit BaseUriUpdate(uri);
        emit BatchMetadataUpdate(0, type(uint256).max);
    }

    function setPrice(uint256 _price) external override onlyOwner {
        price = _price;
        emit PriceUpdate(_price);
    }

    function setDeadline(uint256 _deadline) external override onlyOwner {
        deadline = _deadline;
        emit DeadlineUpdate(_deadline);
    }

    function setMaxSupply(uint256 _maxSupply) external override onlyOwner {
        maxSupply = _maxSupply;
        emit MaxSupplyUpdate(_maxSupply);
    }

    function mintingEnabled() public view returns (bool) {
        return nextTokenId <= maxSupply && deadline > block.timestamp;
    }

    function mintGoldenTicketViaBurn(uint256 amountToBuy, uint256[] calldata tokenIds) external override {
        require(nextTokenId + amountToBuy - 1 <= maxSupply, "Buy exceeds the max supply of golden tickets");
        require(deadline > block.timestamp, "Past the deadline to mint golden tickets");
        require(tokenIds.length == burnAmount * amountToBuy, "Invalid amount of tokenIds for amount to buy");

        for (uint256 i = 0; i < amountToBuy; i++) {
            uint256 tokenId1 = tokenIds[i * 2];
            uint256 tokenId2 = tokenIds[(i * 2) + 1];
            erc721PepeContract.transferFrom(msg.sender, address(this), tokenId1);
            erc721PepeContract.transferFrom(msg.sender, address(this), tokenId2);

            erc721PepeContract.burn(tokenId1);
            erc721PepeContract.burn(tokenId2);

            _mint(msg.sender, nextTokenId++);
        }
    }

    function mintGoldenTicketViaETH(uint256 amountToBuy) external override payable {
        require(nextTokenId + amountToBuy - 1 <= maxSupply, "Buy exceeds the max supply of golden tickets");
        require(deadline > block.timestamp, "Past the deadline to mint golden tickets");
        require(msg.value == price * amountToBuy, "Invalid amount of ether for amount to buy");

        for (uint256 tokensLeftToMint = amountToBuy; tokensLeftToMint != 0; tokensLeftToMint--) {
            _mint(msg.sender, nextTokenId++);
        }
    }

    function mintGoldenTicketViaAdmin(uint256 amountToBuy) external override onlyOwner {
        require(nextTokenId + amountToBuy - 1 <= maxSupply, "Buy exceeds the max supply of golden tickets");

        for (uint256 tokensLeftToMint = amountToBuy; tokensLeftToMint != 0; tokensLeftToMint--) {
            _mint(msg.sender, nextTokenId++);
        }
    }

    /**
     * Returns tokenIds from start to end (end not included)
     * where start and end represent the index of tokens owned by the passed in user
     */
    function tokensByOwner(address owner, uint256 startIndex, uint256 endIndex) public view returns (uint256[] memory) {
        require(endIndex > startIndex, "End index must be greater than start index");
        uint256 length = ERC721.balanceOf(owner);
        require(length >= endIndex, "End index cannot be greater than length of tokens for this owner");

        uint256[] memory itemList = new uint256[](endIndex - startIndex);
        uint256 elementIndex = 0;
        for (uint256 i = startIndex; (i < length && i < endIndex); i++) {
            itemList[elementIndex] = tokenOfOwnerByIndex(owner, i);
            elementIndex++;
        }
        return itemList;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        _requireMinted(_tokenId);

        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"))
            : '';
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function updateMetadata(uint256 _tokenId) external onlyOwner {
         _requireMinted(_tokenId);
        emit MetadataUpdate(_tokenId);
    }

    function batchUpdateMetadata(uint256 fromTokenId, uint256 toTokenId) external onlyOwner {
        require(fromTokenId <= toTokenId, "invalid range");
        emit BatchMetadataUpdate(fromTokenId, toTokenId);
    }

    function batchUpdateMetadata(uint256[] memory tokenIds) external onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            emit MetadataUpdate(tokenIds[i]);
        }
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721Enumerable) returns (bool) {
        // ERC-4906: EIP-721 Metadata Update Extension
        return interfaceId == bytes4(0x49064906) || super.supportsInterface(interfaceId);
    }
}