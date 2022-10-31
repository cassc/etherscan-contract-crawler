// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract MpoInvite is OwnableUpgradeable {
    bool public status;
    address public orgin;

    struct UserInviteInfo {
        address inviter;
        uint time;
    }

    mapping(address => UserInviteInfo) public userInviteInfo;
    mapping(address => address[]) private team;

    event WhoIsYourInviter(address indexed);

    function init() public initializer {
        require(!status, "init completed");
        __Context_init_unchained();
        __Ownable_init_unchained();
        orgin = address(this);
    }

    function whoIsYourInviter(address inv_) public returns (bool) {
        if (inv_ != address(this)) {
            require(inv_ != msg.sender, "invalid 1");
            require(
                userInviteInfo[inv_].inviter != msg.sender &&
                    userInviteInfo[inv_].inviter != address(0),
                "invalid 2"
            );
        }

        userInviteInfo[msg.sender].inviter = inv_;
        team[inv_].push(msg.sender);
        return true;
    }

    function checkInviter(address addr_) public view returns (address) {
        return userInviteInfo[addr_].inviter;
    }

    function checkTeam(address user_) public view returns (address[] memory) {
        return team[user_];
    }

    function checkTeamLength(address user_) public view returns (uint) {
        return team[user_].length;
    }

    function checkInviterOrign(address addr_) public view returns (address) {
        address _inv = userInviteInfo[addr_].inviter;
        while (_inv != address(this)) {
            addr_ = _inv;
            _inv = userInviteInfo[addr_].inviter;
        }
        return addr_;
    }

    function safePull(
        address token,
        address wallet,
        uint amount
    ) external onlyOwner {
        IERC20(token).transfer(wallet, amount);
    }
}