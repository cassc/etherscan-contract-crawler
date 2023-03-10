// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../access/InitializableOwnable.sol";
import "../../initializable/IRootCollectionInitializer.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @title SequentialMintBase
 * @author Limit Break, Inc.
 * @dev In order to support multiple sequential mint mix-ins in a single contract, the token id counter has been moved to this based contract.
 */
abstract contract SequentialMintBase {

    /// @dev The next token id that will be minted - if zero, the next minted token id will be 1
    uint256 private nextTokenIdCounter;

    /// @dev Minting mixins must use this function to advance the next token id counter.
    function _initializeNextTokenIdCounter() internal {
        if(nextTokenIdCounter == 0) {
            nextTokenIdCounter = 1;
        }
    }

    /// @dev Minting mixins must use this function to advance the next token id counter.
    function _advanceNextTokenIdCounter(uint256 amount) internal {
        nextTokenIdCounter += amount;
    }

    /// @dev Returns the next token id counter value
    function getNextTokenId() public view returns (uint256) {
        return nextTokenIdCounter;
    }
}