// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import 'hardhat/console.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract WhitelistMarketplace is AccessControl, EIP712 {
    string private constant SIGNING_DOMAIN = "Bidding-Voucher";
    string private constant SIGNATURE_VERSION = "1";

    using Counters for Counters.Counter;

    bytes32 public constant BID_SIGNER = keccak256("BID_SIGNER");
    bytes32 public constant AUCTIONEER = keccak256("AUCTIONEER");

    Counters.Counter next_id;

    IERC20 currency;
    event ChangeCurrency(address currency_address);

    constructor (address currency_address, address bid_signer)
    EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
        _grantRole(DEFAULT_ADMIN_ROLE, tx.origin);
        changeCurrency(currency_address);

        _grantRole(AUCTIONEER, tx.origin);
        _grantRole(BID_SIGNER, bid_signer);
    }

    function changeCurrency(address currency_address) public onlyRole(DEFAULT_ADMIN_ROLE) {
        currency = IERC20(currency_address);
        emit ChangeCurrency(currency_address);
    }

    enum AuctionType {
        UNDEFINED, // Used for Null checks in mapping
        STANDARD, // Fixed price, sales continue until entry_limit is reached then the auction closes early
        RAFFLE // Unlimited entries are permitted; random selection of winners upon closing
        
                // Removed from Statement of Work by client
        // DUTCH, // Price starts high and declines by a fixed percentage on a timed schedule
        
                // Tricky; requires sorted list of applicants
        // WALKING_ENGLISH, // New entries must be higher than the lowest recorded bid
                         // once entry_limit is reached - the lowest bid gets purged to make room for new bidder
                         // closing occurs after a fixed amount of time has passed after the last successful bid
    }

    event AuctionAnnounced(uint256 db_id, uint256 auction_id);
    event AuctionUpdated(uint256 db_id, uint256 auction_id);
    event AuctionFinalized(uint256 indexed auction_id, address[] recipients);
    struct Auctionable {
        uint256 db_id;
        AuctionType style;

        // Timestamps
        uint256 opening;
        uint256 closing;

        uint256 price;

        // Total number of available entries (0 == infinite)
        uint256 entry_limit;
        // Limit for each wallet (0 == infinite)
        uint256 wallet_limit;

        // Some auctions require additional storage
        // Raffle Entropy
        uint256 extra_1;

        bool locked;
    }

    struct Entry {
        uint256 auction_id;
        address entrant;
        // address whitelist;
    }

    mapping(uint256 => Auctionable) public auctions;
    mapping(uint256 => Entry[]) public entries;
    mapping(address => mapping(uint256=>uint256)) public account_entry_limiter;

    mapping(bytes32 => bool) used_vouchers;

    event VoucherRedeemed(uint256 nonce);
    // The server prepares vouchers and delivers them upon voucher request from users.
    // Creation of vouchers can be limited and ordered by the server; eliminating gas wars
    struct BidVoucher {
        uint256 nonce;
        uint256 auction_id;
        address vouchee;
        // address whitelist;
        uint256 timestamp;

        bytes signature;
    }

    function validateAuction(Auctionable calldata auctionable) internal {
        require(auctionable.style != AuctionType.UNDEFINED, "Cannot create 0 type auction");
        require(auctionable.opening < auctionable.closing
            &&  auctionable.closing > block.timestamp, "Invalid Auction Timing");
    }

    function defineAuction(Auctionable calldata auctionable) public onlyRole(AUCTIONEER) {
        validateAuction(auctionable);
        next_id.increment();
        auctions[next_id.current()] = auctionable;
        emit AuctionAnnounced(auctionable.db_id, next_id.current());
    }

    function updateAuction(uint256 id, Auctionable calldata auctionable) public onlyRole(AUCTIONEER) {
        validateAuction(auctionable);
        auctions[id] = auctionable;
        emit AuctionUpdated(auctionable.db_id, id);
    }

    function _hashBidVoucher(BidVoucher calldata voucher) internal view returns (bytes32) {
        return keccak256(abi.encode(
                // keccak256("BidVoucher(uint256 nonce,uint256 auction_id,address vouchee,address whitelist,uint256 timestamp)"),
                keccak256("BidVoucher(uint256 nonce,uint256 auction_id,address vouchee,uint256 timestamp)"),
                voucher.nonce,
                voucher.auction_id,
                voucher.vouchee,
                // voucher.whitelist,
                voucher.timestamp
            ));
    }

    // Requires user to receive a signature from server's account
    function _verifyBidVoucher(BidVoucher calldata voucher) internal view returns (address, bytes32) {
        bytes32 hash = _hashBidVoucher(voucher);
        bytes32 digest = _hashTypedDataV4(hash);
        address signer = ECDSA.recover(digest, voucher.signature);
        require(hasRole(BID_SIGNER, signer), "Invalid Bid Signer");

        return (signer, hash);
    }

    function redeemVoucher(BidVoucher calldata v) public {
        // Confirm Voucher Validity
        require(v.vouchee == tx.origin, "Intercepted Voucher Detected");

        (, bytes32 hash) = _verifyBidVoucher(v);
        require(!used_vouchers[hash], "Voucher already used");
        used_vouchers[hash] = true;

        Auctionable memory auction = auctions[v.auction_id];

        require(auction.opening <= v.timestamp
            &&  auction.closing >= v.timestamp, "Invalid voucher timestamp");

        // Apply Bid
        require(currency.allowance(v.vouchee, address(this)) >= auction.price, "Allowance not available");
        require(auction.style == AuctionType.RAFFLE // (Raffles allow unlimited entries)
            || (auction.entry_limit  == 0 || entries[v.auction_id].length < auction.entry_limit),
                "Auction fully enrolled");
        require(auction.wallet_limit == 0 || account_entry_limiter[v.vouchee][v.auction_id] < auction.wallet_limit,
                "Account has max entries");

        account_entry_limiter[v.vouchee][v.auction_id] += 1;
        entries[v.auction_id].push(Entry(v.auction_id, v.vouchee));

        emit VoucherRedeemed(v.nonce);

        require(currency.transferFrom(v.vouchee, address(this), auction.price), "transferFrom failed; unknown reason");
    }

    function closeAuction(uint256 auction_id) public onlyRole(AUCTIONEER) {
        Auctionable storage auction = auctions[auction_id];
        require(auction.style != AuctionType.UNDEFINED, "Closing Undefined Auction");
        require(!auction.locked, "Auction already closed");
        auction.locked = true;

        Entry[] memory _list = entries[auction_id];
        if (
            auction.style == AuctionType.STANDARD    // Either we're dealing with a standard Auction
             || (   // Or it's a Raffle; but meets the criteria for all entries being winners
                    auction.style == AuctionType.RAFFLE 
                    && ( // One of two conditions is true
                             _list.length <= auction.entry_limit // We have less than the max entries
                          || auction.entry_limit == 0            // Entries are unlimited
                        )
                )

            ) {

            address[] memory recipients = new address[](_list.length);
            // address[] memory whitelists = new address[](_list.length);
            for (uint i = 0 ; i < _list.length ;){
                recipients[i] = _list[i].entrant;
                // whitelists[i] = _list[i].whitelist;

                unchecked{
                    i++;
                }
            }

            emit AuctionFinalized(auction_id, recipients/*, whitelists*/);
        } else { // The only remaining case is a Raffle which doesn't meet the criteria for all entries being winners
            // Need to randomly select the winners
            address[] memory recipients = new address[](auction.entry_limit);
            // address[] memory whitelists = new address[](auction.entry_limit);

            uint256 virtual_size = _list.length;
            for (uint i = 0 ; i < auction.entry_limit ; ) {
                uint256 index = uint256(keccak256(abi.encodePacked(blockhash(block.number-1), auction.extra_1, i))) % virtual_size;
                Entry memory e = _list[index];

                // Swap, delete, reduce size
                _list[index] = _list[virtual_size - 1];
                delete _list[virtual_size - 1];
                virtual_size -= 1;

                recipients[i] = e.entrant;
                // whitelists[i] = e.whitelist;

                unchecked{
                    i++;
                }
            }

            emit AuctionFinalized(auction_id, recipients/*, whitelists*/);
        }
    }

    /// @notice Returns the chain id of the current blockchain.
    /// @dev This is used to workaround an issue with ganache returning different values from the on-chain chainid() function and
    ///  the eth_chainId RPC method. See https://github.com/protocol/nft-website/issues/121 for context.
    function getChainID() external view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }
}