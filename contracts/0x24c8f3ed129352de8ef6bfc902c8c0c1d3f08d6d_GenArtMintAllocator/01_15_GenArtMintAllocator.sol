// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./MintAlloc.sol";
import "../access/GenArtAccess.sol";
import "../interface/IGenArtInterfaceV4.sol";
import "../interface/IGenArtERC721.sol";
import "../interface/IGenArtMintAllocator.sol";

/**
 * @dev GEN.ART Mint Allocator
 */

contract GenArtMintAllocator is GenArtAccess, IGenArtMintAllocator {
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
        override
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
    ) external override onlyAdmin {
        mintstates[collection].update(
            MintUpdateParams(
                membershipId,
                IGenArtInterfaceV4(genartInterface).isGoldToken(membershipId),
                amount
            )
        );
    }

    function setReservedGold(address collection, uint8 reservedGold)
        external
        override
        onlyAdmin
    {
        mintstates[collection].setReservedGold(reservedGold);
    }

    /**
     *@dev Get available mints for a membershipId
     */
    function getAvailableMintsForMembership(
        address collection,
        uint256 membershipId
    ) external view override returns (uint256) {
        return _getAvailableMintsForMembership(collection, membershipId);
    }

    /**
     *@dev Internal helper method to get available mints for a membershipId
     */
    function _getAvailableMintsForMembership(
        address collection,
        uint256 membershipId
    ) internal view returns (uint256) {
        (, , , , , uint256 maxSupply, uint256 totalSupply) = IGenArtERC721(
            collection
        ).getInfo();
        return
            mintstates[collection].getAvailableMints(
                MintParams(
                    membershipId,
                    IGenArtInterfaceV4(genartInterface).isGoldToken(
                        membershipId
                    ),
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
        override
        returns (uint256)
    {
        return mintstates[collection].getMints(membershipId);
    }

    function getAvailableMintsForAccount(address collection, address account)
        external
        view
        override
        returns (uint256)
    {
        uint256[] memory memberships = IGenArtInterfaceV4(genartInterface)
            .getMembershipsOf(account);
        uint256 available;
        for (uint256 i; i < memberships.length; i++) {
            available += _getAvailableMintsForMembership(
                collection,
                memberships[i]
            );
        }

        return available;
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