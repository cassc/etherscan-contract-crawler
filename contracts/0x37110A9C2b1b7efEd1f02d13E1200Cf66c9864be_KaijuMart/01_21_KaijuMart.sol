// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./interfaces/IKaijuMart.sol";

error KaijuMart_CannotClaimRefund();
error KaijuMart_CannotRedeemAuction();
error KaijuMart_InvalidRedeemerContract();
error KaijuMart_InvalidTokenType();
error KaijuMart_LotAlreadyExists();
error KaijuMart_LotDoesNotExist();
error KaijuMart_MustBeAKing();

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
 * @title KaijuMart
 * @author Augminted Labs, LLC
 */
contract KaijuMart is IKaijuMart, AccessControl, ReentrancyGuard {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    KaijuContracts public kaijuContracts;
    ManagerContracts public managerContracts;
    mapping(uint256 => Lot) public lots;

    constructor(
        KaijuContracts memory _kaijuContracts,
        ManagerContracts memory _managerContracts,
        address admin
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);

        kaijuContracts = _kaijuContracts;
        managerContracts = _managerContracts;
    }

    /**
     * @notice Modifier that requires a sender to be part of the KaijuKingz ecosystem
     */
    modifier onlyKingz() {
        if (!isKing(_msgSender())) revert KaijuMart_MustBeAKing();
        _;
    }

    /**
     * @notice Modifier that ensures a lot identifier is unused
     * @param lotId Globally unique identifier for a lot
     */
    modifier reserveLot(uint256 lotId) {
        if (lots[lotId].lotType != LotType.NONE) revert KaijuMart_LotAlreadyExists();
        _;
    }

    /**
     * @notice Modifier that ensures a lot exists
     * @param lotId Unique identifier for a lot
     */
    modifier lotExists(uint256 lotId) {
        if (lots[lotId].lotType == LotType.NONE) revert KaijuMart_LotDoesNotExist();
        _;
    }

    /**
     * @notice Returns whether or not an address holds any KaijuKingz ecosystem tokens
     * @param account Address to return the holder status of
     */
    function isKing(address account) public view returns (bool) {
        return kaijuContracts.scientists.balanceOf(account) > 0
            || kaijuContracts.mutants.balanceOf(account) > 0
            || kaijuContracts.kaiju.isHolder(account);
    }

    /**
     * @notice Set KaijuKingz contracts
     * @param _kaijuContracts New set of KaijuKingz contracts
     */
    function setKaijuContracts(KaijuContracts calldata _kaijuContracts) external onlyRole(DEFAULT_ADMIN_ROLE) {
        kaijuContracts = _kaijuContracts;
    }

    /**
     * @notice Set manager contracts
     * @param _managerContracts New set of manager contract
     */
    function setManagerContracts(ManagerContracts calldata _managerContracts) external onlyRole(DEFAULT_ADMIN_ROLE) {
        managerContracts = _managerContracts;
    }

    /**
     * @notice Return the address of the manager contract for a specified lot type
     * @param lotType Specified lot type
     */
    function _manager(LotType lotType) internal view returns (address) {
        if (lotType == LotType.RAFFLE) return address(managerContracts.raffle);
        else if (lotType == LotType.DOORBUSTER) return address(managerContracts.doorbuster);
        else if (lotType == LotType.AUCTION) return address(managerContracts.auction);
        else return address(0);
    }

    /**
     * @notice Create a new lot
     * @param id Unique identifier
     * @param lot Struct describing lot
     * @param lotType Sale mechanism of the lot
     * @param rwastePrice Price in $RWASTE when applicable
     * @param scalesPrice Price in $SCALES when applicable
     */
    function _create(
        uint256 id,
        CreateLot calldata lot,
        LotType lotType,
        uint104 rwastePrice,
        uint104 scalesPrice
    )
        internal
    {
        if (
            address(lot.redeemer) != address(0) &&
            !lot.redeemer.supportsInterface(type(IKaijuMartRedeemable).interfaceId)
        ) revert KaijuMart_InvalidRedeemerContract();

        lots[id] = Lot({
            rwastePrice: rwastePrice,
            scalesPrice: scalesPrice,
            lotType: lotType,
            paymentToken: lot.paymentToken,
            redeemer: lot.redeemer
        });

        emit Create(id, lotType, _manager(lotType));
    }

    /**
     * @notice Calculate the cost of a lot based on amount
     * @param lotId Lot to calculate cost for
     * @param amount Number of items to purchase
     * @param token Preferred payment token type
     */
    function _getCost(
        uint256 lotId,
        uint32 amount,
        PaymentToken token
    )
        internal
        view
        returns (uint104)
    {
        PaymentToken acceptedPaymentToken = lots[lotId].paymentToken;

        if (acceptedPaymentToken != PaymentToken.EITHER && acceptedPaymentToken != token)
            revert KaijuMart_InvalidTokenType();

        return amount * (token == PaymentToken.SCALES ? lots[lotId].scalesPrice : lots[lotId].rwastePrice);
    }

    /**
     * @notice Charge an account a specified amount of tokens
     * @dev Payment defaults to $RWASTE if `EITHER` is specified
     * @param account Address to charge
     * @param token Preferred payment token
     * @param value Amount to charge
     */
    function _charge(
        address account,
        PaymentToken token,
        uint104 value
    )
        internal
        nonReentrant
    {
        if (value > 0) {
            if (token == PaymentToken.SCALES) kaijuContracts.scales.spend(account, value);
            else kaijuContracts.rwaste.burn(account, value);
        }
    }

    /**
     * @notice Refund an account a specified amount of tokens
     * @dev No payment default, if `EITHER` is specified this is a noop
     * @param account Address to refund
     * @param token Type of tokens to refund
     * @param value Amount of tokens to refund
     */
    function _refund(
        address account,
        PaymentToken token,
        uint104 value
    )
        internal
        nonReentrant
    {
        if (token == PaymentToken.RWASTE) kaijuContracts.rwaste.claimLaboratoryExperimentRewards(account, value);
        else if (token == PaymentToken.SCALES) kaijuContracts.scales.credit(account, value);
    }

    /**
     * @notice Redeem a lot
     * @param lotId Lot to redeem
     * @param amount Quantity to redeem
     * @param to Address redeeming the lot
     */
    function _redeem(
        uint256 lotId,
        uint32 amount,
        address to
    )
        internal
        nonReentrant
    {
        IKaijuMartRedeemable redeemer = lots[lotId].redeemer;

        if (address(redeemer) != address(0)) {
            redeemer.kmartRedeem(lotId, amount, to);

            emit Redeem(lotId, amount, to, redeemer);
        }
    }

    // 📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣
    // 📣                                          AUCTION MANAGER                                           📣
    // 📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣

    /**
     * @notice Return the details of an auction
     * @param auctionId Lot identifier for the auction
     */
    function getAuction(
        uint256 auctionId
    )
        public
        view
        returns (IAuctionManager.Auction memory)
    {
        return managerContracts.auction.get(auctionId);
    }

    /**
     * @notice Return an account's current bid on an auction lot
     * @param auctionId Lot identifier for the auction
     * @param account Address to return the current bid of
     */
    function getBid(
        uint256 auctionId,
        address account
    )
        public
        view
        returns (uint104)
    {
        return managerContracts.auction.getBid(auctionId, account);
    }

    /**
     * @notice Create a new auction lot
     * @param lotId Globally unique lot identifier
     * @param auction Configuration details of the new auction lot
     */
    function createAuction(
        uint256 lotId,
        CreateLot calldata lot,
        IAuctionManager.CreateAuction calldata auction
    )
        external
        reserveLot(lotId)
        onlyRole(MANAGER_ROLE)
    {
        if (lot.paymentToken == PaymentToken.EITHER) revert KaijuMart_InvalidTokenType();

        _create(lotId, lot, LotType.AUCTION, 0, 0);
        managerContracts.auction.create(lotId, auction);
    }

    /**
     * @notice Close an auction lot
     * @param auctionId Lot identifier for the auction
     * @param lowestWinningBid Lowest amount that is considered a winning bid
     * @param tiebrokenWinners An array of winning addresses use to tiebreak identical winning bids
     */
    function close(
        uint256 auctionId,
        uint104 lowestWinningBid,
        address[] calldata tiebrokenWinners
    )
        external
        lotExists(auctionId)
        onlyRole(MANAGER_ROLE)
    {
        managerContracts.auction.close(auctionId, lowestWinningBid, tiebrokenWinners);
    }

    /**
     * @notice Replaces the sender's current bid on an auction lot
     * @dev Auctions cannot accept `EITHER` PaymentType so we can just assume the token type from the auction details
     * @param auctionId Lot identifier for the auction
     * @param value New bid to replace the current bid with
     */
    function bid(
        uint256 auctionId,
        uint104 value
    )
        external
        lotExists(auctionId)
        onlyKingz
    {
        uint104 increase = managerContracts.auction.bid(auctionId, value, _msgSender());

        _charge(
            _msgSender(),
            lots[auctionId].paymentToken,
            increase
        );

        emit Bid(auctionId, _msgSender(), value);
    }

    /**
     * @notice Claim a refund for spent tokens on a lost auction lot
     * @param auctionId Lot identifier for the auction
     */
    function refund(
        uint256 auctionId
    )
        external
        lotExists(auctionId)
    {
        if (managerContracts.auction.isWinner(auctionId, _msgSender())) revert KaijuMart_CannotClaimRefund();

        uint104 refundAmount = managerContracts.auction.settle(auctionId, _msgSender());

        _refund(
            _msgSender(),
            lots[auctionId].paymentToken,
            refundAmount
        );

        emit Refund(auctionId, _msgSender(), refundAmount);
    }

    /**
     * @notice Redeem a winning auction lot
     * @param auctionId Lot identifier for the auction
     */
    function redeem(
        uint256 auctionId
    )
        external
        lotExists(auctionId)
    {
        if (!managerContracts.auction.isWinner(auctionId, _msgSender())) revert KaijuMart_CannotRedeemAuction();

        managerContracts.auction.settle(auctionId, _msgSender());

        _redeem(auctionId, 1, _msgSender());
    }

    // 🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟
    // 🎟                                           RAFFLE MANAGER                                           🎟
    // 🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟

    /**
     * @notice Return the details of a raffle
     * @param raffleId Lot identifier for the raffle
     */
    function getRaffle(
        uint256 raffleId
    )
        public
        view
        returns (IRaffleManager.Raffle memory)
    {
        return managerContracts.raffle.get(raffleId);
    }

    /**
     * @notice Create a new raffle lot
     * @param lotId Globally unique lot identifier
     * @param raffle Configuration details of the new raffle lot
     */
    function createRaffle(
        uint256 lotId,
        CreateLot calldata lot,
        uint104 rwastePrice,
        uint104 scalesPrice,
        IRaffleManager.CreateRaffle calldata raffle
    )
        external
        reserveLot(lotId)
        onlyRole(MANAGER_ROLE)
    {
        _create(lotId, lot, LotType.RAFFLE, rwastePrice, scalesPrice);
        managerContracts.raffle.create(lotId, raffle);
    }

    /**
     * @notice Draw the results of a raffle lot
     * @param raffleId Lot identifier for the raffle
     * @param vrf Flag indicating if the results should be drawn using Chainlink VRF
     */
    function draw(
        uint256 raffleId,
        bool vrf
    )
        external
        lotExists(raffleId)
        onlyRole(MANAGER_ROLE)
    {
        managerContracts.raffle.draw(raffleId, vrf);
    }

    /**
     * @notice Purchase entry into a raffle lot
     * @param raffleId Lot identifier for the raffle
     * @param amount Number of entries to purchase
     * @param token Preferred payment token
     */
    function enter(
        uint256 raffleId,
        uint32 amount,
        PaymentToken token
    )
        external
        lotExists(raffleId)
        onlyKingz
    {
        managerContracts.raffle.enter(raffleId, amount);

        _charge(
            _msgSender(),
            token,
            _getCost(raffleId, amount, token)
        );

        emit Enter(raffleId, _msgSender(), amount);
    }

    // 🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒
    // 🛒                                         DOORBUSTER MANAGER                                         🛒
    // 🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒

    /**
     * @notice Return the details of a doorbuster
     * @param doorbusterId Lot identifier for the doorbuster
     */
    function getDoorbuster(
        uint256 doorbusterId
    )
        public
        view
        returns (IDoorbusterManager.Doorbuster memory)
    {
        return managerContracts.doorbuster.get(doorbusterId);
    }

    /**
     * @notice Create a new doorbuster lot
     * @param lotId Globally unique lot identifier
     * @param supply Total purchasable supply
     */
    function createDoorbuster(
        uint256 lotId,
        CreateLot calldata lot,
        uint104 rwastePrice,
        uint104 scalesPrice,
        uint32 supply
    )
        external
        reserveLot(lotId)
        onlyRole(MANAGER_ROLE)
    {
        _create(lotId, lot, LotType.DOORBUSTER, rwastePrice, scalesPrice);
        managerContracts.doorbuster.create(lotId, supply);
    }

    /**
     * @notice Purchase from a doorbuster lot
     * @param doorbusterId Lot identifier for the doorbuster
     * @param amount Number of items to purchase
     * @param token Preferred payment token
     * @param nonce Single use number encoded into signature
     * @param signature Signature created by the current doorbuster `signer` account
     */
    function purchase(
        uint256 doorbusterId,
        uint32 amount,
        PaymentToken token,
        uint256 nonce,
        bytes calldata signature
    )
        external
        lotExists(doorbusterId)
        onlyKingz
    {
        managerContracts.doorbuster.purchase(doorbusterId, amount, nonce, signature);

        _charge(
            _msgSender(),
            token,
            _getCost(doorbusterId, amount, token)
        );

        _redeem(doorbusterId, amount, _msgSender());

        emit Purchase(doorbusterId, _msgSender(), amount);
    }
}