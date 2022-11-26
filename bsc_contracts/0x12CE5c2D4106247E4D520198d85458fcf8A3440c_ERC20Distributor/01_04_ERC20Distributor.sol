// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract ERC20Distributor is Ownable {

    function distribute(address _token, address _from, address[] calldata _to, uint256[] calldata _amount) external onlyOwner {
        for (uint256 i = 0; i < _to.length; ++i) {
            IERC20(_token).transferFrom(_from, _to[i], _amount[i]);
        }
    }
}