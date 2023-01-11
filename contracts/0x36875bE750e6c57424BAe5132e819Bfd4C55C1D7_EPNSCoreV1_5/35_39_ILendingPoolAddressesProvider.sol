pragma solidity >=0.6.0 <0.7.0;

interface ILendingPoolAddressesProvider {
    function getLendingPoolCore() external view returns (address payable);

    function getLendingPool() external view returns (address);
}