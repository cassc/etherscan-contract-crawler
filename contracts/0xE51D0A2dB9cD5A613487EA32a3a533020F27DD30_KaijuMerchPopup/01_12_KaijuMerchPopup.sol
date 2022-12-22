// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

import "./interfaces/IKingzInTheShell.sol";
import "./interfaces/IMintable.sol";
import "./interfaces/IMutants.sol";
import "./interfaces/IScientists.sol";

error KaijuMerchPopup_AlreadyPurchased();
error KaijuMerchPopup_InsufficientSupply();
error KaijuMerchPopup_InvalidMerch();
error KaijuMerchPopup_InvalidValue();
error KaijuMerchPopup_NotEligible();
error KaijuMerchPopup_PopupEnded();
error KaijuMerchPopup_WithdrawFailed();

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
 * @title Kaiju Merch Popup
 * @notice Purchase Kaiju merch with ether
 * @author Augminted Labs, LLC
 */
contract KaijuMerchPopup is AccessControl {
    event Purchase(
        address indexed purchaser,
        address indexed receiver,
        uint256 indexed merchId
    );

    struct Merch {
        uint120 supply;
        uint120 cost;
        bool locked;
        uint8 eligibility;
        IMintable redeemer;
        uint256 redeemableId;
    }

    uint8 internal constant _KAIJU_BIT_MASK = 1;
    uint8 internal constant _MUTANT_BIT_MASK = 2;
    uint8 internal constant _SCIENTIST_BIT_MASK = 4;

    IKingzInTheShell public immutable KITS;
    IMutants public immutable MUTANTS;
    IScientists public immutable SCIENTISTS;

    mapping(uint256 => Merch) public merch;
    mapping(address => mapping(uint256 => bool)) public purchased;

    constructor(
        IKingzInTheShell kits,
        IMutants mutants,
        IScientists scientists,
        address admin
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);

        KITS = kits;
        MUTANTS = mutants;
        SCIENTISTS = scientists;
    }

    /**
     * @notice Returns whether or not an address is eligible to mint merch
     * @param merchId Merch identifier
     * @param account Address to return eligibility for
     */
    function isEligible(uint256 merchId, address account) public view returns (bool) {
        return _isEligible(merch[merchId].eligibility, account);
    }

    /**
     * @notice Returns whether or not an address is eligible to mint merch
     * @param eligibility Bitmap defining eligibility requirements
     * @param account Address to return eligibility for
     */
    function _isEligible(uint8 eligibility, address account) internal view returns (bool) {
        return
            // holds genesis or baby
            eligibility & _KAIJU_BIT_MASK > 0 && KITS.isHolder(account)
            // holds mutant
            || eligibility & _MUTANT_BIT_MASK > 0 && MUTANTS.balanceOf(account) > 0
            // holds scientist
            || eligibility & _SCIENTIST_BIT_MASK > 0 && SCIENTISTS.balanceOf(account) > 0;
    }

    /**
     * @notice Start popup for specified merch
     * @param merchId Merch identifier
     * @param _merch Merch details
     */
    function packItOut(uint256 merchId, Merch calldata _merch) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (merch[merchId].locked) revert KaijuMerchPopup_PopupEnded();
        if (address(_merch.redeemer) != address(0) && _merch.redeemableId == 0)
            revert KaijuMerchPopup_InvalidMerch();

        merch[merchId] = _merch;
    }

    /**
     * @notice End popup for specified merch
     * @param merchId Merch identifier
     */
    function packItIn(uint256 merchId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        merch[merchId].locked = true;
    }

    /**
     * @notice Purchase merch for self
     * @param merchId Merch identifier
     */
    function purchase(uint256 merchId) external payable {
        _purchase(merchId, msg.sender);
    }

    /**
     * @notice Purchase merch for a specified receiver
     * @param merchId Merch identifier
     * @param receiver Receiver of the purchase
     */
    function purchaseFor(uint256 merchId, address receiver) external payable {
        _purchase(merchId, receiver);
    }

    /**
     * @notice Purchase merch for a specified receiver
     * @param merchId Merch identifier
     * @param receiver Receiver of the purchase
     */
    function _purchase(uint256 merchId, address receiver) internal {
        Merch memory _merch = merch[merchId];

        if (_merch.locked) revert KaijuMerchPopup_PopupEnded();
        if (_merch.cost != msg.value) revert KaijuMerchPopup_InvalidValue();
        if (_merch.supply == 0) revert KaijuMerchPopup_InsufficientSupply();
        if (!_isEligible(_merch.eligibility, receiver)) revert KaijuMerchPopup_NotEligible();
        if (purchased[receiver][merchId]) revert KaijuMerchPopup_AlreadyPurchased();

        purchased[receiver][merchId] = true;
        unchecked { --merch[merchId].supply; }

        if (address(_merch.redeemer) != address(0)) {
            _merch.redeemer.mint(receiver, _merch.redeemableId, 1);
        }

        emit Purchase(msg.sender, receiver, merchId);
    }

    /**
     * @notice Withdraw ether
     * @param receiver Address to receive the ether
     */
    function withdraw(address receiver) external onlyRole(DEFAULT_ADMIN_ROLE) {
        (bool success, ) = receiver.call{value: address(this).balance}("");
        if (!success) revert KaijuMerchPopup_WithdrawFailed();
    }
}