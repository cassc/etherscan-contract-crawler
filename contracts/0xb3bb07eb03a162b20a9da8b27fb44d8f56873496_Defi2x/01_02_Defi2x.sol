// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IERC20.sol";

contract Defi2x {
    IERC20 public wbtcToken;
    
    uint256 public todayDeposits;
    uint256 public todayRegistrations;
    uint256 public lastResetTimestamp;

    struct User {
        address referrer;
        address userAddress;
        uint256 totalChilds;
        uint256 balance;
        uint256 totalWithdrawal;
        uint256 noOfjoined;
        bool isJoined;
    }

    mapping(address => User) public users;
    address[] public Addresses;
    address public adminAddress;

    uint256 public registerAmount = 0.0012 * 10**8; // Example registration amount in WBTC (assuming 8 decimals)
    uint256 public doubleAmount = 0.004 * 10**8; // Example double amount in WBTC (assuming 8 decimals)
    uint256 public adminAmount = 0.0002 * 10**8;

    event Registration(address indexed user, address indexed referrer);
    event JoinUser(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    event AllowanceGranted(address indexed user, uint256 amount);

    constructor(address wbtcTokenAddress) {
        // Register the contract deployer as the first user
        users[msg.sender] = User(address(0), msg.sender, 0, 0, 0, 1, true);
        Addresses.push(msg.sender);
        adminAddress = msg.sender;
        lastResetTimestamp = block.timestamp;
        todayRegistrations = 1;
        todayDeposits = registerAmount;
        wbtcToken = IERC20(wbtcTokenAddress);
    }

    function register(address referrer) external {
       
        uint256 userBalance = wbtcToken.balanceOf(msg.sender);
        uint256 allowance = wbtcToken.allowance(msg.sender, address(this));

        require(userBalance >= registerAmount, "Insufficient balance");
        require(allowance >= registerAmount, "Allowance not sufficient");
        User storage user = users[msg.sender];

        // Update registrations and deposits counts based on the date
        if (isToday(lastResetTimestamp)) {
            todayRegistrations++;
            todayDeposits += registerAmount;
        } else {
            todayRegistrations = 1;
            todayDeposits = registerAmount;
            lastResetTimestamp = block.timestamp;
        }

        if (user.userAddress == address(0)) {
            uint256 refTotalchilds = users[referrer].totalChilds + 1;
            require(
                users[referrer].userAddress != address(0) ||
                    referrer == address(0),
                "Upline does not exist"
            );

            wbtcTokenTransferFrom(msg.sender, address(this), registerAmount);
            User memory newUser = User(referrer, msg.sender, 0, 0, 0, 1, true);

            // referrer condition
            if (referrer != address(0)) {
                if (refTotalchilds % 2 == 0) {
                    if (refTotalchilds / 2 == users[referrer].noOfjoined) {
                        users[referrer].balance += doubleAmount;
                        users[adminAddress].balance += adminAmount;
                    }
                }
            }

            users[msg.sender] = newUser;
            users[referrer].totalChilds = refTotalchilds;
            Addresses.push(msg.sender);
            emit JoinUser(msg.sender, registerAmount);
            emit Registration(msg.sender, referrer);
        } else {
            wbtcTokenTransferFrom(msg.sender, address(this), registerAmount);
            uint256 Totalchilds = users[msg.sender].totalChilds;
            uint256 noOfjoined = users[msg.sender].noOfjoined + 1;

            if (Totalchilds % 2 == 0) {
                if (Totalchilds / 2 == noOfjoined) {
                    users[msg.sender].balance += doubleAmount;
                    users[adminAddress].balance += adminAmount;
                }
            }

            users[msg.sender].noOfjoined = noOfjoined;
            emit JoinUser(msg.sender, registerAmount);
        }
    }

    function wbtcTokenTransferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        return wbtcToken.transferFrom(sender, recipient, amount);
    }

    function withdrawal() external {
        require(users[msg.sender].balance > 0, "Invalid amount");
        uint256 wbtcAmount = users[msg.sender].balance;   
        require(
            wbtcToken.balanceOf(address(this)) >= wbtcAmount,
            "Insufficient contract balance"
        );
        users[msg.sender].balance = 0; // Reset the pending balance
        users[msg.sender].totalWithdrawal += wbtcAmount;
        require(wbtcToken.transfer(msg.sender, wbtcAmount), "Transfer failed");
        emit Withdrawal(msg.sender, wbtcAmount);
    }

    function contractBalance() public view returns (uint256) {
        
        return wbtcToken.balanceOf(address(this));
    }

    function getAllUsers() public view returns (User[] memory) {
        User[] memory allUsers = new User[](Addresses.length);
        for (uint256 i = 0; i < Addresses.length; i++) {
            allUsers[i] = users[Addresses[i]];
        }
        return allUsers;
    }

    function isToday(uint256 timestamp) internal view returns (bool) {
        uint256 today = block.timestamp / 86400; // 86400 seconds in a day
        uint256 timestampDay = timestamp / 86400;

        return today == timestampDay;
    }

    function getApproval() external {
        wbtcToken.approve(address(this), registerAmount);
        emit AllowanceGranted(msg.sender, registerAmount);
    }
}
