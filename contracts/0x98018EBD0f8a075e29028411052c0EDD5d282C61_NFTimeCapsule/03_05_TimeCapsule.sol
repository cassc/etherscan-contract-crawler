// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Author: TOYMAKERSⓒ
// Drop: #1
// Project: TIME CAPSULE
/*
*******************************************************************************
          |                   |                  |                     |
 _________|________________.=""_;=.______________|_____________________|_______
|                   |  ,-"_,=""     `"=.|                  |
|___________________|__"=._o`"-._        `"=.______________|___________________
          |                `"=._o`"=._      _`"=._                     |
 _________|_____________________:=._o "=._."_.-="'"=.__________________|_______
|                   |    __.--" , ; `"=._o." ,-"""-._ ".   |
|___________________|_._"  ,. .` ` `` ,  `"-._"-._   ". '__|___________________
          |           |o`"=._` , "` `; .". ,  "-._"-._; ;              |
 _________|___________| ;`-.o`"=._; ." ` '`."\` . "-._ /_______________|_______
|                   | |o;    `"-.o`"=._``  '` " ,__.--o;   |
|___________________|_| ;     (#) `-.o `"=.`_.--"_o.-; ;___|___________________
____/______/______/___|o;._    "      `".o|o_.--"    ;o;____/______/______/____
/______/______/______/_"=._o--._        ; | ;        ; ;/______/______/______/_
____/______/______/______/__"=._o--._   ;o|o;     _._;o;____/______/______/____
/______/______/______/______/____"=._o._; | ;_.--"o.--"_/______/______/______/_
____/______/______/______/______/_____"=.o|o_.--""___/______/______/______/____
/______/______/______/______/______/______/______/______/______/______/
*/

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface ERC721 {
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

interface ERC1155 {
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
    function uri(uint256 _tokenId) external view returns (string memory);
}

interface IERC721Metadata {
    function name() external view returns (string memory);
}

interface ITimeCapsuleUri {
    struct TimeLeft {
        string year;
        string day;
        string hour;
        string minute;
        string second;
    }
    function GetMetadata(TimeLeft memory timeLeft, string memory contractName, string memory buriedTokenId, address burier, address buriedTokenAddress, string memory digUpDate, string memory tokenId) external view returns (string memory);
}

contract NFTimeCapsule is ERC721A, Ownable {

    mapping(uint256 => CachedItem) public idsToCachedItem;
    mapping(address => uint) public walletDigups;
    mapping(address => uint) public walletDeposits;

    event TokenBuried(address burier, uint256 tokenId, address buriedContractAddress, uint256 buriedTokenId, string message);
    event TokenDugUp(address digger, uint256 tokenId, address buriedContractAddress, uint256 buriedTokenId, string message);

    error InvalidCapsuleOperation(bool isCapsuleBuried);
    error NotOwner();
    error SupplyMaxMet();
    error UserMaxMet();
    error CapsuleAlreadyDugUp();
    error CapsuleAlreadyBurried();

    uint256 public digUpDate = 0;
    uint256 public maxDeposits = 2053;
    uint256 public digupLimit = 1;
    uint256 public depositLimit = 3;

    address public TimeCapsuleUriAddress = 0x2f02a1a0E5E88e12FE2F6cF2300d4E28E5974167;

    struct CachedItem {
        uint256 buriedTokenId;
        address buriedTokenAddress;
        address burier;
        bool useItemUri;
        bool isDugUp;
        bool is721;
        string message;
    }

    constructor() ERC721A("NFTimeCapsule", "NFTime") {
    }

    function bury() external onlyOwner {
        if (digUpDate != 0)
            revert CapsuleAlreadyBurried();

        // 30 years
        digUpDate = block.timestamp + 10950 days;
    }
    

    function updateTimeCapsuleUri(address newAddress) external onlyOwner {
        if (digUpDate != 0)
            revert CapsuleAlreadyBurried();

        TimeCapsuleUriAddress = newAddress;
    }

    function getTimeLeft() public view returns (ITimeCapsuleUri.TimeLeft memory) {
        ITimeCapsuleUri.TimeLeft memory timeLeft;

        if (digUpDate < block.timestamp) {
            timeLeft.year = "0";
            timeLeft.day = "0";
            timeLeft.hour = "0";
            timeLeft.minute = "0";
            timeLeft.second = "0";
            return timeLeft;
        }

        uint256 timestamp = digUpDate - block.timestamp;

        uint256 yearsLeft = timestamp / 31536000;

        // calculate ticks left after years
        timestamp = timestamp - (yearsLeft * 31536000);

        uint256 daysLeft = timestamp / 86400;

        // calculate ticks left after days
        timestamp = timestamp - (daysLeft * 86400);

        uint256 hoursLeft = timestamp / 3600;

        // calculate ticks left after hours
        timestamp = timestamp - (hoursLeft * 3600);

        uint256 minutesLeft = timestamp / 60;

        // calculate ticks left after minutes
        timestamp = timestamp - (minutesLeft * 60);

        timeLeft.year = _toString(yearsLeft);
        timeLeft.day = _toString(daysLeft);
        timeLeft.hour = _toString(hoursLeft);
        timeLeft.minute = _toString(minutesLeft);
        timeLeft.second = _toString(timestamp);

        return timeLeft;
    }

    function placeNFTInCapsule(address nftAddress, uint256 tokenId, bool is721) external {
        _placeNFTInCapsule(nftAddress, tokenId, is721, "");
    }

    function placeNFTInCapsuleWithMessage(address nftAddress, uint256 tokenId, bool is721, string memory message) external {
        _placeNFTInCapsule(nftAddress, tokenId, is721, message);
    }

    function _placeNFTInCapsule(address nftAddress, uint256 tokenId, bool is721, string memory message) internal {
        if (address(this) == nftAddress)
            revert InvalidCapsuleOperation(digUpDate != 0);

        // capsule is already buried
        if (digUpDate > 0)
            revert CapsuleAlreadyBurried();

        // max supply reached
        if (_nextTokenId() > maxDeposits)
            revert SupplyMaxMet();

        // 3 deposits per user
        if (walletDeposits[_msgSender()] >= depositLimit)
            revert UserMaxMet();

        // transfer NFT
        if (is721)
        {
            ERC721 nftContract = ERC721(nftAddress);
            nftContract.transferFrom(_msgSender(), address(this), tokenId);
        }
        else
        {
            ERC1155 nftContract = ERC1155(nftAddress);
            nftContract.safeTransferFrom(_msgSender(), address(this), tokenId, 1, "");
        }

        // save cached item
        CachedItem memory capsule = CachedItem(tokenId, nftAddress, _msgSender(), false, false, is721, message);
        idsToCachedItem[_nextTokenId()] = capsule;

        emit TokenBuried(_msgSender(), _nextTokenId(), nftAddress, tokenId, message);
        walletDeposits[_msgSender()] += 1;
        _mint(_msgSender(), 1);
    }

    function digUpNFT(uint256 tokenIdToDigUp) external {
        // either not time, or not buried
        if (block.timestamp < digUpDate || digUpDate == 0)
            revert InvalidCapsuleOperation(digUpDate != 0);

        // can't dig up nothing
        if (!_exists(tokenIdToDigUp))
            revert OwnerQueryForNonexistentToken();

        // too many dug up
        if (walletDigups[_msgSender()] >= digupLimit)
            revert UserMaxMet();

        CachedItem memory capsuleToDigUp = idsToCachedItem[tokenIdToDigUp];

        if (capsuleToDigUp.isDugUp)
            revert CapsuleAlreadyDugUp();

        walletDigups[_msgSender()] += 1;

        // transfer nft to person interacting with contract in future
        if (capsuleToDigUp.is721) {
            ERC721(capsuleToDigUp.buriedTokenAddress).transferFrom(address(this), _msgSender(), capsuleToDigUp.buriedTokenId);
        } else {
            ERC1155(capsuleToDigUp.buriedTokenAddress).safeTransferFrom(address(this), _msgSender(), capsuleToDigUp.buriedTokenId, 1, "");
        }

        // set dug up
        idsToCachedItem[tokenIdToDigUp].isDugUp = true;

        emit TokenDugUp(_msgSender(), tokenIdToDigUp, capsuleToDigUp.buriedTokenAddress, capsuleToDigUp.buriedTokenId, capsuleToDigUp.message);
    }

    struct TokenURIInfo {
        string buriedContractName;
        string buriedTokenIdString;
        string tokenIdString;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        CachedItem storage capsule = idsToCachedItem[tokenId];

        if (capsule.useItemUri)
        {
            if (capsule.is721) {
                return ERC721(capsule.buriedTokenAddress).tokenURI(capsule.buriedTokenId);
            } else {
                return ERC1155(capsule.buriedTokenAddress).uri(capsule.buriedTokenId);
            }
        }

        TokenURIInfo memory tokenIdInfo;
        tokenIdInfo.buriedContractName = capsule.is721 ? "ERC721 " : "ERC1155 ";

        try IERC721Metadata(capsule.buriedTokenAddress).name() returns (string memory name) {
            tokenIdInfo.buriedContractName = name;
        }catch (bytes memory) {

        }

        ITimeCapsuleUri.TimeLeft memory timeLeft = getTimeLeft();

        tokenIdInfo.tokenIdString = _toString(tokenId);
        tokenIdInfo.buriedTokenIdString = _toString(capsule.buriedTokenId);
        string memory metadata = ITimeCapsuleUri(TimeCapsuleUriAddress).GetMetadata(timeLeft, tokenIdInfo.buriedContractName, tokenIdInfo.buriedTokenIdString, capsule.burier, capsule.buriedTokenAddress, _toString(digUpDate), tokenIdInfo.tokenIdString);
        return metadata;
    }

    function _startTokenId() internal pure override returns (uint256)
    {
        return 1;
    }

    function toggleShowBuriedTokenMetadata(uint256 tokenId, bool showBuriedTokenMetadata) external
    {
        if (_msgSender() != ownerOf(tokenId))
            revert NotOwner();

        idsToCachedItem[tokenId].useItemUri = showBuriedTokenMetadata;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4)
    {
        return 0xf23a6e61;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4)
    {
        return 0xbc197c81;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    // The interface IDs are constants representing the first 4 bytes
    // of the XOR of all function selectors in the interface.
    // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
    // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
    return
        interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
        interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
        interfaceId == 0x5b5e139f || // ERC165 interface ID for ERC721Metadata.
        interfaceId == 0x4e2312e0;   // ERC-1155 ERC1155TokenReceiver
    }
 }