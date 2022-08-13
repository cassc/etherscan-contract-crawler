// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
* @notice IStakeAirdropFactory
*/
interface IStakeAirdropFactory {

    /**
    * @notice the number of cycles, current cycleId.
    * @return cycles.
    */
    function totalCycle() external view returns (uint256);

    /**
    * @notice the address of the cycle.
    * @param cycleId_ uint256
    * @return address of the cycle.
    */
    function addressOf(uint256 cycleId_) external view returns (address);

    /**
    * @notice set proxy admin.
    * @param proxyAdmin_ address
    */
    function setProxyAdmin(address proxyAdmin_) external;

    /**
    * @notice reset the cycleAddress.
    * @param cycleId_ uint256
    * @param stakeAirdrop_ address
    */
    function reset(uint256 cycleId_, address stakeAirdrop_) external;

    /**
    * @notice create a new cycle.
    * @param airdropToken_ address
    * @param stakeToken_ address
    * @return address of the cycle proxy.
    */
    function createCycle(address airdropToken_, address stakeToken_ ) external returns(address);
    
}