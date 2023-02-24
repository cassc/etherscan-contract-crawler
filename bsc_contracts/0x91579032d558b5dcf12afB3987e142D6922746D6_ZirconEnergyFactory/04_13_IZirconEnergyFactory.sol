pragma solidity =0.5.16;

interface IZirconEnergyFactory {

    // Variables
    function allEnergies(uint p) external view returns (address);
    function insurancePerMille() external view returns (uint);
    function feePercentageRev() external view returns (uint);
    function feePercentageEnergy() external view returns (uint);
    function getEnergy(address _tokenA, address _tokenB) external view returns (address energy);
    function getEnergyRevenue(address _tokenA, address _tokenB) external view returns (address energy);
    function allEnergiesLength() external view returns (uint);
    function feeToSetter() external pure returns (address);
    function setMigrator(address _migrator) external;
    function setFeeToSetter(address _feeToSetter) external;
    function setInsurancePerMille(uint _insurancePerMille) external;
    function setFeePercentageRev(uint fee) external;
    function setFeePercentageEnergy(uint fee) external;
    // Functions
    function createEnergy(address, address, address, address) external returns (address energy);
    function createEnergyRev(address, address, address, address) external returns (address energy);
    function setFee(uint112 _minPylonFee, uint112 _maxPylonFee) external;
    function getMinMaxFee() external view returns (uint112 minFee, uint112 maxFee);
    function getFees(address _token, uint _amount, address _to, address energyRev) external;
    function migrateEnergyLiquidity(address pair, address token, address newEnergy) external;
    function migrateEnergyRevenue(address oldEnergy, address newEnergy) external;
    function migrateEnergyRevenueFees(address oldEnergy, address newEnergy) external;
    function migrateEnergy(address oldEnergy, address newEnergy) external;

}