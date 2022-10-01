// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./interfaces/Offsetable.sol";

error StructOffsetManager_CallerNotContractOwner();
error StructOffsetManager_SignerNotContractOwner();

/**                       .-==+++++++++++++++++++++++++++++++=-:
                     :=*%##########################################+-
                  .+%##################################################-
                .*######################################################%=
               *##################%*##################*###################%:
             .###################+   :##############+   :###################=
            :####################=    ##############=    ####################*
           .#####################=    ##############=    #####################+
           ######################*   -##############*   -######################
          .#########################%##################%#######################=
          :####################################################################*
          .%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%=

       .-+*##############################*-                          .=########*+=.
     -######################################+:                     -###############%=
    *#########################################%=                :+####################
   *##############################################-          .+%######################%
  .##################################################-     =%##########################-
  :####################################################%#%#############################-
   ###################################################################################%
    *#################################################################################
     -#############################################################################%=
        -+*#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%##+=.

          .#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#=
          -####################################################################*
          .####################################################################=
           ####################################################################.
           .##################################################################+
            :################################################################*
             :##############################################################+
              .############################################################-
                :########################################################=
                  :*###################################################=
                     :+###########################################%*-.
                          :-=+******************************++=:.

 * @title Manage the token offsets of contracts deployed with struct
 * @author Augminted Labs, LLC
 */
contract StructOffsetManager is VRFConsumerBaseV2, AccessControl {
    using ECDSA for bytes32;

    struct VRFRequestConfig {
        bytes32 keyHash;
        uint64 subId;
        uint32 callbackGasLimit;
        uint16 requestConfirmations;
    }

    VRFCoordinatorV2Interface internal immutable _COORDINATOR;
    VRFRequestConfig internal _VRF_REQUEST_CONFIG;

    mapping(uint256 => Offsetable) internal _requests;

    constructor(
        address admin,
        address vrfCoordinator,
        VRFRequestConfig memory vrfRequestConfig
    )
        VRFConsumerBaseV2(vrfCoordinator)
    {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);

        _COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        _VRF_REQUEST_CONFIG = vrfRequestConfig;
    }

    /**
     * @notice Set configuration data for Chainlink VRF
     * @param vrfRequestConfig Struct with updated configuration values
     */
    function setVRFRequestConfig(VRFRequestConfig calldata vrfRequestConfig) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _VRF_REQUEST_CONFIG = vrfRequestConfig;
    }

    /**
     * @notice Set offset using on-chain pseudo-random number generation
     * @param offsetable Address of Offsetable contract
     */
    function offsetWithPRNG(Offsetable offsetable) external {
        if (Ownable(address(offsetable)).owner() != _msgSender())
            revert StructOffsetManager_CallerNotContractOwner();

        offsetable.setOffset(uint256(keccak256(
            abi.encodePacked(blockhash(block.number - 1), block.difficulty, block.timestamp)
        )));
    }

    /**
     * @notice Set offset using Chainlink VRF
     * @param offsetable Address of Offsetable contract
     * @param signature Offset signature from contract owner
     */
    function offsetWithVRF(Offsetable offsetable, bytes memory signature) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (Ownable(address(offsetable)).owner() != ECDSA.recover(
            ECDSA.toEthSignedMessageHash(
                keccak256(abi.encodePacked("VRF_OFFSET", address(offsetable)))
            ),
            signature
        )) revert StructOffsetManager_SignerNotContractOwner();

        _requests[_COORDINATOR.requestRandomWords(
            _VRF_REQUEST_CONFIG.keyHash,
            _VRF_REQUEST_CONFIG.subId,
            _VRF_REQUEST_CONFIG.requestConfirmations,
            _VRF_REQUEST_CONFIG.callbackGasLimit,
            1 // number of random words
        )] = offsetable;
    }

    /**
     * @inheritdoc VRFConsumerBaseV2
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        _requests[requestId].setOffset(randomWords[0]);
    }
}