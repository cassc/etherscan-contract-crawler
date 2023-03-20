// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// BlockOS AI developer funds locker

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

error BOSAI_Dev_Funds_Locker_Address_Already_In_List();
error BOSAI_Dev_Funds_Locker_Too_Early_To_Withdraw();

contract BOSAI_Dev_Funds_Locker {
    bool public isHacktonRunning;
    uint256 public totalFunds;
    uint256 public numOfDevs;
    uint256 public devsNumbRewardWithdrawn;
    uint256 public totalLockingTime = 60 * 60 * 24 * 365;

    mapping(address => bool) public partetipatingDev;
    mapping(address => bool) public hasClaimed;

    // The God is Gnosis Safe address that will be in charge to remove address if the community feels that people have cheated
    address public theGod;

    IERC20 public BOSAI;

    event DeveloperAdded(address);
    event DeveloperRemoved(address);

    constructor(address _tokenAddress, address _theGod) {
        BOSAI = IERC20(_tokenAddress);
        theGod = _theGod;
        isHacktonRunning = true;
    }

    function claim() public {
        require(
            partetipatingDev[msg.sender],
            "You are not in the developer participating list"
        );
        require(
            !hasClaimed[msg.sender],
            "You have already claimed your reward"
        );
        if (block.timestamp >= 1713340800) {
            require(IERC20(BOSAI).transfer(msg.sender, checkAmountPerDev()));
            partetipatingDev[msg.sender] = false;
            hasClaimed[msg.sender] = true;
            devsNumbRewardWithdrawn--;
        } else {
            revert BOSAI_Dev_Funds_Locker_Too_Early_To_Withdraw();
        }
    }

    function addDev(address _wallet) public {
        if (msg.sender != theGod) {
            require(
                partetipatingDev[msg.sender],
                "You are not in the developer participating list"
            );
            require(isHacktonRunning, "Time to add developer has ended");
        }
        if (partetipatingDev[_wallet]) {
            revert BOSAI_Dev_Funds_Locker_Address_Already_In_List();
        }
        partetipatingDev[_wallet] = true;
        numOfDevs++;
        devsNumbRewardWithdrawn++;
        updateTotalFunds();
        emit DeveloperAdded(_wallet);
    }

    function removeDev(address _wallet) public {
        require(
            msg.sender == theGod,
            "You are not allowed to remove a developer"
        );
        require(
            partetipatingDev[_wallet],
            "The developer does not exist in the list"
        );
        delete partetipatingDev[_wallet];
        numOfDevs--;
        devsNumbRewardWithdrawn--;
        updateTotalFunds();
        emit DeveloperRemoved(_wallet);
    }

    function checkDevAddr(address _wallet) public view returns (bool) {
        return partetipatingDev[_wallet];
    }

    function checkAmountPerDev() public view returns (uint256) {
        uint256 _amount = totalFunds / numOfDevs;
        return _amount;
    }

    function stopHacktonWhitelist() public {
        require(
            msg.sender == theGod,
            "You are not allowed to stop the whitelist a developer"
        );
        isHacktonRunning = false;
    }

    function updateTotalFunds() internal {
        totalFunds = BOSAI.balanceOf(address(this));
    }

    function updateGod(address _newGodAddress) public {
        require(
            msg.sender == theGod,
            "You can't change GOD if you are not GOD"
        );
        theGod = _newGodAddress;
    }
}