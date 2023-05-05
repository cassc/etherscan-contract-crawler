// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

pragma solidity 0.8.16;

interface IXeno is IERC165 {
    function pause() external;

    function unpause() external;

    function safeMint(address, uint256) external returns (uint256[] memory);

    function setBaseURI(string calldata) external;

    function totalSupply() external view returns (uint256);

    function setMinter(address newMinter) external;

    function getMinter() external view returns (address);

    function setDefaultRoyalty(address, uint96) external;
}