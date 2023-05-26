// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./TokenLock.sol";
import "../HATToken.sol";


contract HATTokenLock is TokenLock {

    bool public canDelegate;

    // Initializer
    function initialize(
        address _tokenLockOwner,
        address _beneficiary,
        HATToken _token,
        uint256 _managedAmount,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _periods,
        uint256 _releaseStartTime,
        uint256 _vestingCliffTime,
        Revocability _revocable,
        bool _canDelegate
    ) external {
        _initialize(
            _tokenLockOwner,
            _beneficiary,
            address(_token),
            _managedAmount,
            _startTime,
            _endTime,
            _periods,
            _releaseStartTime,
            _vestingCliffTime,
            _revocable
        );
        if (_canDelegate) {
            _token.delegate(_beneficiary);
        }
        canDelegate = _canDelegate;
    }

    /// @dev delegate voting power
    /// @param _delegatee Address of delegatee
    function delegate(address _delegatee)
        external
        onlyBeneficiary
    {
        require(canDelegate, "delegate is disable");
        HATToken(address(token)).delegate(_delegatee);
    }
}