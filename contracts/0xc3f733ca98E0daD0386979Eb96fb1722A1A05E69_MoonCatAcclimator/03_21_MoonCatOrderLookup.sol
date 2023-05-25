// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.3;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IMoonCatRescue.sol";
import "./IMoonCatsWrapped.sol";

/**
 * @title MoonCat Order Lookup
 * @notice A space to have an on-chain record mapping token IDs for OLD_MCRW to their original "rescue order" IDs
 * @dev This contract exists because there is no MoonCat ID => Rescue ID function
 * on the original MoonCatRescue contract. The only way to tell a given MoonCat's
 * rescue order if you don't know it is to iterate through the whole `rescueOrder`
 * array. Looping through that whole array in a smart contract would be
 * prohibitively high gas-usage, and so this alternative is needed.
 */
contract MoonCatOrderLookup is Ownable {

    MoonCatRescue MCR = MoonCatRescue(0x60cd862c9C687A9dE49aecdC3A99b74A4fc54aB6);
    MoonCatsWrapped OLD_MCRW = MoonCatsWrapped(0x7C40c393DC0f283F318791d746d894DdD3693572);

    uint256[25600] private _oldTokenIdToRescueOrder;
    uint8 constant VALUE_OFFSET = 10;

    constructor() Ownable() {}

    /**
      * @dev Submit a batch of token IDs, and their associated rescue orders
      * This is the primary method for the utility of the contract. Anyone
      * can submit this pairing information (not just the owners of the token)
      * and the information can be submitted in batches.
      *
      * Submitting pairs of token IDs with their rescue orders is verified with
      * the original MoonCatRescue contract before recording.
      *
      * Within the private array holding this information, a VALUE_OFFSET is used
      * to differentiate between "not set" and "set to zero" (because Solidity
      * has no concept of "null" or "undefined"). Because the maximum value of the
      * rescue ordering can only be 25,600, we can safely shift the stored values
      * up, and not hit the uint256 limit.
      */
    function submitRescueOrder(
        uint256[] memory oldTokenIds,
        uint16[] memory rescueOrders
    ) public {
        for (uint256 i = 0; i < oldTokenIds.length; i++) {
            require(
                MCR.rescueOrder(rescueOrders[i]) == OLD_MCRW._tokenIDToCatID(oldTokenIds[i]),
                "Pair does not match!"
            );
            _oldTokenIdToRescueOrder[oldTokenIds[i]] = rescueOrders[i] + VALUE_OFFSET;
        }
    }

    /**
      * @dev verify a given old token ID is mapped yet or not
      *
      * This function can use just a zero-check because internally all values are
      * stored with a VALUE_OFFSET added onto them (e.g. storing an actual zero
      * is saved as 0 + VALUE_OFFSET = 10, internally), so anything set to an
      * actual zero means "unset".
      */
    function _exists(uint256 oldTokenId) internal view returns (bool) {
        return _oldTokenIdToRescueOrder[oldTokenId] != 0;
    }

    /**
     * @dev public function to verify whether a given old token ID is mapped or not
     */
    function oldTokenIdExists(uint256 oldTokenId) public view returns(bool) {
        return _exists(oldTokenId);
    }

    /**
     * @dev given an old token ID, return the rescue order of that MoonCat
     *
     * Throws an error if that particular token ID does not have a recorded
     * mapping to a rescue order.
     */
    function oldTokenIdToRescueOrder(uint256 oldTokenId) public view returns(uint256) {
        require(_exists(oldTokenId), "That token ID is not mapped yet");
        return _oldTokenIdToRescueOrder[oldTokenId] - VALUE_OFFSET;
    }

    /**
     * @dev remove a mapping from the data structure
     *
     * This allows reclaiming some gas, so as part of the re-wrapping process,
     * this gets called by the Acclimator contract, to recoup some gas for the
     * MoonCat owner.
     */
    function removeEntry(uint256 _oldTokenId) public onlyOwner {
        delete _oldTokenIdToRescueOrder[_oldTokenId];
    }

    /**
     * @dev for a given address, iterate through all the tokens they own in the
     * old wrapping contract, and for each of them, determine how many are mapped
     * in this lookup contract.
     *
     * This method is used by the Acclimator `balanceOf` and `tokenOfOwnerByIndex`
     * to be able to enumerate old-wrapped MoonCats as if they were already
     * re-wrapped in the Acclimator contract.
     */
    function entriesPerAddress(address _owner) public view returns (uint256) {
        uint256 countMapped = 0;
        for (uint256 i = 0; i < OLD_MCRW.balanceOf(_owner); i++) {
            uint256 oldTokenId = OLD_MCRW.tokenOfOwnerByIndex(_owner, i);
            if (_exists(oldTokenId)) {
                countMapped++;
            }
        }
        return countMapped;
    }
}