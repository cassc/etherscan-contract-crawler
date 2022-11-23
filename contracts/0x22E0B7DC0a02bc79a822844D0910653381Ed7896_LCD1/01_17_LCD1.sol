// SPDX-License-Identifier: MIT

// █    ██ ██  ▒▒
// █   █   █ █  ▒
// █   █   █ █  ▒
// ███  ██ ██  ▒▒▒

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract LCD1 is ERC721, ERC721Enumerable, ERC721Royalty, Ownable {
    error InvalidPrice(address emitter);
    error SaleNotStarted(address emitter);
    error SoldOut(address emitter);
    error EtherTransferFail(address emitter);

    event PhysicalDeviceRequested(address sender, uint256 tokenId);
    event Sold(address indexed to, uint256 price, uint256 tokenId);

    using Strings for uint256;

    struct PhysicalDeviceRequest {
        bool entity;
        bool requested;
        address requester;
        uint256 timestamp;
    }

    uint256 public constant MAX_SUPPLY = 41;

    uint256[] public AUCTION_PRICES = [12 ether, 10 ether, 8 ether, 6 ether, 5 ether, 4 ether, 3.5 ether, 3 ether, 2.5 ether];

    uint256 public constant AUCTION_PRICE_CHANGE_TIME = 6 minutes;

    string public baseTokenUri;

    uint256 public currentMintTokenId = 1;

    uint256 public auctionStartTime;

    uint256 public publicMintAmount;

    mapping(uint256 => PhysicalDeviceRequest) physicalDeviceRequests;

    constructor(
        address _owner,
        string memory _name,
        string memory _symbol,
        string memory _tokenUri,
        uint256 _saleStart,
        uint256 _reserveStartingIndex,
        address _royalReceiver,
        uint96 _royalFeeNumerator
    ) payable ERC721(_name, _symbol) {
        baseTokenUri = _tokenUri;
        auctionStartTime = _saleStart;
        publicMintAmount = MAX_SUPPLY - 1 - (MAX_SUPPLY - _reserveStartingIndex);

        _safeMint(_owner, 0);
        for (uint256 i = _reserveStartingIndex; i < MAX_SUPPLY; ++i) {
            _safeMint(_owner, i);
        }

        if (_royalReceiver != address(0)) {
            _setDefaultRoyalty(_royalReceiver, _royalFeeNumerator);
        }

        _transferOwnership(_owner);
    }

    function mint() public payable {
        if (totalSupply() >= MAX_SUPPLY) revert SoldOut(address(this));
        if (block.timestamp < auctionStartTime) {
            revert SaleNotStarted(address(this));
        }

        uint256 price = currentPrice();
        if (msg.value != price) revert InvalidPrice(address(this));

        emit Sold(msg.sender, price, currentMintTokenId);
        _safeMint(msg.sender, currentMintTokenId);
        ++currentMintTokenId;
    }

    function currentPrice() public view returns (uint256) {
        if (block.timestamp < auctionStartTime)
            return AUCTION_PRICES[0];

        uint256 index = (block.timestamp - auctionStartTime) / AUCTION_PRICE_CHANGE_TIME;
        uint256 priceIndex = index >= AUCTION_PRICES.length ? AUCTION_PRICES.length - 1 : index;
        return AUCTION_PRICES[priceIndex];
    }

    function currentOwners() public view returns (uint256[MAX_SUPPLY] memory, address[MAX_SUPPLY] memory, PhysicalDeviceRequest[MAX_SUPPLY] memory) {
        uint256[MAX_SUPPLY] memory tokenIds;
        address[MAX_SUPPLY] memory owners;
        PhysicalDeviceRequest[MAX_SUPPLY] memory requestedDevices;

        for (uint256 i; i < MAX_SUPPLY; ++i) {
            if (_exists(i)) {
                tokenIds[i] = i;
                owners[i] = ownerOf(i);
                requestedDevices[i] = physicalDeviceRequests[i];
            }
        }
        return (tokenIds, owners, requestedDevices);
    }

    function auctionPrices() public view returns (uint256[] memory) {
        uint256 priceCount = AUCTION_PRICES.length;
        uint256[] memory _prices = new uint256[](priceCount);
        for (uint256 i; i < priceCount; ++i) {
            _prices[i] = AUCTION_PRICES[i];
        }
        return _prices;
    }

    function requestDevice(uint256 tokenId) public {
        require(_exists(tokenId), "Token does not exists");
        require(ownerOf(tokenId) == msg.sender, "not authorized");
        PhysicalDeviceRequest storage physicalDeviceRequest = physicalDeviceRequests[tokenId];
        require(!physicalDeviceRequest.requested, "already requested");

        physicalDeviceRequest.requested = true;
        physicalDeviceRequest.entity = true;
        physicalDeviceRequest.timestamp = block.timestamp;
        physicalDeviceRequest.requester = msg.sender;

        emit PhysicalDeviceRequested(msg.sender, tokenId);
    }

    function drain() public payable onlyOwner {
        uint256 balance = address(this).balance;
        if (balance != 0) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool drained,) = payable(msg.sender).call{value : balance}("");
            if (!drained) revert EtherTransferFail(address(this));
        }
    }

    function setBaseTokenUri(string calldata tokenUri) public onlyOwner {
        baseTokenUri = tokenUri;
    }

    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721)
    returns (string memory)
    {
        _requireMinted(tokenId);
        if (physicalDeviceRequests[tokenId].requested) {
            return string.concat(baseTokenUri, tokenId.toString(), "_claimed.json");
        }
        return string.concat(baseTokenUri, tokenId.toString(), ".json");
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        super._setDefaultRoyalty(receiver, feeNumerator);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Royalty, ERC721Enumerable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}