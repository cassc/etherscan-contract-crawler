// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./MintAlloc.sol";
import "../access/GenArtAccess.sol";
import "../app/GenArtCurated.sol";
import "../interface/IGenArtMinter.sol";
import "../interface/IGenArtInterface.sol";
import "../interface/IGenArtERC721.sol";
import "../interface/IGenArtPaymentSplitterV4.sol";

/**
 * @dev GEN.ART Mint Allocator
 */

contract GenArtMintAllocator is GenArtAccess {
    using MintAlloc for MintAlloc.State;

    mapping(address => MintAlloc.State) public mintstates;
    address public genartInterface;

    constructor(address genartInterface_) GenArtAccess() {
        genartInterface = genartInterface_;
    }

    /**
     *@dev Initialize mint state for collection
     */
    function init(address collection, uint8[3] memory mintAlloc)
        external
        onlyAdmin
    {
        mintstates[collection].init(mintAlloc);
    }

    /**
     *@dev Update mint state
     */
    function update(
        address collection,
        uint256 membershipId,
        uint256 amount
    ) external onlyAdmin {
        mintstates[collection].update(
            MintUpdateParams(
                membershipId,
                IGenArtInterface(genartInterface).isGoldToken(membershipId),
                amount
            )
        );
    }

    /**
     *@dev Get available mints for a membershipId
     */
    function getAvailableMintsForMembership(
        address collection,
        uint256 membershipId
    ) external view returns (uint256) {
        (, , , , , uint256 maxSupply, uint256 totalSupply) = IGenArtERC721(
            collection
        ).getInfo();
        return
            mintstates[collection].getAvailableMints(
                MintParams(
                    membershipId,
                    IGenArtInterface(genartInterface).isGoldToken(membershipId),
                    maxSupply,
                    totalSupply
                )
            );
    }

    /**
     *@dev Get amount of mints for a membershipId
     */
    function getMembershipMints(address collection, uint256 membershipId)
        external
        view
        returns (uint256)
    {
        return mintstates[collection].getMints(membershipId);
    }

    function getMintAlloc(address collection)
        external
        view
        returns (
            uint8,
            uint8,
            uint8,
            uint256
        )
    {
        return (
            mintstates[collection].reservedGoldSupply,
            mintstates[collection].allowedMintGold,
            mintstates[collection].allowedMintStandard,
            mintstates[collection]._goldMints
        );
    }
}