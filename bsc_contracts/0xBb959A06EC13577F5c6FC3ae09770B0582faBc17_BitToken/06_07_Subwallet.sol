// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import './ERC20.sol';

/**
* @notice Stakeable is a contract who is ment to be inherited by other contract that wants Staking capabilities
*/
contract Subwallet {

    address public owner;

    constructor() public {
        /*
            Deployer's address ( Factory in our case )
            do not pass this as a constructor argument because
            etherscan will have issues displaying our validated source code
        */
        owner = msg.sender;
    }

    /*
        @notice Send funds owned by this contract to another address
        @param tracker  - ERC20 token tracker ( DAI / MKR / etc. )
        @param amount   - Amount of tokens to send
        @param receiver - Address we're sending these tokens to
        @return true if transfer succeeded, false otherwise
    */
    function sendFundsTo( address tracker, uint256 amount, address receiver) public returns ( bool ) {
        // callable only by the owner, not using modifiers to improve readability
        require(msg.sender == owner);

        // Transfer tokens from this address to the receiver
        return IERC20(tracker).transfer(receiver, amount);
    }


    function balanceOf(address tracker) public returns ( uint ) {
        // callable only by the owner, not using modifiers to improve readability
        require(msg.sender == owner);

        // Transfer tokens from this address to the receiver
        return IERC20(tracker).balanceOf(address(this));
    }

    function selfAddress() public view returns ( address ) {
       return address(this);
    }
}
