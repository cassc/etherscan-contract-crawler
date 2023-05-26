// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {IERC2981Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import {IERC721EnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC721EnumerableUpgradeable.sol";
import {IERC721MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC721MetadataUpgradeable.sol";

interface IEclipseERC721 is
    IERC721MetadataUpgradeable,
    IERC2981Upgradeable,
    IERC721EnumerableUpgradeable
{
    function initialize(
        string memory name,
        string memory symbol,
        string memory uri,
        uint256 id,
        uint24 maxSupply,
        address admin,
        address contractAdmin,
        address artist,
        address[] memory minters,
        address paymentSplitter
    ) external;

    function getTokensByOwner(
        address _owner
    ) external view returns (uint256[] memory);

    function getInfo()
        external
        view
        returns (
            string memory name,
            string memory symbol,
            address artist,
            uint256 id,
            uint24 maxSupply,
            uint256 totalSupply
        );

    function mint(address to, uint24 amount) external;

    function mintOne(address to) external;

    function setMinter(address minter, bool enable) external;
}