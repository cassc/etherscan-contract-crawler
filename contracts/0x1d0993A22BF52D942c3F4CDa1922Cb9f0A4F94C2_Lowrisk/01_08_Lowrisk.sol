// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "../utils/TransferHelper.sol";

contract Lowrisk is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    address public asset;
    address public enfLP;
    uint256 public totalUSDC;
    uint256 public totalLP;

    address public dead = 0x000000000000000000000000000000000000dEaD;

    struct UserInfo {
        uint256 userLP;
        bool isClaimed;
    }

    mapping (address => UserInfo) public userFunds;

    event SetFunds(uint256 funds);

    event OwnerWithdraw(address _asset, uint256 _amount);

    event SetUserFunds(address[] _users, uint256[] _funds);

    event SetTotalLP(uint256 _totalLP);

    event Claim(address caller, uint256 amount);

    constructor(address _asset, address _enfLP, uint256 _totalLP) {
        asset = _asset;
        enfLP = _enfLP;
        totalLP = _totalLP;
    }

    function setFunds(uint256 amount) public onlyOwner {
        require(getBalance(msg.sender) >= amount, "INSUFFICIENT_AMOUNT");
        require(IERC20(asset).allowance(msg.sender, address(this)) >= amount, "INSUFFICIENT_ALLOWANCE");

        uint256 prevBal = getBalance(address(this));
        IERC20(asset).transferFrom(msg.sender, address(this), amount);
        uint256 newBal = getBalance(address(this));
        
        totalUSDC += newBal - prevBal;

        emit SetFunds(totalUSDC);
    }

    function withdraw(address _asset) public onlyOwner {
        uint256 balance = IERC20(_asset).balanceOf(address(this));
        TransferHelper.safeTransfer(_asset, msg.sender, balance);

        emit OwnerWithdraw(_asset, balance);
    }

    function setUserFunds(address[] memory _users, uint256[] memory _userFunds) public onlyOwner {
        require(_users.length == _userFunds.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < _users.length; i++) {
            userFunds[_users[i]] = UserInfo({
                userLP: _userFunds[i],
                isClaimed: false
            });
        }

        emit SetUserFunds(_users, _userFunds);
    }

    function setTotalLP(uint256 _totalLP) public onlyOwner {
        require(_totalLP > 0, "ZERO_TOTAL_LP");
        totalLP = _totalLP;

        emit SetTotalLP(totalLP);
    }

    function getBalance(address account) internal view returns (uint256) {
        return IERC20(asset).balanceOf(account);
    }

    function claim() public nonReentrant {
        UserInfo storage userInfo = userFunds[msg.sender];
        require(userInfo.userLP > 0, "ZERO_HOLDING");
        require(!userInfo.isClaimed, "ALREADY_CLAIMED");

        uint256 userAsset = totalUSDC * userInfo.userLP / totalLP;

        userInfo.isClaimed = true;

        IERC20(enfLP).transferFrom(msg.sender, dead, userInfo.userLP);

        TransferHelper.safeTransfer(asset, msg.sender, userAsset);

        emit Claim(msg.sender, userAsset);
    }
}