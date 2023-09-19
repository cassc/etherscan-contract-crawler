// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import {ID3MM} from "../intf/ID3MM.sol";
import {ID3Maker} from "../intf/ID3Maker.sol";
import {ID3Vault} from "../intf/ID3Vault.sol";
import {InitializableOwnable} from "../lib/InitializableOwnable.sol";
import {ICloneFactory} from "../lib/CloneFactory.sol";

/**
 * @title D3MMFactory
 * @author DODO Breeder
 * @notice This factory contract is used to create/register D3MM pools.
 */
contract D3MMFactory is InitializableOwnable {
    // different index means different tmeplate, 0 is for normal d3 pool.
    mapping(uint256 => address) public _D3POOL_TEMPS;
    mapping(uint256 => address) public _D3MAKER_TEMPS_;
    address public _CLONE_FACTORY_;
    address public _ORACLE_;
    ID3Vault public d3Vault;
    address public _FEE_RATE_MODEL_;
    address public _MAINTAINER_;

    // ============ Events ============

    event D3Birth(address newD3, address creator);
    event AddRouter(address router);
    event RemoveRouter(address router);

    // ============ Constructor Function ============

    constructor(
        address owner,
        address[] memory d3Temps,
        address[] memory d3MakerTemps,
        address cloneFactory,
        address d3VaultAddress,
        address oracleAddress,
        address feeRateModel,
        address maintainer
    ) {
        require(d3MakerTemps.length == d3Temps.length, "temps not match");

        for (uint256 i = 0; i < d3Temps.length; i++) {
            _D3POOL_TEMPS[i] = d3Temps[i];
            _D3MAKER_TEMPS_[i] = d3MakerTemps[i];
        }
        _CLONE_FACTORY_ = cloneFactory;
        _ORACLE_ = oracleAddress;
        d3Vault = ID3Vault(d3VaultAddress);
        _FEE_RATE_MODEL_ = feeRateModel;
        _MAINTAINER_ = maintainer;
        initOwner(owner);
    }

    // ============ Admin Function ============

    /// @notice Set new D3MM template
    function setD3Temp(uint256 poolType, address newTemp) public onlyOwner {
        _D3POOL_TEMPS[poolType] = newTemp;
    }
    /// @notice Set new D3Maker template
    function setD3MakerTemp(uint256 poolType, address newMakerTemp) public onlyOwner {
        _D3MAKER_TEMPS_[poolType] = newMakerTemp;
    }

    /// @notice Set new CloneFactory contract address
    function setCloneFactory(address cloneFactory) external onlyOwner {
        _CLONE_FACTORY_ = cloneFactory;
    }

    /// @notice Set new oracle
    function setOracle(address oracle) external onlyOwner {
        _ORACLE_ = oracle;
    }
    /// @notice Set new maintainer
    function setMaintainer(address maintainer) external onlyOwner {
        _MAINTAINER_ = maintainer;
    }
    /// @notice Set new feeRateModel
    function setFeeRate(address feeRateModel) external onlyOwner {
        _FEE_RATE_MODEL_ = feeRateModel;
    }

    // ============ Breed DODO Function ============

    /// @notice Create new D3MM pool and maker, and register to vault
    /// @param poolCreator Pool owner
    /// @param maker Maker owner
    /// @param maxInterval Maximum interval for heartbeat detection.
    /// @param poolType Pool template type.
    /// @return newPool New pool address
    function breedD3Pool(
        address poolCreator,
        address maker,
        uint256 maxInterval,
        uint256 poolType
    ) external onlyOwner returns (address newPool) {
        address newMaker = ICloneFactory(_CLONE_FACTORY_).clone(_D3MAKER_TEMPS_[poolType]);
        newPool = ICloneFactory(_CLONE_FACTORY_).clone(_D3POOL_TEMPS[poolType]);

        ID3MM(newPool).init(
            poolCreator,
            newMaker,
            address(d3Vault),
            _ORACLE_,
            _FEE_RATE_MODEL_,
            _MAINTAINER_
        );
        
        ID3Maker(newMaker).init(maker, newPool, maxInterval);

        d3Vault.addD3PoolByFactory(newPool);

        emit D3Birth(newPool, poolCreator);
        return newPool;
    }
}