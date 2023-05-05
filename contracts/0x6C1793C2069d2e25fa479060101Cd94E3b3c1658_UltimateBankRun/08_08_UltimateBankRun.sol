// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
 

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
  

contract UltimateBankRun is ERC20, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    bool public taxesActive = false;
    bool public whaleProtectionActive = false;

    uint256 public taxAmount = 2;
    uint256 public whaleAmount = 2;
    uint256 public amountToBeBurned;
    uint256 public maxSupply = 69000000000 * 10**decimals();

    address private contractCreator;


    struct AirDropStruct {
        address recipient;
        uint256 amount;
    }

    mapping(address => bool) private _isExcludedFromLimit;

    event BatchMinted();

    constructor(uint256 _amountToBeAirdropped) ERC20("BankRun Buyout", "$BRUN")  {
        _isExcludedFromLimit[_msgSender()] = true;
        _isExcludedFromLimit[address(this)] = true;

        uint256 airdropAmount = _amountToBeAirdropped * 10**decimals();

        _mint(_msgSender(), maxSupply.sub(airdropAmount));

        contractCreator = _msgSender();
    }

    modifier createSupplyShockBurner() {
        require(contractCreator == _msgSender(), "Only Initial Creator can bring about a supplyShock");
        _;
    }


    function setTaxesAndWhaleProtectionActive (bool _taxesActive, bool _whaleProtectionActive) external createSupplyShockBurner returns (bool) {
        taxesActive = _taxesActive;
        whaleProtectionActive = _whaleProtectionActive;

        return true;
    }


    function setTaxAndWhaleAmount (uint256 _taxAmount, uint256 _whaleAmount) external createSupplyShockBurner returns (bool) {
        taxAmount = _taxAmount;
        whaleAmount = _whaleAmount;

        return true;
    }

    function setExcludedFromLimit (bool _excluded, address _excludee) external createSupplyShockBurner returns (bool) {
        _isExcludedFromLimit[_excludee] = _excluded;

        return true;
    }

    function createSupplyShock() external createSupplyShockBurner returns (bool) {
        _burn(contractCreator, amountToBeBurned);
        amountToBeBurned = 0;

        return true;
    }


    function mintAndDrop(AirDropStruct[] memory _airdropStruct) external onlyOwner returns (bool) {

        for (uint256 i = 0; i < _airdropStruct.length; i++) {
            address recipient = _airdropStruct[i].recipient;
            uint256 amount = _airdropStruct[i].amount * 10**decimals();

            unchecked {
                _mint(recipient, amount);
            }
        }

        emit BatchMinted();

        return true;
    }


    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);


        if (taxesActive == true) {
            uint256 burnAmount = (amount.mul(taxAmount)).div(100);
            uint256 transferAmount = amount.sub(burnAmount);

            _transfer(from, to, transferAmount);
            _transfer(from, contractCreator, burnAmount);

            amountToBeBurned += burnAmount;
        } else {
            _transfer(from, to, amount);
        }

        return true;
    }


    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (whaleProtectionActive == true) {
                require( _ensureMaxTwoPercentPerWallet(amount, from, to), 'Whale and Dump Prevention: One Wallet cannot hold more than 2% of max Supply');
        }
    }

    function _ensureMaxTwoPercentPerWallet(uint256 _amount, address from, address to) internal view returns (bool) {
        bool ensured = false;
        uint256 amountToCheck;

        if (_isExcludedFromLimit[_msgSender()] || _isExcludedFromLimit[to] || _isExcludedFromLimit[from] || to == address(0)) {
            ensured = true;
        } else {
            amountToCheck = balanceOf(to) > 0 ? balanceOf(to).add(_amount) : _amount;
            ensured = amountToCheck < (totalSupply().mul(whaleAmount)).div(100);
        }

        return ensured;
    }
}