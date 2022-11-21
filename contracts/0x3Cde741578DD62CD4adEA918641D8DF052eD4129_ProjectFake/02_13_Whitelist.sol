// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "https://github.com/nibbstack/erc721/src/contracts/ownership/ownable.sol";

contract ControlledAccess is Ownable {
    
    
   /* 
    * @dev Requires msg.sender to have valid access message.
    * @param _v ECDSA signature parameter v.
    * @param _r ECDSA signature parameters r.
    * @param _s ECDSA signature parameters s.
    */
    modifier onlyValidAccess(uint8 _v, bytes32 _r, bytes32 _s, uint256 tokenId) 
    {
        require( isValidAccessMessage(msg.sender,_v,_r,_s, tokenId));
        _;
    }
 
    /* 
    * @dev Verifies if message was signed by owner to give access to _add for this contract.
    *      Assumes Geth signature prefix.
    * @param _add Address of agent with access
    * @param _v ECDSA signature parameter v.
    * @param _r ECDSA signature parameters r.
    * @param _s ECDSA signature parameters s.
    * @return Validity of access message for a given address.
    */
    function isValidAccessMessage(
        address _add,
        uint8 _v, 
        bytes32 _r, 
        bytes32 _s,
        uint256 tokenId) 
        view public returns (bool)
    {
        bytes32 hash = keccak256(abi.encodePacked(address(this), tokenId, _add));
        return owner == ecrecover(
            keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)),
            _v,
            _r,
            _s
        );
    }
}