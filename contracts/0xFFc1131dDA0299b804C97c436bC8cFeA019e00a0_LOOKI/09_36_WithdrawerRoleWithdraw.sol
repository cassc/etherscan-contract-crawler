// SPDX-License-Identifier: MIT
// Creator: [email protected]

pragma solidity ^0.8.8;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/access/AccessControlEnumerable.sol';

abstract contract WithdrawerRoleWithdraw is AccessControlEnumerable {
    using SafeERC20 for IERC20;
    bytes32 public constant WITHDRAWER_ROLE = keccak256('WITHDRAWER_ROLE');

    constructor() {
        _grantRole(WITHDRAWER_ROLE, _msgSender());
    }

    function withdraw(address payable _receiver, uint256 _amount) external onlyRole(WITHDRAWER_ROLE) {
        Address.sendValue(_receiver, _amount);
    }

    function withdrawERC20(
        address _tokenAddress,
        address _receiver,
        uint256 _amount
    ) external onlyRole(WITHDRAWER_ROLE) {
        IERC20(_tokenAddress).transfer(_receiver, _amount);
    }

    function withdrawERC721(
        address _tokenAddress,
        address _receiver,
        uint256[] memory _tokenIds
    ) external onlyRole(WITHDRAWER_ROLE) {
        for (uint256 i; i < _tokenIds.length; ++i) {
            IERC721(_tokenAddress).transferFrom(address(this), _receiver, _tokenIds[i]);
        }
    }
}