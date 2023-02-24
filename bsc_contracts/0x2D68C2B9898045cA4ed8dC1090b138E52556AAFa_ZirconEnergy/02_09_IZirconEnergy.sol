pragma solidity =0.5.16;

interface IZirconEnergy {
    function initialize(address _pylon, address _pair, address _token0, address _token1) external;
    function getFeeByGamma(uint gammaMulDecimals) external view returns (uint amount);
    function registerFee() external;
    function migrateLiquidity(address newEnergy) external;
    function _updateMu(uint muUpdatePeriod, uint muChangeFactor, uint muBlockNumber, uint muMulDecimals, uint gammaMulDecimals, uint muOldGamma) external returns (uint mu);
    function handleOmegaSlashing(uint ptu, uint omegaMulDecimals, bool isFloatReserve0, address _to) external returns (uint retPTU, uint amount);
}