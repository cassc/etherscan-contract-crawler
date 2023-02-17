/**
 *Submitted for verification at BscScan.com on 2023-02-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

interface IERC20 {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "!owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "lost owner");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract AbsToken is IERC20, Ownable {
    string public _name;
    string public _symbol;
    uint8 public _decimals;
    uint256 public _tTotal;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    bool isOpen;

    address fundAddress;

    uint256 public _tranferFee;

    uint256 public _LPFee;

    mapping(address => bool) public _blackList;

    mapping(address => bool) public _feeWhiteList;

    mapping(address => bool) public _boardMembers;

    mapping(address => bool) public _lpBlackList;

    modifier onlyFundAddress() {
        require(fundAddress == msg.sender, "!fundAddress");
        _;
    }

    constructor(
        string memory Name,
        string memory Symbol,
        uint8 Decimals,
        uint256 Supply,
        address FundAddress
    ) {
        _name = Name;
        _symbol = Symbol;
        _decimals = Decimals;

        fundAddress = FundAddress;

        minHolderNum = 50 * 10**Decimals;
        minOrdinaryNum = 10 * 10**Decimals;

        limitFeeMaxGas = 500000;
        limitFeeMin = 5 * 10**Decimals;
        minTimeSec = 400000;
        compRete = 400;

        _LPFee = 25;

        isOpen = false;

        _feeWhiteList[address(this)] = true;
        _feeWhiteList[FundAddress] = true;

        uint256 total = Supply * 10**Decimals;
        _tTotal = total;
        _balances[msg.sender] = total;
        emit Transfer(address(0), msg.sender, total);
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);

        _allowances[sender][msg.sender] =
            _allowances[sender][msg.sender] -
            amount;
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");

        require(!_blackList[from] && !_blackList[to], "black account!");

        uint256 balance = balanceOf(from);

        require(balance >= amount, "balanceNotEnough");

        if (map_LPList[from].enable || map_LPList[to].enable) {
            require(isOpen || _boardMembers[from], "trade is not open!");

            require(!_boardMembers[to], "this account not quit!");

            if (map_LPList[from].enable) {
                _funTransfer(from, to, amount, from);
                processLP(from);
            } else {
                _funTransfer(from, to, amount, to);
                addHolder(from, to);
                processLP(to);
            }
        } else {
            _tokenTransfer(from, to, amount);
        }
    }

    function _funTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        address pairAddr
    ) private {
        _balances[sender] = _balances[sender] - tAmount;

        if (_feeWhiteList[sender]) {
            _takeTransfer(sender, recipient, tAmount);
        } else {
            uint256 feeAmount = (tAmount * _LPFee) / 1000;
            _takeTransfer(sender, address(this), feeAmount);

            map_LPList[pairAddr].totalAmount += feeAmount;

            _takeTransfer(sender, recipient, tAmount - feeAmount);
        }
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        _balances[sender] = _balances[sender] - tAmount;

        if (_feeWhiteList[sender] || _tranferFee == 0) {
            _takeTransfer(sender, recipient, tAmount);
        } else {
            uint256 fee = (tAmount * _tranferFee) / 1000;

            uint256 recipientAmount = tAmount - fee;

            _takeTransfer(sender, recipient, recipientAmount);

            _takeTransfer(sender, fundAddress, fee);
        }
    }

    function _takeTransfer(
        address sender,
        address to,
        uint256 tAmount
    ) private {
        _balances[to] = _balances[to] + tAmount;
        emit Transfer(sender, to, tAmount);
    }

    receive() external payable {}

    struct LPList {
        address pair;
        bool enable;
        address[] member;
        mapping(address => uint256) member_map;
        uint256 currentIndex;
        uint256 lastMembers;
        uint256 totalAmount;
        uint256 lastTotalAmount;
        uint256 lastBlockNumber;
        mapping(address => uint256) recordBoardRate;
    }

    mapping(address => LPList) private map_LPList;

    function addHolder(address adr, address pairAddr) private {
        uint256 size;

        assembly {
            size := extcodesize(adr)
        }

        if (size > 0) {
            return;
        }

        if (0 == map_LPList[pairAddr].member_map[adr]) {
            if (
                0 == map_LPList[pairAddr].member.length ||
                map_LPList[pairAddr].member[0] != adr
            ) {
                map_LPList[pairAddr].member_map[adr] = map_LPList[pairAddr]
                    .member
                    .length;
                map_LPList[pairAddr].member.push(adr);
            }
        }
    }

    uint256 private minHolderNum;
    uint256 private minOrdinaryNum;
    uint256 private limitFeeMin;
    uint256 private limitFeeMaxGas;
    uint256 private minTimeSec;
    uint256 private compRete;

    function processLP(address pairAddr) private {
        LPList storage pairObj = map_LPList[pairAddr];

        if (block.timestamp - pairObj.lastBlockNumber < minTimeSec) {
            return;
        }

        IERC20 _lpPair = IERC20(pairAddr);

        uint256 totalPair = _lpPair.totalSupply();

        uint256 lastAmount = pairObj.lastTotalAmount;

        uint256 shareholderCount = pairObj.lastMembers;

        if (pairObj.lastMembers == 0) {
            shareholderCount = pairObj.member.length;
            pairObj.lastMembers = shareholderCount;
        }

        uint256 gasUsed = 0;

        uint256 iterations = 0;

        uint256 gasLeft = gasleft();

        address shareHolder;

        uint256 tokenBalance;

        uint256 minNum;

        uint256 amount;

        uint256 userPairBalance;

        IERC20 FIST = IERC20(address(this));

        while (gasUsed < limitFeeMaxGas && iterations < shareholderCount) {
            if (pairObj.currentIndex >= shareholderCount) {
                pairObj.currentIndex = 0;
                pairObj.lastMembers = pairObj.member.length;
            }

            if (pairObj.currentIndex == 0) {
                LPList storage pairObjCopy = pairObj;

                lastAmount = pairObjCopy.totalAmount;

                if (lastAmount < limitFeeMin) {
                    pairObjCopy.lastBlockNumber = block.timestamp;
                    break;
                }

                uint256 compProfit = (lastAmount * compRete) / 1000;

                uint256 userProfit = lastAmount - compProfit;

                FIST.transfer(fundAddress, compProfit);

                pairObjCopy.totalAmount = 0;

                pairObjCopy.lastTotalAmount = userProfit;
                lastAmount = userProfit;
            }

            shareHolder = pairObj.member[pairObj.currentIndex];

            if (!_lpBlackList[shareHolder]) {
                tokenBalance = balanceOf(shareHolder);

                if (_boardMembers[shareHolder]) {
                    minNum = minHolderNum;
                } else {
                    minNum = minOrdinaryNum;
                }

                userPairBalance =
                    _lpPair.balanceOf(shareHolder) +
                    pairObj.recordBoardRate[shareHolder];

                if (userPairBalance > 0) {
                    amount = (lastAmount * userPairBalance) / totalPair;

                    if (tokenBalance >= minNum) {
                        FIST.transfer(shareHolder, amount);
                    } else {
                        FIST.transfer(fundAddress, amount);
                    }
                }
            }

            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            pairObj.currentIndex++;
            iterations++;
        }

        pairObj.lastBlockNumber = block.timestamp;
    }

    function showPairInfo(address pairAddr)
        public
        view
        returns (
            address _pair,
            bool _enable,
            address[] memory _member,
            uint256 _currentIndex,
            uint256 _lastMembers,
            uint256 _totalAmount,
            uint256 _lastTotalAmount,
            uint256 _lastBlockNumber
        )
    {
        _pair = map_LPList[pairAddr].pair;
        _enable = map_LPList[pairAddr].enable;
        _member = map_LPList[pairAddr].member;
        _currentIndex = map_LPList[pairAddr].currentIndex;
        _lastMembers = map_LPList[pairAddr].lastMembers;
        _totalAmount = map_LPList[pairAddr].totalAmount;
        _lastTotalAmount = map_LPList[pairAddr].lastTotalAmount;
        _lastBlockNumber = map_LPList[pairAddr].lastBlockNumber;
        return (
            _pair,
            _enable,
            _member,
            _currentIndex,
            _lastMembers,
            _totalAmount,
            _lastTotalAmount,
            _lastBlockNumber
        );
    }

    function showRecordBoardRate(address pairAddr, address addr)
        public
        view
        returns (uint256)
    {
        return map_LPList[pairAddr].recordBoardRate[addr];
    }

    function setOpenStatus(bool _open) external onlyOwner {
        isOpen = _open;
    }

    function setBoardMembers(address addr, bool enable)
        external
        onlyFundAddress
    {
        _boardMembers[addr] = enable;
    }

    function setLPBlackList(address addr, bool enable)
        external
        onlyFundAddress
    {
        _lpBlackList[addr] = enable;
    }

    function setRecordBoardRate(
        address pairAddr,
        address addr,
        uint256 amount
    ) external onlyFundAddress {
        map_LPList[pairAddr].recordBoardRate[addr] = amount;
    }

    function setSwapPairList(address pairAddr, bool enable)
        external
        onlyFundAddress
    {
        map_LPList[pairAddr].enable = enable;
        map_LPList[pairAddr].pair = pairAddr;
        map_LPList[pairAddr].lastBlockNumber = block.timestamp;
    }

    function depositFee(address pairAddr) external onlyFundAddress {
        uint256 amount = map_LPList[pairAddr].totalAmount;
        IERC20 FIST = IERC20(address(this));
        FIST.transfer(fundAddress, amount);
        map_LPList[pairAddr].totalAmount = 0;
        map_LPList[pairAddr].lastTotalAmount = 0;
        map_LPList[pairAddr].currentIndex = 0;
        map_LPList[pairAddr].lastMembers = 0;
    }

    function setHolderCondition(
        uint256 _minHolderNum,
        uint256 _minOrdinaryNum,
        uint256 _limitFeeMaxGas,
        uint256 _limitFeeMin,
        uint256 _minTimeSec,
        uint256 _compRete
    ) external onlyFundAddress {
        minHolderNum = _minHolderNum;
        minOrdinaryNum = _minOrdinaryNum;
        limitFeeMaxGas = _limitFeeMaxGas;
        limitFeeMin = _limitFeeMin;
        minTimeSec = _minTimeSec;
        compRete = _compRete;
    }

    function setFee(uint256 tranferFee, uint256 lPFee)
        external
        onlyFundAddress
    {
        _tranferFee = tranferFee;
        _LPFee = lPFee;
    }

    function setfundAddress(address addr) external onlyFundAddress {
        fundAddress = addr;
    }

    function setBlackAddress(address addr, bool enable) external onlyOwner {
        _blackList[addr] = enable;
    }

    function setFeeWhiteList(address addr, bool enable)
        external
        onlyFundAddress
    {
        _feeWhiteList[addr] = enable;
    }

    function nextFundTime(address pairAddr) public view returns (uint256) {
        return block.timestamp - map_LPList[pairAddr].lastBlockNumber;
    }

    function getFundInfo()
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            minHolderNum,
            minOrdinaryNum,
            limitFeeMin,
            limitFeeMaxGas,
            minTimeSec,
            compRete
        );
    }
}

contract Plant is AbsToken {
    constructor()
        AbsToken(
            "Plant",
            "Plant",
            18,
            50000000,
            address(0x3c3aEEE1F0372317a2aa77d22A68cFcd22e56BB2)
        )
    {}
}