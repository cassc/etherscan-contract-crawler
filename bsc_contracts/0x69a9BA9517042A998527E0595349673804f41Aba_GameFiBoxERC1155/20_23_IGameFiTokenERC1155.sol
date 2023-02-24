// SPDX-License-Identifier: BUSL-1.1
// GameFi Core™ by CDEVS

pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/IERC1155MetadataURIUpgradeable.sol";

interface IGameFiTokenERC1155 is IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    function initialize(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        string memory tokenURI_,
        bytes memory data_
    ) external;

    function setContractURI(string memory newURI) external;

    function setTokenURI(string memory newURI) external;

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    function burn(
        address account,
        uint256 id,
        uint256 value,
        bytes memory data
    ) external;

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) external;

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function contractURI() external view returns (string memory);

    function totalSupply() external view returns (uint256);
}