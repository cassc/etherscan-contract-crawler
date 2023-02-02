// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./ILockProvider.sol";
import "./IMissionControlStaking.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";

import {IConnext} from "@connext/nxtp-contracts/contracts/core/connext/interfaces/IConnext.sol";

contract NewlandsGenesisLockProvider is ILockProvider, OwnableUpgradeable, ERC165Upgradeable {
    IConnext public connext;
    IMissionControlStaking public missionControlStaking;

    uint32 public destinationDomain;
    address public target;

    modifier onlyMCStaking() {
        require(msg.sender == address(missionControlStaking), "LOCK_PROVIDER: MC STAKING ONLY");
        _;
    }

    function initialize() external initializer {
        __Ownable_init();
    }

    function onTokenLocked(
        address _user,
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _amount,
        uint256 _relayerFee
    ) external payable onlyMCStaking {
        bytes memory callData = abi.encode(_user, _amount);
        connext.xcall{value: _relayerFee}(
            destinationDomain, // _destination: Domain ID of the destination chain
            target, // _to: address of the target contract
            address(0), // _asset: use address zero for 0-value transfers
            msg.sender, // _delegate: address that can revert or forceLocal on destination
            0, // _amount: 0 because no funds are being transferred
            0, // _slippage: can be anything between 0-10000 because no funds are being transferred
            callData // _callData: the encoded calldata to send
        );
    }

    // Identical to onLocked but still included in the interface in case
    // we need to differentiate them in a different provider in the future
    function onTokenUnlocked(
        address _user,
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _amount,
        uint256 _relayerFee
    ) external payable onlyMCStaking {
        bytes memory callData = abi.encode(_user, _amount);
        connext.xcall{value: _relayerFee}(
            destinationDomain, // _destination: Domain ID of the destination chain
            target, // _to: address of the target contract
            address(0), // _asset: use address zero for 0-value transfers
            msg.sender, // _delegate: address that can revert or forceLocal on destination
            0, // _amount: 0 because no funds are being transferred
            0, // _slippage: can be anything between 0-10000 because no funds are being transferred
            callData // _callData: the encoded calldata to send
        );
    }

    function setConnext(IConnext _connext) external onlyOwner {
        require(address(_connext) != address(0), "LOCK_PROVIDER: ADDRESS ZERO");
        connext = _connext;
    }

    function setDestinationDomain(uint32 _destinationDomain) external onlyOwner {
        destinationDomain = _destinationDomain;
    }

    function setTarget(address _target) external onlyOwner {
        require(_target != address(0), "LOCK_PROVIDER: ADDRESS ZERO");
        target = _target;
    }

    function setMCStaking(address _mcStaking) external onlyOwner {
        require(_mcStaking != address(0), "LOCK_PROVIDER: ADDRESS ZERO");
        missionControlStaking = IMissionControlStaking(_mcStaking);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable) returns (bool) {
        return interfaceId == type(ILockProvider).interfaceId || super.supportsInterface(interfaceId);
    }
}