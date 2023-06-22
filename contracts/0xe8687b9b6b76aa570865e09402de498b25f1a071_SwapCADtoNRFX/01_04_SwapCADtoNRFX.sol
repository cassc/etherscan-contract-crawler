//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SwapCADtoNRFX is Ownable {
    IERC20 constant public CAD = IERC20(0x7099f572f039E44ACc2D8E4e024FB5507bCFE252);
    IERC20 constant public NRFX = IERC20(0x41BbD051E366D8437cb02374FBb0521C847F494E);
    uint constant NRFX_PRECISION = 10**18;
    uint public price = 100000;

    event Swap(address indexed caller, uint CADamount, uint NRFXamount);
    event Withdraw(uint NRFXamount);
    event SetPrice(uint newPrice);

    function swap(uint inputAmount) public {
        uint outAmount = inputAmount * NRFX_PRECISION / price;
        require (CAD.balanceOf(msg.sender) >= inputAmount, "Not enough CAD balance");
        require (NRFX.balanceOf(address(this)) >= outAmount, "Not enough liquidity");
        
        CAD.transferFrom(msg.sender, address(this), inputAmount);
        NRFX.transfer(msg.sender, outAmount);
        emit Swap(msg.sender, inputAmount, outAmount);
    }

    function withdrawNRFX(uint amount) public onlyOwner {
        require (NRFX.balanceOf(address(this)) >= amount, "Not enough NRFX");
        NRFX.transfer(msg.sender, amount);
        emit Withdraw(amount);
    }

    function withdrawNRFX() public onlyOwner {
        withdrawNRFX(NRFX.balanceOf(address(this)));
    }

    function setPrice(uint newPrice) public onlyOwner {
        price = newPrice;
        emit SetPrice(newPrice);
    }
}