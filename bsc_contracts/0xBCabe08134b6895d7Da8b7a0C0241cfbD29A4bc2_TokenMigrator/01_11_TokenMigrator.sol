//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';

contract TokenMigrator is AccessControl {
    using SafeERC20 for IERC20Metadata;

    IERC20Metadata public immutable tokenFrom;
    IERC20Metadata public immutable tokenTo;

    event Migrated(
        address _user,
        uint256 _amount
    );

    constructor(
        IERC20Metadata _tokenFrom,
        IERC20Metadata _tokenTo
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        tokenFrom = _tokenFrom;
        tokenTo = _tokenTo;
    }

    function migrate() public {
        address user = _msgSender();
        uint256 balance = tokenFrom.balanceOf(user);
        tokenFrom.safeTransferFrom(user, address(this), balance);
        tokenTo.safeTransfer(user, balance);
        emit Migrated(user, balance);
    }

    /**
     * @dev governance can withdraw all stuck funds in emergency case
     * @param _token - IERC20Metadata token that should be fully withdraw from ZunamiGateway
     */
    function withdrawStuckToken(IERC20Metadata _token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 tokenBalance = _token.balanceOf(address(this));
        if (tokenBalance > 0) {
            _token.safeTransfer(_msgSender(), tokenBalance);
        }
    }

    function withdrawStuckNative() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(_msgSender()).transfer(balance);
        }
    }
}