//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @notice Broadcasts signed intents of Expansion item applications to Dynamic Blueprint NFTs
 * @dev Allows the platform to emit bundled intents or users to submit intents themselves
 * @author Ohimire Labs
 */
contract DynamicBlueprintsBroadcast is Ownable {
    /**
     * @notice Emitted when bundled intents are emitted
     * @param intentsFile File of bundled signed intents
     */
    event CollatedIntents(string intentsFile);

    /**
     * @notice Emitted when a single intent is emitted
     * @param intentFile File of signed intent
     * @param applier User applying the expansion item to the dbp
     */
    event Intent(string intentFile, address indexed applier);

    /**
     * @notice Lets platform emit bundled user intents to apply expansion items to their DBPs
     * @param intentsFile File of bundled signed intents
     */
    function saveBatch(string memory intentsFile) external onlyOwner {
        emit CollatedIntents(intentsFile);
    }

    /**
     * @notice Lets user emit signed intents to apply expansion items to their Dynamic Blueprint NFTs
     * @param intentFile File of signed intent
     */
    function applyItems(string memory intentFile) external {
        emit Intent(intentFile, msg.sender);
    }
}