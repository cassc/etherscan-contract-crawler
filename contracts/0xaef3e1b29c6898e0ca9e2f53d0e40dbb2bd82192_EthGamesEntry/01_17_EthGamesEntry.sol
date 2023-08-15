//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract EthGamesEntry is ERC721A, ERC721AQueryable, AccessControl, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    struct Drop {
        address to;
        uint256 amount;
    }

    bytes32 public constant AIRDROP_ROLE = keccak256("AIRDROP_ROLE");
    address public constant DEV_ADDRESS = 0xC61d067E2239496996ADa99Ea878f7b8c5f383Db;

    uint256 public maxTokenSupply;
    string public baseTokenURI;
    bool public saleEnabled;
    uint256 public currentPrice;
    uint256 public currentMaxSale;
    uint256 public maxMintPerWallet;
    mapping(address => uint256) public mintCount;

    constructor(string memory baseURI) ERC721A("EthGames Season 0", "EGXS0") {
        setBaseURI(baseURI);
        saleEnabled = false;
        currentPrice = 0 ether;
        currentMaxSale = 5555;
        maxTokenSupply = 5555;
        maxMintPerWallet = 4;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(AIRDROP_ROLE, msg.sender);
        _setupRole(AIRDROP_ROLE, 0x2bf51624303867B85db1261107ADeF699C7AF68e);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    modifier saleIsOpen() {
        require(totalSupply() <= maxTokenSupply, "EthGamesEntry: Sale ended");
        _;
    }

    function mint(
        uint256 _count
    ) public payable saleIsOpen {
        uint256 total = totalSupply();
        require(total <= maxTokenSupply, "EthGames Season 0: Max limit");
        require(total + _count <= maxTokenSupply, "EthGames Season 0: Max limit");
        require(total + _count <= currentMaxSale, "EthGames Season 0: Max sale limit");
        require(mintCount[msg.sender] + _count <= maxMintPerWallet, "EthGames Season 0: Max wallet limit");
        require(saleEnabled, "EthGames Season 0: Sale is not active");
        require(msg.value >= getPrice(_count), "EthGames Season 0: Value below price");
        _mintElements(msg.sender, _count);
    }

    // @dev start of public/external views
    function getPrice(uint256 _count) public view returns (uint256) {
        return currentPrice.mul(_count);
    }

    function saleActive() external view returns (bool) {
        return saleEnabled;
    }
    // @dev end of public/external views

    // @dev start of internal/private functions
    function _mintElements(address _to, uint256 _amount) private {
        mintCount[_to] = mintCount[_to] + _amount;
        _safeMint(_to, _amount);
        require(totalSupply() <= maxTokenSupply, "EthGames Season 0: Limit reached");
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function _payout(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "EthGames Season 0: Transfer failed");
    }
    // @dev end of internal/private functions

    // @dev start of only owner functions
    function mintReserve(uint256 _count, address _to) public onlyOwner {
        uint256 total = totalSupply();
        require(total <= maxTokenSupply, "EthGames Season 0: Sale ended");
        require(total + _count <= maxTokenSupply, "EthGames Season 0: Max limit");
        _mintElements(_to, _count);
    }

    function setMaxSale(uint256 currentMaxSale_) external onlyOwner {
        currentMaxSale = currentMaxSale_;
    }

    function setMaxTokenSupply(uint256 maxTokenSupply_) external onlyOwner {
        maxTokenSupply = maxTokenSupply_;
    }

    function setPrice(uint256 priceInWei) external onlyOwner {
        currentPrice = priceInWei;
    }

    function setMaxMintPerWallet(uint256 maxMintPerWallet_) external onlyOwner {
        maxMintPerWallet = maxMintPerWallet_;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function toggleSale() public onlyOwner {
        saleEnabled = !saleEnabled;
    }

    function withdrawAll() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "EthGames Season 0: Balance should be above 0");
        _payout(DEV_ADDRESS, address(this).balance);
    }
    // @dev end of only owner functions

    // @dev start of airdrop functions
    function airdrop(Drop[] calldata drops) public onlyRole(AIRDROP_ROLE) {
        for (uint i = 0; i < drops.length; i++) {
            Drop calldata drop = drops[i];
            _mintElements(drop.to, drop.amount);
        }
    }
    // @dev end of airdrop functions

    // @dev start of supportsInterface
    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, AccessControl) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    // @dev end of supportsInterface
}