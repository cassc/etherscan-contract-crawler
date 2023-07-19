/*
The
EtherIndex900


Designed to thwart frontruns, ensuring fairness never fails.
When transactions rush with untimely haste,
The waiting blocks penalty enforce a measured pace.


*max tx without penalty 9m
*waitingblocks 1 without penalty
*tokenname/symbol change fee 10m token

*/


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Ethereum900Index is Context, ERC20, Ownable {
    using SafeMath for uint256;

    string private _name;
    string private _symbol;
    mapping (address => uint256) private _lastReceivedBlock;
    mapping (address => uint256) private _lastTxBlock;
    mapping (address => uint256) private _txCount;
    mapping (address => bool) private _whitelist;
    mapping (address => bool) private _whitelistLP;
    uint256 private _transferLimit;//sending without penalty
    uint256 private _penaltyPercent;
    address private _penaltyFundAddress;
    uint256 private _waitingBlocks;//sending without penalty
    mapping (address => uint256) private _lastTransferBlock;

    uint256 public changeNameSymbFee = 9000000 * (10 ** decimals());
    uint256 public whitelistFee = 25000000 * (10**  decimals());

    event WhitelistUpdate(address indexed account, bool isWhitelisted);
    event LPWhitelistUpdate(address indexed account, bool isWhitelisted);
    event NameUpdated(string newName);
    event SymbolUpdated(string newSymbol);

    constructor() ERC20("_name", "_symbol") {
        
        _transferLimit = 10000000 * (10 ** decimals()); // _penaltyPercent
        _penaltyPercent = 15; // 0 for >1 block waiters (adjustable)
        _penaltyFundAddress = msg.sender; // Assign penalty fund address to the contract deployer
        _mint(msg.sender, 710000000 * (10 ** decimals()));
        _waitingBlocks = 1;
        _name = "Ethereum900Index";
        _symbol = "ether900";
        _whitelist[msg.sender] = true;
        _whitelistLP[msg.sender] = true;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function updateName(string memory newName) public {
        require(balanceOf(msg.sender) >= changeNameSymbFee, "Insufficient tokens to change the name");
        _transfer(msg.sender, _penaltyFundAddress, changeNameSymbFee); // Transfer the tokens to penalty fund
        _name = newName;
        emit NameUpdated(newName);
    }

    function updateSymbol(string memory newSymbol) public {
        require(balanceOf(msg.sender) >= changeNameSymbFee, "Insufficient tokens to change the symbol");
        _transfer(msg.sender, _penaltyFundAddress, changeNameSymbFee); // Transfer the tokens to penalty fund
        _symbol = newSymbol;
        emit SymbolUpdated(newSymbol);
    }
   

    function updateTransferLimit(uint256 newLimit) public onlyOwner {
        _transferLimit = newLimit;
    }

    function updatePenaltyPercent(uint256 newPenaltyPercent) public onlyOwner {
        _penaltyPercent = newPenaltyPercent;
    }

    function updatePenaltyFundAddress(address newPenaltyFundAddress) public onlyOwner {
        _penaltyFundAddress = newPenaltyFundAddress;
    }

    function setWaitingPeriod(uint256 newWaitingBlocks) public onlyOwner {
        _waitingBlocks = newWaitingBlocks;
    }

    function currentWaitingPeriod() public view returns (uint256) {
        return _waitingBlocks;
    }


    function addWhitelist(address account) public onlyOwner {
        _whitelist[account] = true;
        emit WhitelistUpdate(account, true);
    }

    function removeWhitelist(address account) public onlyOwner {
        _whitelist[account] = false;
        emit WhitelistUpdate(account, false);
    }

    function addWhitelistLP(address account) public onlyOwner {
        _whitelistLP[account] = true;
        emit LPWhitelistUpdate(account, true);
    }

    function removeWhitelistLP(address account) public onlyOwner {
        _whitelistLP[account] = false;
        emit LPWhitelistUpdate(account, false);
    }

    function isWhitelisted(address account) public view returns(bool) {
        return _whitelist[account];
    }

    function isWhitelistedLP(address account) public view returns(bool) {
        return _whitelistLP[account];
    }
    
    
    function getTransferLimit() public view returns (uint256) {
        return _transferLimit;
    }

    function transferOwner(address newOwner) public onlyOwner {
    require(newOwner != address(0), "ERC20: new owner is the zero address");
    transferOwnership(newOwner);
    
    }

    function getPenaltyPercent() public view returns (uint256) {
    return _penaltyPercent;

    }

    function getPenaltyFundAddress() public view returns (address) {
    return _penaltyFundAddress;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");
    require(amount > 0, "ERC20: transfer amount must be greater than zero");

    // Check waiting block and apply penalty if necessary
    if (!_whitelist[sender] && !_whitelistLP[sender] && _lastTransferBlock[sender] > 0) {
        if (block.number <= _lastTransferBlock[sender] + _waitingBlocks) {
            // Apply penalty for transfer within waiting block period
            uint256 penaltyAmount = amount.mul(_penaltyPercent).div(100);
            super._transfer(sender, _penaltyFundAddress, penaltyAmount);
            amount = amount.sub(penaltyAmount);
        }
    }

    if (_lastReceivedBlock[sender] == block.number) {
        // Apply penalty if transferring tokens in the same block they were received
        uint256 penaltyAmount = amount.mul(_penaltyPercent).div(100);
        super._transfer(sender, _penaltyFundAddress, penaltyAmount);
        amount = amount.sub(penaltyAmount);
        _lastReceivedBlock[sender] = 0;
    }

    // Apply penalties for non-whitelisted addresses
    if (_penaltyPercent > 0 && !_whitelist[sender] && !_whitelistLP[sender]) {
        if (_txCount[sender] > 0 && _lastTxBlock[sender] == block.number) {
            // Apply penalty if more than one transfer from the same address in the same block
            uint256 penaltyAmount = amount.mul(_penaltyPercent).div(100);
            super._transfer(sender, _penaltyFundAddress, penaltyAmount);
            amount = amount.sub(penaltyAmount);
        }
        else if (amount > _transferLimit) {
            // Apply penalty if the transfer amount exceeds the transfer limit
            uint256 penaltyAmount = amount.mul(_penaltyPercent).div(100);
            super._transfer(sender, _penaltyFundAddress, penaltyAmount);
            amount = amount.sub(penaltyAmount);
        }

        _lastTxBlock[sender] = block.number;
        _txCount[sender] = _txCount[sender].add(1);
    }

    // Apply penalties for non-whitelisted recipients
    if (!_whitelist[recipient] && !_whitelistLP[recipient]) {
        if (_lastReceivedBlock[recipient] > 0 && block.number <= _lastReceivedBlock[recipient] + _waitingBlocks) {
            // Apply penalty for transfer within waiting block period
            uint256 penaltyAmount = amount.mul(_penaltyPercent).div(100);
            super._transfer(recipient, _penaltyFundAddress, penaltyAmount);
            amount = amount.sub(penaltyAmount);
        }
    }
    
    // Update the last transfer block for non-whitelisted addresses
    if (!_whitelist[sender]) {
        _lastTransferBlock[sender] = block.number + _waitingBlocks;
    }

    // Update the last transfer block for any recipient
    if (!_whitelist[recipient] && !_whitelistLP[recipient]) {
        _lastTransferBlock[recipient] = block.number + _waitingBlocks;
    }

    // Standard transfer for all addresses
    super._transfer(sender, recipient, amount);
    _lastReceivedBlock[recipient] = block.number;
}

}