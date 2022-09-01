// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./interfaces/IRaffleManager.sol";

error RaffleManager_RaffleAlreadyDrawn();
error RaffleManager_RaffleExpired();
error RaffleManager_InvalidRaffle();
error RaffleManager_InvalidScriptId();

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
 * @title KaijuMart Raffle Manager
 * @author Augminted Labs, LLC
 */
contract RaffleManager is IRaffleManager, AccessControl, VRFConsumerBaseV2 {
    struct VrfRequestConfig {
        bytes32 keyHash;
        uint64 subId;
        uint32 callbackGasLimit;
        uint16 requestConfirmations;
    }

    bytes32 public constant KMART_CONTRACT_ROLE = keccak256("KMART_CONTRACT_ROLE");
    VRFCoordinatorV2Interface internal immutable COORDINATOR;

    VrfRequestConfig public vrfRequestConfig;
    mapping(uint256 => Raffle) public raffles;
    mapping(uint64 => string) public scripts;
    mapping(uint256 => uint256) internal _requests;

    constructor (
        address vrfCoordinator,
        address admin
    )
        VRFConsumerBaseV2(vrfCoordinator)
    {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    }

    /**
     * @notice Return a raffle
     * @param id Identifier of the raffle
     */
    function get(uint256 id) public view returns (Raffle memory) {
        return raffles[id];
    }

    /**
     * @notice Return whether or not a raffle has been drawn
     * @param id Identifier of the raffle
     */
    function isDrawn(
        uint256 id
    )
        public
        view
        override
        returns (bool)
    {
        return raffles[id].seed != 0;
    }

    /**
     * @notice Set configuration data for Chainlink VRF
     * @param _vrfRequestConfig Struct with updated configuration values
     */
    function setVrfRequestConfig(
        VrfRequestConfig calldata _vrfRequestConfig
    )
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        vrfRequestConfig = _vrfRequestConfig;
    }

    /**
     * @notice Set draw script URI for a raffle
     * @param id Identifier of the raffle
     * @param uri New draw script URI
     */
    function setScript(
        uint64 id,
        string calldata uri
    )
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (bytes(scripts[id]).length != 0) revert RaffleManager_InvalidScriptId();

        scripts[id] = uri;
    }

    /**
     * @notice Create a new raffle
     * @param id Identifier of the raffle
     * @param raffle Configuration details of the new raffle
     */
    function create(
        uint256 id,
        CreateRaffle calldata raffle
    )
        public
        override
        onlyRole(KMART_CONTRACT_ROLE)
    {
        if (
            bytes(scripts[raffle.scriptId]).length == 0 ||
            raffle.winners == 0
        ) revert RaffleManager_InvalidRaffle();

        raffles[id] = Raffle({
            scriptId: raffle.scriptId,
            winners: raffle.winners,
            endsAt: raffle.endsAt,
            seed: 0
        });
    }

    /**
     * @notice Add entries into a raffle
     * @dev Currently, no state change is needed but we should maintain function signature just in case
     * @param id Identifier of the raffle
     * @param amount Number of entries to add
     */
    function enter(
        uint256 id,
        uint32 amount
    )
        public
        view
        override
    {
        if (isDrawn(id) || raffles[id].endsAt < block.timestamp)
            revert RaffleManager_RaffleExpired();
    }

    /**
     * @notice Draw the results of a raffle
     * @param id Identifier of the raffle
     * @param vrf Flag indicating if the results should be drawn using Chainlink VRF
     */
    function draw(
        uint256 id,
        bool vrf
    )
        public
        override
        onlyRole(KMART_CONTRACT_ROLE)
    {
        if (isDrawn(id)) revert RaffleManager_RaffleAlreadyDrawn();

        if (vrf) {
            _requests[COORDINATOR.requestRandomWords(
                vrfRequestConfig.keyHash,
                vrfRequestConfig.subId,
                vrfRequestConfig.requestConfirmations,
                vrfRequestConfig.callbackGasLimit,
                1 // number of random words
            )] = id;
        } else {
            raffles[id].seed = uint256(keccak256(
                abi.encodePacked(blockhash(block.number - 1), block.difficulty, block.timestamp)
            ));
        }
    }

    /**
     * @inheritdoc VRFConsumerBaseV2
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        raffles[_requests[requestId]].seed = randomWords[0];
    }
}