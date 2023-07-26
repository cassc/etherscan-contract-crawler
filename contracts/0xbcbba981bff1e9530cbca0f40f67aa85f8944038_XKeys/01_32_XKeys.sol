/*
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@      @@@,    @@@@@(     @@@    @/   &#       @        [email protected]@@@@@  *@@@@@@@@@@* %@@@
@@        V.    @@@@@      @@@     /    @       @         %@@@        @@,        @@
@@   @>   @.    @@@@@       @@          @    @@@@@@,    @@@@@@@    @@@     /@*  *@@
@@        ^.    @@@@        (@          @      /@@@,    @&     #&       %@@@@@@@@@@
@@       (@,    @@@@    %   (@          @      /@@@,    @      @&      [email protected]@@@@@@@@@@
@@   ,@@@@@,    @@@#         @          @    @@@@@@,    @@@@@@@*    @      @@@  @@@
@@   ,@@@@@,       #   #%    @    @     @       @@@,    @@@@@@      /@@&         @@
@@   ,@@@@@,       #   #@,   @    @/    @       @@@,    @@@@@@@     @@@@@@@(    *@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

Planet-X X-Keys
playplanetx.com
Planet-X Ltd © 2023 | All rights reserved
cfec19b223b57f38d96f52994b515d455b5dd1bb3741b8791ada32f862e95879
*/

// #region Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions
// #endregion

// SPDX-License-Identifier: UNLICENCED
pragma solidity 0.8.20;

import "../base/Withdrawer.sol";
import "./XRaffleBase.sol";
import "../auctions/XAuctions.sol";

// #region errors

error NullAddressParameters();
error ForbiddenDuringRaffle();

// #endregion

/**
 X-Keys raffle auctions contract.
 @dev This contract is used to mint an X-Key NFTs in 3 different ways:
    1. Raffle: users can mint an XKey for free by owning a specific NFT.
    2. Auction: users can bid for a chance to buy an XKey in an auction round.
    3. Limited airdrop, see RESERVED_SUPPLY
 */
contract XKeys is XRaffleBase, XAuctions, ReentrancyGuard {
    enum RoundType {
        None,
        Raffle,
        Auction
    }

    // the total number of X Key NFTs that have been allocated by rounds created so far
    uint16 public totalSupplyAllocated;

    // the total number of X Key NFTs that can be minted
    uint16 private constant MAX_SUPPLY = 500;

    // the number of reserved X Keys for team & marketing
    uint8 private constant RESERVED_SUPPLY = 25;

    // reserved tokens already minted
    uint8 public mintedReserved;

    // current round type
    RoundType currentRound;

    modifier requireRound(RoundType _round) {
        _checkRoundType(_round);
        _;
    }

    constructor(
        address vrfCoordinator,
        uint64 vrfSubscriptionId,
        bytes32 vrfKeyHash,
        address delegateRegistryAddress
    )
        payable
        XRaffleBase(
            "X-Key",
            "X-KEY",
            500, // 5% royalty
            msg.sender, // royalty recipient
            vrfCoordinator,
            vrfSubscriptionId,
            vrfKeyHash,
            delegateRegistryAddress,
            48 hours // reward claim deadline for raffle rounds
        )
    {}

    // #region External functions
    function mintReservedTokens(uint8 number, address to) external payable onlyOwner {
        // don't allow airdrops during a raffle
        if (currentRound == RoundType.Raffle) {
            revert ForbiddenDuringRaffle();
        }

        uint8 _minted = mintedReserved;
        if (_minted + number > RESERVED_SUPPLY) {
            revert ExceedsMaxSupply();
        }
        mintedReserved = _minted + number;
        _mint(to, number);
    }

    function closeRound() external payable onlyOwner {
        _closeRound(true);
    }

    function releaseNewRaffleRound(
        uint16 _supply,
        address requiredOwnership
    ) external payable onlyOwner {
        // no raffle can be created with less than 2 tokens
        if (_supply < 2) {
            revert SupplyTooSmall();
        }

        // the contract must be an ERC721 contract
        if (!_isNFTContract(requiredOwnership)) {
            revert NotAnNFTContract(requiredOwnership);
        }

        if (currentRound == RoundType.Raffle) {
            revert RoundMustBeClosed();
        }

        // supply must not exceed max supply, taking into account the reserved supply
        _addNewRoundWithSupply(_supply);

        uint8 _roundId = roundId;

        raffles[roundId] = Raffle({
            id: _roundId,
            requiredOwnership: requiredOwnership,
            supply: _supply,
            supplyLeft: _supply,
            stage: RaffleStage.Open,
            startTokenId: uint16(_totalMinted() + 1)
        });

        // set the current round to raffle
        currentRound = RoundType.Raffle;

        emit RoundCreated(_roundId, requiredOwnership, _supply);
    }

    function releaseNewAuctionRound(
        uint16 _supply,
        uint8 _maxWinPerWallet,
        uint64 _minimumBid
    ) external payable onlyOwner requireRound(RoundType.None) {
        // _checkCreateParams(_supply, _maxWinPerWallet, _minimumBid);
        _addNewRoundWithSupply(_supply);

        // set the current round to auction
        currentRound = RoundType.Auction;

        _saveNewAuction(roundId, _supply, _maxWinPerWallet, _minimumBid);
    }

    /**
     * @notice Respond to a mint request
     * @param _roundId The round id
     * @param minter The minter address
     * @param approved Whether the mint request is approved
     *  @dev To ensure 1 holder can only claim 1 XKey per round, we need to verify
     *  that the NFT which they hold, allowing them to mint, is not already used by another minter
     * this is done externally by our backend, and the result is passed to this function
     */
    function validateMintRequest(
        uint8 _roundId,
        address minter,
        bool approved
    ) external payable onlyOwner requireRound(RoundType.Raffle) {
        // mint if the request is approved
        uint256 _supplyLeft = _validateMintRequest(_roundId, minter, approved);

        if (_supplyLeft < 1) {
            // if the pool is full, close the round
            _closeRound(false);
        }
    }

    function mintXKey() external nonReentrant requireRound(RoundType.Raffle) {
        _mintInRaffle(roundId);
    }

    /**
     * @notice Claim an XKey from a hot wallet
     */
    function mintXKeyDelegated(
        address vault,
        address to
    ) external nonReentrant requireRound(RoundType.Raffle) {
        if (vault == address(0) || to == address(0)) {
            revert NullAddressParameters();
        }

        _mintInRaffleDelegated(vault, to, roundId);
    }

    /// @notice Claim the reward via a delegated wallet
    /// @param _roundId The round id
    /// @param vault The vault for which to check delegation for msg.sender
    function claimRewardDelegated(
        uint8 _roundId,
        address vault
    ) external isDelegated(vault) {
        _claimRewardInternal(_roundId, vault);
    }

    /// @notice Open a crate via a delegated wallet
    /// @param _crateId The crate id
    /// @param vault The vault which will
    function openCrateDelegated(
        uint16 _crateId,
        address vault
    ) external isDelegated(vault) {
        _openCrateInternal(_crateId, msg.sender);
    }

    // #region auction functions
    function startAuction() external payable onlyOwner requireRound(RoundType.Auction) {
        _startAuction(roundId);
    }

    function bid() external payable requireRound(RoundType.Auction) {
        XAuctions.bid(roundId);
    }

    function setPriceForAuction(
        uint8 _auctionId,
        uint64 newPrice
    ) external payable onlyOwner {
        _setPrice(_auctionId, newPrice);
    }

    function startClaimsForAuction(uint8 _auctionId) external payable onlyOwner {
        _startClaims(_auctionId);
    }

    /**
     * @notice Claim tokens and refund for a specific auction.
     */
    function claimForAuction(uint8 forAuctionId) external nonReentrant {
        // don't allow claims during an active raffle
        if (currentRound == RoundType.Raffle) {
            revert ForbiddenDuringRaffle();
        }
        _internalClaim(msg.sender, forAuctionId);
    }

    // function currentAuction()
    //     external
    //     view
    //     requireRound(RoundType.Auction)
    //     returns (Auction memory)
    // {
    //     return auctions[roundId];
    // }

    // #endregion

    /**
     * @notice Withdraw function for the owner
     * @dev since only NFT sales funds can be withdrawn at any time
     * and users' funds need to be protected, this is marked as nonReentrant
     */
    function withdraw(address payable receiver) external onlyOwner nonReentrant {
        _withdraw(receiver);
    }

    // #endregion

    // #region internal functions
    function _addNewRoundWithSupply(uint16 _newSupply) internal {
        // supply must not exceed max supply, taking into account the reserved supply
        uint16 _totalSupply = totalSupplyAllocated;
        if (_totalSupply + _newSupply > MAX_SUPPLY - RESERVED_SUPPLY) {
            revert ExceedsMaxSupply();
        }

        unchecked {
            // allocate the supply
            totalSupplyAllocated = _totalSupply + _newSupply;

            // increment the round id
            ++roundId;
        }
    }

    // #endregion

    // #region private functions

    function _checkRoundType(RoundType _round) private view {
        if (_round != currentRound) {
            revert InvalidRound();
        }
    }

    function _closeRound(bool checkSupply) private {
        RoundType _round = currentRound;

        if (_round == RoundType.None) {
            revert InvalidRound();
        }
        currentRound = RoundType.None;

        uint8 _roundId = roundId;
        if (_round == RoundType.Raffle) {
            if (raffles[_roundId].stage != RaffleStage.Open) {
                revert InvalidRaffleStage();
            }
            // close the round
            raffles[_roundId].stage = RaffleStage.Closed;

            // if the full supply allocated for this round is not claimed
            // release it back
            if (checkSupply) {
                uint16 _supplyLeft = raffles[_roundId].supplyLeft;
                if (_supplyLeft > 0) {
                    unchecked {
                        totalSupplyAllocated = totalSupplyAllocated - _supplyLeft;
                    }
                }
            }

            emit RoundClosed(roundId);
        } else {
            if (auctions[_roundId].stage != AuctionStage.Active) {
                revert AuctionMustBeActive();
            }
            // end the auction
            auctions[_roundId].stage = AuctionStage.Closed;
            activeAuctionId = 0;
            emit AuctionEnded(_roundId);
        }
    }
    // #endregion
}