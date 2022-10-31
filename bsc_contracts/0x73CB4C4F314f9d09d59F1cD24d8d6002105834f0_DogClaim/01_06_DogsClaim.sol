// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DogClaim is Ownable, ReentrancyGuard {

    bool public isCreditingActive = false;
    mapping(address => uint256) public userClaimInfo;
    IERC20 public DogsToken;

    constructor(IERC20 _dogsToken){
        DogsToken = _dogsToken;
    }

    function claimDogs() external nonReentrant {
        require(isCreditingActive, 'not active yet');

        uint256 amountClaimable = userClaimInfo[msg.sender];
        require(amountClaimable > 0, 'nothing to claim');

        DogsToken.transfer(msg.sender, amountClaimable);

        userClaimInfo[msg.sender] = 0;
    }

    function setUserClaimInfo(address[] memory _users, uint256[] memory _usersClaimData) external onlyOwner {
        require(_users.length == _usersClaimData.length);
        for (uint256 i = 0; i < _users.length; i++) {
            userClaimInfo[_users[i]] = _usersClaimData[i];
        }
    }

    // Admin Functions
    function toggleCreditingActive(bool _isActive) external onlyOwner {
        isCreditingActive = _isActive;
    }

    function recoverDogs(address _token, uint256 _amount, address _to) external onlyOwner {
        IERC20(_token).transfer(_to, _amount);
    }
}