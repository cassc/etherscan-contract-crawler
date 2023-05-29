// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Metacade is Ownable, ERC20 {
    using SafeERC20 for IERC20;

    constructor() ERC20("Metacade", "MCADE") {

        _mint(owner(), 2_000_000_000 * 10**18);
    }

   
     /**
     * @notice Rescue ETH locked up in this contract.
     * @param _to       Recipient address
     */

    function withdrawETH(
        address _to,
        uint256 _amount        
    ) external payable onlyOwner{
        require(_to != address(0), "Zero address");

        (bool sent,) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
        
    }

    /**
     * @notice Rescue ERC20 tokens locked up in this contract.
     * @param tokenContract ERC20 token contract address
     * @param to        Recipient address
     * @param amount    Amount to withdraw
     */
    function rescueERC20(
        IERC20 tokenContract,
        address to,
        uint256 amount
    ) external onlyOwner {        
        require(to != address(0), "Zero address");

        tokenContract.safeTransfer(to, amount);
    }

    /**
     * @notice Burn tokens from wallet.
     * @param _amount   Number of tokens to burn
     */

    function burn(uint256 _amount) external {
        _burn(msg.sender, _amount);
    }
}