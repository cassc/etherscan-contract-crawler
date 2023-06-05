// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Teams.sol";

error ValueCannotBeZero();

abstract contract Withdrawable is Teams {
    address public constant payableAddress = 0x821a2a1C9FA029e851aFC3600D800c158Fc4B87C;

    function withdrawAll() public onlyTeamOrOwner {
        if (address(this).balance == 0) revert ValueCannotBeZero();
        _widthdraw(payableAddress, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }
}