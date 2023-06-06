//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

interface IERC2612 is IERC20Metadata, IERC20Permit {
    function _nonces(address owner) external view returns (uint256);

    function version() external view returns (string memory);
}