// contracts/EDGEToken.sol
// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract ApproveAndCallFallBack {
    function receiveApproval(address from, address _token, uint256 _amount, string memory _destination) public virtual;
}

contract EDGEToken is ERC20, Ownable {
    constructor() public ERC20("Edge", "EDGE") {
        _mint(msg.sender, 60000000000000000000000000);
    }

    /* Approves and then calls the receiving contract */
    function approveAndCall(address _spender, uint256 _amount, string memory _destination) public returns (bool success) {
        require(approve(_spender, _amount));

        ApproveAndCallFallBack(_spender).receiveApproval(
            msg.sender,
            address(this),
            _amount,
            _destination
        );

        return true;
    }

    /**
     * @dev Allow contract owner to mint new tokens.
     * @param receiver The address to transfer the new tokens to
     * @param amount  Number of new tokens to mint
     */
    function mint(address receiver, uint256 amount) external onlyOwner {
        _mint(receiver, amount);
    }

    /**
     * @dev Recover any ERC20 token that was sent to the token contract.
     * @param tokenAddress The token contract address
     * @param tokenAmount  Number of tokens to be sent
     */
    function recoverERC20(address tokenAddress, uint256 tokenAmount)
        external
        onlyOwner
    {
        IERC20(tokenAddress).transfer(msg.sender, tokenAmount);
    }
}