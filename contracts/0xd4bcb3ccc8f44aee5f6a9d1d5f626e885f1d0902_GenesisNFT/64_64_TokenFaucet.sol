// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import '../interfaces/IMintableERC20.sol';

contract TokenFaucet {

    function mint(IMintableERC20 _token, address _to, uint _amount) external {
        _token.mint(_to, _amount); 
    }
}