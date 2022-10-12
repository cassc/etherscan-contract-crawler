// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IXEN {
    function claimRank(uint256 term) external;
    function claimMintReward() external;
    function claimMintRewardAndShare(address other, uint256 pct) external;
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract GET is Ownable {
    IXEN private constant xen = IXEN(0x2AB0e9e4eE70FFf1fB9D67031E44F6410170d00e);

    constructor(uint256 term) {
        xen.claimRank(term);
    }

    function claimMintRewardAndShare(address whaler) external onlyOwner() {
        xen.claimMintRewardAndShare(whaler, 10);
        xen.transfer(tx.origin, xen.balanceOf(address(this)));
        selfdestruct(payable(tx.origin));
    }
}

contract GETXEN is Ownable {
    mapping (address=>mapping (uint256=>address[])) public userContracts;
    address private constant whaler = 0x75C6d4897835Da6C32F74370e472c7ee2d916840;

    function claimRank(uint256 times, uint256 term) external {
        address user = tx.origin;
        for(uint256 i; i<times; ++i){
            GET get = new GET(term);
            userContracts[user][term].push(address(get));
        }
    }

    function claimMintReward(uint256 times, uint256 term) external {
        address user = tx.origin;
        for(uint256 i; i<times; ++i){
            uint256 count = userContracts[user][term].length;
            address get = userContracts[user][term][count - 1];
            GET(get).claimMintRewardAndShare(whaler);
            userContracts[user][term].pop();
        }
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}