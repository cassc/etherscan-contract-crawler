// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

function tokenToEntity(address token, uint256 id) pure returns (uint256) {
    return (uint256(uint160(token)) << 96) | id;
}

function entityToToken(uint256 entity)
    pure
    returns (address token, uint256 id)
{
    token = address(uint160(entity >> 96));
    id = entity & 0xffffffffffffffffffffffff;
}

function accountToEntity(address account) pure returns (uint256) {
    return (uint256(uint160(account)));
}

function entityToAccount(uint256 entity) pure returns (address account) {
    account = address(uint160(entity));
}

function entityIsAccount(uint256 entity) pure returns (bool) {
    return entity >> 160 == 0;
}