// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFV2WrapperInterface.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IStructRandomnessManager.sol";

error StructRandomnessManager_CallerNotOwner();
error StructRandomnessManager_IndexAlreadySet();
error StructRandomnessManager_InvalidState();

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

 * @title Manage collection randomness for creating token offsets, drawing raffles, etc.
 * @author Augminted Labs, LLC
 */
contract StructRandomnessManager is IStructRandomnessManager, VRFV2WrapperConsumerBase, AccessControl {
    struct VRFRequestConfig {
        uint32 callbackGasLimit;
        uint16 requestConfirmations;
    }

    LinkTokenInterface internal immutable _LINK;
    VRFV2WrapperInterface internal immutable _VRF_V2_WRAPPER;

    VRFRequestConfig internal _vrfRequestConfig;
    mapping(uint256 => bytes32) internal _requestsToIndex;
    mapping(bytes32 => uint256) internal _indexToRandomness;

    bytes32 public constant TOKEN_OFFSET_SLOT = keccak256("TOKEN_OFFSET");

    constructor(
        address admin,
        address link,
        address wrapper,
        VRFRequestConfig memory vrfRequestConfig
    )
        VRFV2WrapperConsumerBase(link, wrapper)
    {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);

        _LINK = LinkTokenInterface(link);
        _VRF_V2_WRAPPER = VRFV2WrapperInterface(wrapper);
        _vrfRequestConfig = vrfRequestConfig;
    }

    /**
     * @notice Return the index for a given randomness slot of a collection
     * @param collection Address of the collection
     * @param slot Unique value that offsets the randomness location
     */
    function _getIndex(address collection, bytes32 slot) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(collection, slot));
    }

    /**
     * @notice Return the randomness value for a specific collection and slot
     * @param collection Address of the collection
     * @param slot Unique value that offsets the randomness location
     */
    function randomness(address collection, bytes32 slot) external view returns (uint256) {
        return _indexToRandomness[_getIndex(collection, slot)];
    }

    /**
     * @notice Return the randomness value for a specific collection and slot if set, revert otherwise
     * @param collection Address of the collection
     * @param slot Unique value that offsets the randomness location
     * @param set Target state
     */
    function requireRandomnessState(address collection, bytes32 slot, bool set) external view {
        if (
            set
            ? _indexToRandomness[_getIndex(collection, slot)] == 0
            : _indexToRandomness[_getIndex(collection, slot)] != 0
        ) revert StructRandomnessManager_InvalidState();
    }

    /**
     * @notice Set configuration data for Chainlink VRF
     * @param vrfRequestConfig Struct with updated configuration values
     */
    function setVRFRequestConfig(
        VRFRequestConfig calldata vrfRequestConfig
    )
        external
        payable
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _vrfRequestConfig = vrfRequestConfig;
    }

    /**
     * @notice Set randomness using on-chain pseudo-random number generation
     * @param collection Address of the collection
     * @param slot Unique value that offsets the randomness location
     */
    function setWithPRNG(address collection, bytes32 slot) external payable {
        bytes32 index = _getIndex(collection, slot);

        if (tx.origin != Ownable(collection).owner()) revert StructRandomnessManager_CallerNotOwner();
        if (_indexToRandomness[index] != 0) revert StructRandomnessManager_IndexAlreadySet();

        _indexToRandomness[index] = uint256(keccak256(abi.encodePacked(
            blockhash(block.number - 1),
            block.difficulty,
            block.timestamp,
            index
        )));
    }

    /**
     * @notice Set randomness using the Chainlink VRF
     * @param collection Address of the collection
     * @param slot Unique value that offsets the randomness location
     */
    function setWithVRF(address collection, bytes32 slot) external payable {
        bytes32 index = _getIndex(collection, slot);

        if (tx.origin != Ownable(collection).owner()) revert StructRandomnessManager_CallerNotOwner();
        if (_indexToRandomness[index] != 0) revert StructRandomnessManager_IndexAlreadySet();

        _LINK.transferFrom(
            tx.origin,
            address(this),
            _VRF_V2_WRAPPER.calculateRequestPrice(_vrfRequestConfig.callbackGasLimit)
        );

        _requestsToIndex[requestRandomness(
            _vrfRequestConfig.callbackGasLimit,
            _vrfRequestConfig.requestConfirmations,
            1 // number of random words
        )] = index;
    }

    /**
     * @inheritdoc VRFV2WrapperConsumerBase
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        _indexToRandomness[_requestsToIndex[requestId]] = randomWords[0];
    }
}