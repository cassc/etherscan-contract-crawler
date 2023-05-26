// SPDX-License-Identifier: MIT
//CHRONOS IS A UTILITY TOKEN FOR THE PXQUEST ECOSYSTEM.
//$CHRONOS is NOT an investment and has NO economic value.
//It will be earned by active holding within the PXQUEST ecosystem. Each Genesis Adventurer will be eligible to claim tokens at a rate of 5 $CHRONOS per day.

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

interface iAdv {
    function balanceOf(address owner) external view returns (uint256);
}

contract Chronos is ERC20, Ownable {
    iAdv public AdvContract;

    uint256 public constant BASE_RATE = 5 ether;
    uint256 public START = 1641859200;

    bool public rewardPaused = false;

    // Yield tracking
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public lastUpdate;
    event ChronosGranted(address user, uint256 amount);

    // Permissions mapping system
    struct Perms {
        bool Grantee;
        bool Burner;
    }
    mapping(address => Perms) public permsMap;

    constructor(address advContract) ERC20("CHRONOS", "CHR") {
        AdvContract = iAdv(advContract);
    }

    // Setter function in case migration needed again
    function setAdv(address address_) external onlyOwner {
        AdvContract = iAdv(address_);
    }

    // Then add setter functions for START just in case
    function setStart(uint256 start_) external onlyOwner {
        START = start_;
    }

    // Update yield ledger
    function updateRewardAndTimestamp(address user) internal {
        if (user != address(0)) {
            console.log("Got to user", user);
            rewards[user] += getPendingReward(user);
            lastUpdate[user] = block.timestamp;
        }
    }

    //called before transfer
    function updateReward(address from, address to) public {
        console.log("Got to reward");
        updateRewardAndTimestamp(from);
        updateRewardAndTimestamp(to);
    }

    //placeholder for staking, now being split into its own contract
    function stake(
        address from,
        uint256 advId,
        uint256 util
    ) external {}

    function withdrawChronos() external {
        require(!rewardPaused, "Claiming Chronos has been paused");
        // add last reward tally to pending rewards since
        uint256 calcrew = rewards[msg.sender] + getPendingReward(msg.sender);
        // reset rewards to zero
        rewards[msg.sender] = 0;
        // update last tally timestamp
        lastUpdate[msg.sender] = block.timestamp;
        _mint(msg.sender, calcrew);
    }

    function grantChronos(address _address, uint256 _amount) external {
        require(
            permsMap[msg.sender].Grantee,
            "Address does not have permission to distribute tokens"
        );
        _mint(_address, _amount);
        emit ChronosGranted(_address, _amount);
    }

    function burnUnclaimed(address user, uint256 amount) external {
        // the sender must be an 'allowedAddress' or a PXAdv
        require(
            msg.sender == address(AdvContract) || permsMap[msg.sender].Burner,
            "Address does not have permission to burn"
        );
        require(user != address(0), "ERC20: burn from the zero address");
        updateRewardAndTimestamp(user);
        require(
            rewards[user] >= amount,
            "ERC20: burn amount exceeds unclaimed balance"
        );
        rewards[user] -= amount;
    }

    function burn(address user, uint256 amount) external {
        // the sender must be an 'allowedAddress' or a PXAdv
        require(
            msg.sender == address(AdvContract) || permsMap[msg.sender].Burner,
            "Address does not have permission to burn"
        );
        _burn(user, amount);
        if (amount == 750 ether) {
            // if breeding, update the rewards so that baby isn't treated as having existed since genesis
            updateRewardAndTimestamp(user);
        }
    }

    function getTotalUnclaimed(address user)
        external
        view
        returns (uint256 unclaimed)
    {
        uint256 accum = AdvContract.balanceOf(user);
        if ((lastUpdate[user] == 0)) {
            return
                rewards[user] +
                ((accum * BASE_RATE * (block.timestamp - START)) / 1 days);
        }
        return
            rewards[user] +
            ((accum * BASE_RATE * (block.timestamp - lastUpdate[user])) /
                1 days);
    }

    function getPendingReward(address user) internal returns (uint256) {
        // get how many adventurers the wallet holds
        console.log("about to do this");
        uint256 accum = AdvContract.balanceOf(user);
        if ((lastUpdate[user] == 0)) {
            console.log("Got in here");
            // if I do not already have a record in lastUpdate, i must be genesis minter or new buyer
            if ((accum > 0)) {
                // i'm already holding, treat me as a genesis minter and give me a record in lastUpdate of mint date
                lastUpdate[user] = START;
            } else {
                // i'm not already holding, so i'm a new buyer, my last updated status will occur at the end of the transfer call
                return 0;
            }
        }
        console.log("cleared all that");
        // return no. adv held * rate *days since last updated
        return
            (accum * BASE_RATE * (block.timestamp - lastUpdate[user])) / 86400;
    }

    function setAllowedAddresses(
        address _address,
        bool _grant,
        bool _burn
    ) external onlyOwner {
        permsMap[_address].Grantee = _grant;
        permsMap[_address].Burner = _burn;
    }

    function toggleReward() public onlyOwner {
        rewardPaused = !rewardPaused;
    }
}