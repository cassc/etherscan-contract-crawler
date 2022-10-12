pragma solidity ^0.8.0;

interface IMisoCrowdsale {
    function tokensClaimable(address _user) external view returns (uint256 claimerCommitment);
    function commitments(address user) external view returns (uint256 amount);
    function withdrawTokens(address user) external;
    function getTokenAmount(uint256 _amount) external view returns (uint256);
    function paymentCurrency() external view returns (address);
}