// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.7.6;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {IUniswapV3Factory} from '@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol';
import {IICHIVaultFactory} from "../../interfaces/IICHIVaultFactory.sol";
import {IVaultCreate} from "../../interfaces/IVaultCreate.sol";

interface IICHIVault{

    function setAffiliate(address _affiliate) external;
    
    function setHysteresis(uint256 _hysteresis) external;

    function transferOwnership(address _owner) external;
}

contract VaultCreate is IVaultCreate, Ownable {

    address public override affiliate;
    uint256 public override hysteresis;
    address public override defaultVaultOwner;

    address public immutable override uniswapV3Factory;
    address public immutable override ichiVaultsFactory;

    constructor(
        address _affiliate,
        uint256 _hysteresis,
        address _uniswapV3Factory,
        address _ichiVaultsFactory,
        address _defaultVaultOwner
    ) {
        affiliate = _affiliate;
        hysteresis = _hysteresis;
        uniswapV3Factory = _uniswapV3Factory;
        ichiVaultsFactory = _ichiVaultsFactory;
        defaultVaultOwner = _defaultVaultOwner;
    }

    /// @notice Create a new vault
    /// @param depositToken The token to be deposited to the vault
    /// @param quoteToken The token the deposit token is trade with in the uniswap pool
    /// @param fee The fee of the uniswap pool
    /// @param minObservations The min number of observations the pool will be at.  The vaults require at least 60.  
    function createVault(
        address depositToken,
        address quoteToken,
        uint24 fee,
        uint16 minObservations
    ) external override returns(address vault) {

        require(minObservations < 600, "VaultCreate: minObservations has to be less than 600");

        address pool = IUniswapV3Factory(uniswapV3Factory).getPool(depositToken, quoteToken, fee);

        (/*uint160 sqrtPriceX96*/,
         /*int24 tick*/,
         /*uint16 observationIndex*/,
         /*uint16 observationCardinality*/,
         uint16 observationCardinalityNext,
         /*uint8 feeProtocol*/,
         /*bool unlocked*/
        ) = IUniswapV3Pool(pool).slot0();

        if (minObservations > observationCardinalityNext) {
            IUniswapV3Pool(pool).increaseObservationCardinalityNext(minObservations);
        }

        vault = IICHIVaultFactory(ichiVaultsFactory)
                        .createICHIVault(depositToken,true,quoteToken,false,fee);

        IICHIVault(vault).setAffiliate(affiliate);
        IICHIVault(vault).setHysteresis(hysteresis);
        IICHIVault(vault).transferOwnership(defaultVaultOwner);

        emit VaultCreated(vault);
    }

    /// @notice Set the affiliate address
    /// @param _affiliate The address of the affiliate
    function setAffiliate(address _affiliate) external override onlyOwner {
        affiliate = _affiliate;

        emit AffiliateUpdated(affiliate);
    }

    /// @notice Set the hysteresis
    /// @param _hysteresis The hysteresis
    function setHysteresis(uint256 _hysteresis) external override onlyOwner {
        hysteresis = _hysteresis;

        emit HysteresisUpdated(hysteresis);
    }

    /// @notice Set the default vault owner
    /// @param _defaultVaultOwner The address of the default vault owner
    function setDefaultVaultOwner(address _defaultVaultOwner) external override onlyOwner {
        defaultVaultOwner = _defaultVaultOwner;

        emit DefaultVaultOwnerUpdated(defaultVaultOwner);
    }
}