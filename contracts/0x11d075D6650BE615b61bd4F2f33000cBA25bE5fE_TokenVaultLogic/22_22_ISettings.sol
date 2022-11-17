//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISettings {
    // interface
    function weth() external view returns (address);

    function minBidIncrease() external view returns (uint256);

    function minVotePercentage() external view returns (uint256);

    function maxExitFactor() external view returns (uint256);

    function minExitFactor() external view returns (uint256);

    function feeReceiver() external view returns (address payable);

    function feePercentage() external view returns (uint256);

    function exitFeeForCuratorPercentage() external view returns (uint256);

    function exitFeeForPlatformPercentage() external view returns (uint256);

    function presaleFeePercentage() external view returns (uint256);

    function reduceStep() external view returns (uint256);

    function auctionLength() external view returns (uint256);

    function auctionExtendLength() external view returns (uint256);

    function votingQuorumPercent() external view returns (uint256);

    function votingMinTokenPercent() external view returns (uint256);

    function votingDelayBlock() external view returns (uint256);

    function votingPeriodBlock() external view returns (uint256);

    function term1Duration() external view returns (uint256);

    function term2Duration() external view returns (uint256);

    function epochDuration() external view returns (uint256);

    function nftOracle() external view returns (address);

    function flashLoanAdmin() external view returns (address);

    function bnftURI() external view returns (string memory);

    function vaultTpl() external view returns (address);

    function stakingTpl() external view returns (address);

    function treasuryTpl() external view returns (address);

    function governmentTpl() external view returns (address);

    function exchangeTpl() external view returns (address);

    function bnftTpl() external view returns (address);

    function getGovernorSetting(address[] memory nftAddrslist)
        external
        view
        returns (
            address,
            address,
            uint256,
            uint256
        );
     function checkGovernorSetting(address[] memory nftAddrslist)
        external
        view
        returns (
          bool
        );
}