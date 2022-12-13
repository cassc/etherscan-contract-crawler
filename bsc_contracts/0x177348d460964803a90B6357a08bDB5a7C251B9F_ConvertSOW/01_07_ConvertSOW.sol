// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ConvertSOW is Ownable {
    address public signer;
    IERC20 public immutable sow;
    IERC20 public immutable sowNew;

    constructor(IERC20 _sow, IERC20 _sowNew) {
        sow = _sow;
        sowNew = _sowNew;
    }

    function convert(uint amount) external {
        sow.transferFrom(_msgSender(), address(this), amount);
        sowNew.transfer(_msgSender(), amount);
    }

    function inCaseTokensGetStuck(IERC20 _token) external onlyOwner {

        uint amount = _token.balanceOf(address(this));
        _token.transfer(msg.sender, amount);
    }
}