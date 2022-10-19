// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./interfaces/IPoolFactory.sol";
import "./interfaces/IPoolMaster.sol";

contract ClearpoolLens {
    /// @notice PooLFactory contract
    IPoolFactory public factory;

    /// @notice Contract constructor
    /// @param factory_ Address of the PoolFactory contract
    constructor(IPoolFactory factory_) {
        factory = factory_;
    }

    /// @notice Function that calculates poolsize-weighted index of pool supply APRs
    /// @return rate Supply rate (APR) index
    function getSupplyRateIndex() external view returns (uint256 rate) {
        address[] memory pools = factory.getPools();
        uint256 totalPoolSize = 0;
        for (uint256 i = 0; i < pools.length; i++) {
            IPoolMaster pool = IPoolMaster(pools[i]);
            uint256 poolSize = pool.poolSize();

            totalPoolSize += poolSize;
            rate += pool.getSupplyRate() * poolSize;
        }
        rate /= totalPoolSize;
    }

    /// @notice Function that calculates poolsize-weighted index of pool borrow APRs
    /// @return rate Borrow rate (APR) index
    function getBorrowRateIndex() external view returns (uint256 rate) {
        address[] memory pools = factory.getPools();
        uint256 totalPoolSize = 0;
        for (uint256 i = 0; i < pools.length; i++) {
            IPoolMaster pool = IPoolMaster(pools[i]);
            uint256 poolSize = pool.poolSize();

            totalPoolSize += poolSize;
            rate += pool.getBorrowRate() * poolSize;
        }
        rate /= totalPoolSize;
    }

    /// @notice Function that calculates total amount of liquidity in all active pools
    /// @return liquidity Total liquidity
    function getTotalLiquidity() external view returns (uint256 liquidity) {
        address[] memory pools = factory.getPools();
        for (uint256 i = 0; i < pools.length; i++) {
            IPoolMaster pool = IPoolMaster(pools[i]);
            liquidity +=
                pool.cash() +
                pool.borrows() -
                pool.insurance() -
                pool.reserves();
        }
    }

    /// @notice Function that calculates total amount of interest accrued in all active pools
    /// @return interest Total interest accrued
    function getTotalInterest() external view returns (uint256 interest) {
        address[] memory pools = factory.getPools();
        for (uint256 i = 0; i < pools.length; i++) {
            interest += IPoolMaster(pools[i]).interest();
        }
    }

    /// @notice Function that calculates total amount of borrows in all active pools
    /// @return borrows Total borrows
    function getTotalBorrows() external view returns (uint256 borrows) {
        address[] memory pools = factory.getPools();
        for (uint256 i = 0; i < pools.length; i++) {
            borrows += IPoolMaster(pools[i]).borrows();
        }
    }

    /// @notice Function that calculates total amount of principal in all active pools
    /// @return principal Total principal
    function getTotalPrincipal() external view returns (uint256 principal) {
        address[] memory pools = factory.getPools();
        for (uint256 i = 0; i < pools.length; i++) {
            principal += IPoolMaster(pools[i]).principal();
        }
    }

    /// @notice Function that calculates total amount of reserves in all active pools
    /// @return reserves Total reserves
    function getTotalReserves() external view returns (uint256 reserves) {
        address[] memory pools = factory.getPools();
        for (uint256 i = 0; i < pools.length; i++) {
            reserves += IPoolMaster(pools[i]).reserves();
        }
    }
}