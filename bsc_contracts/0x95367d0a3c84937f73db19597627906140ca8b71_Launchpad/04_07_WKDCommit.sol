// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./utils/SafeBEP20.sol";
import "./utils/IBEP20.sol";

contract WKDCommit {
    // This contract alllows userrs to comit WKD in order to be able to participate in the WKD Launchpad
    using SafeBEP20 for IBEP20;

    IBEP20 public wkd;
    // Admin address
    address public admin;
    // Whether it is initialized
    bool public isInitialized;
    // Amount of WKD commited by users
    uint256 totalusersCommit;

    // Details of a user's commit
    mapping(address => uint256) public userCommit;
    // Custom error messages

    error NotPermitted();
    error NotInitialized();
    error InvalidAmount();

    event Commit(address indexed user, uint256 amount);
    event AdminTokenRecovery(address tokenRecovered, uint256 amount);
    event Initialize(address indexed admin, address wkd);
    event removeWkdCommit(address indexed user, uint256 amount);

    constructor(address _admin) {
        admin = _admin;
    }

    function initialize(address _wkd) external {
        if (msg.sender != admin) revert NotPermitted();
        if (isInitialized) revert NotInitialized();
        wkd = IBEP20(_wkd);
        isInitialized = true;
        emit Initialize(admin, _wkd);
    }

    function commitWkd(uint256 _amount) public {
        if (!isInitialized) revert NotInitialized();
        if (_amount == 0) revert InvalidAmount();
        userCommit[msg.sender] += _amount;
        totalusersCommit += _amount;
        wkd.transferFrom(msg.sender, address(this), _amount);
        emit Commit(msg.sender, _amount);
    }

    function removeWkd(uint256 _amount) public {
        require(isInitialized, "WKDCommit: Contract not initialized");
        require(_amount > 0, "WKDCommit: Amount must be greater than 0");
        require(userCommit[msg.sender] >= _amount, "WKDCommit: Amount must be less than user's commit");
        userCommit[msg.sender] -= _amount;
        totalusersCommit -= _amount;
        wkd.safeTransfer(msg.sender, _amount);
        emit removeWkdCommit(msg.sender, _amount);
    }

    function getUserCommit(address _user) public view returns (uint256) {
        return userCommit[_user];
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of tokens to withdraw
     * @dev This function is only callable by admin.
     */
    function recoveryToken(address _tokenAddress, uint256 _tokenAmount) external {
        if (msg.sender != admin) revert NotPermitted();
        require(_tokenAddress != address(wkd), "WKDCommit: Cannot be WKD token");
        IBEP20(_tokenAddress).safeTransfer(admin, _tokenAmount);
        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }
}