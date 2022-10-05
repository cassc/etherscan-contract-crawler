// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.4;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import './IDelegate.sol';

contract Delegate is IDelegate, AccessControl {
    bytes32 public constant DELEGATION_CALLER = keccak256('DELEGATION_CALLER');

    using SafeERC20 for IERC20;

    constructor(address _admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    function erc20Transfer(address sender, address receiver, address token, uint256 amount) external override  onlyRole(DELEGATION_CALLER){
        IERC20(token).safeTransferFrom(sender, receiver, amount);
    }

    function erc721Transfer(address sender, address receiver, address token, uint256 tokenId) external override onlyRole(DELEGATION_CALLER){
        IERC721(token).safeTransferFrom(sender, receiver, tokenId);
    }
}