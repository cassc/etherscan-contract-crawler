// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SignedMath.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract WZLock is Ownable {

    using SafeERC20 for IERC20;
    using Math for uint256;
    using SafeMath for uint256;
    using SignedMath for uint256;
   
    struct Lock {
        uint256 balance;
        uint256 amount;
        uint256 lastUnlocktime;
        bool isUnlock;
    }

    uint256 constant UNLOCK_INTERVAl = 1 minutes;
    uint256 constant UNLOCK_CYCLE = 180 days / UNLOCK_INTERVAl;

    IERC20 public immutable defiWz;
    IERC20 public immutable wzDao;

    uint256 public minHoldDefiWz = 1e18;
    bool public enable = true;
    
    mapping(address => Lock) private _locks;
    mapping(address=>bool) private _isImports;

    event Unlock(address user, uint256 amount);

    constructor(
        IERC20 wzDao_,
        IERC20 defiWz_
    ) {
        defiWz = defiWz_;
        wzDao = wzDao_;
    }

    function canUnlock(address _address) public view returns (bool) {
        return enable && getIsUnlock(_address) && isImport(_address) &&  block.timestamp > getLastUnlocktime(_address).add(UNLOCK_INTERVAl) &&
            getLockBalance(_address) > 0 &&
            _isMinHoldDefiWz(_address) && 
            wzDao.balanceOf(address(this)) >=
            _getUnlockAmount(_locks[_address], _getUnlockCycles(_address));
    }

    function isImport(address _address) public view returns(bool){
        return _isImports[_address];
    }

    function getUnlockAmount(address _address)
        external
        view
        returns (uint256)
    {
        return
            canUnlock(_address)
                ? _getUnlockAmount(_locks[_address],_getUnlockCycles(_address))
                : 0;
    }

    function getLastUnlocktime(address _address)
        private
        view
        returns (uint256 result)
    {
        result = _locks[_address].lastUnlocktime;
    }

    function getIsUnlock(address _address) private view returns(bool){
        return _locks[_address].isUnlock;
    }

    function getLockBalance(address _address) public view returns (uint256) {
        return _locks[_address].balance;
    }

    function getLockAmount(address _address) external view returns (uint256) {
        return _locks[_address].amount;
    }

    function unlock() external {
        address user = msg.sender;
        require(canUnlock(user), "Can't receive IVO");
        Lock storage ivoData = _locks[user];
        uint256 unlockDays = _getUnlockCycles(user);
        uint256 amount = _getUnlockAmount(ivoData,unlockDays);
        ivoData.balance = ivoData.balance.sub(amount);
        ivoData.lastUnlocktime = ivoData.lastUnlocktime.add(unlockDays.mul(UNLOCK_INTERVAl));
        wzDao.safeTransfer(user, amount);
        emit Unlock(user, amount);
    }

    function _getUnlockAmount(Lock memory _ivoData,uint256 unlockCycles)
        private
        pure
        returns (uint256 result)
    {
        result = _ivoData.amount.div(UNLOCK_CYCLE).mul(unlockCycles).min(_ivoData.balance);
    }

    function _getUnlockCycles(address _address) private view returns (uint256 result){
        result = block.timestamp.sub(getLastUnlocktime(_address)).div(UNLOCK_INTERVAl);
    }

    function _isMinHoldDefiWz(address _address) private view returns (bool)
    {
        return defiWz.balanceOf(_address) >= minHoldDefiWz;
    }

    function setMinHoldDefiWz(uint256 _v) external onlyOwner{
        minHoldDefiWz = _v;
    }

    function setEnable(bool _v) external onlyOwner{
        enable = _v;
    }

     function withdraw(address _token, address payable _to) external onlyOwner {
        if (_token == address(0x0)) {
            payable(_to).transfer(address(this).balance);
        } else {
            IERC20(_token).transfer(
                _to,
                IERC20(_token).balanceOf(address(this))
            );
        }
    }

    function import1(address[] calldata _addresses,uint256[] calldata _amounts,uint256 lastUnlocktime) external onlyOwner {
        require(_addresses.length == _amounts.length);
        for(uint256 i=0;i<_addresses.length;i++){
            address account = _addresses[i];
            require(!_isImports[account]);
            _isImports[account] = true;
            Lock memory lock = Lock(0,0,lastUnlocktime,true);
            lock.amount = lock.balance = _amounts[i];
            _locks[account] = lock;
        }
    }

    function incUnlockBalance(address _address,uint256 _amount) external onlyOwner verifyImport(_address){
        require(_isImports[_address]);
        Lock storage lock = _locks[_address];
        lock.balance = lock.balance.add(_amount);
    }

    function decUnlockBalance(address _address,uint256 _amount) external onlyOwner verifyImport(_address){
        require(_isImports[_address]);
        Lock storage lock = _locks[_address];
        _amount = _amount.min(lock.balance);
        lock.balance = lock.balance.sub(_amount);
    }

    function updateLock(address _address,uint256 _amount,bool _isUnlock,uint256 _lastUnlocktime) external onlyOwner verifyImport(_address){
        Lock storage lock = _locks[_address];
        lock.amount = _amount;
        lock.isUnlock = _isUnlock;
        if(_lastUnlocktime > 0){
            lock.lastUnlocktime = _lastUnlocktime;
        }
    }

    modifier verifyImport(address _address){
        require(isImport(_address));
        _;
    }
}