// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract MpoInvite is OwnableUpgradeable {
    address public orgin;

    struct UserInviteInfo {
        address inviter;
        uint time;
    }

    mapping(address => UserInviteInfo) public userInviteInfo;
    mapping(address => address[]) private team;
    mapping(address => bool) public admin;
    event WhoIsYourInviter(address indexed user, address indexed inv);
    event SetAdmin(address indexed user);

    //2.0
    modifier onlyAdmin() {
        require(admin[msg.sender], "not admin!");
        _;
    }

    function init() public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        orgin = address(this);
    }

    function setAdmin(address admin_) public onlyOwner {
        admin[admin_] = true;
        emit SetAdmin(admin_);
    }

    function whoIsYourInviterPublic(address inv_) public returns (bool) {
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
        emit WhoIsYourInviter(msg.sender, inv_);
        return true;
    }

    function whoIsYourInviter(address user_, address inv_)
        public
        onlyAdmin
        returns (bool)
    {
        if (inv_ != address(this)) {
            require(inv_ != user_, "invalid 1");
            require(
                userInviteInfo[inv_].inviter != user_ &&
                    userInviteInfo[inv_].inviter != address(0),
                "invalid 2"
            );
        }

        userInviteInfo[user_].inviter = inv_;
        team[inv_].push(user_);
        emit WhoIsYourInviter(user_, inv_);
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