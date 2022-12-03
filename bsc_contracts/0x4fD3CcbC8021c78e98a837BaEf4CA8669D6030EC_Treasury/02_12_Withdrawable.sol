// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract Withdrawable {
    event Withdrawn(address from, address to, uint256 amount);

    receive() external payable {}

    /// @dev Allow the owner to transfer Ether
    function _withdrawEthers(address to) internal virtual {
        uint256 amount = address(this).balance;
        emit Withdrawn(msg.sender, to, amount);
        payable(to).transfer(amount);
    }

    /// @dev Allow the owner to transfer tokens
    function _withdrawTokenAll(address token, address to)
        internal
        virtual
        returns (bool)
    {
        IERC20 foreignToken = IERC20(token);
        uint256 amount = foreignToken.balanceOf(address(this));
        bool result = foreignToken.transfer(to, amount);
        assert(result);
        emit Withdrawn(msg.sender, to, amount);

        return result;
    }
}