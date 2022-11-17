pragma solidity ^0.4.24;

import "zos-lib/contracts/Initializable.sol";
import "openzeppelin-eth/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-eth/contracts/ownership/Ownable.sol";


/**
 * @title ERC20Mintable
 * @dev ERC20 minting logic
 */
contract ERC20Mintable is Initializable, ERC20, Ownable {
  function initialize(address sender) public initializer {
    Ownable.initialize(sender);
  }

  /**
   * @dev Function to mint tokens
   * @param to The address that will receive the minted tokens.
   * @param amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    address to,
    uint256 amount
  )
    public
    onlyOwner
    returns (bool)
  {
    _mint(to, amount);
    return true;
  }


  modifier hasMintPermission() {
    require(msg.sender == owner());
    _;
  }

  uint256[50] private ______gap;
}