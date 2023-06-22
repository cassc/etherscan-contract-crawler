pragma solidity ^0.8.10;

import { IERC20Upgradeable } from "openzeppelin-contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IERC20UpgradeableDetailed is IERC20Upgradeable {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
}