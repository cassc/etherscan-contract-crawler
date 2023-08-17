pragma solidity 0.8.19;

import "../Staking.sol";
import "../Distributor.sol";

contract StakingAndDistributorFactory {
    address private immutable QWAFactory;

    constructor(address _qwaFactory) {
        QWAFactory = _qwaFactory;
    }

    function create(
        address _qwa,
        address _sQWA,
        address _treasury,
        address _owner
    ) external returns (address _stakingAddress, address _distributorAddress) {
        require(msg.sender == QWAFactory, "msg.sender not QWA Factory");
        QWAStaking _staking = new QWAStaking(_qwa, _sQWA, 8 hours, 1 days);

        Distributor _distributor = new Distributor(
            _treasury,
            _qwa,
            address(_staking)
        );

        _staking.setDistributor(address(_distributor));

        _distributor.setRate(10000);

        _staking.transferOwnership(_owner);
        _distributor.transferOwnership(_owner);

        return (address(_staking), address(_distributor));
    }
}