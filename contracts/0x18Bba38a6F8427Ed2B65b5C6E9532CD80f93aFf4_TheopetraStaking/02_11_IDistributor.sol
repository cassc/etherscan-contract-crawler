// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.7.5 <=0.8.10;

interface IDistributor {
    function distribute() external;

    function bounty() external view returns (uint256);

    function retrieveBounty() external returns (uint256);

    function nextRewardAt(uint256 _rate, address _recipient) external view returns (uint256);

    function nextRewardFor(address _recipient) external view returns (uint256);

    function nextRewardRate(uint256 _index) external view returns (uint256);

    function setBounty(uint256 _bounty) external;

    function addRecipient(
        address _recipient,
        uint256 _startRate,
        int256 _drs,
        int256 _dys,
        bool _locked
    ) external;

    function removeRecipient(uint256 _index) external;

    function setDiscountRateStaking(uint256 _index, int256 _drs) external;

    function setDiscountRateYield(uint256 _index, int256 _dys) external;

    function setStaking(address _addr) external;
}