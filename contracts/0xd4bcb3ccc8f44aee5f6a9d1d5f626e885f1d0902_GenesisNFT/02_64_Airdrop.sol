// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../core/SafeOwnable.sol';

contract Airdrop is SafeOwnable {
    using SafeERC20 for IERC20;

    uint public nonce;

    function ERC20Transfer(uint _startNonce, IERC20 _token, address _vault, address[] memory _users, uint[] memory _amounts) external onlyOwner {
        if (_vault == address(0)) {
            _vault = address(this);
        }
        require(_startNonce > nonce, "already done");
        require(_users.length > 0 && _users.length == _amounts.length, "illegal length");
        for (uint i = 0; i < _users.length; i ++) {
            _token.safeTransferFrom(_vault, _users[i], _amounts[i]);
        }
        nonce = _startNonce + _users.length - 1;
    }

}