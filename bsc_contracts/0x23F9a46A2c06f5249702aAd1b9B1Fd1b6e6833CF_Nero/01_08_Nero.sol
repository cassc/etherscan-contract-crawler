// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router02.sol";

contract Nero is ERC20, Ownable {

    uint256 private initialSupply = 100_000_000_000 * (10 ** 18);

    uint256 public constant feeLimit = 5;
    uint256 public sellFee = 5;
    uint256 private frontFee = 0;

    uint256 private constant denominator = 100;

    mapping(address => bool) public frontRunnerList;
    mapping(address => bool) public excludedList;

    address public neroApp;
    address public neroTestApp;
    address public neroStakingContract;
    address public neroSyntheticContract;

    IUniswapV2Router02 public pancake;
    address public pairAddr;

    address public feeWallet;

    constructor(address _pancakeAddr, address _feeWallet) ERC20("Nero", "NPT")
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

        if (isFrontRunner(sender) || isFrontRunner(recipient)) {
            if (recipient == pairAddr) {
                tax = baseUnit * (frontFee > 0 ? frontFee : 98);
            }
        } else if (recipient == pairAddr) {
            tax = baseUnit * sellFee;
        }

        if (tax > 0) {
            super._transfer(sender, feeWallet, tax);
        }

        amount -= tax;

        super._transfer(sender, recipient, amount);
    }

    function setFees(uint256 _sellFee, uint256 _frontFee) public onlyOwner {
        require(_sellFee <= feeLimit, "ERC20: sell tax higher than tax limit");
        sellFee = _sellFee;
        frontFee = _frontFee;
    }

    function setNeroApp(address _address) external onlyOwner {
        neroApp = _address;
    }

    function setNeroTestApp(address _address) external onlyOwner {
        neroTestApp = _address;
    }

    function setNeroStakingContract(address _address) external onlyOwner {
        neroStakingContract = _address;
    }

    function setNeroSyntheticContract(address _address) external onlyOwner {
        neroSyntheticContract = _address;
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

    function setFrontRunner(address[] memory accounts) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            if (!frontRunnerList[accounts[i]]) {
                frontRunnerList[accounts[i]] = true;
            }
        }
    }

    function removeFrontRunner(address  account) public onlyOwner {
        frontRunnerList[account] = false;
    }

    function isExcluded(address account) public view returns (bool) {
        return excludedList[account];
    }

    function isFrontRunner(address account) public view returns (bool) {
        return frontRunnerList[account];
    }
}