pragma solidity >=0.5.0;

interface IThenaGauge {
    function notifyRewardAmount(address token, uint amount) external;
    function getReward() external;
    function claimFees() external returns (uint claimed0, uint claimed1);
    function isForPair() external view returns (bool);
    function earned(address account) external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external;
}