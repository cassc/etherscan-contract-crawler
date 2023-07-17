// Hearken, weary souls, and heed the tale of the Hourglass, a mystic contract wrought upon Ethereum's realm by the creator of the REAPER'S GAMBIT, where $RG tokens dwell. 
// In this somber domain, mortals may submit their tokens, a minimum of 300,000, as tribute to the contract's dark embrace.
// In exchange, a shadowy reduction doth consume the tokens, ere long, and bestow upon the depositor a fleeting taste of immortality, granting a brief reprieve from the Reaper's cold grasp.
// Should one's deposit, combined with the tokens already ensnared, exceed a third of the total tokens entrapped, the reduction shall be halved, thus lessening the merciless toll exacted by the contract's malevolent grasp. 
// Upon withdrawal, one may select any address they desire, a final act of defiance in the face of Death.

// The tokens, once offered, are shackled and bound for 4800 blocks, unable to flee the grasp of this unholy contract. 
// As the lock is lifted, these captive tokens may be withdrawn, though not without a price, 0.09% for every 2400 block cycles. 
// The reduction, cruel as fate itself, shall be cast upon them, leaving but a fraction to return to the mortal world.

// Behold the Reduction Pool, a forsaken pit that gathers the tokens consumed by the merciless reduction. 
// To empty this accursed pool, one must possess 30 times the pool's dark bounty in their balance, and still have tokens in the hourglass. 
// Then, two-thirds shall be cast into the abyss, forever lost to the dead, whilst the remaining third shall find its way to a chosen destination.

// In the gloom of this contract, queries may be whispered, revealing the secrets of one's deposit, the foreboding reduction pool, 
// and the wretched souls who dare to partake in this unhallowed pact. 
// Thus, the Hourglass sinister workings are laid bare, a testament to the inescapable reduction and the inevitability of fate.
//
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Hourglass {
    struct DepositInfo {
        uint256 amount;
        uint256 blockNumber;
        uint256 reductionPercentage;
    }

    mapping(address => DepositInfo) private _deposits;

    IERC20 private _token;

    uint256 private _totalDeposits;
    mapping(uint256 => address) private _depositers;
    mapping(address => uint256) private _depositerIndex;
    uint256 private _totalDepositedAmount;
    uint256 private _reductionPool;

    constructor(IERC20 token) {
        require(address(token) == 0x2C91D908E9fab2dD2441532a04182d791e590f2d, "Invalid token address");
        _token = token;
    }

    modifier onlyDepositor() {
        require(_deposits[msg.sender].amount > 0, "Not a depositor");
        _;
    }

    function deposit(uint256 amount) external {
        require(amount >= 300000 * 1e18, "Minimum deposit is 300,000 tokens");
        require(_token.allowance(msg.sender, address(this)) >= amount, "Allowance not sufficient");

        DepositInfo storage depositInfo = _deposits[msg.sender];
        uint256 previousDeposit = depositInfo.amount;

        depositInfo.amount += amount;
        depositInfo.blockNumber = block.number;

        uint256 reductionPercentage = 9e14;
        if ((depositInfo.amount + amount) > _totalDepositedAmount / 3) {
            reductionPercentage /= 2;
        }
        depositInfo.reductionPercentage = reductionPercentage;

        if (previousDeposit == 0) {
            _totalDeposits += 1;
            _depositers[_totalDeposits] = msg.sender;
            _depositerIndex[msg.sender] = _totalDeposits;
        }

        _totalDepositedAmount += amount;
        _token.transferFrom(msg.sender, address(this), amount);
    }

    function withdrawTo(address recipient) external onlyDepositor {
        require(block.number - _deposits[msg.sender].blockNumber >= 4800, "Tokens are locked");

        uint256 blocksSinceDeposit = block.number - _deposits[msg.sender].blockNumber;
        uint256 reductionCycles = blocksSinceDeposit / 2400;

        uint256 reduction = (_deposits[msg.sender].amount * _deposits[msg.sender].reductionPercentage * reductionCycles) / 1e18;
        _reductionPool += reduction;
        uint256 withdrawAmount = _deposits[msg.sender].amount - reduction;

        _token.transfer(recipient, withdrawAmount);
        
        _totalDepositedAmount -= _deposits[msg.sender].amount;
        uint256 removedIndex = _depositerIndex[msg.sender];
        if (removedIndex < _totalDeposits) {
            address lastDepositer = _depositers[_totalDeposits];
            _depositers[removedIndex] = lastDepositer;
            _depositerIndex[lastDepositer] = removedIndex;
        }
        delete _depositers[_totalDeposits];
        delete _depositerIndex[msg.sender];
        delete _deposits[msg.sender];
        _totalDeposits -= 1;
    }

    function emptyReductionPool(address specifiedAddress) external onlyDepositor {
    require(_reductionPool > 0, "Reduction pool is empty, cannot empty pool");
    require(_token.balanceOf(msg.sender) >= _reductionPool * 30, "Insufficient token balance to empty pool");

    uint256 oneThird = _reductionPool / 3;
    uint256 twoThird = oneThird * 2;

    _token.transfer(address(0x000000000000000000000000000000000000dEaD), twoThird);
    _token.transfer(specifiedAddress, oneThird);

    _reductionPool = 0;
}

    function getDepositInfo(address depositor) external view returns (uint256 amount, uint256 blockNumber, uint256 reductionPercentage) {
        DepositInfo memory depositInfo = _deposits[depositor];
        return (depositInfo.amount, depositInfo.blockNumber, depositInfo.reductionPercentage);
    }

    function getReductionPool() external view returns (uint256) {
        return _reductionPool;
    }

    function getHourglassInfo() external view returns (address[] memory depositors, uint256 numberOfDepositors, uint256 totalDeposited) {
    depositors = new address[](_totalDeposits);
    for (uint256 i = 1; i <= _totalDeposits; i++) {
        depositors[i - 1] = _depositers[i];
    }
    numberOfDepositors = _totalDeposits;
    totalDeposited = _totalDepositedAmount;
    return (depositors, numberOfDepositors, totalDeposited);
    }
}