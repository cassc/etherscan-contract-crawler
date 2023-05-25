pragma solidity 0.8.16;

import {IERC20} from "@oz/token/ERC20/IERC20.sol";

interface IERC20MintableBurnable is IERC20 {
    function mint(address from, uint256 quantity) external;
    function burn(address from, uint256 quantity) external;
    function burn(uint256 quantity) external;
}