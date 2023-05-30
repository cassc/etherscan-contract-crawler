pragma solidity >=0.4.24;

interface IGasMining {
    // Views

    function rewardPerToken() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function totalFundETH() external view returns (uint256);

    // function withdrawableETH(uint256 amount) external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    // Mutative

    function stake() external payable;

    function withdraw(uint256 amount) external;

    function getReward() external;

    function exit() external;
}