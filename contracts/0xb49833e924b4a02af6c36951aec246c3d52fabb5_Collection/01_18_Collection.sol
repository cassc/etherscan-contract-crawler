// SPDX-License-Identifier: MIT
// Latest stable version of solidity

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

struct CollectionData {
    string uri;
    uint256 startTime;
    uint256 endTime;
    address admin;
    address treasury;
}

contract Collection is Ownable, ERC1155, AccessControl {
    event Sold(
        address indexed operator,
        address indexed to,
        uint256 indexed id,
        uint256 amount
    );
    using EnumerableSet for EnumerableSet.UintSet;

    EnumerableSet.UintSet soldCards;

    address payable internal commissionAddress =
        payable(0x49c6B1c099b5B3F00787376d4A06f769742afbfd);

    bytes32 public constant MINTER_ROLE = bytes32(keccak256("MINTER_ROLE"));
    uint256 public sold;
    uint256 public startTime;
    uint256 public endTime;

    address payable public treasury;

    constructor(
        CollectionData memory collecData
    ) ERC1155(collecData.uri) Ownable() {
        startTime = collecData.startTime;
        endTime = collecData.endTime;
        treasury = payable(collecData.treasury);
        require(treasury != address(0), "Treasury can't be zero address");

        _setupRole(DEFAULT_ADMIN_ROLE, collecData.admin);
    }

    struct TokenRange {
        uint32 startId;
        uint32 endId;
        uint32 availableId;
        uint256 amount;
    }

    TokenRange[] private tokenRange;

    function buy(uint32 artId) payable external {
        require(
            startTime <= block.timestamp && endTime > block.timestamp,
            "Sale did not start yet"
        );
        address buyer = _msgSender();
        uint256 tokenId = _withToken(buyer, artId);
        require(!(soldCards.contains(tokenId)), "This card already sold");

        _mint(buyer, tokenId, 1, "");

        sold += 1;
        soldCards.add(tokenId);
    }

    function recoverToken(
        address _token
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(msg.sender, amount);
    }

    function mint(
        address to,
        uint256 _id
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!(soldCards.contains(_id)), "This card already sold");

        _mint(to, _id, 1, "");

        sold += 1;
        soldCards.add(_id);
    }

    function setOwner(address to) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(to != address(0), "Treasury can't be zero address");

        _setupRole(DEFAULT_ADMIN_ROLE, to);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amount_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < ids.length; i++) {
            require(!(soldCards.contains(ids[i])), "This card already sold");
            soldCards.add(ids[i]);
        }

        _mintBatch(to, ids, amount_, "");

        sold += ids.length;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setStartTime(
        uint256 _starTime
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_starTime > 0, "Start time must be greater than 0");
        startTime = _starTime;
    }

    function setEndTime(
        uint256 _endTime
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_endTime > 0, "Start time must be greater than 0");
        endTime = _endTime;
    }

    function setTreasury(
        address _treasury
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_treasury != address(0), "Treasury can't be zero address");
        treasury = payable(_treasury);
    }

    function setTokenRanges(
        TokenRange[] calldata _priceRange
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        delete tokenRange;
        for (uint32 i = 0; i < _priceRange.length; i++) {
            tokenRange.push(_priceRange[i]);
        }
    }

    function getPrice(uint32 tokenRangeId) public view returns (uint256) {
        require(tokenRangeId < tokenRange.length, "Token range does not exist");
        return tokenRange[tokenRangeId].amount;
    }

    function getAvailable(uint32 tokenRangeId) external view returns (uint32) {
        require(tokenRangeId < tokenRange.length, "Token range does not exist");
        return
            tokenRange[tokenRangeId].endId -
            tokenRange[tokenRangeId].availableId +
            1;
    }

    function getNextTokenId(uint32 tokenRangeId) private view returns (uint32) {
        require(tokenRangeId < tokenRange.length, "Token range does not exist");
        uint32 tokenId = tokenRange[tokenRangeId].availableId;
        uint32 endId = tokenRange[tokenRangeId].endId;
        while (soldCards.contains(tokenId) && tokenId <= endId) {
            tokenId = tokenId + 1;
        }
        return tokenId;
    }

    function _withToken(
        address buyer,
        uint32 tokenRangeId
    ) private returns (uint256) {
        require(tokenRangeId < tokenRange.length, "Token range does not exist");

        TokenRange memory range = tokenRange[tokenRangeId];
        uint32 tokenId = getNextTokenId(tokenRangeId);
        tokenRange[tokenRangeId].availableId = tokenId + 1;
        uint256 price = getPrice(tokenRangeId);

        require(tokenId <= range.endId, "Nft is sold out");

        require(
            msg.value >= price,
            "Insufficient funds: Cannot buy this NFT"
        );

        uint256 amount = msg.value;

        treasury.transfer(amount - calculateCommission(amount, 7));

        commissionAddress.transfer(calculateCommission(amount, 7));

        emit Sold(address(this), buyer, tokenId, price);

        return tokenId;
    }

    function calculateCommission(
        uint256 value,
        uint256 percentage
    ) internal pure returns (uint256) {
        return (value * percentage) / 100;
    }
}