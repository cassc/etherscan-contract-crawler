pragma solidity >=0.5.16;

interface IZirconFactory {
    function energyFactory() external view returns (address);

    function getPair(address, address) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function dynamicRatio() external view returns (uint);
    function liquidityFee() external view returns (uint);
    function setLiquidityFee(uint _liquidityFee) external;

    function pairCodeHash() external pure returns (bytes32);
    function createPair(address tokenA, address tokenB, address _pylonFactory) external returns (address pair);

    function setMigrator(address _migrator) external;
    function setFeeToSetter(address _feeToSetter) external;
    function changeEnergyRevAddress(address _pairAddress, address _tokenA, address _tokenB, address _pylonFactory) external returns (address newEnergy);

    function changeEnergyFactoryAddress(address _newEnergyFactory) external;
    function setDynamicRatio(uint _dynamicRatio) external;
}