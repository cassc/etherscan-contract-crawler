// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract SendBoxs is Ownable {
    IERC1155 public immutable box;

    constructor(IERC1155 _box) {
        box = _box;
    }

    function send(uint _tokenId, uint[] memory _amounts, address[] memory users) external {
        for(uint i = 0; i < _amounts.length; i++){
            box.safeTransferFrom(_msgSender(), users[i], _tokenId, _amounts[i], '0x');
        }

    }

    function inCaseTokensGetStuck(IERC20 _token) external onlyOwner {

        uint amount = _token.balanceOf(address(this));
        _token.transfer(msg.sender, amount);
    }
}