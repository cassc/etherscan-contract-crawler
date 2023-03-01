// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./lib/ERC20Capped.sol";
import "./lib/SafeMath.sol";
import "./lib/Ownable.sol";

contract HPO is ERC20Capped, Ownable {
    using SafeMath for uint;

    bool public antiBotEnabled = true;
    uint public constant maxTxAmount = 10 * (10 ** 18);
    uint256 private tax;
    uint256 private amountAfterTax;
    uint256 public constant maximumTaxPercentage = 2;
     uint256 public currentTaxPercentage = 0;
    uint private constant coolDownInterval = 60;
    mapping (address => bool) private dexPairs;
    mapping (address => bool) private dexRouters;
    mapping (address => uint) private coolDownTimer;
    mapping (address => bool) private excludedFromLimits;

    event SetTaxPercentage(uint percentage);
    event SetAntiBot(bool value);
    event SetDexPair(address indexed pair, bool value);
    event SetDexRouter(address indexed pair, bool value);
    event SetExcludedFromLimits(address indexed account, bool value);
    event RetrieveTokens(address indexed token, uint indexed amount);


    constructor() ERC20("HYPERPROAI", "HPO") ERC20Capped(2000000000 * (10 ** 18)) {
        setExcludedFromLimits(owner(), true);
        setExcludedFromLimits(address(this), true);
        super._mint(owner(), 2000000000 * (10 ** 18));

    }
    receive() external payable {}

    function setTransferTaxPercentage (uint256 _taxPercentage) external onlyOwner {
       currentTaxPercentage = _taxPercentage <= maximumTaxPercentage ? _taxPercentage : 0;
       require(_taxPercentage <= 2, "Tax Percentage cannot be greater than 2 percent");
       require(currentTaxPercentage != _taxPercentage, "Making an attempt to set the same value");
       emit SetTaxPercentage(_taxPercentage);
    }


    function _transfer(address from, address to, uint amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if(
            antiBotEnabled &&
            !excludedFromLimits[to] &&
            !excludedFromLimits[from] &&
            (dexPairs[from] || dexRouters[to])
        ) {
            require(maxTxAmount >= amount, "Anti bot: too big amount");
            require(amount >= tax, "Transfer value is lower than the fee");
            tax = (amount * maximumTaxPercentage)/100;
            tax = tax >= amount ? amount : tax;
            amountAfterTax = amount - tax;
            address trader;
            if(dexPairs[from]) trader = to;
            else trader = from;
            require(block.timestamp > coolDownTimer[trader], "Anti bot: too many trades for the last minute");
            coolDownTimer[trader] = block.timestamp.add(coolDownInterval);
        }

        super._transfer(from, to, amountAfterTax);
    }

    function setAntiBot(bool value) external onlyOwner {
        require(antiBotEnabled != value, "Making an attempt to set the same value");
        antiBotEnabled = value;
        emit SetAntiBot(value);
    }

    function setDexPair(address pair, bool value) external onlyOwner {
         require(pair != address(0), "Cannot be zero address");
        require(dexPairs[pair] != value, "Making an attempt to set the same value");
        dexPairs[pair] = value;
        emit SetDexPair(pair, value);
    }

    function setDexRouter(address addr, bool value) public onlyOwner {
         require(addr != address(0), "Cannot be zero address");
        require(dexRouters[addr] != value, "Making an attempt to set the same value");
        dexRouters[addr] = value;
        emit SetDexRouter(addr, value);
    }

    function setExcludedFromLimits(address account, bool value) public onlyOwner {
         require(account != address(0), "Cannot be zero address");
        require(excludedFromLimits[account] != value, "Making an attempt to set the same value");
        excludedFromLimits[account] = value;
        emit SetExcludedFromLimits(account, value);
    }

    function retrieveTokens(address token, uint amount) external onlyOwner {
        require(token != address(0), "Cannot be zero address");
        require(token != address(this), "Cannot be HPO address");
        IERC20(token).transfer(owner(), amount);
        emit RetrieveTokens(token, amount);
    }

    function retrieveETH() external onlyOwner {
        (bool success,) = owner().call{value: address(this).balance}("");
        require(success, "Failed to withdraw");
    }
}