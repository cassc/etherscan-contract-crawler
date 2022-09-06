// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity ^0.8.0;

interface IERC721Factory {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function numOptions() external view returns (uint256);

    function canMint(uint256 _optionId) external view returns (bool);

    function tokenURI(uint256 _optionId) external view returns (string memory);

    function supportsFactoryInterface() external view returns (bool);

    function mint(uint256 _optionId, address _toAddress) external;
}