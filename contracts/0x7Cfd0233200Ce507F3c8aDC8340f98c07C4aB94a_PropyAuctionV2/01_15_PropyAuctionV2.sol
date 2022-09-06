// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';

import './IWhitelist.sol';
import './TimeContract.sol';


contract PropyAuctionV2 is AccessControl, TimeContract {
    using SafeERC20 for IERC20;
    using Address for *;

    bytes32 public constant CONFIG_ROLE = keccak256('CONFIG_ROLE');
    bytes32 public constant FINALIZE_ROLE = keccak256('FINALIZE_ROLE');
    uint32 public constant BID_DEADLINE_EXTENSION = 15 minutes;
    uint32 public constant MAX_AUCTION_LENGTH = 30 days;
    IWhitelist public immutable whitelist;

    // Auction ID is constructed as keccak256(abi.encodePacked(address(nft), uint256(nftId), uint32(startDate)))
    mapping(bytes32 => Auction) internal auctions;
    mapping(bytes32 => mapping(address => uint)) internal bids;
    mapping(address => uint) public unclaimed;

    struct Auction {
        uint128 minBid;
        uint32 deadline;
        uint32 finalizeTimeout;
        bool finalized;
    }

    event TokensRecovered(address token, address to, uint value);
    event Bid(IERC721 nft, uint nftId, uint32 start, address user, uint value);
    event Claimed(IERC721 nft, uint nftId, uint32 start, address user, uint value);
    event Withdrawn(address user, uint value);
    event Finalized(IERC721 nft, uint nftId, uint32 start, address winner, uint winnerBid);
    event AuctionAdded(IERC721 nft, uint nftId, uint32 start, uint32 deadline, uint128 minBid, uint32 timeout);
    event MinBidUpdated(IERC721 nft, uint nftId, uint32 start, uint128 minBid);
    event DeadlineExtended(IERC721 nft, uint nftId, uint32 start, uint32 deadline);

    modifier onlyWhitelisted() {
        require(whitelist.whitelist(_msgSender()), "Auction: User is not whitelisted");
        _;
    }

    constructor(
        address _owner,
        address _configurator,
        address _finalizer,
        IWhitelist _whitelist
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _grantRole(CONFIG_ROLE, _configurator);
        _grantRole(FINALIZE_ROLE, _finalizer);
        whitelist = _whitelist;
    }

    function _auctionId(IERC721 _nft, uint _nftId, uint32 _start) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(_nft, _nftId, _start));
    }

    function getAuction(IERC721 _nft, uint _nftId, uint32 _start) external view returns(Auction memory) {
        return auctions[_auctionId(_nft, _nftId, _start)];
    }

    function getBid(IERC721 _nft, uint _nftId, uint32 _start, address _bidder) public view returns(uint) {
        return bids[_auctionId(_nft, _nftId, _start)][_bidder];
    }

    function bid(IERC721 _nft, uint _nftId, uint32 _start) external payable virtual {
        _bid(_nft, _nftId, _start, msg.value);
    }

    function _bid(IERC721 _nft, uint _nftId, uint32 _start, uint _amount) internal onlyWhitelisted {
        require(_amount > 0, 'Auction: Zero bid not allowed');
        require(passed(_start), 'Auction: Not started yet');
        bytes32 id = _auctionId(_nft, _nftId, _start);
        Auction memory auction = auctions[id];

        require(auction.deadline > 0, 'Auction: Not found');
        require(notPassed(auction.deadline), 'Auction: Already finished');

        if (passed(auction.deadline - BID_DEADLINE_EXTENSION)) {
            uint32 newDeadline = uint32(block.timestamp) + BID_DEADLINE_EXTENSION;
            auctions[id].deadline = newDeadline;
            emit DeadlineExtended(_nft, _nftId, _start, newDeadline);
        }

        uint newBid = bids[id][_msgSender()] + _amount;
        require(newBid >= auction.minBid, 'Auction: Can not bid less than allowed');

        bids[id][_msgSender()] = newBid;
        emit Bid(_nft, _nftId, _start, _msgSender(), newBid);
    }

    function addAuction(IERC721 _nft, uint _nftId, uint32 _start, uint32 _deadline, uint128 _minBid, uint32 _finalizeTimeout) external onlyRole(CONFIG_ROLE) {
        require(_minBid > 0, 'Auction: Invalid min bid');
        require(notPassed(_start), 'Auction: Start should be more than current time');
        require(_deadline > _start, 'Auction: Deadline should be more than start time');
        require(MAX_AUCTION_LENGTH >= _deadline - _start, 'Auction: Auction time is more than max allowed');
        bytes32 id = _auctionId(_nft, _nftId, _start);
        Auction storage auction = auctions[id];
        require(auction.deadline == 0, 'Auction: Already added');

        auction.minBid = _minBid;
        auction.deadline = _deadline;
        auction.finalizeTimeout = _finalizeTimeout;

        emit AuctionAdded(_nft, _nftId, _start, _deadline, _minBid, _finalizeTimeout);
    }

    function updateMinBid(IERC721 _nft, uint _nftId, uint32 _start, uint128 _minBid) external onlyRole(CONFIG_ROLE) {
        require(_minBid > 0, 'Auction: Invalid min bid');
        Auction storage auction = auctions[_auctionId(_nft, _nftId, _start)];
        require(auction.deadline > 0, 'Auction: Not found');
        auction.minBid = _minBid;

        emit MinBidUpdated(_nft, _nftId, _start, _minBid);
    }

    function updateDeadline(IERC721 _nft, uint _nftId, uint32 _start, uint32 _deadline) external onlyRole(CONFIG_ROLE) {
        bytes32 id = _auctionId(_nft, _nftId, _start);
        Auction memory auction = auctions[id];
        require(auction.deadline > 0, 'Auction: Not found');
        require(_deadline > auction.deadline, 'Auction: New deadline should be more than previous');
        require(_deadline - _start <= MAX_AUCTION_LENGTH, 'Auction: Auction time is more than max allowed');
        Auction storage auctionUpdate = auctions[id];
        auctionUpdate.deadline = _deadline;

        emit DeadlineExtended(_nft, _nftId, _start, _deadline);
    }

    function finalize(
        IERC721 _nft,
        uint _nftId,
        uint32 _start,
        address _winner,
        address[] memory _payoutAddresses,
        uint256[] memory _payoutAddressValues
    ) external onlyRole(FINALIZE_ROLE) {
        bytes32 id = _auctionId(_nft, _nftId, _start);
        require(_payoutAddresses.length > 0, "Auction: Payout address(es) required");
        require(_payoutAddresses.length == _payoutAddressValues.length, "Auction: Each fixed payout address must have a corresponding fee");
        Auction memory auction = auctions[id];
        require(auction.deadline > 0, 'Auction: Not found');
        require(!auction.finalized, 'Auction: Already finalized');
        require(notPassed(auction.deadline + auction.finalizeTimeout), 'Auction: Finalize expired, auction cancelled');
        uint winnerBid = bids[id][_winner];
        require(winnerBid > 0, 'Auction: Winner did not bid');

        bids[id][_winner] = 0;
        auctions[id].finalized = true;

        _nft.safeTransferFrom(_nft.ownerOf(_nftId), _winner, _nftId);

        uint256 totalPayout;
        for(uint256 i = 0; i < _payoutAddresses.length; i++) {
            require((_payoutAddressValues[i] > 0) && (_payoutAddressValues[i] <= winnerBid), "Auction: _payoutAddressValues may not contain values of 0 and may not exceed the winnerBid value");
            _pay(payable(_payoutAddresses[i]), _payoutAddressValues[i]);
            totalPayout += _payoutAddressValues[i];
        }
        require(totalPayout == winnerBid, "Auction: _payoutAddressValues must equal winnerBid");

        emit Finalized(_nft, _nftId, _start, _winner, winnerBid);
    }

    function claim(IERC721 _nft, uint _nftId, uint32 _start) external {
        claimFor(_nft, _nftId, _start, _msgSender());
    }

    function claimFor(IERC721 _nft, uint _nftId, uint32 _start, address _user) public {
        bytes32 id = _auctionId(_nft, _nftId, _start);
        Auction memory auction = auctions[id];
        require(_isDone(auction), 'Auction: Not done yet');
        uint userBid = bids[id][_user];
        require(userBid > 0, 'Auction: Nothing to claim');

        _claimFor(_nft, _nftId, _start, _user, userBid);
    }

    function _claimFor(IERC721 _nft, uint _nftId, uint32 _start, address _user, uint _userBid) internal {
        bytes32 id = _auctionId(_nft, _nftId, _start);
        bids[id][_user] = 0;
        unclaimed[_user] += _userBid;
        emit Claimed(_nft, _nftId, _start, _user, _userBid);
    }

    function withdraw() external {
        _withdraw(_msgSender());
    }

    function withdrawFor(address _user) external onlyRole(CONFIG_ROLE) {
        _withdraw(_user);
    }

    function _withdraw(address _user) internal {
        uint toWithdraw = unclaimed[_user];
        require(toWithdraw > 0, 'Auction: Nothing to withdraw');

        unclaimed[_user] = 0;
        _pay(_user, toWithdraw);
        emit Withdrawn(_user, toWithdraw);
    }

    function claimAndWithdrawFor(IERC721 _nft, uint _nftId, uint32 _start, address[] calldata _users) external onlyRole(CONFIG_ROLE) {
        bytes32 id = _auctionId(_nft, _nftId, _start);

        Auction memory auction = auctions[id];
        require(auction.deadline > 0, 'Auction: Not found');
        require(_isDone(auction), 'Auction: Not done yet');

        for (uint i = 0; i < _users.length; i++) {
            address _user = _users[i];
            uint _userBid = bids[id][_user];
            if (_userBid > 0) {
                _claimFor(_nft, _nftId, _start, _user, _userBid);
            }
            if (unclaimed[_user] > 0) {
                _withdraw(_user);
            }
        }
    }

    function claimAndWithdraw(IERC721 _nft, uint _nftId, uint32 _start) external {
        claimFor(_nft, _nftId, _start, _msgSender());
        _withdraw(_msgSender());
    }

    function recoverTokens(IERC20 _token, address _destination, uint _amount) public virtual onlyRole(CONFIG_ROLE) {
        require(_destination != address(0), 'Auction: Zero address not allowed');

        _token.safeTransfer(_destination, _amount);
        emit TokensRecovered(address(_token), _destination, _amount);
    }

    function isDone(IERC721 _nft, uint _nftId, uint32 _start) external view returns(bool) {
        return _isDone(auctions[_auctionId(_nft, _nftId, _start)]);
    }

    function _isDone(Auction memory _auction) internal view returns(bool) {
        return _auction.finalized || passed(_auction.deadline + _auction.finalizeTimeout);
    }

    function _pay(address _to, uint _amount) internal virtual {
        payable(_to).sendValue(_amount);
    }
}