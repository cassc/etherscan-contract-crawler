pragma experimental ABIEncoderV2;
pragma solidity ^0.7.6;
import "./IERC20Upgradeable.sol";
interface IRebasingLiquidityToken is IERC20Upgradeable {
    function tokenCaller() external;
    function reserveCaller(uint256,uint256) external;
    function wrapWithReturn() external returns (uint256);
    function wrap() external;
    function rlpPerLP() external view returns (uint256);
}