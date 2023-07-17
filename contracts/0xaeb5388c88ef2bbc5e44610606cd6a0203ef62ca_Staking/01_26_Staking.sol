// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {AccessControlEnumerable} from '@openzeppelin/contracts/access/AccessControlEnumerable.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import {IsekaiBattle} from './IsekaiBattle.sol';

contract Staking is IERC721Receiver, Context, AccessControlEnumerable {
    bytes32 public constant STAKER_ROLE = keccak256('STAKER_ROLE');

    mapping(uint256 => address) public tokenOwners;

    IsekaiBattle public immutable ISB;

    constructor(IsekaiBattle _ISB) {
        ISB = _ISB;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(STAKER_ROLE, _msgSender());
    }

    function stake(address user, uint256[] memory tokenIds) public virtual onlyRole(STAKER_ROLE) {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            ISB.safeTransferFrom(user, address(this), tokenIds[i]);
        }
    }

    function unstake(uint256[] memory tokenIds) public virtual onlyRole(STAKER_ROLE) {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            address owner = tokenOwners[tokenIds[i]];
            tokenOwners[tokenIds[i]] = address(0);
            ISB.safeTransferFrom(address(this), owner, tokenIds[i]);
        }
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory
    ) public virtual override returns (bytes4) {
        require(address(this) == operator, 'not me');
        tokenOwners[tokenId] = from;
        return this.onERC721Received.selector;
    }
}