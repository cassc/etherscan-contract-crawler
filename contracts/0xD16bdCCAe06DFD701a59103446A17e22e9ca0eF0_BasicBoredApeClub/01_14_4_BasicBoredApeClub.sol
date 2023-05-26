// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// ____  ____          _____
// |  _ \|  _ \   /\   / ____|
// | |_) | |_) | /  \ | |
// |  _ <|  _ < / /\ \| |
// | |_) | |_) / ____ \ |____
// |____/|____/_/    \_\_____|

/**
 * @title BasicBoredApeClub contract
 * @author pasalog
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract BasicBoredApeClub is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using SafeMath for uint256;

    string public baseURI;

    // Costs ====================================
    uint256 public presaleCost = 0.05 ether;
    uint256 public publicSaleCost = 0.07 ether;

    // Sale dates ===============================
    uint public presaleStartTimestamp = 1640116800; // 21 December 8 PM UTC
    uint public publicSaleStartTimestamp = 1640289600; // 23 December 8 PM UTC

    // Count values =============================
    uint256 public MAX_ITEMS = 10000;
    uint256 public _mintedItems = 0;
    uint256 public maxMintAmount = 10; // Max items per tx

    bool public paused = false;

    // Lists ====================================
    mapping(address => bool) public whitelisted;
    mapping(address => uint) public presaleWallets;

    // Events ===================================
    event PublicSaleMint(
        address indexed _from,
        uint indexed _tokenId
    );

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

    function presaleMint() public payable {
        require(!paused, "Contract is paused!");
        require(block.timestamp >= presaleStartTimestamp, "Presale is not opened yet");
        require(block.timestamp <= publicSaleStartTimestamp, "Not in presale period");
        uint remainder = msg.value % presaleCost;
        uint _mintAmount = msg.value / presaleCost;
        require(remainder == 0, "Send a divisible amount of price");
        require(_mintedItems.add(_mintAmount) <= MAX_ITEMS, "Purchase would not exceed max supply");
        require(_mintAmount <= maxMintAmount, "Over the maxMintAmount");
        require(whitelisted[msg.sender] == true, "You need to be in whitelist");
        require(presaleWallets[msg.sender] <= 10, "Max 10 items per wallet");

        if (msg.sender != owner()) {
            for (uint i = 0; i < _mintAmount; i++) {
                uint mintIndex = _mintedItems;
                require(_mintedItems <= MAX_ITEMS, "All items sold!");
                _safeMint(msg.sender, mintIndex);
                _mintedItems++;
            }
            presaleUser(msg.sender, presaleWallets[msg.sender] + _mintAmount);
        }
    }

    function publicSaleMint() public payable {
        require(!paused, "Contract is paused");
        require(block.timestamp >= publicSaleStartTimestamp, "Public sale is not opened yet");
        uint remainder = msg.value % publicSaleCost;
        uint _mintAmount = msg.value / publicSaleCost;
        require(remainder == 0, "Send a divisible amount of price");
        require(_mintedItems.add(_mintAmount) <= MAX_ITEMS, "Purchase would  not exceed max supply of Basic Apes");
        require(_mintAmount <= maxMintAmount, "Over the maxMintAmount");

        if (msg.sender != owner()) {
            for (uint i = 0; i < _mintAmount; i++) {
                uint mintIndex = _mintedItems;
                require(_mintedItems <= MAX_ITEMS, "All items sold!");
                _safeMint(msg.sender, mintIndex);
                emit PublicSaleMint(msg.sender, mintIndex);
                _mintedItems++;
            }}
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

    function setPresaleStartTimestamp(uint _startTimestamp) external onlyOwner {
        presaleStartTimestamp = _startTimestamp;
    }

    function setPublicSaleStartTimestamp(uint _startTimestamp) external onlyOwner {
        publicSaleStartTimestamp = _startTimestamp;
    }

    function setPresaleCost(uint256 _newCost) public onlyOwner {
        presaleCost = _newCost;
    }

    function setPublicSaleCost(uint256 _newCost) public onlyOwner {
        publicSaleCost = _newCost;
    }

    function setMaxMintAmount(uint256 _maxItemsPerTx) public onlyOwner {
        maxMintAmount = _maxItemsPerTx;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function whitelistUser(address _user) public onlyOwner {
        whitelisted[_user] = true;
    }

    function removeWhitelistUser(address _user) public onlyOwner {
        whitelisted[_user] = false;
    }

    function presaleUser(address _user, uint _amount) internal {
        presaleWallets[_user] = _amount;
    }

    function getMintedCountByPresaledUser(address _user) public view virtual returns (uint) {
        return presaleWallets[_user];
    }

    function removePresaleUser(address _user, uint _amount) external onlyOwner {
        presaleWallets[_user] = _amount;
    }

    function withdraw() external onlyOwner {
        (bool success,) = owner().call{value : address(this).balance}("");
        require(success, "Failed to withdraw");
    }
}