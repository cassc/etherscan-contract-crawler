pragma solidity 0.7.6;

interface IOnwardIncentivesController {
    function handleAction(
        address _user,
        uint256 _balance,
        uint256 _totalSupply
    ) external;
}