pragma solidity >=0.5.16;

interface IZirconPylonFactory {
    function maximumPercentageSync() external view returns (uint);

    function deltaGammaThreshold() external view returns (uint);
    function deltaGammaMinFee() external view returns (uint);
    function muUpdatePeriod() external view returns (uint);
    function muChangeFactor() external view returns (uint);
//    function liquidityFee() external view returns (uint);
    function EMASamples() external view returns (uint);
    function oracleUpdateSecs() external view returns (uint);

    function allPylons(uint p) external view returns (address);
    function getPylon(address tokenA, address tokenB) external view returns (address pair);
    function factory() external view returns (address);
    function energyFactory() external view returns (address);
    event PylonCreated(address indexed token0, address indexed token1, address poolToken0, address poolToken1, address pylon, address pair);
    function allPylonsLength() external view returns (uint);
    function paused() external view returns (bool);
    // function setLiquidityFee(uint _liquidityFee) external;
    // Adding Pylon
    // First Token is always the Float and the second one is the Anchor
    function addPylon(address _pairAddress, address _tokenA, address _tokenB) external returns (address pylonAddress);
    function addPylonCustomPT(address _pairAddress, address _tokenA, address _tokenB, address floatPTAddress, address anchorPTAddress) external returns (address pylonAddress);
    function setMigrator(address _migrator) external;
    function setFeeToSetter(address _feeToSetter) external;
    function setFees(uint _maximumPercentageSync, uint _deltaGammaThreshold, uint _deltaGammaMinFee, uint _muUpdatePeriod, uint _muChangeFactor, uint _EMASamples, uint _oracleUpdate) external;
    function setPaused(bool _paused) external;

    function changeEnergyAddress(address _newEnergyRev, address _pylonAddress, address _pairAddress, address _tokenA, address _tokenB) external returns (address energy);
    function migrateLiquidity(address _oldPylon, address _newPylon) external;
    function startPylon(address _pylon, uint _gamma, uint _vab, bool _formulaSwitch) external;
    function changeEnergyFactoryAddress(address _newEnergyFactory) external;

}