// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITokenTransferProxy {

    function transferFrom(IERC20 _token, address _from, address _to, uint _amount) external returns (bool);

}