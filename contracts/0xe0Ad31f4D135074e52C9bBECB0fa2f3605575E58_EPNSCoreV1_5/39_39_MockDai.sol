/**
 *Submitted for verification at Etherscan.io on 2020-02-28
*/

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.6.11;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
/**
 * @title ERC20Mintable
 * @dev ERC20 minting logic
 */
abstract contract MintableERC20 is ERC20 {
    /**
     * @dev Function to mint tokens
     * @param value The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(uint256 value) public returns (bool) {
        _mint(msg.sender, value);
        return true;
    }
}

contract MockDAI is MintableERC20 {
    constructor () ERC20("DAI", "DAI") public {}
}