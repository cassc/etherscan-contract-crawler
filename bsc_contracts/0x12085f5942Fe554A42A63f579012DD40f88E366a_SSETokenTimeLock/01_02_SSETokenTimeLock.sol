// SPDX-License-Identifier: MIT

// SSETimeLockWallet - Modified by SOROOSH ORG WEB3 Team.

pragma solidity ^0.8.16;

import "./Ownable.sol";

interface IBEP20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract SSETokenTimeLock is Ownable {

    // creation time of the token
    uint256 public immutable creationTime;
    
    // Number of tokens which is released after each period.
    uint256 private immutable periodicReleaseNum;
    
    //  Release period in seconds.
    uint256 public constant PERIOD = 15552000; // (seconds in 6 month)
    
    // Number of tokens that has been withdrawn already.
    uint256 private _withdrawnTokens;
    
    IBEP20 private immutable _token;
    
    event TokenWithdrawn(uint indexed previousAmount, uint indexed newAmount);


    /// @dev creates timelocked wallet with given info.
    /// @param token_ tokenContract address.
    /// @param periodicReleaseNum_ periodic release number.
    constructor(IBEP20 token_, uint256 periodicReleaseNum_) {
        _transferOwnership(msg.sender);
        _token = token_;
        creationTime = block.timestamp;
        periodicReleaseNum = periodicReleaseNum_;
    }

    /// @dev withdraws token from wallet if it has enough balance.
    /// @param amount_ amount of withdrawal.
    /// @param beneficiary_ destination address.
    function withdraw(uint256 amount_, address beneficiary_) public onlyOwner {
        require(availableTokens() >= amount_);
        uint256 oldAmount  = _withdrawnTokens;
        _withdrawnTokens += amount_;
        emit TokenWithdrawn(oldAmount, _withdrawnTokens);
        require(token().transfer(beneficiary_, amount_));
    }
    
    /// @dev returns token.
    function token() public view returns (IBEP20) {
        return _token;
    }

    /// @dev returns periodic release number.
    function getPeriodicReleaseNum() public view returns (uint256) {
        return periodicReleaseNum;
    }

    /// @dev returns amount of withdrawan tokens.
    function withdrawnTokens() public view returns (uint256) {
        return _withdrawnTokens;
    }
    
    /// @dev returns available balance to withdraw.
    function availableTokens() public view returns (uint256) {
        uint256 passedTime = block.timestamp - creationTime;
        return ((passedTime / PERIOD) * periodicReleaseNum) - _withdrawnTokens;
    }

    /// @dev returns total locked balance of token.
    function lockedTokens() public view returns (uint256) {
        uint256 balance = timeLockWalletBalance();
        return balance - availableTokens();
    }

    /// @dev returns total balance of the token.
    function timeLockWalletBalance() public view returns (uint256) {
        uint256 balance = token().balanceOf(address(this));
        return balance;
    }
}