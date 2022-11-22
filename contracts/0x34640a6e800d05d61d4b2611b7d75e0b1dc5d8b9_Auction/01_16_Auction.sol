// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";

contract Auction is AccessControlUpgradeable, ERC721HolderUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeERC20Upgradeable for ERC20Upgradeable;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    struct Position {
        address collection;
        uint256 tokenId;
        uint256 startDate;
        uint256 endDate;
        uint256 minPrice;
        address owner;
        address currency;
        uint256 bid;
        address bidder;
        bool isFinished;
    }

    mapping(uint256 => Position) public positions;
    uint256 public positionsCount;

    uint256 public minDuration;
    uint256 public maxDuration;
    uint256 public extensionSpan;

    address public feeAddress;
    uint256 public sellerFee;

    event NewAuction(
        uint256 indexed id,
        address indexed owner,
        address collection,
        uint256 tokenId,
        uint256 minPrice,
        address currency,
        uint256 startDate,
        uint256 endDate
    );

    event NewBid(
        uint256 indexed id,
        uint256 bid,
        address bidder,
        uint256 previousBid,
        address previousBidder,
        uint256 endDate
    );

    event CloseAuction(
        uint256 indexed id,
        address collection,
        uint256 tokenId,
        address winner,
        uint256 price,
        address currency
    );

    function __Auction_init() public initializer {
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, _msgSender());

        minDuration = 7 days;
        maxDuration = 30 days;
        extensionSpan = 5 minutes;

        feeAddress = _msgSender();
        sellerFee = 300;
    }

    function changeMinDuration(uint256 _minDuration) external onlyRole(ADMIN_ROLE) {
        minDuration = _minDuration;
    }

    function changeMaxDuration(uint256 _maxDuration) external onlyRole(ADMIN_ROLE) {
        maxDuration = _maxDuration;
    }

    function changeExtensionSpan(uint256 _extensionSpan) external onlyRole(ADMIN_ROLE) {
        extensionSpan = _extensionSpan;
    }

    function changeFeeAddress(address _feeAddress) external onlyRole(ADMIN_ROLE) {
        feeAddress = _feeAddress;
    }

    function changeSellerFee(uint256 _sellerFee) external onlyRole(ADMIN_ROLE) {
        sellerFee = _sellerFee;
    }

    function startAuction(
        address _collection,
        uint256 _id,
        uint256 _minPrice,
        address _currency,
        uint256 _duration
    ) external {
        IERC721Upgradeable nft = IERC721Upgradeable(_collection);

        require(_duration >= minDuration && _duration <= maxDuration, "Duration is not between minimum and maximum");
        require(nft.ownerOf(_id) == _msgSender(), "Sender is not the owner of the token");
        require(nft.getApproved(_id) == address(this) || nft.isApprovedForAll(_msgSender(), address(this)),
            "NFT is not approved to lock");

        nft.safeTransferFrom(_msgSender(), address(this), _id);

        uint256 startDate = block.timestamp;
        uint256 endDate = startDate + _duration;

        positions[positionsCount] = Position(
            _collection,
            _id,
            startDate,
            endDate,
            _minPrice,
            _msgSender(),
            _currency,
            0,
            address(0),
            false
        );

        emit NewAuction(
            positionsCount,
            _msgSender(),
            _collection,
            _id,
            _minPrice,
            _currency,
            startDate,
            endDate
        );

        positionsCount++;
    }

    function placeBid(uint256 _id, uint256 _bid) external {
        Position storage position = positions[_id];
        ERC20Upgradeable token = ERC20Upgradeable(position.currency);

        require(block.timestamp <= position.endDate, "Auction is over");
        require(_bid >= position.minPrice, "Bid is less than minimum price");
        require(_bid > position.bid, "Bid is less than previous bid");
        require(_bid >= position.bid + _getMinStep(_bid, token.decimals()), "Step is too small");

        if (position.bid > 0 && position.bidder != address(0)) {
            token.safeTransfer(position.bidder, position.bid);
        }

        uint256 previousBid = position.bid;
        address previousBidder = position.bidder;

        token.safeTransferFrom(_msgSender(), address(this), _bid);

        position.bid = _bid;
        position.bidder = _msgSender();

        if ((position.endDate - block.timestamp) < extensionSpan) {
            position.endDate += extensionSpan;
        }

        emit NewBid(
            _id,
            _bid,
            _msgSender(),
            previousBid,
            previousBidder,
            position.endDate
        );
    }

    function stopAuction(uint256 _id) external {
        Position storage position = positions[_id];

        require(_msgSender() == position.owner, "Only owner can stop auction");
        require(!position.isFinished, "Auction is already finished");

        _closeAuction(_id);
    }

    function finishAuction(uint256 _id) external onlyRole(ADMIN_ROLE) {
        Position storage position = positions[_id];

        require(block.timestamp > position.endDate, "Auction is not over");
        require(!position.isFinished, "Auction is already finished");

        _closeAuction(_id);
    }

    function _closeAuction(uint256 _id) internal {
        Position storage position = positions[_id];

        IERC721Upgradeable nft = IERC721Upgradeable(position.collection);
        IERC20Upgradeable token = IERC20Upgradeable(position.currency);

        if (position.bid > 0 && position.bidder != address(0)) {
            nft.safeTransferFrom(address(this), position.bidder, position.tokenId);

            uint256 fee = _calculateFee(position.bid, sellerFee);

            token.safeTransfer(feeAddress, fee);
            token.safeTransfer(position.owner, position.bid - fee);
        }
        else {
            nft.safeTransferFrom(address(this), position.owner, position.tokenId);
        }

        position.isFinished = true;

        emit CloseAuction(
            _id,
            position.collection,
            position.tokenId,
            position.bidder,
            position.bid,
            position.currency
        );
    }

    function _calculateFee(uint256 _amount, uint256 _fee) internal pure returns (uint256) {
        return (_amount * _fee) / 10000;
    }

    function _getMinStep(uint256 _price, uint8 decimals) internal pure returns (uint256) {
        uint256 multiplier = 10 ** decimals;
        if (_price <= 99 * multiplier) return multiplier;
        else if (_price < 999 * multiplier) return 10 * multiplier;
        else return 100 * multiplier;
    }

    function withdraw(address _currency, address _to, uint256 _amount) external onlyRole(ADMIN_ROLE) {
        IERC20Upgradeable(_currency).safeTransfer(_to, _amount);
    }

    function version() external pure returns (uint256) {
        return 103; // 1.0.3
    }
}