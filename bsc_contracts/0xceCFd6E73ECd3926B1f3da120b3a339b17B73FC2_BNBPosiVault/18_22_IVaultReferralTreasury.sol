pragma solidity ^0.8.0;

interface IVaultReferralTreasury {
    function payReferralCommission(address _address, uint256 _rewards) external returns (bool);
}