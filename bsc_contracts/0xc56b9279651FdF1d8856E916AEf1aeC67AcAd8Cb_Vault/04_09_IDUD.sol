// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./openzeppelin/token/ERC20/IERC20.sol";

interface IDUD is IERC20 {
    function mint(address to, uint256 amount) external;
    function pause() external;
    function unpause() external;
    function confiscateFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    function blacklistAddress(address _addr, bool _value) external;
    function burnFrom(address account, uint256 amount) external;
}