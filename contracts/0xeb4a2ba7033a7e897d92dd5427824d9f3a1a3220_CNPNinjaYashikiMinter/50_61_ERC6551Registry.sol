// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Create2} from '@openzeppelin/contracts/utils/Create2.sol';
import {AccessControl} from '@openzeppelin/contracts/access/AccessControl.sol';

import {IERC6551Registry} from './interface/IERC6551Registry.sol';
import {ERC6551BytecodeLib} from './lib/ERC6551BytecodeLib.sol';

contract ERC6551Registry is IERC6551Registry, AccessControl {
    error InitializationFailed();
    bool public canCreate = false;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setCanCreate(bool _canCreate) external onlyRole(DEFAULT_ADMIN_ROLE) {
        canCreate = _canCreate;
    }

    function createAccount(
        address implementation,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId,
        uint256 salt,
        bytes calldata initData
    ) external returns (address) {
        require(canCreate, 'can not create account');
        bytes memory code = ERC6551BytecodeLib.getCreationCode(implementation, chainId, tokenContract, tokenId, salt);

        address _account = Create2.computeAddress(bytes32(salt), keccak256(code));

        if (_account.code.length != 0) return _account;

        emit AccountCreated(_account, implementation, chainId, tokenContract, tokenId, salt);

        _account = Create2.deploy(0, bytes32(salt), code);

        if (initData.length != 0) {
            (bool success, ) = _account.call(initData);
            if (!success) revert InitializationFailed();
        }

        return _account;
    }

    function account(
        address implementation,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId,
        uint256 salt
    ) external view returns (address) {
        bytes32 bytecodeHash = keccak256(
            ERC6551BytecodeLib.getCreationCode(implementation, chainId, tokenContract, tokenId, salt)
        );

        return Create2.computeAddress(bytes32(salt), bytecodeHash);
    }
}