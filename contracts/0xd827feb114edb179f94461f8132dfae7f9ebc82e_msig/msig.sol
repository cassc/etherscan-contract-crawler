/**
 *Submitted for verification at Etherscan.io on 2023-03-15
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

contract msig {
    //constants
    address _owner_1;
    address _owner_2;
    uint256 public unlock_time;
    uint256 max_unlock_time = 1797333460; // year 2027

    address[2] owners_arr;

    mapping(address => bool) public votes;

    constructor(address owner2, uint256 unlock_time_) {
        require((msg.sender != owner2) && (owner2 != address(0)));
        _owner_2 = owner2;
        owners_arr[1] = owner2;
        owners_arr[0] = msg.sender;
        require(unlock_time_ < max_unlock_time, "must be < max_unlock_time");
        unlock_time = unlock_time_;
    }

    function unlock() external onlyOwner {
        votes[msg.sender] = true;
    }

    function lock(uint256 ul_time) external onlyOwner {
        require(
            (ul_time < max_unlock_time) && (ul_time > unlock_time),
            "must be < max_unlock_time or must be > old_unlock_time"
        );
        unlock_time = ul_time;
        for (uint256 i = 0; i < owners_arr.length; i++) {
            votes[owners_arr[i]] = false;
        }
    }

    function check_unlocked() public view onlyOwner returns (bool) {
        for (uint256 i = 0; i < owners_arr.length; i++) {
            if (votes[owners_arr[i]] == false) {
                return false;
            }
        }
        return true;
    }

    modifier onlyOwner() {
        require(check_owner());
        _;
    }

    receive() external payable {}

    function check_owner() internal view returns (bool) {
        for (uint256 i = 0; i < owners_arr.length; i++) {
            if (msg.sender == owners_arr[i]) {
                return true;
            }
        }
        return false;
    }

    function withdraw_ETH(address destination_) external onlyOwner {
        if (check_unlocked() == true) {
            if (block.timestamp >= unlock_time) {
                payable(destination_).transfer(address(this).balance);
            }
        }
    }
}