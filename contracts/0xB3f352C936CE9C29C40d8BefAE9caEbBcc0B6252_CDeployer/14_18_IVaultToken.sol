pragma solidity >=0.5.0;

interface IVaultToken {

    function isVaultToken() external pure returns (bool);

    function getScale() external view returns (uint);
}