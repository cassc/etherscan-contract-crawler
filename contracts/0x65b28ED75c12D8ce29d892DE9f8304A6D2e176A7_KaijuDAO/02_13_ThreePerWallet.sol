// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC721.sol";

/// @author 1001.digital
/// @title An extension that enables checking that an address only holds one token.
abstract contract ThreePerWallet is ERC721 {
    // Mapping owner address to token
    mapping (address => uint256) private _ownedGen0;
    mapping (address => uint256) private _ownedGen1;

    /// Require an externally owned account to only hold one token.
    /// @param wallet the address of
    /// @dev Only allow one token per wallet
    modifier threePerWallet(address wallet, uint256 tokenId) {
        if (_isExternal(wallet)) {
            if(tokenId<10001){
                require(_ownedGen0[wallet] < 3, "Can only hold three tokens per wallet");
            }else{
                require(_ownedGen1[wallet] < 3, "Can only hold three tokens per wallet");
            }
            
        }

        _;
    }


    /// Store `_ownedGen0` instead of `_balances`.
    /// @param to the address to which to mint the token
    /// @param tokenId the tokenId that should be minted
    /// @dev overrides the OpenZeppelin `_mint` method to accomodate for our own balance tracker
    function _mint(address to, uint256 tokenId) internal virtual override threePerWallet(to, tokenId) {
        super._mint(to, tokenId);

        // We add one to account for 0-index based collections
        if(msg.sender==to){
            if(tokenId<10001){
                _ownedGen0[to] += 1;
            }else{
                _ownedGen1[to] += 1;
            }
        }
        
    }
    /*
    /// Track transfers in `_ownedGen0` instead of `_balances`
    /// @param from the address from which to transfer the token
    /// @param to the address to which to transfer the token
    /// @param tokenId the tokenId that is being transferred
    /// @dev overrides the OpenZeppelin `_transfer` method to accomodate for our own balance tracker
    function _transfer(address from, address to, uint256 tokenId) internal virtual override threePerWallet(to, tokenId) {
        super._transfer(from, to, tokenId);
        if(tokenId<10001){
            _ownedGen0[from] -= 1;
            // We add one to account for 0-index based collections
            _ownedGen0[to] += 1;
        }else{
            _ownedGen1[from] -= 1;
            // We add one to account for 0-index based collections
            _ownedGen1[to] += 1;
        }
        
    }
    */
    function _isContract(address account) internal view returns (bool) {
        return _getSize(account) > 0;
    }

    /// Check whether an address is an external wallet.
    /// @param account the address to check
    /// @dev checks if the `extcodesize` of `address` is zero
    /// @return true for external wallets
    function _isExternal(address account) internal view returns (bool) {
        return _getSize(account) == 0;
    }

    /// Get the size of the code of an address
    /// @param account the address to check
    /// @dev gets the `extcodesize` of `address`
    /// @return the size of the address
    function _getSize(address account) internal view returns (uint256) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size;
    }
}