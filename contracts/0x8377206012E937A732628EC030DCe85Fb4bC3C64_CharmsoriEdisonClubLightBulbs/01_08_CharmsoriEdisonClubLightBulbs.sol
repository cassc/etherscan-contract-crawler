// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract CharmsoriEdisonClubLightBulbs is Ownable, ERC721A, ReentrancyGuard, Pausable {

    // Configuration of sale
    struct SaleConfig {
        uint256 saleStartTime;
        uint256 fixedPrice;
    }

    SaleConfig public saleConfig;

    uint256 public constant BATCH_SIZE = 1;

    uint256 public constant COLLECTION_SIZE = 10;

    // Use mapping(address => uint256) to record the minting balance of every whitelist
    mapping(address => bool) public whitelist;

    string private _baseTokenURI;

    constructor(
        string memory name,
        string memory symbol
    ) ERC721A(name, symbol) {
    }

    // Before calling mint function, check if the caller is the user rather than other contracts.
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // The mint function for the whitelisted users
    function whitelistMint() external payable callerIsUser {
        SaleConfig memory config = saleConfig;
        require(config.fixedPrice != 0, "Sale has not set yet");

        require(
            config.saleStartTime != 0 && block.timestamp >= config.saleStartTime,
            "Sale has not started yet"
        );
        require(whitelist[msg.sender], "Not eligible for whitelist mint");
        require(totalSupply() + 1 <= COLLECTION_SIZE, "reached max supply");
        // User can mint only one nft per address
        whitelist[msg.sender] = false;

        require(msg.value >= config.fixedPrice, "Need to send more ETH.");
        _safeMint(msg.sender, 1);
        refundIfOver(config.fixedPrice);
    }

    // Anyone can get the so-far price of the sale
    function getSalePrice()
    public
    view
    returns (uint256)
    {
        return saleConfig.fixedPrice;
    }

    // Decide when the auction starts
    function setUpSale(uint256 startAt, uint256 price) external onlyOwner {
        saleConfig.saleStartTime = startAt;
        saleConfig.fixedPrice = price;
    }

    // Set the whitelisted address
    function seedWhitelist(address[] memory addresses)
    external
    onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = true;
        }
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    // Withdraw the fund in NFT contract to the owner address
    function withdrawFund() external onlyOwner nonReentrant {
        (bool success,) = msg.sender.call{value : address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // The function of returning the excess money
    function refundIfOver(uint256 price) private {
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

}