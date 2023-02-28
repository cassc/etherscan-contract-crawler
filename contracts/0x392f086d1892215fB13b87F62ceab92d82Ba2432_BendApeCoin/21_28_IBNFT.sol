// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {IERC721ReceiverUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";

interface IBNFT is IERC721Upgradeable, IERC721ReceiverUpgradeable {
    function flashLoan(
        address receiverAddress,
        uint256[] calldata nftTokenIds,
        bytes calldata params
    ) external;

    function mint(address to, uint256 tokenId) external;

    function minterOf(uint256 tokenId) external view returns (address);

    function burn(uint256 tokenId) external;

    function underlyingAsset() external view returns (address);

    function setFlashLoanLocking(
        uint256 tokenId,
        address locker,
        bool locked
    ) external;

    function isFlashLoanLocked(
        uint256 tokenId,
        address minter,
        address operator
    ) external view returns (bool);

    function setFlashLoanApproval(address operator, bool approved) external;
}