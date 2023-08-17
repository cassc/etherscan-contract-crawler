pragma solidity 0.8.19;

import "../Treasury.sol";
import "../token/sQWA.sol";
import "../interface/factory/IQWAFactory.sol";

contract TreasuryAndStakedTokenFactory {
    address private immutable QWAFactory;

    constructor(address _qwaFactory) {
        QWAFactory = _qwaFactory;
    }

    function create(
        address _qwa,
        address[] calldata _backingTokens,
        uint256[] calldata _backingAmounts,
        string[2] memory _nameAndSymbol,
        bool _qwnBackingToken
    ) external returns (address _treasuryAddress, address _sQWAAddress) {
        require(msg.sender == QWAFactory, "msg.sender not QWA Factory");
        QWATreasury _treasury = new QWATreasury(
            IQWAFactory(QWAFactory).QWN(),
            IQWAFactory(QWAFactory).sQWN(),
            IQWAFactory(QWAFactory).QWNStaking(),
            _qwa,
            IQWAFactory(QWAFactory).WETH(),
            _backingTokens,
            _backingAmounts,
            _qwnBackingToken
        );

        _nameAndSymbol[0] = string.concat("Staked ", _nameAndSymbol[0]);
        _nameAndSymbol[1] = string.concat("s", _nameAndSymbol[1]);

        sQWA _sQWA = new sQWA(_nameAndSymbol[0], _nameAndSymbol[1]);

        return (address(_treasury), address(_sQWA));
    }

    function setDistributorAndInitialize(
        address _distributor,
        address _staking,
        QWATreasury _treasury,
        sQWA _sQWA,
        address _owner
    ) external {
        require(msg.sender == QWAFactory, "msg.sender not QWA Factory");

        _treasury.setDistributor(_distributor);
        _sQWA.initialize(_staking);

        _treasury.transferOwnership(_owner);
    }
}