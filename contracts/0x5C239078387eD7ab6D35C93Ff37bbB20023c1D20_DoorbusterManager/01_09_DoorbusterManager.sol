// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./interfaces/IDoorbusterManager.sol";

error DoorbusterManager_InsufficientSupply();
error DoorbusterManager_InvalidDoorbuster();
error DoorbusterManager_InvalidSignature();
error DoorbusterManager_NonceAlreadyUsed();
error DoorbusterManager_SupplyLocked();

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
 * @title KaijuMart Doorbuster Manager
 * @author Augminted Labs, LLC
 */
contract DoorbusterManager is IDoorbusterManager, AccessControl {
    using ECDSA for bytes32;

    bytes32 public constant KMART_CONTRACT_ROLE = keccak256("KMART_CONTRACT_ROLE");

    address public signer;
    mapping(uint256 => uint32) public supply;
    mapping(uint256 => bool) public nonceUsed;
    mapping(uint256 => bool) public supplyLocked;

    constructor (
        address _signer,
        address admin
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);

        signer = _signer;
    }

    /**
     * @notice Return a doorbuster
     * @param id Identifier of the doorbuster
     */
    function get(uint256 id) public view returns (Doorbuster memory) {
        return Doorbuster({ supply: supply[id] });
    }

    /**
     * @notice Set signature signing address
     * @param _signer New address of account used to create signatures
     */
    function setSigner(address _signer) external onlyRole(DEFAULT_ADMIN_ROLE) {
        signer = _signer;
    }

    /**
     * @notice Set new supply for a doorbuster
     * @param id Identifier of the doorbuster
     * @param _supply Total purchasable supply
     */
    function setSupply(uint256 id, uint32 _supply) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (supplyLocked[id]) revert DoorbusterManager_SupplyLocked();

        supply[id] = _supply;
    }

    /**
     * @notice Lock supply of a doorbuster, preventing it from being changed it the future
     * @dev This is necessary for capping the token supply of contracts that implement `KaijuMartRedeemable`
     * @param id Identifier of the doorbuster
     */
    function lockSupply(uint256 id) external onlyRole(DEFAULT_ADMIN_ROLE) {
        supplyLocked[id] = true;
    }

    /**
     * @notice Create a new doorbuster
     * @param id Identifier of the doorbuster
     * @param _supply Total purchasable supply
     */
    function create(
        uint256 id,
        uint32 _supply
    )
        public
        override
        onlyRole(KMART_CONTRACT_ROLE)
    {
        if (_supply == 0) revert DoorbusterManager_InvalidDoorbuster();

        supply[id] = _supply;
    }

    /**
     * @notice Purchase from a doorbuster
     * @param id Identifier of the doorbuster
     * @param amount Number of items to purchase
     * @param nonce Single use number encoded into signature
     * @param signature Signature created by the `signer` account
     */
    function purchase(
        uint256 id,
        uint32 amount,
        uint256 nonce,
        bytes calldata signature
    )
        public
        override
        onlyRole(KMART_CONTRACT_ROLE)
    {
        if (amount > supply[id]) revert DoorbusterManager_InsufficientSupply();
        if (nonceUsed[nonce]) revert DoorbusterManager_NonceAlreadyUsed();

        if (signer != ECDSA.recover(
            ECDSA.toEthSignedMessageHash(keccak256(
                abi.encodePacked(tx.origin, id, amount, nonce)
            )),
            signature
        )) revert DoorbusterManager_InvalidSignature();

        nonceUsed[nonce] = true;

        unchecked { supply[id] -= amount; }
    }
}