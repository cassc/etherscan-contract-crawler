/**
 *Submitted for verification at Etherscan.io on 2023-05-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract ChefInfo {

    ICigToken constant public cig = ICigToken(0xCB56b52316041A62B6b5D0583DcE4A8AE7a3C629);

    // so that CIG can be used on Snapshot.org with the masterchef strategy
    // https://github.com/snapshot-labs/snapshot-strategies/blob/master/src/strategies/masterchef-pool-balance/index.ts can work
    function userInfo(uint256, address _a) external view returns (uint256, uint256) {
        return cig.farmers(_a);
    }

}

interface ICigToken {
    function farmers(address) external view returns (uint256, uint256);
}