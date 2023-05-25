pragma solidity 0.8.16;

interface IPRVRouter {
    function convertAndStake(uint256 amount) external;
    function convertAndStake(uint256 amount, address _receiver) external;
    function convertAndStakeWithSignature(
        uint256 amount,
        address _receiver,
        uint256 _deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}