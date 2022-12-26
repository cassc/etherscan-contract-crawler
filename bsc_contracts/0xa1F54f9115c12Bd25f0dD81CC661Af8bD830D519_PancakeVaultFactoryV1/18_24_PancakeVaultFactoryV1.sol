pragma solidity ^0.8.0;

import './interfaces/IRiveraAutoCompoundingVaultFactoryV1.sol';
import './interfaces/IPancakeFactory.sol';
import './strategies/cake/interfaces/IMasterChef.sol';
import './strategies/common/interfaces/IStrategy.sol';
import './vaults/RiveraAutoCompoundingVaultV1.sol';
import './strategies/cake/CakeLpStakingV1.sol';
import './strategies/common/AbstractStrategy.sol';

contract PancakeVaultFactoryV1 is IRiveraAutoCompoundingVaultFactoryV1 {

    address[] public allVaults;

    ///@notice fixed params that are required to deploy the pool
    address chef;
    address router;
    address pancakeFactory;
    address manager;

    constructor(address _chef, address _router, address _pancakeFactory) {
        chef = _chef;
        router = _router;
        pancakeFactory = _pancakeFactory;
        manager = msg.sender;
    }

    function createVault(CreateVaultParams memory createVaultParams) external returns (address vaultAddress) {
        address lpToken0 = createVaultParams.rewardToLp0Route[createVaultParams.rewardToLp0Route.length - 1];
        address lpToken1 = createVaultParams.rewardToLp1Route[createVaultParams.rewardToLp1Route.length - 1];
        address lpPool = IPancakeFactory(pancakeFactory).getPair(lpToken0, lpToken1);
        require(IMasterChef(chef).poolLength() >= createVaultParams.poolId, 'INVALID_POOL_ID');
        require(lpToken0 != address(0), 'LP_TOKEN0_ZERO_ADDRESS');
        RiveraAutoCompoundingVaultV1 vault = new RiveraAutoCompoundingVaultV1(createVaultParams.tokenName, createVaultParams.tokenSymbol, createVaultParams.approvalDelay);
        vaultAddress = address(vault);
        CakeLpStakingV1 strategy = new CakeLpStakingV1(CakePoolParams(lpPool, createVaultParams.poolId, chef, createVaultParams.rewardToLp0Route, createVaultParams.rewardToLp1Route), 
                                                        CommonAddresses(vaultAddress, router, manager));
        vault.transferOwnership(msg.sender);
        strategy.transferOwnership(msg.sender);
        vault.init(IStrategy(address(strategy)));
        allVaults.push(vaultAddress);
        emit VaultCreated(msg.sender, lpPool, createVaultParams.poolId, vaultAddress);
    }

    function listAllVaults() external view returns (address[] memory) {
        return allVaults;
    }

}