// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./IBMICoverStaking.sol";

interface IBMICoverStakingView {
    function getPolicyBookAPY(address policyBookAddress, uint256 bmiPriceInUSDT)
        external
        view
        returns (uint256);

    function policyBookByNFT(uint256 tokenId) external view returns (address);

    function stakingInfoByStaker(
        address staker,
        address[] calldata policyBooksAddresses,
        uint256 bmiPriceInUSDT,
        uint256 offset,
        uint256 limit
    )
        external
        view
        returns (
            IBMICoverStaking.PolicyBookInfo[] memory policyBooksInfo,
            IBMICoverStaking.UserInfo[] memory usersInfo,
            uint256[] memory nftsCount,
            IBMICoverStaking.NFTsInfo[][] memory nftsInfo
        );

    function stakingInfoByToken(uint256 tokenId)
        external
        view
        returns (IBMICoverStaking.StakingInfo memory);

    // Not Migratable
    // function totalStaked(address user) external view returns (uint256);
    // function totalStakedSTBL(address user) external view returns (uint256);
    // function getStakerBMIProfit(address staker, address policyBookAddress, uint256 offset, uint256 limit) external view returns (uint256) ;
    // function getSlashedBMIProfit(uint256 tokenId) external view returns (uint256);
    // function getBMIProfit(uint256 tokenId) external view returns (uint256);
    // function uri(uint256 tokenId) external view returns (string memory);
    // function tokenOfOwnerByIndex(address user, uint256 index) external view returns (uint256);
    // function ownerOf(uint256 tokenId) external view returns (address);
    // function getSlashingPercentage() external view returns (uint256);
    // function getSlashedStakerBMIProfit( address staker, address policyBookAddress, uint256 offset, uint256 limit) external view returns (uint256 totalProfit) ;
    // function balanceOf(address user) external view returns (uint256);
    // function _aggregateForEach( address staker, address policyBookAddress, uint256 offset, uint256 limit, function(uint256) view returns (uint256) func) internal view returns (uint256 total);
    // function stakedByNFT(uint256 tokenId) external view returns (uint256);
    // function stakedSTBLByNFT(uint256 tokenId) external view returns (uint256);
}