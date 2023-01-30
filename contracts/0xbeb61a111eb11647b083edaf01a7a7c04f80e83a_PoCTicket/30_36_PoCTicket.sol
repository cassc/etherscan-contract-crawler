// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity >=0.8.16 <0.9.0;

import {Address} from "openzeppelin-contracts/utils/Address.sol";
import {IERC721} from "openzeppelin-contracts/token/ERC721/IERC721.sol";

import {IDelegationRegistry} from
    "delegatecash/delegation-registry/IDelegationRegistry.sol";

import {ERC721ACommon, ERC721A} from "ethier/erc721/ERC721ACommon.sol";
import {BaseTokenURI} from "ethier/erc721/BaseTokenURI.sol";

import {PROOFTokens} from "poc-ticket/PROOFTokens.sol";
import {
    TokenRedemption, TokenRedemptionLib
} from "poc-ticket/TokenRedemption.sol";

import {PurchaseLimiter} from "poc-ticket/PurchaseLimiter.sol";
import {Upgrader, AccessControlEnumerable} from "poc-ticket/Upgrader.sol";
import {DelegationChecker} from "poc-ticket/DelegationChecker.sol";
import {Minter} from "poc-ticket/Minter.sol";
import {Airdropper} from "poc-ticket/Airdropper.sol";
import {UsageTracker} from "poc-ticket/UsageTracker.sol";
import {TransferRestriction} from
    "poc-ticket/TransferRestriction/ERC721ATransferRestricted.sol";

/**
 * @title Proof of Conference Tickets
 * @author Dave (@cxkoda)
 * @author KRO's kid
 * @custom:reviewer Arran (@divergencearran)
 */
contract PoCTicket is
    Minter,
    Airdropper,
    UsageTracker,
    PurchaseLimiter,
    Upgrader,
    DelegationChecker,
    BaseTokenURI
{
    using Address for address payable;
    using TokenRedemptionLib for TokenRedemption[];

    // =========================================================================
    //                          Errors
    // =========================================================================

    error DisallowedByCurrentStage();
    error TooManyPurchasesRequestedFromToken(
        IERC721 token, uint256 tokenId, uint256 numMax
    );
    error TokenNotOwnedByOrDelegatedToCaller(IERC721, uint256);
    error InvalidPayment(uint256 want);

    error TokenNotOwnedByVault(IERC721 token, uint256 tokenId);

    // =========================================================================
    //                           Types
    // =========================================================================

    /**
     * @notice The different stages of the ticket sale.
     * @dev Some methods are only accessible for some stages. See also the
     * `Steering` section for more information.
     * @dev The ordering is very important as each stage's permissions are a
     * strict sub set of the next stage and this is assumed when checking.
     */
    enum Stage {
        Closed,
        ProofCollective,
        Moonbirds,
        Oddities,
        GeneralAdmission
    }

    /**
     * @notice Information about a given ticket.
     * @dev Intended to interact with the dApp frontend.
     */
    struct TokenInfo {
        bool upgraded;
        bool airdropped;
        bool upgradable;
        bool upgradedFreeOfCharge;
        uint256 revealBlockNumber;
    }

    /**
     * @notice Helper struct to initialise the contract.
     * @
     */
    struct ERC721MetadataSetup {
        string name;
        string symbol;
        string baseTokenURI;
    }

    // =========================================================================
    //                           Constants
    // =========================================================================

    /**
     * @notice The PROOF Collective token.
     */
    IERC721 private immutable _proof;

    /**
     * @notice The Moonbirds token.
     */
    IERC721 private immutable _moonbirds;

    /**
     * @notice The Oddities token.
     */
    IERC721 private immutable _oddities;

    // =========================================================================
    //                           Storage
    // =========================================================================

    /**
     * @notice The current stage of the contract.
     * @dev Some methods are only accessible for some stages. See also the
     * `Steering` section for more information.
     */
    Stage public stage;

    /**
     * @notice The receiver of primary sales funds.
     */
    address payable internal _salesReceiver;

    /**
     * @notice The reduced price of a ticket for PROOF-ecosystem NFT holders.
     */
    uint128 public reducedTicketPrice;

    /**
     * @notice The price of a ticket during the general admission sale.
     */
    uint128 public fullTicketPrice;

    // =========================================================================
    //                           Constructor
    // =========================================================================

    constructor(
        address admin,
        address steerer,
        ERC721MetadataSetup memory setup,
        PROOFTokens memory tokens,
        IDelegationRegistry delegationRegistry,
        address payable salesReceiver,
        address bnSigner
    )
        ERC721ACommon(
            admin,
            steerer,
            setup.name,
            setup.symbol,
            payable(address(0xdeadface)),
            0
        )
        BaseTokenURI(setup.baseTokenURI)
        Upgrader(125, bnSigner) // 1.25 %
        DelegationChecker(tokens, delegationRegistry)
    {
        _proof = tokens.proof;
        _moonbirds = tokens.moonbirds;
        _oddities = tokens.oddities;

        fullTicketPrice = 1.5 ether;
        reducedTicketPrice = 0.75 ether;

        _salesReceiver = salesReceiver;

        _grantRole(AIRDROPPER_ROLE, steerer);
        _grantRole(PURCHASE_LIMIT_SETTER_ROLE, steerer);
        _grantRole(UPGRADER_ROLE, steerer);

        _setTransferRestriction(TransferRestriction.OnlyMint);
    }

    // =========================================================================
    //                           Metadata
    // =========================================================================

    /**
     * @notice Returns information about a given ticket.
     * @dev Intended to interact with the dApp frontend.
     */
    function tokenInfos(uint256[] calldata tokenIds)
        external
        view
        returns (TokenInfo[] memory infos)
    {
        infos = new TokenInfo[](tokenIds.length);
        for (uint256 i; i < tokenIds.length; ++i) {
            uint256 ticketId = tokenIds[i];
            bool airdropped = _airdropped(ticketId);
            infos[i] = TokenInfo({
                upgraded: upgraded(ticketId),
                airdropped: airdropped,
                upgradable: _upgradable(ticketId),
                upgradedFreeOfCharge: _upgradedFreeOfCharge(ticketId),
                revealBlockNumber: airdropped ? 0 : _revealBlockNumber(ticketId)
            });
        }
    }

    // =========================================================================
    //                           Mint
    // =========================================================================

    /**
     * @notice Interface to purchase a Proof of Conference ticket.
     * @param vault The vault address if delegation is used. Otherwise has to be
     * the caller.
     * @param delegationType The finest-grained type of delegation that is
     * applicable to all tokens that will be used for redemption.
     * @param pcRedemptions The redemptions via Proof Collective tokens
     * @param mbRedemptions The redemptions via Moonbird tokens
     * @param oddRedemptions The redemptions via Oddity tokens
     * @param numGA The number of general admission purchases.
     */
    function purchase(
        address vault,
        IDelegationRegistry.DelegationType delegationType,
        TokenRedemption[] calldata pcRedemptions,
        TokenRedemption[] calldata mbRedemptions,
        TokenRedemption[] calldata oddRedemptions,
        uint256 numGA
    ) external payable {
        // Checks

        // Checking this first to revert as early as possible in the case of a
        // race for tickets.
        uint256 num = pcRedemptions.totalNum() + mbRedemptions.totalNum()
            + oddRedemptions.totalNum() + numGA;
        _checkAndTrackPurchaseLimits(vault, num, numGA);

        _checkOwnership(vault, pcRedemptions, mbRedemptions, oddRedemptions);
        if (vault != msg.sender) {
            _checkDelegation(
                msg.sender,
                vault,
                delegationType,
                pcRedemptions,
                mbRedemptions,
                oddRedemptions
            );
        }
        if (numGA > 0 && stage != Stage.GeneralAdmission) {
            revert DisallowedByCurrentStage();
        }
        // Not checking other stages here since they are implicitly checked in
        // `purchaseCost`.

        uint256 cost =
            purchaseCost(pcRedemptions, mbRedemptions, oddRedemptions, numGA);
        if (msg.value != cost) {
            revert InvalidPayment(cost);
        }

        // Effects
        _trackTokenUsage(_proof, pcRedemptions);
        _trackTokenUsage(_moonbirds, mbRedemptions);
        _trackTokenUsage(_oddities, oddRedemptions);

        // Interactions
        _salesReceiver.sendValue(msg.value);
        _mintPurchase(msg.sender, num);
    }

    /**
     * @notice The cost for a ticket purchase.
     * @param pcRedemptions The redemptions via Proof Collective tokens
     * @param mbRedemptions The redemptions via Moonbird tokens
     * @param oddRedemptions The redemptions via Oddity tokens
     * @param numGA The number of general admission purchases.
     */
    function purchaseCost(
        TokenRedemption[] calldata pcRedemptions,
        TokenRedemption[] calldata mbRedemptions,
        TokenRedemption[] calldata oddRedemptions,
        uint256 numGA
    ) public view returns (uint256) {
        (
            uint256[] memory pcCosts,
            uint256[] memory mbCosts,
            uint256[] memory oddCosts
        ) = _costsPerTokenRedemption();

        uint256 totalCost = 0;
        totalCost += _redemptionCost(_proof, pcCosts, pcRedemptions);
        totalCost += _redemptionCost(_moonbirds, mbCosts, mbRedemptions);
        totalCost += _redemptionCost(_oddities, oddCosts, oddRedemptions);
        totalCost += numGA * fullTicketPrice;

        return totalCost;
    }

    /**
     * @notice Returns the costs for the n-th ticket purchase using a PROOF
     * ecosystem token.
     * @dev The length of the individual arrays tell how often a token can be
     * used.
     */
    function _costsPerTokenRedemption()
        internal
        view
        returns (
            uint256[] memory pcCosts,
            uint256[] memory mbCosts,
            uint256[] memory oddCosts
        )
    {
        uint256 rPrice = reducedTicketPrice;
        if (stage == Stage.ProofCollective) {
            pcCosts = new uint[](1);
            // pcCosts[0] deliberately left as 0
        }
        if (stage >= Stage.Moonbirds) {
            pcCosts = new uint[](2);
            // pcCosts[0] deliberately left as 0
            pcCosts[1] = rPrice;

            pcCosts = new uint[](2);
            pcCosts[1] = reducedTicketPrice;

            mbCosts = new uint[](2);
            mbCosts[0] = rPrice;
            mbCosts[1] = rPrice;
        }
        if (stage >= Stage.Oddities) {
            oddCosts = new uint[](1);
            oddCosts[0] = rPrice;
        }
    }

    /**
     * @notice Frontend interface to get the number of tickets that can be
     * purchased per token.
     */
    function numTicketsPerToken()
        external
        view
        returns (uint256, uint256, uint256)
    {
        (
            uint256[] memory pcCosts,
            uint256[] memory mbCosts,
            uint256[] memory oddCosts
        ) = _costsPerTokenRedemption();
        return (pcCosts.length, mbCosts.length, oddCosts.length);
    }

    /**
     * @notice Computes the cost for ticket purchases via token redemptions.
     * @param token The token contract.
     * @param costs A list of costs indexed by token usage, e.g. if purchasing
     * via a token costs 10 for the first time and 20 for second time, the list
     * would be `[10,20]`.
     * @param redemptions the list of redeeming tokens and number of
     * redemptions.
     */
    function _redemptionCost(
        IERC721 token,
        uint256[] memory costs,
        TokenRedemption[] calldata redemptions
    ) internal view returns (uint256) {
        if (redemptions.length == 0) {
            return 0;
        }

        // Validating that the tokenIDs are strictly monotonically increasing
        // guarantees that no token is supplied twice, which allows us to write
        // the rest of the view function more efficiently because we don't have
        // to track usage.
        redemptions.checkStrictlyMonotonicallyIncreasing();

        uint256 totalCost;
        for (uint256 i; i < redemptions.length; ++i) {
            uint256 costStart = numTokenUsed(token, redemptions[i].tokenId);
            uint256 costEnd = costStart + redemptions[i].num;

            if (costEnd > costs.length) {
                revert TooManyPurchasesRequestedFromToken(
                    token, redemptions[i].tokenId, costs.length
                );
            }

            for (uint256 usage = costStart; usage < costEnd; ++usage) {
                totalCost += costs[usage];
            }
        }

        return totalCost;
    }

    // =========================================================================
    //                           Steering
    // =========================================================================

    /**
     * @notice Sets the stage of the contract.
     * @dev Only callable by an admin.
     */
    function setStage(Stage stage_) external onlyRole(DEFAULT_STEERING_ROLE) {
        stage = stage_;
    }

    /**
     * @notice Sets the ticket purchase prices.
     */
    function setPurchasePrices(
        uint128 reducedTicketPrice_,
        uint128 fullTicketPrice_
    ) external onlyRole(DEFAULT_STEERING_ROLE) {
        reducedTicketPrice = reducedTicketPrice_;
        fullTicketPrice = fullTicketPrice_;
    }

    /**
     * @notice Sets the receiver of funds.
     */

    function setSalesReceiver(address payable salesReceiver)
        external
        onlyRole(DEFAULT_STEERING_ROLE)
    {
        _salesReceiver = salesReceiver;
    }

    /**
     * @notice Airdrops a number of tickets to a given address.
     */
    function airdrop(address to, uint256 num)
        external
        bypassTransferRestriction
    {
        _doAirdrop(to, num);
    }

    // =========================================================================
    //                           Ownership verification
    // =========================================================================

    /**
     * @notice Convenience overload to check that the given address owns the
     * tokens for all redemptions.
     */
    function _checkOwnership(
        address vault,
        TokenRedemption[] calldata pcRedemptions,
        TokenRedemption[] calldata mbRedemptions,
        TokenRedemption[] calldata oddRedemptions
    ) internal view {
        _checkOwnership(vault, _proof, pcRedemptions);
        _checkOwnership(vault, _moonbirds, mbRedemptions);
        _checkOwnership(vault, _oddities, oddRedemptions);
    }

    /**
     * @notice Checks that a given address own the redeeming tokens of a certain
     * kind.
     */
    function _checkOwnership(
        address vault,
        IERC721 token,
        TokenRedemption[] calldata redemptions
    ) internal view {
        for (uint256 i; i < redemptions.length; ++i) {
            if (token.ownerOf(redemptions[i].tokenId) != vault) {
                revert TokenNotOwnedByVault(token, redemptions[i].tokenId);
            }
        }
    }

    // =========================================================================
    //                           Upgrader Upgrades
    // =========================================================================

    /**
     * @notice Returns the receiver of the upgade sales.
     * @dev Callback required by the `Upgrader`.
     */
    function _upgradeSalesReceiver()
        internal
        view
        virtual
        override(Upgrader)
        returns (address payable)
    {
        return _salesReceiver;
    }

    /**
     * @notice Returns the maximum number of upgradable tokens.
     */
    function _maxUpgradesSellable()
        internal
        view
        virtual
        override
        returns (uint256)
    {
        if (stage == Stage.ProofCollective) {
            return 400;
        }
        if (stage == Stage.Moonbirds) {
            return 700;
        }
        if (stage == Stage.Oddities || stage == Stage.GeneralAdmission) {
            return 800;
        }

        return 0;
    }

    /**
     * @notice Returns the number of the block that is used to derive the
     * salt for the randomised upgrade of a given ticket.
     */
    function _revealBlockNumber(uint256 ticketId)
        internal
        view
        override
        returns (uint256)
    {
        return _mintBlockNumber(ticketId) + 1;
    }

    // =========================================================================
    //                           Internals
    // =========================================================================

    /**
     * @dev Inheritance resolution.
     */
    function _baseURI()
        internal
        view
        virtual
        override(ERC721A, BaseTokenURI)
        returns (string memory)
    {
        return BaseTokenURI._baseURI();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721ACommon, AccessControlEnumerable)
        returns (bool)
    {
        return ERC721A.supportsInterface(interfaceId);
    }

    function _airdropped(uint256 ticketId)
        internal
        view
        override(Minter, Upgrader)
        returns (bool)
    {
        return Minter._airdropped(ticketId);
    }

    function _mixHashOfTicket(uint256 ticketId)
        internal
        view
        override(Minter, Upgrader)
        returns (uint256)
    {
        return Minter._mixHashOfTicket(ticketId);
    }

    function _exists(uint256 tokenId)
        internal
        view
        virtual
        override(ERC721A, Upgrader)
        returns (bool)
    {
        return ERC721A._exists(tokenId);
    }

    function _mintAirdrop(address to, uint256 num)
        internal
        virtual
        override(Minter, Airdropper)
    {
        Minter._mintAirdrop(to, num);
    }
}