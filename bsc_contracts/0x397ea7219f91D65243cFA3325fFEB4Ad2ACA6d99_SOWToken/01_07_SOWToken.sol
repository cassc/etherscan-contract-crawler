// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SOWToken is ERC20, ERC20Burnable, Ownable {
    event InCaseTokensGetStuck(IERC20 _token, uint _amount);

    constructor() ERC20("SOCCER WORLDCUP", "SOW") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
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