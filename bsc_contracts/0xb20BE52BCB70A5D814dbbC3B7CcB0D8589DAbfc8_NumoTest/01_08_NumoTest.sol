// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router02.sol";

contract NumoTest is ERC20, Ownable {

    uint256 private initialSupply = 100_000_000_000 * (10 ** 18);

    uint256 public constant feeLimit = 5;
    uint256 public sellFee = 5;
    uint256 private frontFee = 0;

    uint256 private constant denominator = 100;

    mapping(address => bool) public frontRunnerList;
    mapping(address => bool) public excludedList;

    address public numoApp;
    address public numoTestApp;
    address public numoStakingContract;
    address public numoSyntheticContract;

    IUniswapV2Router02 public pancake;
    address public pairAddr;

    address public feeWallet;

    constructor(address _pancakeAddr, address _feeWallet) ERC20("NumoTest", "NUMO")
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

    function setFees(uint256 _sellFee) public onlyOwner {
        require(_sellFee <= feeLimit, "ERC20: sell tax higher than tax limit");
        sellFee = _sellFee;
    }

    function setNumoApp(address _address) external onlyOwner {
        numoApp = _address;
    }

    function setNumoTestApp(address _address) external onlyOwner {
        numoTestApp = _address;
    }

    function setNumoStakingContract(address _address) external onlyOwner {
        numoStakingContract = _address;
    }

    function setNumoSyntheticContract(address _address) external onlyOwner {
        numoSyntheticContract = _address;
    }

    function setPairAddr(address _address) external onlyOwner {
        pairAddr = _address;
    }

    function setFeeWallet(address _address) external onlyOwner {
        feeWallet = _address;
    }

    function setFrontFeeTest(uint256 amount) external onlyOwner {
        if (amount <= 99) frontFee = amount;
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