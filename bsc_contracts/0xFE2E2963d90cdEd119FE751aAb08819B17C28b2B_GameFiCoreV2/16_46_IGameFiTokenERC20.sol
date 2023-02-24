// SPDX-License-Identifier: BUSL-1.1
// GameFi Core™ by CDEVS

pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

interface IGameFiTokenERC20 is IERC20Upgradeable, IERC20MetadataUpgradeable {
    function initialize(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        bytes memory data_
    ) external;

    function setContractURI(string memory newURI) external;

    function mint(
        address to,
        uint256 amount,
        bytes memory data
    ) external;

    function burn(
        address to,
        uint256 amount,
        bytes memory data
    ) external;

    function contractURI() external view returns (string memory);
}