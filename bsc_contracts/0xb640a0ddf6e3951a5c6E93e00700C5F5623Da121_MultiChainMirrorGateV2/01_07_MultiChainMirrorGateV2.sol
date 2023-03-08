// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import "./multichain/IAnyswapV6CallProxy.sol";
import "./multichain/IApp.sol";

struct LockedBalance {
    int128 amount;
    uint256 end;
}

struct MirroredChain {
    uint256 chain_id;
    uint256 escrow_count;
}

interface IVotingEscrow {
    function locked(address _user) external view returns(LockedBalance memory);
}

interface IMirroredVotingEscrow {

    function voting_escrows(uint256 _index) external view returns(address);

    function mirrored_locks(address _user, uint256 _chain, uint256 _escrow_id) external view returns(LockedBalance memory);

    function mirror_lock(
        address _to,
        uint256 _chain,
        uint256 _escrow_id,
        uint256 _value,
        uint256 _unlock_time
    ) external;
}

contract MultiChainMirrorGateV2 is Ownable, Pausable, IApp {

    uint256 immutable chainId;

    IMirroredVotingEscrow public mirrorEscrow;

    IAnyswapV6CallProxy public endpoint;

    mapping(address => mapping(uint256 => bool)) public isAllowedCaller;

    constructor(
        IAnyswapV6CallProxy _endpoint,
        IMirroredVotingEscrow _mirrorEscrow,
        uint256 _chainId
    ) {
        endpoint = _endpoint;
        mirrorEscrow = _mirrorEscrow;
        chainId = _chainId;
    }

    function mirrorLocks(
        uint256 _toChainId,
        address _toMirrorGate,
        uint256[] memory _chainIds,
        uint256[] memory _escrowIds,
        int128[] memory _lockAmounts,
        uint256[] memory _lockEnds
    ) external payable whenNotPaused {
        require(_toChainId != chainId, "Cannot mirror from/to same chain");

        uint256 nbLocks_ = _chainIds.length;
        address user_ = _msgSender();
        for (uint256 i = 0; i < nbLocks_; i++) {
            require(_chainIds[i] != _toChainId, "Cannot mirror target chain locks");

            if (_chainIds[i] == chainId) {
                address escrow_ = mirrorEscrow.voting_escrows(i);
                LockedBalance memory lock_ = IVotingEscrow(escrow_).locked(user_);

                require(lock_.amount == _lockAmounts[i], "Incorrect lock amount");
                require(lock_.end == _lockEnds[i], "Incorrect lock end");
            } else {
                LockedBalance memory mirroredLock_ = mirrorEscrow.mirrored_locks(user_, _chainIds[i], _escrowIds[i]);

                require(mirroredLock_.amount == _lockAmounts[i], "Incorrect lock amount");
                require(mirroredLock_.end == _lockEnds[i], "Incorrect lock end");
            }
        }

        bytes memory payload = abi.encode(user_, _chainIds, _escrowIds, _lockAmounts, _lockEnds);
        endpoint.anyCall{value: msg.value}(_toMirrorGate, payload, address(0), _toChainId, 2);
    }

    function calculateFee(
        address _user,
        uint256 _toChainID,
        uint256[] memory _chainIds,
        uint256[] memory _escrowIds,
        int128[] memory _lockAmounts,
        uint256[] memory _lockEnds
    ) external view returns (uint256) {
        bytes memory payload = abi.encode(_user, _chainIds, _escrowIds, _lockAmounts, _lockEnds);
        return endpoint.calcSrcFees(address(this), _toChainID, payload.length);
    }

    function anyFallback(address _to, bytes calldata _data) override external {}

    function anyExecute(bytes calldata _data) override external returns (bool success, bytes memory result) {
        require(_msgSender() == address(endpoint.executor()), "Only multichain endpoint can trigger mirroring");

        (address from, uint256 fromChainId,) = endpoint.executor().context();
        require(isAllowedCaller[from][fromChainId], "Caller is not allowed from source chain");

        (address user_,
        uint256[] memory chainIds_,
        uint256[] memory escrowIds_,
        uint256[] memory lockAmounts_,
        uint256[] memory lockEnds_) = abi.decode(_data, (address, uint256[], uint256[], uint256[], uint256[]));

        uint256 nbLocks = chainIds_.length;
        for (uint256 i = 0; i < nbLocks; i++) {
            mirrorEscrow.mirror_lock(
                user_,
                chainIds_[i],
                escrowIds_[i],
                lockAmounts_[i],
                lockEnds_[i]
            );
        }

        return (true, "");
    }

    function recoverExecutionBudget() external onlyOwner {
        uint256 amount_ = endpoint.executionBudget(address(this));
        endpoint.withdraw(amount_);

        uint256 balance_ = address(this).balance;

        (bool success, ) = msg.sender.call{value: balance_}("");
        require(success, "Fee transfer failed");
    }

    function setEndpoint(IAnyswapV6CallProxy _endpoint) external onlyOwner {
        endpoint = _endpoint;
    }

    function setMirrorEscrow(IMirroredVotingEscrow _mirrorEscrow) external onlyOwner {
        mirrorEscrow = _mirrorEscrow;
    }

    function setupAllowedCallers(
        address[] memory _callers,
        uint256[] memory _chainIds,
        bool[] memory _areAllowed
    ) external onlyOwner {
        uint256 nbCallers_ = _callers.length;
        for (uint256 i = 0; i < nbCallers_; i++) {
            isAllowedCaller[_callers[i]][_chainIds[i]] = _areAllowed[i];
        }
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unPause() external onlyOwner {
        _unpause();
    }

}