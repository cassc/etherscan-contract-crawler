// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

import {IBBOTSRenderer} from "src/interface/BBOTSRenderer.interface.sol";

//_/\\\\\\\\\\\\\__________________/\\\\\\\\\\\\\_________/\\\\\_______/\\\\\\\\\\\\\\\_____/\\\\\\\\\\\___
//_\/\\\/////////\\\_______________\/\\\/////////\\\_____/\\\///\\\____\///////\\\/////____/\\\/////////\\\_
// _\/\\\_______\/\\\_______________\/\\\_______\/\\\___/\\\/__\///\\\________\/\\\________\//\\\______\///__
//  _\/\\\\\\\\\\\\\\___/\\\\\\\\\\\_\/\\\\\\\\\\\\\\___/\\\______\//\\\_______\/\\\_________\////\\\_________
//   _\/\\\/////////\\\_\///////////__\/\\\/////////\\\_\/\\\_______\/\\\_______\/\\\____________\////\\\______
//    _\/\\\_______\/\\\_______________\/\\\_______\/\\\_\//\\\______/\\\________\/\\\_______________\////\\\___
//     _\/\\\_______\/\\\_______________\/\\\_______\/\\\__\///\\\__/\\\__________\/\\\________/\\\______\//\\\__
//      _\/\\\\\\\\\\\\\/________________\/\\\\\\\\\\\\\/_____\///\\\\\/___________\/\\\_______\///\\\\\\\\\\\/___
//       _\/////////////__________________\/////////////_________\/////_____________\///__________\///////////_____

/// @title B-BOTS Renderer using Fisher-Yates shuffle to randomize metadata
/// @author ghard.eth
contract BBOTSRenderer is IBBOTSRenderer, Ownable, VRFConsumerBaseV2 {
    using Strings for uint256;

    /*///////////////////////////////////////////////////////////////
                        	RANDOMNESS STORAGE
    //////////////////////////////////////////////////////////////*/

    uint16 constant REQUEST_CONFIRMATIONS = 3;
    uint32 constant NUM_WORDS = 1;
    uint32 requestedEntropy;
    uint256[] public entropies;
    VRFCoordinatorV2Interface vrfCoordinator;
    uint64 subscriptionId;

    /*///////////////////////////////////////////////////////////////
                              METADATA
    //////////////////////////////////////////////////////////////*/

    uint16[] public tranches;
    string public metadataPrefix;

    constructor(
        uint64 _subscriptionId,
        address _vrfCoordinator,
        uint16[] memory _tranches,
        string memory _metadataPrefix
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        subscriptionId = _subscriptionId;
        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        tranches = _tranches;
        metadataPrefix = _metadataPrefix;
    }

    /*///////////////////////////////////////////////////////////////
                              RENDERING
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Get the metadata address for token `_id`. Will be updated after the reveal of each tranche
     * @dev the length of `entropies` determines how many tranches have been revealed.
     */
    function tokenURI(uint256 id)
        public
        view
        override
        returns (string memory metadataUri)
    {
        // TODO: Translate tokenId to metadata id
        uint256 metadataId = _renderId(id);
        return string.concat(metadataPrefix, metadataId.toString());
    }

    function _renderId(uint256 tokenId)
        internal
        view
        returns (uint256 metadataId)
    {
        uint256 metadataIdx = tranches[0];
        uint256 MAX_SUPPLY = tranches[tranches.length - 1];

        uint256 entropy;
        uint256 randomIndex;

        uint256[] memory metadata = new uint256[](MAX_SUPPLY + 1); // f(metadataIdx) = tokenId

        for (uint256 j; j < entropies.length; j++) {
            entropy = entropies[j];

            for (metadataIdx; metadataIdx <= tranches[j + 1]; metadataIdx++) {
                // Get a random index higher than the current index
                randomIndex =
                    metadataIdx +
                    (entropy % (MAX_SUPPLY + 1 - metadataIdx));

                // if still virtualized, set value of random index
                if (metadata[randomIndex] == 0)
                    metadata[randomIndex] = randomIndex;

                // if still virtualized, set value of current index
                if (metadata[metadataIdx] == 0)
                    metadata[metadataIdx] = metadataIdx;

                // swap current and random index
                (metadata[metadataIdx], metadata[randomIndex]) = (
                    metadata[randomIndex],
                    metadata[metadataIdx]
                );

                // if the assigned metadata is our token, return
                if (metadata[metadataIdx] == tokenId + 1) {
                    return metadataIdx;
                }
            }
        }

        // if we havent returned yet, metadata hasnt been assigned
        return 0;
    }

    /*///////////////////////////////////////////////////////////////
                              RANDOMNESS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Request random number from Chainlink VRF. Only callable by owner.
     * @dev check keyHash and callbackGasLimit requirements: https://docs.chain.link/docs/vrf-contracts/
     */
    function requestEntropy(bytes32 _keyHash, uint32 _callbackGasLimit)
        external
        onlyOwner
    {
        if (requestedEntropy + NUM_WORDS > tranches.length - 1)
            revert TooMuchEntropy();

        vrfCoordinator.requestRandomWords(
            _keyHash,
            subscriptionId,
            REQUEST_CONFIRMATIONS,
            _callbackGasLimit,
            NUM_WORDS
        );

        requestedEntropy += NUM_WORDS;
        emit EntropyRequested();
    }

    /// @dev callback from chainlink vrf. This triggers the tranche reveal of metadata
    function fulfillRandomWords(uint256, uint256[] memory randomWords)
        internal
        override
    {
        for (uint256 i; i < randomWords.length; i++) {
            entropies.push(randomWords[i]);
            emit EntropyReceived(randomWords[i]);
        }
    }

    function updateSubscription(uint64 _subscriptionId) external onlyOwner {
        subscriptionId = _subscriptionId;
    }
}