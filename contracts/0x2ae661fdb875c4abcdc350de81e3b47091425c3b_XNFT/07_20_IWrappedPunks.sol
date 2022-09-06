// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

interface IWrappedPunks is IERC721EnumerableUpgradeable {

    function punkContract() external view returns (address);

    function mint(uint256 punkIndex) external;

    function burn(uint256 punkIndex) external;

    function registerProxy() external;

    function proxyInfo(address user) external returns (address proxy);
}