// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.0;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IPHTR is IERC20Metadata {
    function INITIAL_SUPPLY() external view returns (uint);
    function MAX_SUPPLY() external view returns (uint);
    function burnFrom(address account, uint amount) external;
    function burn(uint amount) external;
}