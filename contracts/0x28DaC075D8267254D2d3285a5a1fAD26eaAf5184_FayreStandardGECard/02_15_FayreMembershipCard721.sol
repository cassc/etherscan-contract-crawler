// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

abstract contract FayreMembershipCard721 is Ownable, ERC721Enumerable, ERC721Burnable {
    struct FreeMinterData {
        address freeMinter;
        uint256 amount;
    }

    event Mint(address indexed owner, uint256 indexed tokenId, uint256 indexed membershipCardMintTimestamp, string tokenURI);

    mapping(uint256 => uint256) public membershipCardMintTimestamp;
    uint256 public price;
    uint256 public mintedSupply;
    uint256 public supplyCap;
    address public treasuryAddress;
    mapping(address => bool) public isMembershipCardsManager;
    mapping(address => uint256) public remainingFreeMints;

    uint256 private _currentTokenId;
    string private _tokenURI;

    modifier onlyMembershipCardsManager() {
        require(isMembershipCardsManager[msg.sender], "Only membership cards manager");
        _;
    }

    constructor(string memory name_, string memory symbol_, uint256 price_, uint256 supplyCap_) ERC721(name_, symbol_) {
        price = price_;

        supplyCap = supplyCap_;
    }

    function setTokenURI(string memory newTokenUri) external onlyOwner {
        _tokenURI = newTokenUri;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function setSupplyCap(uint256 newSupplyCap) external onlyOwner {
        supplyCap = newSupplyCap;
    }

    function setTreasury(address newTreasuryAddress) external onlyOwner {
        require(newTreasuryAddress != address(0), "Cannot set address 0");

        treasuryAddress = newTreasuryAddress;
    }

    function setAddressAsMembershipCardsManager(address membershipCardsManagerAddress) external onlyOwner {
        isMembershipCardsManager[membershipCardsManagerAddress] = true;
    }

    function unsetAddressAsMembershipCardsManager(address membershipCardsManagerAddress) external onlyOwner {
        isMembershipCardsManager[membershipCardsManagerAddress] = false;
    }

    function setFreeMinters(FreeMinterData[] calldata freeMintersData) external onlyMembershipCardsManager {
        for (uint256 i = 0; i < freeMintersData.length; i++)
            remainingFreeMints[freeMintersData[i].freeMinter] = freeMintersData[i].amount;
    }

    function batchMint(address recipient, uint256 amount) external onlyMembershipCardsManager {
        for (uint256 i = 0; i < amount; i++)
            _mintInBatch(recipient);
    }

    function batchMintToList(FreeMinterData[] calldata freeMintersData) external onlyMembershipCardsManager {
        for (uint256 i = 0; i < freeMintersData.length; i++)
            for (uint256 j = 0; j < freeMintersData[i].amount; j++)
                _mintInBatch(freeMintersData[i].freeMinter);
    }

    function mint(address recipient) external payable returns(uint256) {
        mintedSupply++;

        if (supplyCap > 0)
            require(mintedSupply - 1 < supplyCap, "Supply cap reached");

        if (remainingFreeMints[msg.sender] > 0) {
            require(msg.value == 0, "Liquidity not needed");

            remainingFreeMints[msg.sender]--;   
        } else {
            require(msg.value > 0, "Must send liquidity");

            require(msg.value >= price, "Insufficient liquidity");

            uint256 valueToRefund = msg.value - price;

            if (valueToRefund > 0) {
                (bool refundSuccess, ) = msg.sender.call{value: valueToRefund }("");

                require(refundSuccess, "Unable to refund extra liquidity");
            }

            (bool liquiditySendToTreasurySuccess, ) = treasuryAddress.call{value: price }("");

            require(liquiditySendToTreasurySuccess, "Unable to send liquidity to treasury");
        }

        uint256 tokenId = _currentTokenId++;

        _mint(recipient, tokenId);

        membershipCardMintTimestamp[tokenId] = block.timestamp;

        emit Mint(recipient, tokenId, membershipCardMintTimestamp[tokenId], _tokenURI);

        return tokenId;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return _tokenURI;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns(bool) {
        return interfaceId == type(ERC721Enumerable).interfaceId || interfaceId == type(ERC721Burnable).interfaceId || super.supportsInterface(interfaceId);
    }

    function burn(uint256 tokenId) public override {
        super.burn(tokenId);

        mintedSupply--;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        ERC721Enumerable._beforeTokenTransfer(from , to, tokenId);
    }

    function _mintInBatch(address recipient) private {
        mintedSupply++;

        if (supplyCap > 0)
            require(mintedSupply - 1 < supplyCap, "Supply cap reached");

        uint256 tokenId = _currentTokenId++;

        _mint(recipient, tokenId);

        membershipCardMintTimestamp[tokenId] = block.timestamp;

        emit Mint(recipient, tokenId, membershipCardMintTimestamp[tokenId], _tokenURI);
    }
}