// SPDX-License-Identifier: MIT
pragma solidity =0.8.2;

import "./SOCOUtils.sol";

contract SOCOIDO is Ownable {
    using SafeMath for uint256;

    struct FunderInfo {
        uint256  balances;
        uint256  investCount;
        uint256  investTime;
        uint256  blockNumber;
        address  funderAddr;
        address  refererAddr;
    }

    address                      private _admin;
    FunderInfo[]                 private _funderArray;
    mapping (address => uint256) private _funderIndex;
    mapping (address => uint256) public  whiteList;

    event Withdrawal(address indexed src, uint wad);
    event Deposit(address indexed dst, address indexed referer,  uint indexed wad, uint amount);
    event Rewards(address indexed dst, address indexed follower, uint indexed wad, uint amount);

    constructor () {
        Ownable._initOwnable();
        _admin = msg.sender;

        // element 0 is never used
        _funderArray.push();
    }

    modifier onlyAdmin() {
        require(_admin == msg.sender, "SOCOIDO: invalid caller");
        _;
    }

    function renounceOwnership() public virtual override onlyOwner {}

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Allow to receive the native asset
    receive() external payable {
        revert("SOCOIDO: check your logic!!");
    }

    fallback() external payable {
        revert("SOCOIDO: check your logic!!");
    }

    function deposit(address referer) external payable {
        require (msg.value > 0, "SOCOIDO: invalid fund");
        require (address(msg.sender).balance >= msg.value, "SOCOIDO: insufficient fund");

        require (referer != address(0), "SOCOIDO: invalid referer");
        require (whiteList[referer] >0, "SOCOIDO: the referer is not exist");
        require (referer != msg.sender, "SOCOIDO: sender and referer is same");

        if (_funderIndex[msg.sender] == 0) {
            _funderArray.push();
            _funderIndex[msg.sender] = _funderArray.length - 1;
        }

        FunderInfo storage funderInfo = _funderArray[_funderIndex[msg.sender]];
        funderInfo.investCount += 1;
        funderInfo.balances    += msg.value;
        funderInfo.blockNumber = block.number;
        funderInfo.investTime  = block.timestamp;
        funderInfo.funderAddr  = msg.sender;
        funderInfo.refererAddr = referer;

        uint256 reward = SafeMath.div(SafeMath.mul(msg.value, 20), 100);
        payable(referer).transfer(reward);
        emit Rewards(referer, msg.sender, reward, msg.value);
        
        uint256 amount = msg.value - reward;
        emit Deposit(msg.sender, referer, amount, msg.value);
    }

    function withdraw(uint wad) external onlyOwner {
        require(address(this).balance >= wad, "SOCOIDO: insufficient fund");

        payable(msg.sender).transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }

    function balanceOf(address addr) external view returns (uint256) {
        if (_funderIndex[addr] <= 0) {
            return 0;
        } else {
            return _funderArray[_funderIndex[addr]].balances;
        }
    }

    function getFunderCount() external view returns (uint256) {
        return (_funderArray.length - 1);
    }

    function getFunderInfo(address addr) external view returns (FunderInfo memory funderInfo) {
        if (_funderIndex[addr] > 0) {
            funderInfo = _funderArray[_funderIndex[addr]];
        }
    }

    function listFunder(uint256 index, uint256 pageSize) external view returns (uint256 count, FunderInfo[] memory funders) {
        count = 0;
        funders = new FunderInfo[](pageSize);
        for (uint256 idx = index; idx < _funderArray.length; idx++) {
            funders[count] = _funderArray[idx];
            count++;
        }
    }

    function addReferer(address referer) external onlyAdmin {
        require (referer != address(0), "SOCOIDO: invalid referer");
        require (!isContract(referer),  "SOCOIDO: referer is contract");

        whiteList[referer] = 1;
    }

    function getAdmin() external view returns (address) {
        return _admin;
    }

    function setAdmin(address account) external onlyOwner {
        require(account != address(0), "SOCOBonus: awarder is zero");
        require(!isContract(account),  "SOCOBonus: awarder is contract");

        _admin = account;
    }
}