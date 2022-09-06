pragma solidity >=0.5.16;

interface IOracle {
    function isExpired() external view returns (bool);

    function isRedeemable(bool future0) external view returns (bool);
}