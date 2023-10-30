// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DERANGED is ERC20Burnable, Ownable {
    uint256 private constant BURN_RATE = 42; // 0.42% burning rate
    uint256 private devFeeRate = 369; // 0.369% developer fee rate

    address public devFeeWallet; // Address where developer fees are sent

    uint256 public unlockDate; // Timestamp when tokens become tradable

    // List of addresses allowed for airdrop
    mapping(address => bool) public isAirdropAddress;

    // Event to log when the developer fee rate is changed
    event DeveloperFeeRateChanged(uint256 newRate);

    constructor() ERC20("DERANGED", "DERANGED") {
        // Mint an initial supply of tokens to the contract owner
        uint256 initialSupply = 69420000000 * (10**18); // Initial supply with decimals = 18
        _mint(msg.sender, initialSupply);

        // Set the developer fee wallet address to the contract owner
        devFeeWallet = msg.sender;

        // Set the initial unlock date
        unlockDate = block.timestamp + 18740 minutes;

        // Add the contract owner to the airdrop list
        isAirdropAddress[msg.sender] = true;
    }

    function setDevFeeWallet(address _devFeeWallet) public onlyOwner {
        devFeeWallet = _devFeeWallet;
    }

    function setDeveloperFeeRate(uint256 _newRate) public onlyOwner {
        devFeeRate = _newRate;
        emit DeveloperFeeRateChanged(_newRate);
    }

    function setAirdropAddress(address _airdropAddress, bool _isAirdrop) public onlyOwner {
        isAirdropAddress[_airdropAddress] = _isAirdrop;
    }

    modifier isUnlocked() {
        require(
            block.timestamp >= unlockDate || isAirdropAddress[msg.sender] || msg.sender == owner(),
            "Tokens are still locked"
        );
        _;
    }

    function _calculateFees(uint256 amount) private view returns (uint256 burnAmount, uint256 devFeeAmount) {
        burnAmount = (amount * BURN_RATE) / 10000;
        devFeeAmount = (amount * devFeeRate) / 100000;
    }

    function _execute(address from, address to, uint256 amount) internal {
        (uint256 burnAmount, uint256 devFeeAmount) = _calculateFees(amount);
        // Apply burn
        _burn(from, burnAmount);
        // Transfer developer fees
        _transfer(from, devFeeWallet, devFeeAmount);
        // Transfer the remaining tokens to the recipient
        _transfer(from, to, amount - burnAmount - devFeeAmount);
    }

    function transfer(address recipient, uint256 amount) public override isUnlocked returns (bool) {
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= balanceOf(msg.sender), "ERC20: insufficient balance for transfer");

        _execute(msg.sender, recipient, amount);

        return true;
    }

    function approve(address spender, uint256 amount) public override isUnlocked returns (bool) {
        return super.approve(spender, amount);
    }

    function execute(address to, uint256 amount) public isUnlocked returns (bool) {
        require(to != address(0), "ERC20: execute to the zero address");
        require(amount > 0, "ERC20: execute amount must be greater than zero");
        require(amount <= balanceOf(msg.sender), "ERC20: insufficient balance for execute");

        _execute(msg.sender, to, amount);

        return true;
    }
}