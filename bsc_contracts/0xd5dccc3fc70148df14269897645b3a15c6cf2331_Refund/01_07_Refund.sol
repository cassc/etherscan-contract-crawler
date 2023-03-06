// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Refund is Initializable, OwnableUpgradeable {
    address public token;
    uint256 public totalRefundAmount;
    uint256 public totalInjectedAmount;

    uint256 public injectCount;
    uint256 public totalWallets;
    uint256 percentDivider;
    mapping(uint256 => uint256) public injects;
    mapping(uint256 => bool) public isInjectExit;

    function initialize(address _token, uint256 _totalRefundAmount)
        public
        initializer
    {
        _owner = msg.sender;
        token = _token;
        totalRefundAmount = _totalRefundAmount;
        percentDivider = 100_00;
    }

    function changeDivider(uint256 _value) public onlyOwner {
        percentDivider = _value;
    }

    function changeToltalRefund(uint256 _refundAmount) public onlyOwner {
        totalRefundAmount = _refundAmount;
    }

    function changeInjectCount(uint256 _value) public onlyOwner {
        injectCount = _value;
    }

    function changeInjectionAmount(uint256 _Id, uint256 _value)
        public
        onlyOwner
    {
        injects[_Id] = _value;
    }

    function changeInjectionStatus(uint256 _Id, bool _status) public onlyOwner {
        isInjectExit[_Id] = _status;
    }

    function changeToken(address _token) public onlyOwner {
        token = _token;
    }

    function setTotalWallets(uint256 _value) public onlyOwner{
        totalWallets = _value;
    }

    function depositToken(uint256 _amount) public onlyOwner {
        IERC20MetadataUpgradeable(token).transferFrom(
            owner(),
            address(this),
            _amount
        );
        injects[injectCount] = _amount;
        isInjectExit[injectCount] = true;
        injectCount++;
        totalInjectedAmount += _amount;
    }

    struct UserData {
        uint256 share;
        uint256 claimedAmount;
        mapping(uint256 => bool) calimedInjection;
    }
    mapping(address => UserData) public users;

    function insertUserAmount(address[] memory accounts, uint256[] memory _value) 
        external onlyOwner
    {
        for (uint256 i; i < accounts.length; i++) {
            users[accounts[i]].share = _value[i];
            totalWallets++;
        }
    }
    function editUserAmount(address _user, uint256 _amount) public onlyOwner {
        users[_user].share = _amount;
    }

    function claimInjection(uint256 _injection) public {
        UserData storage user = users[msg.sender];
        require(isInjectExit[_injection], "Injection doesn't exist");
        require(user.share > 0, "Don't have any amount to calim");
        require(
            !user.calimedInjection[_injection],
            "you already claimed that injection"
        );
                uint256 userShare = (user.share * percentDivider) / totalRefundAmount;
        uint256 claim = (userShare * injects[_injection]) / percentDivider;
        require(user.claimedAmount+claim<user.share,"Amount is claimed");
        IERC20MetadataUpgradeable(token).transfer(msg.sender, claim);
        user.calimedInjection[_injection] = true;
        user.claimedAmount += claim;
    }

    function claimAbleamount(uint256 _injection) public view returns (uint256) {
        UserData storage user = users[msg.sender];
        uint256 userShare = (user.share * percentDivider) / totalRefundAmount;
        uint256 claim = (userShare * injects[_injection]) / percentDivider;
        return claim;
    }

    function withdrawTokens(uint256 _amount) public onlyOwner {
        IERC20MetadataUpgradeable(token).transfer(owner(), _amount);
    }
}