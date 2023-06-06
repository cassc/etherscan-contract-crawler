pragma solidity ^0.8.11;


interface ICurveGaugeController {
    function vote_user_slopes(address, address) external view returns (uint256, uint256, uint256);
}