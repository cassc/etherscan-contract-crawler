//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract BankRun is ERC20, Ownable {
    using SafeMath for uint256;

    uint256 public maxSupply = 69000000000 * 10**decimals();
    uint256 public amountToBeBurned;

    address private contractCreator;

    bool renounced;

    mapping(address => bool) private _isExcludedFromLimit;

    constructor() ERC20("BankRun", "$RUN") {
        _isExcludedFromLimit[_msgSender()] = true;
        _isExcludedFromLimit[address(this)] = true;

        _mint(_msgSender(), maxSupply);

        contractCreator = _msgSender();
    }

    modifier createSupplyShockBurner() {
        require(contractCreator == _msgSender(), "Only Initial Creator can bring about a supplyShock");
        _;
    }

    function renounceOwnershipForPresale () external onlyOwner returns (bool) {
         renounceOwnership();

         renounced = true;

         return true;
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address _owner = _msgSender();

        if (renounced == true) {
            uint256 burnAmount = (amount.mul(2)).div(100);
            uint256 transferAmount = amount.sub(burnAmount);

            _transfer(_owner, to, transferAmount);
            _transfer(_owner, contractCreator, burnAmount);

            amountToBeBurned += burnAmount;
        } else {
            _transfer(_owner, to, amount);
        }

        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);


        if (renounced == true) {
            uint256 burnAmount = (amount.mul(2)).div(100);
            uint256 transferAmount = amount.sub(burnAmount);

            _transfer(from, to, transferAmount);
            _transfer(from, contractCreator, burnAmount);

            amountToBeBurned += burnAmount;
        } else {
            _transfer(from, to, amount);
        }

        return true;
    }

    function createSupplyShock() external createSupplyShockBurner returns (bool) {
        _burn(contractCreator, amountToBeBurned);
        amountToBeBurned = 0;

        return true;
    }


    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (renounced == true) {
                require(to == address(0) || _isExcludedFromLimit[_msgSender()] || _ensureMaxTwoPercentPerWallet(amount, to), 'Whale and Dump Prevention: One Wallet cannot hold more than 2% of max Supply');
        }
    }


    function _ensureMaxTwoPercentPerWallet(uint256 _amount, address reciever) internal view returns (bool) {
        bool ensured = false;
        uint256 amountToCheck;

        if (reciever != contractCreator) {
            amountToCheck = balanceOf(reciever) > 0 ? balanceOf(reciever).add(_amount) : _amount;
            ensured = amountToCheck < (maxSupply.mul(2)).div(100);
        } else {
            ensured = true;
        }

        return ensured;
    }


}