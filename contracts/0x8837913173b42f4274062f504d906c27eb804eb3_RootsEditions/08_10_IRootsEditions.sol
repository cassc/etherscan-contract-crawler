// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

interface IRootsEditions {
    function mintArtistProof() external;

    function mintEdition(
        uint128 price,
        uint32 starts,
        uint8 presaleAmount,
        bytes32 presaleRoot
    ) external;

    function collectInPresale(uint256 id, bytes32[] calldata proof) external payable;

    function collect(uint256 id) external payable;

    function closeEdition(uint256 id) external;

    function setPresaleAmountForEdition(uint256 id, uint8 presaleAmount) external;

    function setPresaleRootForEdition(uint256 id, bytes32 presaleRoot) external;

    function removePresaleRequirementForEdition(uint256 id) external;

    function getHasArtistProofBeenMinted(uint256 id) external view returns (bool);

    function getHasArtworkEditionBeenMinted(uint256 id) external view returns (bool);

    function getArtworkEditionSize(uint256 id) external view returns (uint256);

    function getArtworkPresaleAmount(uint256 id) external view returns (uint256);

    function getArtworkSalePrice(uint256 id) external view returns (uint256);

    function getArtworkSaleStartTime(uint256 id) external view returns (uint256);

    function getArtworkEditionsSold(uint256 id) external view returns (uint256);

    function getArtworkEditionsSoldInPresale(uint256 id) external view returns (uint256);

    function getArtworkEditionsCurrentlyAvailable(uint256 id) external view returns (uint256);

    function getArtworkEditionsNextReleaseTime(uint256 id) external view returns (uint256);

    function getArtworkRealTokenId(uint256 id, uint256 edition) external view returns (uint256);

    function getArtworkIdFromRealId(uint256 realId) external view returns (uint256);

    function getArtworkEditionNumberFromRealId(uint256 realId) external view returns (uint256);

    function getArtworkInformation(uint256 id)
        external
        view
        returns (
            bool artistProofMinted,
            uint256 editionSize,
            uint256 price,
            uint256 starts,
            uint256 nextEditionReleaseTime,
            uint256 editionsCurrentlyAvailable,
            uint256 presaleAmount,
            bytes32 presaleRoot,
            uint256 soldPresale,
            uint256 sold,
            bool editionMinted
        );
}