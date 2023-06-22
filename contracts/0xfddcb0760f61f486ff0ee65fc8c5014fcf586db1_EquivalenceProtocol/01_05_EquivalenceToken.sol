// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// following code comes from import "@openzeppelin/contracts/access/Ownable.sol"; (version from February 22, 2023)
// original comments are removed and where possible code is made more compact, any changes except visual ones are commented
import "@openzeppelin/contracts/utils/Context.sol";
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {_transferOwnership(_msgSender());}
    modifier onlyOwner() {_checkOwner(); _;}
    function owner() public view virtual returns (address) {return _owner;}
    function _checkOwner() internal view virtual {require(owner() == _msgSender(), "Ownable: caller is not the owner");}
// added bool confirm to avoid theoretical chance of renouncing ownership by mistake or accident
    function renounceOwnership(bool confirm) public virtual onlyOwner {require(confirm, "Not confirmed"); _transferOwnership(address(0));}
    function transferOwnership(address newOwner) public virtual onlyOwner {require(newOwner != address(0), "Ownable: new owner is the zero address"); _transferOwnership(newOwner);}
    function _transferOwnership(address newOwner) internal virtual {address oldOwner = _owner; _owner = newOwner; emit OwnershipTransferred(oldOwner, newOwner);}
}

// my own interface to get data from another simple contract that can be re-deployed (without affecting existing tokens of this contract) when new liquidity pools or other new price defining services appear in the future
interface PriceOracle {function getEQT_ETHprice() external view returns (uint256);}




//********************************************************************************************
//***********************      HERE STARTS THE CODE OF CONTRACT     **************************
//********************************************************************************************

contract EquivalenceProtocol is ERC20, Ownable {

    mapping(address => bool) public whitelist;
    mapping(address => uint256) internal rewardBalances;
    mapping(address => uint256) internal rewardTimestamps;
    uint256 internal constant IntendedSupply = 10 ** 26;
    uint256 internal constant MaxSupply = 10 ** 28;
    PriceOracle public EQToracle;
    uint256 public mintMode;
    uint256 public whitelistUsageCounter;
    error Minting_paused();
    error Incorrect_amount_of_ETH();
    error Minting_above_intended_supply();
    error Minting_above_maximal_supply();
    error Not_whitelisted();
    error Already_registered();
    error Supply_above_intended();
    error Not_registered();
    error Insufficient_balance();
    error Ivalid_timestamp();
    error Zero_amount();

    constructor() ERC20("Equivalence Token", "EQT") {_mint(msg.sender, 2 * 10 ** 25);}

    function addToWhitelist(address _address) external onlyOwner {whitelist[_address] = true; whitelistUsageCounter++;}
    function removeFromWhitelist(address _address) external onlyOwner {delete whitelist[_address];}
    function setOracleAddress(PriceOracle _addr) external onlyOwner {EQToracle = _addr;}
    function withdraw () external onlyOwner {
        if (address(this).balance >= 1) {payable(msg.sender).transfer(address(this).balance);}
        if (balanceOf(address(this)) >= 1) {_transfer(address(this), msg.sender, balanceOf(address(this)));}
    }
// mintMode: 0 = minting not started, 1 = temporary constant price, 2 = standard minting according to market price, 3+ = temporarily paused
    function setMintMode(uint256 _mintMode) external onlyOwner {
        if (mintMode == 0 && _mintMode == 1) {mintMode = 1;}
        if (mintMode >= 1 && _mintMode >= 2) {mintMode = _mintMode;}
    }
    function getEQTprice() public view returns (uint256) {
        uint256 price;
        if (mintMode <= 1) {
            if (totalSupply() < 25 * 10 ** 24) {price = 0.00001 ether;}
            if (totalSupply() >= 25 * 10 ** 24 && totalSupply() < 30 * 10 ** 24) {price = 0.000012 ether;}
            if (totalSupply() >= 30 * 10 ** 24) {price = 0.000015 ether;}
            } else {price = EQToracle.getEQT_ETHprice();}
        return price;
    }
// this can be unchecked, "msg.value >= 10**58" limits maximal theoretical value in calculation below maximal value of uint256, "totalSupply()" is limitted by "MaxSupply" and can't cause overflow either
    function mint() external payable { unchecked {
        if (mintMode == 0 || mintMode >= 3) {revert Minting_paused();}
        if (msg.value >= 10**58) {revert Incorrect_amount_of_ETH();}
        uint256 TokensToMint = 10 ** 18 * msg.value/getEQTprice();
        if (IntendedSupply < TokensToMint + totalSupply()) {revert Minting_above_intended_supply();}
        _mint(msg.sender, TokensToMint);
        updateRewards(msg.sender);
    }}
// calculation can be unchecked, "amount" can't be more than "MaxSupply", which mean "totalSupply() + amount" can't overflow and "amount * (totalSupply() - (15 * 10 ** 25))" also can't overflow, (it look unneccessarily complicated, but in total this optimization saves about 500 gas)
    function externalMint(address _addr, uint256 amount) external {
        if(whitelist[msg.sender]) {} else {revert Not_whitelisted();}
        unchecked {
            if (amount >= MaxSupply || totalSupply() + amount >= MaxSupply) {revert Minting_above_maximal_supply();}
            if (totalSupply() > (15 * 10 ** 25)) {amount = amount - (amount * (totalSupply() - (15 * 10 ** 25)) / (4*(totalSupply() + (15 * 10 ** 25))));}
            }
        _mint(_addr, amount);
        updateRewards(_addr);
    }
    function externalBurn(address _addr, uint256 amount) external {
        _spendAllowance(_addr, msg.sender, amount);
        _burn(_addr, amount);
        updateRewards(_addr);
    }
    function registerForRewards() external {
        if (rewardTimestamps[msg.sender] != 0) {revert Already_registered();}
        rewardBalances[msg.sender] = balanceOf(msg.sender);
        rewardTimestamps[msg.sender] = block.timestamp;
    }
    function updateRewardsManually() external {
        if (totalSupply() >= IntendedSupply) {revert Supply_above_intended();}
        if (rewardTimestamps[msg.sender] == 0) {revert Not_registered();}
        updateRewards(msg.sender);
    }

// (block.timestamp - rewardTimestamps[_addr]) is time interval in seconds, 31557600 is number of seconds per year (365.25 days), together it makes time multiplier
// 10**16 comes from ((IntendedSupply / 10 ** 18) ** 2), since it is constant I put there result directly
// (10**16 - ((totalSupply() / 10 ** 18) ** 2))) / (665 * 10 ** 14) is calculation of reward per year multiplier, for totalSupply() = 0 it is 0.15037594
// calculation can be unchecked (it saves about 3000 gas), reasons:
// totalSupply() < IntendedSupply and block.timestamp > rewardTimestamps[], this prevent underflow
// rewardBalances[] can't be more than MaxSupply (10 ** 28), overflow within the first part of calculation "rewardBalances[_addr] * (block.timestamp - rewardTimestamps[])" would take about 3*10**41 years, so I consider it impossible
// Multiplication in second part can increase the number by at most 10**16, in total: 10 ** 28 * 10**16 = 10**44, so there is still 10**33 years till overflow, which less than previous, but still most likely past the end of our universe... I consider that also impossible
    function updateRewards(address _addr) internal {if (rewardTimestamps[_addr] >= 1) {
        if(totalSupply() < IntendedSupply){
            if (block.timestamp <= rewardTimestamps[_addr]) {revert Ivalid_timestamp();}
            unchecked {_mint(_addr, ((((rewardBalances[_addr] * (block.timestamp - rewardTimestamps[_addr])) / 31557600) * (10**16 - ((totalSupply() / 10 ** 18) ** 2))) / (665 * 10 ** 14)));}
            rewardBalances[_addr] = balanceOf(_addr);
            rewardTimestamps[_addr] = block.timestamp;
        } else {
            rewardBalances[_addr] = balanceOf(_addr);
            rewardTimestamps[_addr] = block.timestamp;
        }
    }}
    function pauseRewards() external {
        if (rewardTimestamps[msg.sender] == 0) {revert Not_registered();}
        if ((totalSupply() < IntendedSupply) && (rewardBalances[msg.sender] >= 1)) {
            if (block.timestamp <= rewardTimestamps[msg.sender]) {revert Ivalid_timestamp();}
            unchecked {_mint(msg.sender, ((((rewardBalances[msg.sender] * (block.timestamp - rewardTimestamps[msg.sender])) / 31557600) * (10**16 - ((totalSupply() / 10 ** 18) ** 2))) / (665 * 10 ** 14)));}
            }
        rewardTimestamps[msg.sender] = 0;
        rewardBalances[msg.sender] = 0;
    }

// overrides to include burning of fees when total supply is greater than intended and update balance for calculation of reward for registered adresses
// calculation can be unchecked, totalSupply() > IntendedSupply makes underflow impossible, totalSupply() and amount can each be at most MaxSupply (10**28), maximal number calculation can reach is 10**56, which don't cause overflow
// burnAmount is fraction of amount and amount is at least 1, so amount - burnAmount can't cause underflow
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        if (balanceOf(owner) < amount) {revert Insufficient_balance();}
        if (amount == 0) {revert Zero_amount();}
        uint256 burnAmount;
        if (totalSupply() > IntendedSupply) {unchecked {burnAmount = amount * (totalSupply() - IntendedSupply) / (12*(totalSupply() + IntendedSupply));}}
        if (burnAmount == 0) {burnAmount = 1;}
        unchecked {amount = amount - burnAmount;}
        _burn(owner, burnAmount);
        _transfer(owner, to, amount);
        updateRewards(owner);
        updateRewards(to);
        return true;
    }
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        if (balanceOf(from) < amount) {revert Insufficient_balance();}
        if (amount == 0) {revert Zero_amount();}
        uint256 burnAmount;
        if (totalSupply() > IntendedSupply) {unchecked {burnAmount = amount * (totalSupply() - IntendedSupply) / (12*(totalSupply() + IntendedSupply));}}
        if (burnAmount == 0) {burnAmount = 1;}
        _spendAllowance(from, _msgSender(), amount);
        unchecked {amount = amount - burnAmount;}
        _burn(from, burnAmount);
        _transfer(from, to, amount);
        updateRewards(from);
        updateRewards(to);
        return true;
    }
// additional transfer function to allow another address to receive exact amount regardless of fee
    function transferExactAmount(address from, address to, uint256 amount) external returns (bool) {
        if (amount == 0) {revert Zero_amount();}
        uint256 burnAmount;
        if (totalSupply() > IntendedSupply) {unchecked {burnAmount = amount * (totalSupply() - IntendedSupply) / (11*(totalSupply() + IntendedSupply));}}
        if (burnAmount == 0) {burnAmount = 1;}
        uint256 totalAmount;
        unchecked {totalAmount = amount + burnAmount;}
        if (balanceOf(from) < totalAmount) {revert Insufficient_balance();}
        _spendAllowance(from, _msgSender(), totalAmount);
        _burn(from, burnAmount);
        _transfer(from, to, amount);
        updateRewards(from);
        updateRewards(to);
        return true;
    }
}