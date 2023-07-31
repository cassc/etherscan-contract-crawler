// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMintableBurnableERC20 is IERC20 {
    function mint(address _to, uint256 _amount) external;
    function burn(uint256 _amount) external;
    function transferOwner(address _owner) external;
    function setMinter(address _minter, bool _status) external;
}