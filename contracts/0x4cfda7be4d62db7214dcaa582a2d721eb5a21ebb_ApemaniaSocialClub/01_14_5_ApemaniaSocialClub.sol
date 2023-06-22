// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title Apemania contract
 * @author Apemania Blockchain Developer
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract ApemaniaSocialClub is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using SafeMath for uint256;

    string public baseURI;

    // Costs ====================================
    uint256 public publicSaleCost = 0.015 ether;

    // Sale dates ===============================
    uint public publicSaleStartTimestamp = 1642500000;

    // Count values =============================
    uint256 public MAX_ITEMS = 20000;
    uint256 public _mintedItems = 0;
    uint256 public maxMintAmount = 15; // Max items per tx
    uint256 public maxMintAmntPerWal = 15; // Max items per wallet

    bool public paused = false;

    // Mappings ====================================
    mapping(address => uint) public soldWallets;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function giveAwayMint(address to, uint amount) external onlyOwner {
        _mintWithoutValidation(to, amount);
    }

    function _mintWithoutValidation(address to, uint amount) internal {
        require(_mintedItems + amount <= MAX_ITEMS, "All items sold!");
        for (uint i = 0; i < amount; i++) {
            _safeMint(to, _mintedItems);
            _mintedItems++;
        }
    }

    function publicMint() public payable {
        require(!paused, "Contract is paused");
        require(block.timestamp >= publicSaleStartTimestamp, "Public sale is not opened yet");
        uint remainder = msg.value % publicSaleCost;
        uint _mintAmount = msg.value / publicSaleCost;
        require(remainder == 0, "Send a divisible amount of price");
        require(_mintedItems.add(_mintAmount) <= MAX_ITEMS, "exceeded max supply of Apemania Apes");
        require(_mintAmount <= maxMintAmount, "max mint amount per tx is 15");
        require(soldWallets[msg.sender] + _mintAmount <= maxMintAmntPerWal, "Max mint amount per wallet is 15");

        if (msg.sender != owner()) {
            for (uint i = 0; i < _mintAmount; i++) {
                uint mintIndex = _mintedItems;
                require(_mintedItems <= MAX_ITEMS, "All items sold!");
                _safeMint(msg.sender, mintIndex);
                _mintedItems++;
            }
            soldUser(msg.sender, soldWallets[msg.sender] + _mintAmount);
        }
    }

    function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
        : "";
    }

    function setPublicSaleStartTimestamp(uint _startTimestamp) external onlyOwner {
        publicSaleStartTimestamp = _startTimestamp;
    }

    function setPublicSaleCost(uint256 _newCost) public onlyOwner {
        publicSaleCost = _newCost;
    }

    function setMaxMintAmount(uint256 _maxItemsPerTx) public onlyOwner {
        maxMintAmount = _maxItemsPerTx;
    }

    function setMaxMintAmountPerWallet(uint256 _maxItemsPerWallet) public onlyOwner {
        maxMintAmntPerWal = _maxItemsPerWallet;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function soldUser(address _user, uint _amount) internal {
        soldWallets[_user] = _amount;
    }

    function getMintedCountBySoldUser(address _user) public view virtual returns (uint) {
        return soldWallets[_user];
    }

    function withdraw() external onlyOwner {
        (bool success,) = owner().call{value : address(this).balance}("");
        require(success, "Failed to withdraw");
    }
}