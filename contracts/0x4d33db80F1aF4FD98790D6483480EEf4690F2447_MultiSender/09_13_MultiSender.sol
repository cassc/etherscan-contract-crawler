//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./MultiTransfer.sol";
import "./MultiTransferEqual.sol";
import "./MultiTransferToken.sol";
import "./MultiTransferTokenEqual.sol";


contract MultiSender is Pausable, Ownable,
    MultiTransfer,
    MultiTransferEqual,
    MultiTransferToken,
    MultiTransferTokenEqual
{
    using SafeERC20 for IERC20;

    function emergencyStop() external onlyOwner {
        _pause();
    }

    receive() external payable {
        revert("Can not accept Ether directly.");
    }

    fallback() external payable { require(msg.data.length == 0); }

    function claim(address _token) public onlyOwner {
        if (_token == address(0)) {
            payable(owner()).transfer(address(this).balance);
            return;
        }
        IERC20 erc20token = IERC20(_token);
        uint256 balance = erc20token.balanceOf(address(this));
        erc20token.safeTransfer(owner(), balance);
    }
}