// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

import "./ERC20.sol";

contract BEDA is ERC20 {
    using SafeMath for uint256;
  
    constructor (uint256 totalsupply_) public ERC20("BEDA", "BEDA") {
        _mint(_msgSender(), totalsupply_);
    }
    
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

        /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

}