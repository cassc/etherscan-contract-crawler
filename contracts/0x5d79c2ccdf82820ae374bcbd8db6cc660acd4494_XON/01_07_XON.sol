// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract XON is ERC20, Ownable {
    using SafeMath for uint256;

    uint256 private constant MAX_SUPPLY = 7000000 * 10**18;
    uint256 private constant OWNER_SUPPLY = 1000000 * 10**18;
    uint256 private constant MIN_SUPPLY = 1000000 * 10**18;
    uint256 private constant BURN_RATE = 35; // 0.35%

    bool private burningEnabled;

    constructor() ERC20("XON", "XON") {
        _mint(msg.sender, OWNER_SUPPLY);
        _mint(address(this), MAX_SUPPLY.sub(OWNER_SUPPLY));
        burningEnabled = true;
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(recipient != address(0), "Invalid recipient address");
        require(amount > 0, "Amount must be greater than zero");
        _burnTokens(amount);
        return super.transfer(recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        require(sender != address(0), "Invalid sender address");
        require(recipient != address(0), "Invalid recipient address");
        require(amount > 0, "Amount must be greater than zero");
        _burnTokens(amount);
        return super.transferFrom(sender, recipient, amount);
    }

    function _burnTokens(uint256 amount) internal {
        if (burningEnabled && totalSupply() > MIN_SUPPLY) {
            uint256 burnAmount = amount.mul(BURN_RATE).div(10000); // Dividing by 10000 to account for decimal places
            if (totalSupply().sub(burnAmount) < MIN_SUPPLY) {
                burnAmount = totalSupply().sub(MIN_SUPPLY);
                burningEnabled = false;
            }
            _burn(msg.sender, burnAmount);
        }
    }

    function enableBurning() external onlyOwner {
        require(totalSupply() > MIN_SUPPLY, "Token supply is already at the minimum");
        burningEnabled = true;
    }

    function disableBurning() external onlyOwner {
        burningEnabled = false;
    }

    function upgradeContract(address newContract) external onlyOwner {
        require(newContract != address(0), "Invalid contract address");
        transferOwnership(newContract);
    }
}