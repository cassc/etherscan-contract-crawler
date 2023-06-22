// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC721.sol";

interface ISanctum is IERC721 {
    function mint(address _to, address _for) external;

    function totalSupply() external returns (uint256);

    function getDistributionLimit(address _address) external view returns (uint256);
}