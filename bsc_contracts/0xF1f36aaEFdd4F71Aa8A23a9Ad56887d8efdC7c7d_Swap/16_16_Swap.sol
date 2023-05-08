// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/DoubleEndedQueue.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../interface/ISFTToken.sol";

// support FIL and SFT exchange mutually
contract Swap is Ownable2StepUpgradeable, Pausable {
    using DoubleEndedQueue for DoubleEndedQueue.Bytes32Deque;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    // wait queue
    struct WaitQueue {
        DoubleEndedQueue.Bytes32Deque idQueue; // the id queue
        DoubleEndedQueue.Bytes32Deque accountQueue; // the account wait queue
        DoubleEndedQueue.Bytes32Deque amountQueue; // the amount wait queue corresponding to the account wait queue
    }

    WaitQueue private waitQueue;
    EnumerableSet.AddressSet private _whiteList;

    uint constant public BASE_POINT = 10000;
    IERC20 public filToken;
    ISFTToken public sftToken;
    address public taker; // take FIL address
    uint public feePoint;
    uint public counter = 0; // the waite queue counter
    address public oracle;

    event SwapSft(address user, uint filInAmount, uint sftOutAmount);
    event SwapFil(address user, uint amount);
    event Recharge(address recharger, uint amount);
    event Enqueue(uint id, address account, uint amount);
    event Dequeue(uint id, address account, uint amount, uint feePoint, bool isFull);
    event UpdateFirstItemAmount(uint id, address account, uint oldAmount, uint newAmount);
    event SetTaker(address oldTaker, address newTaker);
    event SetFeePoint(uint oldFeePoint, uint newFeePoint);
    event TakeTokens(address taker, address recipient, uint amount);
    event TokensRescued(address to, address token, uint256 amount);
    event SetOracle(address oldOracle, address newOracle);
    
    function initialize(IERC20 _filToken, ISFTToken _sftToken, address _taker, uint _feePoint) external initializer {
        require(address(_filToken) != address(0), "fil token address cannot be zero");
        require(address(_sftToken) != address(0), "SFT token address cannot be zero");
        __Context_init_unchained();
        __Ownable_init_unchained();
        filToken = _filToken;
        sftToken = _sftToken;
        _setTaker(_taker);
        _setFeePoint(_feePoint);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function addWhiteList(address account) external onlyOwner {
        _whiteList.add(account);
    }

    function removeWhiteList(address account) external onlyOwner {
        _whiteList.remove(account);
    }

    function getWhiteList() external view returns(address[] memory) {
        return _whiteList.values();
    }

    function isInWhiteList(address account) public view returns (bool) {
        return _whiteList.contains(account);
    }

    function setTaker(address newTaker) external onlyOwner {
        _setTaker(newTaker);
    }

    function _setTaker(address _taker) private {
        emit SetTaker(taker, _taker);
        taker = _taker;
    }

    function setOracle(address newOracle) external onlyOwner {
        _setOracle(newOracle);
    }

    function _setOracle(address _oracle) private {
        emit SetOracle(oracle, _oracle);
        oracle = _oracle;
    }

    function setFeePoint(uint newFeePoint) external {
        require(address(msg.sender) == oracle, "only oracle can call");
        _setFeePoint(newFeePoint);
    }

    function _setFeePoint(uint _feePoint) private {
        require(_feePoint < BASE_POINT, "invalid fee point");
        emit SetFeePoint(feePoint, _feePoint);
        feePoint = _feePoint;
    }

    function getFilBalance() public view returns (uint) {
        return filToken.balanceOf(address(this));
    }

    function getSftBalance() public view returns (uint) {
        return sftToken.balanceOf(address(this));
    }

    function isWaitQueueEmpty() public view returns (bool) {
        return waitQueue.accountQueue.empty();
    }

    function getSftOutAmount(uint filInAmount) public view returns (uint) {
        return filInAmount * (BASE_POINT - feePoint) / BASE_POINT;
    }

    function getFilOutAmount(uint sftInAmount) public view returns (uint) {
        return sftInAmount * BASE_POINT / (BASE_POINT - feePoint);
    }

    function isSftBalanceTooSmall() public view returns (bool) {
        return sftToken.balanceOf(address(this)) <= 10000;
    }

    function getWaitQueueLength() public view returns (uint) {
        return waitQueue.accountQueue.length();
    }

    function getWaitQueueItem(uint index) public view returns (uint id, address account, uint amount) {
        id = uint256(waitQueue.idQueue.at(index));
        account = address(uint160(uint256(waitQueue.accountQueue.at(index))));
        amount = uint256(waitQueue.amountQueue.at(index));
    }

    function getWaitQueue() public view returns (uint[] memory idList, address[] memory accountList, uint[] memory amountList) {
        uint waitQueueLength = getWaitQueueLength();
        idList = new uint[](waitQueueLength);
        accountList = new address[](waitQueueLength);
        amountList = new uint[](waitQueueLength);
        for (uint i = 0; i < waitQueue.accountQueue.length(); i++) {
            (idList[i], accountList[i], amountList[i]) = getWaitQueueItem(i);
        }
    }
 

    /**
    * @notice use fil to swap sft back according to specific exchange rate
    * @param amount the fil amount to swap
    */
    function swapSft(uint amount) external whenNotPaused() {
        require(filToken.allowance(address(msg.sender), address(this)) >= amount, "swapSft: approve amount not enough");
        require(filToken.balanceOf(address(msg.sender)) >= amount, "swapSft: fil balance not enough");
        filToken.safeTransferFrom(address(msg.sender), address(this), amount);
        if (!isWaitQueueEmpty()) {
            _enqueue(msg.sender, amount);
            return;
        }
        uint sftOutAmount = getSftOutAmount(amount);
        uint currentSftBlance = getSftBalance();
        if (currentSftBlance >= sftOutAmount) {
            require(sftToken.transfer(address(msg.sender), sftOutAmount), "swapSft: sft token transfer failed");
            _emitEnQueueAndDequeueEvent(msg.sender, amount);
            emit SwapSft(msg.sender, amount, sftOutAmount);
        } else {
            _enqueue(msg.sender, amount);
            if (!isSftBalanceTooSmall()) {
                uint filInAmount = getFilOutAmount(currentSftBlance);
                // actualSftOutAmount <= currentSftBlance
                uint actualSftOutAmount = getSftOutAmount(filInAmount);
                uint remainFilAmount = amount - filInAmount;
                // _enqueue(msg.sender, remainFilAmount);
                _updateFirstItemAmount(remainFilAmount);
                require(sftToken.transfer(address(msg.sender), actualSftOutAmount), "swapSft: sft token transfer failed");
                emit SwapSft(msg.sender, filInAmount, actualSftOutAmount);
            }
        }
    }

     /**
    * @notice the user who only is in the whitelist can use sft to swap fil back, according to the exchange rate 1:1
    * @param amount the sft amount to swap
    */
    function swapFil(uint amount) external whenNotPaused() {
        require(isInWhiteList(msg.sender), "swapFil: account not in whitelist");
        require(sftToken.allowance(address(msg.sender), address(this)) >= amount, "swapFil: approve amount not enough");
        require(sftToken.balanceOf(address(msg.sender)) >= amount, "swapFil: sft balance not enough");
        require(getFilBalance() >= amount, "swapFil: fil balance not enough");
        require(sftToken.transferFrom(address(msg.sender), address(this), amount), "swapFil: sft token transfer failed");
        filToken.safeTransfer(address(msg.sender), amount);
        _liquidateWaitQueue();  
        emit SwapFil(msg.sender, amount);
    }

    /**
    * @notice transfer SFT into this contract and liquidate wait queue
    * @param amount the SFT amount transfer in
    */
    function recharge(uint amount) external {
        require(sftToken.allowance(address(msg.sender), address(this)) >= amount, "recharge: approve amount not enough");
        require(sftToken.balanceOf(address(msg.sender)) >= amount, "recharge: sft balance not enough");
        require(sftToken.transferFrom(address(msg.sender), address(this), amount), "recharge: sft token transfer failed");
        _liquidateWaitQueue();
        emit Recharge(msg.sender, amount);
    }

    // take fil token away from this contract
    function takeTokens(address recipient, uint amount) external {
        require(address(msg.sender) == taker, "only taker can call");
        require(filToken.balanceOf(address(this)) >= amount, "fil token balance not enough");
        filToken.safeTransfer(recipient, amount);
        emit TakeTokens(address(msg.sender), recipient, amount);
    }

    // liquate the wait queue when new sft token transfer in through `recharge` and `swapFil` method
    function _liquidateWaitQueue() internal {
        while (!isWaitQueueEmpty() && !isSftBalanceTooSmall()) {
            (, address account, uint filInAmount) = getWaitQueueItem(0);
            uint sftOutAmount = getSftOutAmount(filInAmount);
            if (getSftBalance() >= sftOutAmount) {
                _dequeue();
                require(sftToken.transfer(account, sftOutAmount), "recharge: sft token transfer failed");
            } else {
                uint _filInAmount = getFilOutAmount(getSftBalance());
                uint actualSftOutAmount = getSftOutAmount(_filInAmount);
                _updateFirstItemAmount(filInAmount - _filInAmount);
                require(sftToken.transfer(account, actualSftOutAmount), "recharge: sft token transfer failed");
                break;
            }
        }
    }

    /**
    * @notice join the wait queue
    * @param account the user address wait to swap
    * @param amount the FIL amount to swap
    */
    function _enqueue(address account, uint amount) internal {
        counter++;
        waitQueue.idQueue.pushBack(bytes32(counter));
        waitQueue.accountQueue.pushBack(bytes32(uint256(uint160(account))));
        waitQueue.amountQueue.pushBack(bytes32(amount));
        emit Enqueue(counter, account, amount);
    }

    // dequeue
    function _dequeue() internal {
        uint256 id = uint256(waitQueue.idQueue.popFront());
        address account = address(uint160(uint256(waitQueue.accountQueue.popFront())));
        uint256 amount = uint256(waitQueue.amountQueue.popFront());
        emit Dequeue(id, account, amount, feePoint, true);
    }

    function _updateFirstItemAmount(uint256 newAmount) internal {
        uint256 oldAmount = uint256(waitQueue.amountQueue.popFront());
        waitQueue.amountQueue.pushFront(bytes32(newAmount));
        address account = address(uint160(uint256(waitQueue.accountQueue.at(0))));
        uint256 id = uint256(waitQueue.idQueue.at(0));
        emit UpdateFirstItemAmount(id, account, oldAmount, newAmount);
        emit Dequeue(id, account, oldAmount - newAmount, feePoint, false);
    }

    function _emitEnQueueAndDequeueEvent(address account, uint amount) internal {
        counter++;
        emit Enqueue(counter, account, amount);
        emit Dequeue(counter, account, amount, feePoint, true);
    }

    function _msgSender() internal view override(Context, ContextUpgradeable) returns (address) {
      return Context._msgSender();
  }

    function _msgData() internal view override(Context, ContextUpgradeable) returns (bytes calldata) {
      return Context._msgData();
  }

    // recover wrong tokens
    function rescueTokens(
        address _to,
        address _token,
        uint256 _amount
    ) external onlyOwner {
        require(_to != address(0), "Cannot send to address(0)");
        require(_amount != 0, "Cannot rescue 0 tokens");
        IERC20 token = IERC20(_token);
        token.safeTransfer(_to, _amount);
        emit TokensRescued(_to, _token, _amount);
    }
}