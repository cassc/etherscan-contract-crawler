// SPDX-License-Identifier: MIT

// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxddxxxxddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxdol:;,''....'',;:lodxxxxxxxxxxxxxxxxxxxxxdlc;,''....'',;:codxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxdc;'.                .';ldxxxxxxxxxxxxxxdl;'.                ..;cdxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxdl;.                        .;ldxxxxxxxxxo;.                        .;ldxxxxxxxxxxxxxx
// xxxxxxxxxxxxxl,.                            .,lxxxxxxo;.                            .'ldxxxxxxxxxxxx
// xxxxxxxxxxxo;.                                .,lddo;.                                .;oxxxxxxxxxxx
// xxxxxxxxxxo'                                    ....                                    'lxxxxxxxxxx
// xxxxxxxxxl'                             .                   .                            .lxxxxxxxxx
// xxxxxxxxo,                             'c,.              .,c'                             'oxxxxxxxx
// xxxxxxxxc.                             .lxl,.          .,ldo.                             .:xxxxxxxx
// xxxxxxxd,                              .:xxxl,.      .,ldxxc.                              'oxxxxxxx
// xxxxxxxo'                               ,dxxxxl,.  .,ldxxxd;                               .lxxxxxxx
// xxxxxxxo.                               .oxxxxxxl::ldxxxxxo'                               .lxxxxxxx
// xxxxxxxd,                               .cxxxxxxxxxxxxxxxxl.                               'oxxxxxxx
// xxxxxxxx:.           ..                  ;xxxxxxxxxxxxxxxx:                  ..            ;dxxxxxxx
// xxxxxxxxo'           ''                  'oxxxxxxxxxxxxxxd,                  .'           .lxxxxxxxx
// xxxxxxxxxc.          ;,                  .lxxxxxxxxxxxxxxo.                  ';.         .cxxxxxxxxx
// xxxxxxxxxxc.        .c,                  .:xxxxxxxxxxxxxxc.                  'c.        .cdxxxxxxxxx
// xxxxxxxxxxxl'       'l,       ..          ,dxxxxxxxxxxxxd;          ..       'l,       'lxxxxxxxxxxx
// xxxxxxxxxxxxd:.     ;o,       .'          .oxxxxxxxxxxxxo'          ..       'o:.    .:dxxxxxxxxxxxx
// xxxxxxxxxxxxxxd:.  .cd,       .;.         .cxxxxxxxxxxxxl.         .,'       'ol.  .:oxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxo:.,od,       .:.          ;xxxxxxxxxxxx:          .:'       'oo,.:oxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxdodd,       .l,          'dxxxxxxxxxxd,          'l'       'oxodxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxd;       .l:.         .lxxxxxxxxxxo.          :o'       ,dxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxd:.     .ol.         .:xxxxxxxxxxc.         .co'     .:oxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxd:.   .oo'          ;dxxxxxxxxd;          .oo'   .:oxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxo:. .od;          'oxxxxxxxxo'          ,do' .:oxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxd::oxc.         .cxxxxxxxxl.         .:xd::oxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxl.          ;xxxxxxxx:.         .lxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd;          'dxxxxxxd,          ,dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd:.        .lxxxxxxo.        .:oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd:.      .cxxxxxxc.      .:oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo:.     ;dxxxxd;     .:oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd:.   'oxxxxo'   .:oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo:. .cxxxxl. .:oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo:'cxxxxc,:oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxddxxxxddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
//
// MEGAMI https://www.megami.io/

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MegamiRaffle is Ownable, VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface internal immutable vrfCoordinator;

    struct VrfRequestConfig {
        bytes32 keyHash;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
        uint16 requestConfirmations;
    }

    /**
     * @dev The configuration for requesting Chainlink VRF
     */
    VrfRequestConfig public vrfRequestConfig;

    /**
     * @dev The URI of the script used in the raffle. Stored in here only for verification/recording purposes.
     */
    string public raffleScriptURI;

    /**
     * @dev The random seeds retrieved from Chainlink VRF
     */
    mapping (uint256 => uint256) public randomSeeds;

    /**
     * @dev The URI of the data used in the raffle. Stored in here only for verification/recording purposes.
     */
    mapping (uint256 => string) public raffleDataURIs;

    /**
     * @dev Variable stores the tokenId associated to the random seed returned by Chainlin VRF
     */
    uint256 public raffleIdForRetrievingRandomSeed;

    /**
     * @notice Event fired when the random seed is returned by ChainlinkVRF
     */
    event RandomSeedDrawn(uint256 indexed requestId, uint256 raffleId, uint256 indexed seed);

    /**
     * @dev Constractor of VintageNaoki contract. Setting the VRF configurations and royalty recipient.
     * @param vrfCoordinatorAddress Address of the VRF coordinatior
     * @param subscriptionId Subscription ID of Chainlink
     * @param keyHash The gas lane to use, which specifies the maximum gas price to bump to.
     */
    constructor(address vrfCoordinatorAddress, uint64 subscriptionId, bytes32 keyHash) 
        VRFConsumerBaseV2(vrfCoordinatorAddress) 
    {
        vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorAddress);

        vrfRequestConfig.keyHash = keyHash;
        vrfRequestConfig.subscriptionId = subscriptionId;
        vrfRequestConfig.callbackGasLimit = 100000;
        vrfRequestConfig.requestConfirmations = 3;

    }

    /**
     * @notice Set configuration data for Chainlink VRF
     * @param _vrfRequestConfig Struct with updated configuration values
     */
    function setVrfRequestConfig(VrfRequestConfig memory _vrfRequestConfig) external onlyOwner {
        vrfRequestConfig = _vrfRequestConfig;
    }

    /**
     * @notice Set the uri of the raffle script for verification and recording purpose
     * @param scriptUri The URI of the raffle script
     */
    function setRaffleScriptURI(string calldata scriptUri) external onlyOwner {
        raffleScriptURI = scriptUri;
    }    

    /**
     * @notice Get the random seed from Chainlink VRF for the raffle script
     * @param raffleId The id of the raffle
     * @param dataUri The URL of the raffle data fed into the raffle script
     */
    function setRandomSeed(uint256 raffleId, string calldata dataUri) external onlyOwner {   
        require(raffleId != 0, "raffleId must be non zero");
        require(bytes(raffleScriptURI).length != 0, "raffle script is empty");
        require(bytes(raffleDataURIs[raffleId]).length == 0, "seed is already requested");

        // Save the specified raffle ID
        raffleIdForRetrievingRandomSeed = raffleId;

        // Save the raffle data
        raffleDataURIs[raffleIdForRetrievingRandomSeed] = dataUri;

        // Will revert if subscription is not set and funded.
        vrfCoordinator.requestRandomWords(
            vrfRequestConfig.keyHash,
            vrfRequestConfig.subscriptionId,
            vrfRequestConfig.requestConfirmations,
            vrfRequestConfig.callbackGasLimit,
            1
        );
    }

    /**
     * @notice Callback function used by Chainlink VRF
     */
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        randomSeeds[raffleIdForRetrievingRandomSeed] = randomWords[0];

        emit RandomSeedDrawn(requestId, raffleIdForRetrievingRandomSeed, randomSeeds[raffleIdForRetrievingRandomSeed]);
    }
}