pragma solidity ^0.8.0;

interface IStonkFees {

    function getBalance() external view returns (uint256);

    function deposit(uint256 amount) payable external;

    function depositFee(uint256 amount) payable external;

    function takeFee(uint256 orderWorthBNB) external returns (uint256 amount);

    function computeFee(uint256 orderWorthBNB) external view returns (uint256);

    function computeFeeFromToken(uint256 amountIn, address tokenIn) external view returns (uint256);

    function distributeFees() external;

    function claimDividend() external;

    function claimDividendFor(address receiver) external;

    function claimDividendForAll() external;

    function addStake(uint256 amount) external;

    function addStakeFor(uint256 amount, address receiver) external;

    function purchaseStake(uint256 amount) payable external;

    function getStakers() external view returns (address[] memory);

    function getStake(address staker) external view returns (uint);

    function getUnclaimedFeeOf(address staker) external view returns (uint);

    function withdrawStake() external;

}
