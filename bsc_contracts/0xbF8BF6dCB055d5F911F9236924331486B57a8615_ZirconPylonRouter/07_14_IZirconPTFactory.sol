pragma solidity >=0.5.16;

interface IZirconPTFactory {
    function getPoolToken(address pylon, address token) external view returns (address pt);
    function createPTAddress(address _floatToken, address _anchorToken, address pylonAddress, bool isAnchor) external returns (address poolToken);
    function changePylonAddress(address oldPylon, address tokenA, address tokenB, address newPylon, address pylonFactory) external;
    function setMigrator(address _migrator) external;
    function setFeeToSetter(address _feeToSetter) external;
}