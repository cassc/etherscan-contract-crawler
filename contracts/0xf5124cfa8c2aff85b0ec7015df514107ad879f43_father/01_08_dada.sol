// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract father is ERC20, Ownable, Pausable, ReentrancyGuard {
    address public TokenSwapContract;
    address public StakingContract;
    bool public locked;

    constructor() ERC20("FATHER", "FATHER") {
        locked = true;
        _mint(msg.sender, 69000000000 * 1 ether);
    }

    modifier whenLocked() {
        if (locked) {
            require(
                msg.sender == TokenSwapContract || msg.sender == getOwner(),
                "Token transfer is Locked"
            );
        }
        _;
    }

    function getOwner() public view returns (address) {
        return owner();
    }

    function setTokenSwapContract(
        address _tokenSwapContract
    ) external onlyOwner {
        require(_tokenSwapContract != address(0), "Cannot set zero address");
        TokenSwapContract = _tokenSwapContract;
    }

    function setStakingContract(address _stakingContract) external onlyOwner {
        require(_stakingContract != address(0), "Cannot set zero address");
        StakingContract = _stakingContract;
    }

    function lock() public onlyOwner {
        locked = true;
    }

    function unlock() public onlyOwner {
        locked = false;
    }

    function pauseswap() public onlyOwner {
        _pause();
    }

    function unpauseswap() public onlyOwner {
        _unpause();
    }

    function transfer(
        address to,
        uint256 amount
    ) public override whenNotPaused whenLocked nonReentrant returns (bool) {
        address sender = _msgSender();

        _transfer(sender, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override whenNotPaused whenLocked returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);

        _transfer(from, to, amount);
        return true;
    }
}