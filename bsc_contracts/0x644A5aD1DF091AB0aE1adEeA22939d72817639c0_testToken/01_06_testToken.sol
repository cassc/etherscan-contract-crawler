//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-0.8/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-0.8/access/Ownable.sol";
import "@openzeppelin/contracts-0.8/utils/math/SafeMath.sol";

contract testToken is ERC20, Ownable {
    using SafeMath for uint256;

    uint256 public constant maxSupply = 7951696555 ether;
    uint256 public supply;
    uint256 public transferFee;

    constructor() ERC20("test", "TEST") {
        supply = 0 ether;
        transferFee = 18;
    }

    function mint(address to, uint256 amount) onlyOwner public returns(bool) {
        require(supply.add(amount) <= maxSupply, "Cannot mint more Tokens than the maximum supply");
        _mint(to, amount);
        supply = supply.add(amount);

        return(true);
    }

    function burn(address tokenHolder, uint256 amount) onlyOwner public returns(bool) {
        _burn(tokenHolder, amount);

        return(true);
    }

    function setTransferFee(uint256 _fee) public onlyOwner returns(bool) {
        transferFee = _fee;

        emit transferFeeSet(_fee);
        return(true);
    }

    function getTransferFee() public view returns(uint256) {
        return(transferFee);
    }

    function transfer(address to, uint amount) public virtual override returns(bool) {
        require(balanceOf(msg.sender) >= amount, "Balance is too low");

        uint256 fee = amount.mul(transferFee).div(1000);
        uint256 afterFee = amount.sub(fee);
        
        _transfer(_msgSender(), to, afterFee);
        _transfer(_msgSender(), address(this), fee);

        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns(bool) {
        require(balanceOf(from) >= amount, "Balance is too low");

        uint256 fee = amount.mul(transferFee).div(1000);
        uint256 afterFee = amount.sub(fee);

        _transfer(from, to, afterFee);
        _transfer(from, address(this), fee);

        uint256 currentAllowance = allowance(from, _msgSender());
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(from, _msgSender(), currentAllowance - amount);

        return true;
    }

    event transferFeeSet(uint256 fee);
}