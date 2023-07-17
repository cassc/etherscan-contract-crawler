// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract IAKCCore {
    /** VARIABLES */
    function userToEarnings(address user) external returns(uint256) {}
    function userToAKC(address user, uint256 spec) external view returns (uint256) {}
    function getLastClaimedOfUser(address tribeOwner) external view returns(uint256) {}
    function userToTribes(address user, uint256 index) external view returns(uint256) {}
    function tribeSpecs(uint256 index) external view returns(uint256, uint256, string memory) {}

    function affiliatePercentage() external returns(uint256) {}
    function akcStakeBoost() external view returns (uint256) {}
    function affiliateKickback() external returns(uint256) {}

    /** CREATING */
     function createManyTribes(address[] calldata newOwners, uint256[] calldata specs)
        external {}

    /** CLAIMING */
    function claimAllRewards(address tribeOwner)
        external returns(uint256) {}

    /** STAKING */
    function stakeAKC(address staker, uint256 akcId, uint256 spec) external {}
    function unstakeAKC(address staker, uint256 akcId, uint256 spec) external {}

    /** AFFILIATE */
    function registerAffiliate(address affiliate, uint256 earned) external {}

    /** GETTERS */
    function getSpecFromTribe(uint256 tribe)
        public
        pure
        returns(uint256) {}

    function getAkcIdFromAKCData(uint256 akcData)
        public
        pure
        returns(uint256) {}

    function getLastClaimedTimeFromTribe(uint256 tribe)
        public
        pure
        returns(uint256) {}

    function getCreatedAtFromTribe(uint256 tribe)
        public
        pure
        returns(uint256) {}

    /** VIEWING */
     function getTribeAmount(address tribeOwner)
        external
        view
        returns(uint256) {}

    function getTribeSpecAmount()
        external
        view 
        returns(uint256) {}
    
    function getTotalTribesByspec(address tribeOwner, uint256 spec)
        public
        view
        returns(uint256) {}
    
    function getAllRewards(address tribeOwner)
        external
        view
        returns(uint256) {}

    function getDiscountFactor(address tribeOwner)
        external
        view
        returns(uint256) {}

    function getCapsuleRewards(address capsuleOwner, uint256 timestamp)
        public
        view
        returns(uint256) {}
}