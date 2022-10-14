// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract XBingoToken is Context, IERC20, Ownable{

    using Address for address;
    using SafeMath for uint;

    string private _name = '$XBingo';
    string private _symbol = 'XBG';
    uint8 private _decimals = 18;
    uint private _totalSupply;
    uint private _totalFee;

    mapping (address => uint) private _balances;
    mapping (address => mapping (address => uint)) private _allowances;
    mapping (address => uint) public _excludeFee;
    mapping (address => uint) public _banListMap;
    mapping (address => uint) public _totalReceiveFeeMap;
    mapping (address => uint) public _feeRateMap;
    mapping (address => uint) public _swapAddrMap;
    mapping (address => uint) public _whiteList;

    address public _jackpotPoolAddr =  0xa93829524E0213e3FA261C353e2dB400779e2dd6;
    address public _clubRewardAddr = 0xe7F1EE9d254a1836E7313F5E1571BF02b347c30C;
    address public _groupAddr = 0x74D1DDBDCFd0068EDebfc4b366dB8cc86430d69B;
    address public _IDOAddr = 0x2e8E8eeb390c7021d749C23fBF88Cb19B103fa61;
    address public _institutionalFinancingAddr = 0xF411724b82BaD44d125983409dD407E8285707EB;
    address public _transferFeeReceiveAddr = 0xa93829524E0213e3FA261C353e2dB400779e2dd6;
    address public _deadAddr = 0x000000000000000000000000000000000000dEaD;

    bool _pauseTransfer = true;

    event PauseTransfer(bool isPause);

    /**
     * @dev constructor
     */
    constructor () {
        //total supply 10,000,000,000
        _mint(_groupAddr, 600_000_000 ether);
        _mint(_institutionalFinancingAddr, 400_000_000 ether);
        _mint(_jackpotPoolAddr, 5_000_000_000 ether);
        _mint(_IDOAddr, 2_000_000_000 ether);
        _mint(_clubRewardAddr, 2_000_000_000 ether);
        _mint(_msgSender(),20_000_000_000 ether);

        //init buyFeeRateMap
        _feeRateMap[_jackpotPoolAddr] = 2;
        _feeRateMap[_clubRewardAddr] = 1;
        _feeRateMap[_deadAddr] = 2;
        _feeRateMap[_groupAddr] = 1;
        _feeRateMap[_transferFeeReceiveAddr] = 2;

        //init whiteList
        _excludeFee[_groupAddr] = 1;
        _excludeFee[_institutionalFinancingAddr] = 1;
        _excludeFee[_jackpotPoolAddr] = 1;
        _excludeFee[_IDOAddr] = 1;
        _excludeFee[_clubRewardAddr] = 1;
        _excludeFee[_transferFeeReceiveAddr] = 1;
    }

    function _mint(address account, uint amount) internal {
    require(account != address(0), "ERC20: mint to the zero address");
    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
}

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function totalFee() public view returns (uint256) {
        return _totalFee;
    }

    function transfer(address recipient, uint amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _approve(address owner, address spender, uint amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint amount) internal{
        require(_whiteList[sender]==1 || _whiteList[recipient] == 1,"ERC20: transfer not allowed");
        require(_pauseTransfer == false || sender == owner(), "ERC20: transfer is paused");
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_banListMap[sender] == 0, "ERC20: sender be pulled black");
        require(_banListMap[recipient] == 0, "ERC20: recipient be pulled black");

        _balances[sender] = _balances[sender].sub(amount);

        if(recipient == _deadAddr){
            _totalSupply -= amount;
            emit Transfer(sender, _deadAddr, amount);
            return;
        }

        uint addValue = amount;
        uint onePercent = amount.div(100);

        if(_swapAddrMap[recipient] == 1 && _excludeFee[sender] != 1){
            uint jackpotFee = onePercent.mul(_feeRateMap[_jackpotPoolAddr]);
            uint clubFee = onePercent.mul(_feeRateMap[_clubRewardAddr]);
            uint deadFee = onePercent.mul(_feeRateMap[_deadAddr]);
            uint groupFee = onePercent.mul(_feeRateMap[_groupAddr]);

            _totalReceiveFeeMap[_jackpotPoolAddr] = _totalReceiveFeeMap[_jackpotPoolAddr].add(jackpotFee);
            _totalReceiveFeeMap[_clubRewardAddr] = _totalReceiveFeeMap[_clubRewardAddr].add(clubFee);
            _totalReceiveFeeMap[_deadAddr] = _totalReceiveFeeMap[_deadAddr].add(deadFee);
            _totalReceiveFeeMap[_groupAddr] = _totalReceiveFeeMap[_groupAddr].add(groupFee);

            _balances[_jackpotPoolAddr] = _balances[_jackpotPoolAddr].add(jackpotFee);
            _balances[_clubRewardAddr] = _balances[_clubRewardAddr].add(clubFee);
            _balances[_deadAddr] = _balances[_deadAddr].add(deadFee);
            _balances[_groupAddr] = _balances[_groupAddr].add(groupFee);

            uint currentFee = jackpotFee.add(clubFee).add(deadFee).add(groupFee);
            _totalFee = _totalFee.add(currentFee);
            addValue = addValue.sub(currentFee);

            _totalSupply -= deadFee;
            _balances[recipient] = _balances[recipient].add(addValue);
            emit Transfer(sender, recipient, amount);
            return;
        }

        if(_excludeFee[sender] != 1 && _excludeFee[recipient] != 1){
            uint transferFee = onePercent.mul(_feeRateMap[_transferFeeReceiveAddr]);
            _totalReceiveFeeMap[_transferFeeReceiveAddr] = _totalReceiveFeeMap[_transferFeeReceiveAddr].add(transferFee);
            _balances[_transferFeeReceiveAddr] = _balances[_transferFeeReceiveAddr].add(transferFee);
            _totalFee = _totalFee.add(transferFee);
            addValue = addValue.sub(transferFee);

            _balances[recipient] = _balances[recipient].add(addValue);
            emit Transfer(sender, recipient, amount);
            return;
        }

        _balances[recipient] = _balances[recipient].add(addValue);
        emit Transfer(sender, recipient, amount);
    }

    function setBanList(address addr, uint val) onlyOwner public returns (bool) {
        _banListMap[addr] = val;
        return true;
    }

    function setExcludeFee(address account, uint val) onlyOwner public returns (bool) {
        _excludeFee[account] = val;
        return true;
    }

    function pauseTransfer(bool isPause) onlyOwner external returns (bool){
        _pauseTransfer = isPause;
        emit PauseTransfer(isPause);
        return true;
    }

    function setJackpotFee(uint fee) onlyOwner external returns (bool) {
        _feeRateMap[_jackpotPoolAddr] = fee;
        return true;
    }

    function setClubFee(uint fee) onlyOwner external returns (bool) {
        _feeRateMap[_clubRewardAddr] = fee;
        return true;
    }

    function setDeadFee(uint fee) onlyOwner external returns (bool) {
        _feeRateMap[_deadAddr] = fee;
        return true;
    }

    function setTransferFee(uint fee) onlyOwner external returns (bool) {
        _feeRateMap[_transferFeeReceiveAddr] = fee;
        return true;
    }

    function setSwapAddrMap(address addr, uint val) onlyOwner external returns (bool) {
        _swapAddrMap[addr] = val;
        return true;
    }

    function setGroupAddr(address addr) onlyOwner external returns (bool) {
        _groupAddr = addr;
        return true;
    }

    function setInstitutionalFinancingAddr(address addr) onlyOwner external returns (bool) {
        _institutionalFinancingAddr = addr;
        return true;
    }

    function setJackpotPoolAddr(address addr) onlyOwner external returns (bool) {
        _jackpotPoolAddr = addr;
        return true;
    }

    function setIDOAddrAddr(address addr) onlyOwner external returns (bool) {
        _IDOAddr = addr;
        return true;
    }

    function setClubRewardAddr(address addr) onlyOwner external returns (bool) {
        _clubRewardAddr = addr;
        return true;
    }
    function setWhiteList(address addr,uint value) onlyOwner external{
        _whiteList[addr] = value;
    }

}