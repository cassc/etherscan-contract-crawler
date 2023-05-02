pragma solidity ^0.6.0;


abstract contract ITap {
     function updateBeneficiary(address _beneficiary) external virtual;
     function updateMaximumTapRateIncreasePct(uint256 _maximumTapRateIncreasePct) external virtual;
     function updateMaximumTapFloorDecreasePct(uint256 _maximumTapFloorDecreasePct) external virtual;
     function addTappedToken(address _token, uint256 _rate, uint256 _floor) external virtual;
     function updateTappedToken(address _token, uint256 _rate, uint256 _floor) external virtual;
     function resetTappedToken(address _token) external virtual;
     function updateTappedAmount(address _token) external virtual;
     function withdraw(address _token, uint _amount) external virtual;
     function getMaximumWithdrawal(address _token) public view virtual returns (uint256);
     function getRates(address _token) public view virtual returns (uint256);
 }