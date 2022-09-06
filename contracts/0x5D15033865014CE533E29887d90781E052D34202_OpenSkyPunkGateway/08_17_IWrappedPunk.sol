// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IWrappedPunk is IERC721 {
    function punkContract() external view returns (address);
    function mint(uint256 punkIndex) external;
    function burn(uint256 punkIndex) external;
    function registerProxy() external;
    function proxyInfo(address user) external returns (address proxy);
}