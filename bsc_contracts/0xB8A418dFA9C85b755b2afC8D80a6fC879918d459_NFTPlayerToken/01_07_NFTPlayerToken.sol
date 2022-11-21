// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTPlayerToken is ERC20, ERC20Burnable, Ownable {
    event InCaseTokensGetStuck(IERC20 _token, uint _amount);

    constructor() ERC20("NFT Players", "NP") {
        _mint(msg.sender, 100000000 * 10 ** decimals());

    }
    /**
     * @notice Withdraw unexpected tokens sent to the token contract
     */
    function inCaseTokensGetStuck(IERC20 _token) external onlyOwner {

        uint amount = _token.balanceOf(address(this));
        _token.transfer(msg.sender, amount);
        emit InCaseTokensGetStuck(_token, amount);
    }
}