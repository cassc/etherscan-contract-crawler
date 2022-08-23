// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IProxyFactory.sol";
import "hardhat/console.sol";

contract TokenTransferProxy {
    using SafeERC20 for IERC20;

    IProxyFactory public factory;

    constructor(IProxyFactory _factory) {
        factory = _factory;
    }

    function transferFrom(IERC20 _token, address _from, address _to, uint _amount) external returns (bool) {
        require(factory.contracts(msg.sender), "illegal caller");
        _token.safeTransferFrom(_from, _to, _amount);
        return true;
    }

}