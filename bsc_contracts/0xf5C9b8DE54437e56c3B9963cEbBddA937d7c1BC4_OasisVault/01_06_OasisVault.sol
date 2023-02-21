// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "IOasisVault.sol";
import "AccessManager.sol";
import "IERC20.sol";

contract OasisVault is IOasisVault, AccessManager {
    address public receiver;

    constructor(IRoleRegistry _roleRegistry, address _receiver) {
        setRoleRegistry(_roleRegistry);
        receiver = _receiver;
    }

    receive() external payable {}

    function changeReceiver(address _receiver)
        external
        override
        onlyRole(Roles.ADMIN)
    {
        receiver = _receiver;
    }

    function withdrawChainToken(uint256 _amount)
        external
        override
        onlyRole(Roles.VAULT_WITHDRAWER)
    {
        payable(receiver).transfer(_amount);
        emit ChainTokenWithdrawed(_amount);
    }

    function withdrawERC20Token(address _tokenAddress, uint256 _amount)
        external
        override
        onlyRole(Roles.VAULT_WITHDRAWER)
    {
        IERC20(_tokenAddress).transfer(receiver, _amount);
        emit ERC20Withdrawed(_tokenAddress, _amount);
    }
}