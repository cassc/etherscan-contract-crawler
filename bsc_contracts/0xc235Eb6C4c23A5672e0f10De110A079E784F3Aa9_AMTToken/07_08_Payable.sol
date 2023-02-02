pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Payable is ERC20, Ownable {

    function selfBalance() public view returns (uint256) {
        return balanceOf(address(this));
    }

    function balance() public view returns (uint256) {
        return address(this).balance;
    }

    receive() external payable {}

    fallback() external payable {}

    function withdraw(uint256 amount) public onlyOwner {
        checkSelfBalance(amount);

        _transfer(address(this), owner(), amount);
    }

    function withdrawAll() public onlyOwner {

        _transfer(address(this), owner(), selfBalance());
    }

    function sendTo(address payable account, uint256 amount) public onlyOwner {
        checkSelfBalance(amount);

        _transfer(address(this), account, amount);
    }

    function withdrawEth(uint256 amount) public onlyOwner {
        checkBalance(amount);

        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success, "Failed to send Ether");
    }

    function withdrawAllEth() public onlyOwner {

        (bool success, ) = payable(owner()).call{value: balance()}("");
        require(success, "Failed to send Ether");
    }

    function sendEthTo(address payable account, uint256 amount) public onlyOwner {
        checkBalance(amount);

        (bool sent, ) = account.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    function checkSelfBalance(uint256 amount) private view {
        require(selfBalance() >= amount, "ERC20: transfer amount exceeds allowance");
    }

    function checkBalance(uint256 amount) private view {
        require(balance() >= amount, "ERC20: transfer amount exceeds allowance");
    }
}