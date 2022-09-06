//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.8;

import {IERC721AUpgradeable} from "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";

interface IEye is IERC721AUpgradeable {
    enum Phase {
        INIT,
        ADMIN,
        PREMINT,
        PUBLIC
    }

    struct Story {
        uint16 id;
        bytes32 librariumId;
    }

    function getArtifactName() external view returns (string memory);

    function getCollectionCuration()
        external
        view
        returns (Story[] memory storiesList);

    function getIndividualCuration(uint256 tokenId)
        external
        view
        returns (bytes32[] memory);

    function getAttunement(uint256 tokenId)
        external
        view
        returns (string memory);

    function getOrder(uint256 tokenId) external view returns (string memory);

    function getNamePrefix(uint256 tokenId)
        external
        view
        returns (string memory);

    function getNameSuffix(uint256 tokenId)
        external
        view
        returns (string memory);

    function getVision(uint256 tokenId) external view returns (string memory);

    function getName(uint256 tokenId) external view returns (string memory);

    function getVisionIndex(uint256 tokenId) external view returns (uint256);

    function getConditionIndex(uint256 tokenId) external view returns (uint256);

    function getOrderIndex(uint256 tokenId) external view returns (uint256);

    function getAttunementIndex(uint256 tokenId)
        external
        view
        returns (uint256);

    function getGreatness(uint256 tokenId) external pure returns (uint256);
}