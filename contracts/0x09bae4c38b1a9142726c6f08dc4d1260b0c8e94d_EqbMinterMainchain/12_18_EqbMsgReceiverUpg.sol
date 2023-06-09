// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../Interfaces/IEqbMsgReceiver.sol";
import "../Dependencies/Errors.sol";

abstract contract EqbMsgReceiverUpg is IEqbMsgReceiver, OwnableUpgradeable {
    address public eqbMsgReceiveEndpoint;

    uint256[100] private __gap;

    modifier onlyFromEqbMsgReceiveEndpoint() {
        if (msg.sender != eqbMsgReceiveEndpoint)
            revert Errors.MsgNotFromReceiveEndpoint(msg.sender);
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function __EqbMsgReceiver_init(
        address _eqbMsgReceiveEndpoint
    ) internal onlyInitializing {
        __EqbMsgReceiver_init_unchained(_eqbMsgReceiveEndpoint);
    }

    function __EqbMsgReceiver_init_unchained(
        address _eqbMsgReceiveEndpoint
    ) internal onlyInitializing {
        __Ownable_init_unchained();

        eqbMsgReceiveEndpoint = _eqbMsgReceiveEndpoint;
    }

    function executeMessage(
        uint256 _srcChainId,
        address _srcAddr,
        bytes calldata _message
    ) external virtual onlyFromEqbMsgReceiveEndpoint {
        _executeMessage(_srcChainId, _srcAddr, _message);
    }

    function _executeMessage(
        uint256 _srcChainId,
        address _srcAddr,
        bytes memory _message
    ) internal virtual;
}