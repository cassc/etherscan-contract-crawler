//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract OBSource is ReentrancyGuard, Context {
    function transfer(address payable _to, bytes calldata _ext)
        public
        payable
        nonReentrant
    {
        (bool sent, ) = _to.call{value: msg.value}("");
        require(sent, "ERROR");
    }

    function transferERC20(
        IERC20 _token,
        address _to,
        uint256 _amount,
        bytes calldata _ext
    ) external nonReentrant {
        bool sent = _token.transferFrom(msg.sender, _to, _amount);
        require(sent, "ERROR");
    }
}