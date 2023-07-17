pragma solidity 0.8.8;

/**
 * @title Interface for IELRewardFactory
 * @notice EL Reward factory
 */

interface IELRewardFactory {
    /**
     * @notice create vault contract proxy
     * @param _operatorId operator id
     * @param _manager func manager
     */
    function create(uint256 _operatorId, address _manager) external returns (address);

    event ELRewardProxyDeployed(address _proxyAddress);
    event DaoAddressChanged(address _oldDao, address _dao);
}