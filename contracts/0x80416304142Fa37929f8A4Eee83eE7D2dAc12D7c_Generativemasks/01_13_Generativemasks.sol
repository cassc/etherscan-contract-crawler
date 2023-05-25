//SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./../extensions/HasSecondarySaleFees.sol";

interface iGenerativemasks {

    function price() external returns (uint256);

    function remainingAmount() external returns (uint256);

    function mintForPromotion(uint256 amount) external;

    function buy(uint256 amount) external payable;

    function withdrawETH() external;

    function switchOnSale() external;

    function lottery() external;
}

contract Generativemasks is iGenerativemasks, ERC721Burnable, HasSecondarySaleFees, Ownable {

    using Strings for uint256;

    bool private _isOnSale;
    string private baseURI;
    uint256 private constant NFT_SUPPLY_AMOUNT = 10000;
    uint256 public nextTokenId;
    uint256 private _price = 0.1 ether;
    uint256 public lotterySeed;
    uint256 public metadataIndex;
    uint256 private _revealDate;
    address payable[2] royaltyRecipients;

    constructor(
        string memory initialBaseURI,
        address payable[2] memory _royaltyRecipients,
        uint256 __revealDate
    )
    ERC721("Generativemasks", "GM")
    HasSecondarySaleFees(new address payable[](0), new uint256[](0))
    {
        require(_royaltyRecipients[0] != address(0), "Invalid address");
        require(_royaltyRecipients[1] != address(0), "Invalid address");
        require(0 < __revealDate, "Invalid date");

        baseURI = initialBaseURI;
        royaltyRecipients = _royaltyRecipients;
        _revealDate = __revealDate;

        address payable[] memory thisAddressInArray = new address payable[](1);
        thisAddressInArray[0] = payable(address(this));
        uint256[] memory royaltyWithTwoDecimals = new uint256[](1);
        royaltyWithTwoDecimals[0] = 1000;

        _setCommonRoyalties(thisAddressInArray, royaltyWithTwoDecimals);
    }

    function price() external override view returns (uint256) {
        return _price;
    }

    function remainingAmount() external override view returns (uint256) {
        return NFT_SUPPLY_AMOUNT - nextTokenId;
    }

    function mintForPromotion(uint256 amount) external override onlyOwner {
        require(!_isOnSale, "On sale");
        require(nextTokenId < 500, "All tokens for promotion are minted");

        for (uint256 i = 0; i < amount; i++) {
            _mint(msg.sender, nextTokenId++);
        }
    }

    function buy(uint256 amount) external payable override {
        require(_isOnSale, "Not on sale");
        require(0 != amount, "Incorrect amount");
        require(msg.value == amount * _price, "Incorrect value");

        require(nextTokenId + amount <= NFT_SUPPLY_AMOUNT, "No remaining tokens");
        for (uint256 i = 0; i < amount; i++) {
            _mint(msg.sender, nextTokenId++);
        }

        if (lotterySeed != 0) {
            return;
        }
        if (nextTokenId == NFT_SUPPLY_AMOUNT || _revealDate < block.timestamp) {
            lotterySeed = block.number;
        }
    }

    function withdrawETH() external override {
        uint256 royalty = address(this).balance / 2;

        Address.sendValue(payable(royaltyRecipients[0]), royalty);
        Address.sendValue(payable(royaltyRecipients[1]), royalty);
    }

    function lottery() external override {
        require(metadataIndex == 0, "Metadata index is already set");
        require(lotterySeed != 0, "Lottery seed must be set");

        metadataIndex = uint256(blockhash(lotterySeed)) % NFT_SUPPLY_AMOUNT;
        if ((block.number - lotterySeed) > 255) {
            metadataIndex = uint256(blockhash(block.number - 1)) % NFT_SUPPLY_AMOUNT;
        }
        if (metadataIndex == 0) {
            metadataIndex = metadataIndex + 1;
        }
    }

    function switchOnSale() external override onlyOwner {
        require(nextTokenId == 500, "Invalid id");

        _isOnSale = true;
    }

    function updateBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (metadataIndex == 0) {
            return string(abi.encodePacked(baseURI, "unrevealed.json"));
        }

        uint256 metadataId = (tokenId + metadataIndex) % NFT_SUPPLY_AMOUNT;
        return string(abi.encodePacked(baseURI, metadataId.toString(), ".json"));
    }

    receive() external payable {}

    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721, HasSecondarySaleFees)
    returns (bool)
    {
        return ERC721.supportsInterface(interfaceId) ||
        HasSecondarySaleFees.supportsInterface(interfaceId);
    }
}