// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

import "./interfaces/IAuctionManager.sol";

error AuctionManager_AuctionEnded();
error AuctionManager_AuctionNotClosed();
error AuctionManager_AuctionNotEnded();
error AuctionManager_InvalidAuction();
error AuctionManager_InvalidBid();
error AuctionManager_InvalidWinningBid();
error AuctionManager_InvalidTokenType();
error AuctionManager_NothingToSettle();

/**
                        .             :++-
                       *##-          +####*          -##+
                       *####-      :%######%.      -%###*
                       *######:   =##########=   .######*
                       *#######*-#############*-*#######*
                       *################################*
                       *################################*
                       *################################*
                       *################################*
                       *################################*
                       :*******************************+.

                .:.
               *###%*=:
              .##########+-.
              +###############=:
              %##################%+
             =######################
             -######################++++++++++++++++++=-:
              =###########################################*:
               =#############################################.
  +####%#*+=-:. -#############################################:
  %############################################################=
  %##############################################################
  %##############################################################%=----::.
  %#######################################################################%:
  %##########################################+:    :+%#######################:
  *########################################*          *#######################
   -%######################################            %######################
     -%###################################%            #######################
       =###################################-          :#######################
     ....+##################################*.      .+########################
  +###########################################%*++*%##########################
  %#########################################################################*.
  %#######################################################################+
  ########################################################################-
  *#######################################################################-
  .######################################################################%.
     :+#################################################################-
         :=#####################################################:.....
             :--:.:##############################################+
   ::             +###############################################%-
  ####%+-.        %##################################################.
  %#######%*-.   :###################################################%
  %###########%*=*####################################################=
  %####################################################################
  %####################################################################+
  %#####################################################################.
  %#####################################################################%
  %######################################################################-
  .+*********************************************************************.
 * @title KaijuMart Auction Manager
 * @author Augminted Labs, LLC
 */
contract AuctionManager is IAuctionManager, AccessControl {
    bytes32 public constant KMART_CONTRACT_ROLE = keccak256("KMART_CONTRACT_ROLE");

    struct BidConfig {
        uint104 sigFigs;
        uint64 snipeThreshold;
        uint64 timeExtension;
    }

    BidConfig public bidConfig;
    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => mapping(address => uint104)) public bids;
    mapping(uint256 => address[]) public tiebrokenWinners;

    constructor(
        BidConfig memory _bidConfig,
        address admin
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);

        bidConfig = _bidConfig;
    }

    /**
     * @notice Return an auction
     * @param id Identifier of the auction
     */
    function get(uint256 id) public view returns (Auction memory) {
        return auctions[id];
    }

    /**
     * @notice Return an account's current bid on an auction
     * @param id Identifier of the auction
     * @param account Address to return the current bid of
     */
    function getBid(uint256 id, address account) public view returns (uint104) {
        return bids[id][account];
    }

    /**
     * @notice Returns whether or not an account is included in a list of addresses
     * @param addresses List of addresses
     * @param account Address to search for
     */
    function includes(
        address[] memory addresses,
        address account
    )
        internal
        pure
        returns (bool)
    {
        for (uint256 i; i < addresses.length;) {
            if (addresses[i] == account) return true;
            unchecked { ++i; }
        }

        return false;
    }

    /**
     * @notice Return the winner status of an account for an auction
     * @param id Identifier of the auction
     * @param sender Account to check winner status for
     */
    function isWinner(
        uint256 id,
        address sender
    )
        public
        view
        override
        returns (bool)
    {
        uint104 lowestWinningBid = auctions[id].lowestWinningBid;

        if (lowestWinningBid == 0) revert AuctionManager_AuctionNotClosed();

        uint104 _bid = bids[id][sender];

        if (_bid > lowestWinningBid) return true;
        else if (_bid < lowestWinningBid) return false;
        else return tiebrokenWinners[id].length == 0 || includes(tiebrokenWinners[id], sender);
    }

    /**
     * @notice Normalize a bid to the configured number of significant figures
     * @param _bid Value to normalize
     */
    function normalizeBid(uint104 _bid) public view returns (uint104) {
        unchecked {
            return (_bid / bidConfig.sigFigs) * bidConfig.sigFigs;
        }
    }

    /**
     * @notice Set new configuration for auction bids
     * @param _bidConfig New bid configuration
     */
    function setBidConfig(BidConfig calldata _bidConfig) public onlyRole(DEFAULT_ADMIN_ROLE) {
        bidConfig = _bidConfig;
    }

    /**
     * @notice Create a new auction
     * @param id Identifier of the auction
     * @param auction Configuration details of the new auction
     */
    function create(
        uint256 id,
        CreateAuction calldata auction
    )
        public
        override
        onlyRole(KMART_CONTRACT_ROLE)
    {
        if (
            auction.endsAt < block.timestamp + bidConfig.snipeThreshold ||
            auction.reservePrice == 0 ||
            auction.winners == 0
        ) revert AuctionManager_InvalidAuction();

        auctions[id] = Auction({
            reservePrice: auction.reservePrice,
            winners: auction.winners,
            endsAt: auction.endsAt,
            lowestWinningBid: 0
        });
    }

    /**
     * @notice Close an auction
     * @param id Identifier of the auction
     * @param lowestWinningBid Lowest amount that is considered a winning bid
     * @param _tiebrokenWinners An array of winning addresses use to tiebreak identical winning bids
     */
    function close(
        uint256 id,
        uint104 lowestWinningBid,
        address[] calldata _tiebrokenWinners
    )
        public
        override
        onlyRole(KMART_CONTRACT_ROLE)
    {
        if (block.timestamp < auctions[id].endsAt) revert AuctionManager_AuctionNotEnded();
        if (lowestWinningBid < auctions[id].reservePrice) revert AuctionManager_InvalidWinningBid();

        auctions[id].lowestWinningBid = lowestWinningBid;
        if (_tiebrokenWinners.length > 0) tiebrokenWinners[id] = _tiebrokenWinners;
    }

    /**
     * @notice Replaces the sender's current bid on an auction lot
     * @param id Identifier of the auction
     * @param value New bid to replace the current bid with
     * @param sender Account placing the bid
     * @return uint104 Increase from the previous bid
     */
    function bid(
        uint256 id,
        uint104 value,
        address sender
    )
        public
        override
        onlyRole(KMART_CONTRACT_ROLE)
        returns (uint104)
    {
        if (auctions[id].endsAt < block.timestamp) revert AuctionManager_AuctionEnded();

        uint104 newBid = normalizeBid(value);
        uint104 increase = newBid - bids[id][sender];

        if (newBid < auctions[id].reservePrice || increase == 0) revert AuctionManager_InvalidBid();

        if (auctions[id].endsAt - block.timestamp < bidConfig.snipeThreshold)
            auctions[id].endsAt += bidConfig.timeExtension;

        bids[id][sender] = newBid;

        return increase;
    }

    /**
     * @notice Settle an auction for an account
     * @param id Identifier of the auction
     * @param sender Account to settle the auction for
     */
    function settle(
        uint256 id,
        address sender
    )
        public
        override
        onlyRole(KMART_CONTRACT_ROLE)
        returns (uint104)
    {
        uint104 amount = bids[id][sender];

        if (amount == 0) revert AuctionManager_NothingToSettle();

        bids[id][sender] = 0;

        return amount;
    }
}