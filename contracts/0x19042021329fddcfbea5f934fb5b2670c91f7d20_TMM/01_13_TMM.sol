// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract TMM is ERC20Permit, Ownable {
    using SafeERC20 for IERC20;

    constructor(address owner)
        ERC20("Take My Muffin", "TMM")
        ERC20Permit("Take My Muffin")
    {
        _mint(msg.sender, 275_000e6);
        transferOwnership(owner);
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function rescueFunds(IERC20 token, uint256 amount) external onlyOwner {
        token.safeTransfer(msg.sender, amount);
    }
}