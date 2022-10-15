// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;
import './IERC721AQueryable.sol';

interface IValidatorNft is IERC721AQueryable {
    function activeValidators() external view returns (bytes[] memory);

    function validatorExists(bytes calldata pubkey) external view returns (bool);

    function validatorOf(uint256 tokenId) external view returns (bytes memory);

    function validatorsOfOwner(address owner) external view returns (bytes[] memory);

    function tokenOfValidator(bytes calldata pubkey) external view returns (uint256);

    function setGasHeight(uint256 tokenId, uint256 value) external;

    function gasHeightOf(uint256 tokenId) external view returns (uint256);

    function lastOwnerOf(uint256 tokenId) external view returns (address);

    function whiteListMint(bytes calldata data, address _to) external payable;

    function whiteListBurn(uint256 tokenId) external;

    function updateNodeCapital(uint256 tokenId, uint256 value) external;

    function nodeCapitalOf(uint256 tokenId)  external view returns (uint256);
}