// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.15;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "../lib/Ownable.sol";

/**
 * @title Allows the owner to whitelist remote ExecutionNode addresses
 * @author Padoriku
 */
abstract contract RemoteExecutionNodeRegistry is Ownable, Initializable {
    // chainId => address mapping
    mapping(uint64 => address) public remotes;

    event RemotesUpdated(uint64[] chainIds, address[] remotes);

    function setRemotes(uint64[] memory _chainIds, address[] memory _remotes) external onlyOwner {
        _setRemotes(_chainIds, _remotes);
    }

    function _setRemotes(uint64[] memory _chainIds, address[] memory _remotes) private {
        require(_chainIds.length == _remotes.length, "remotes length mismatch");
        for (uint256 i = 0; i < _chainIds.length; i++) {
            remotes[_chainIds[i]] = _remotes[i];
        }
        emit RemotesUpdated(_chainIds, _remotes);
    }

    modifier onlyRemoteExecutionNode(uint64 _chainId, address _remote) {
        requireRemoteExecutionNode(_chainId, _remote);
        _;
    }

    function requireRemoteExecutionNode(uint64 _chainId, address _remote) internal view {
        require(remotes[_chainId] == _remote, "unknown remote");
    }
}