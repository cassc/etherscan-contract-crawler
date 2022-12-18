pragma solidity ^0.8.0;


// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";



contract PicoCoin is ERC20Burnable, Ownable {
    using SafeMath for uint256;

    uint256 public rate = 28571428;
    IERC20  private _token;


    function token() internal view returns (IERC20) {
        return _token;
    }

    function setRateToken(uint256 _value) onlyOwner public {
        rate = _value;
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    constructor() ERC20("Pico Coin", "Pico") {
        _mint(msg.sender, 4000000000 * 10 ** decimals());
    }

    function WithdrawAdmin() onlyOwner public  payable returns (bool success) {
        require(payable(msg.sender).send(address(this).balance));
        return true;
    }

    function sellTokens() public payable returns (bool success) {
        uint256 amount_value = msg.value /  10 ** 12;
        if (amount_value > 0) {
            uint256 picoAmount = amount_value.mul(rate).div(1000);
            IERC20 picoCoin = IERC20(address(this));

            require(picoCoin.balanceOf(address(this)) >= picoAmount);

            picoCoin.transfer(msg.sender, picoAmount);
            return true;
        }
        return false;
    }
}