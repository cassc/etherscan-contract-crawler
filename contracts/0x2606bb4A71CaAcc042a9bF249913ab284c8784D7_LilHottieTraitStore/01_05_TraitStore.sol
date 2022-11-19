pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract LilHottieTraitStore is Ownable, Pausable, ReentrancyGuard {
    string public name;
    address private withdrawWallet;

    event PointsPurchased(
        address owner,
        uint amount
    );

    constructor() {
        name = "LilHottie Trait Store";
        withdrawWallet = address(msg.sender);
        _pause();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function getWithdrawWallet() public view onlyOwner returns (address) {
        return withdrawWallet;
    }


    function setWithdrawWallet(address wallet) public onlyOwner {
        withdrawWallet = wallet;
    }

    function withdraw() public payable onlyOwner nonReentrant {
        (bool os, ) = payable(withdrawWallet).call{value: address(this).balance}("");
        require(os);
    }

    function buyPoints() public payable whenNotPaused {
        emit PointsPurchased(msg.sender, msg.value);
    }
}