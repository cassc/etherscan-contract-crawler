pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/**
 * @dev This implements Ownable plus a few utilities
 */
contract Ownablearama is Ownable {
    /**
     * @dev ETH should not be sent to this contract, but in the case that it is
     * sent by accident, this function allows the owner to withdraw it.
     */
    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    /**
     * @dev Again, ERC20s should not be sent to this contract, but if someone
     * does, it's nice to be able to recover them
     * @param token IERC20 the token address
     * @param amount uint256 the amount to send
     */
    function forwardERC20s(IERC20 token, uint256 amount) public onlyOwner {
        require(address(msg.sender) != address(0));
        token.transfer(msg.sender, amount);
    }

    // disable renouncing ownership
    function renounceOwnership() public override onlyOwner {}
}