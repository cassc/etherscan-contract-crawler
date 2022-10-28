// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./abstracts/BaseContract.sol";
// Interfaces.
import "./interfaces/IPresale.sol";
import "./interfaces/IToken.sol";
import "./interfaces/IVault.sol";

/**
 * @title Claim
 * @author Steve Harmeyer
 * @notice This contract handles presale NFT claims
 */

/// @custom:security-contact [email protected]
contract Claim is BaseContract
{
    /**
     * Contract initializer.
     * @dev This intializes all the parent contracts.
     */
    function initialize() initializer public
    {
        __BaseContract_init();
    }

    /**
     * NFT Values.
     */
    mapping(uint256 => uint256) private _value;

    /**
     * Empty NFTs.
     */
    mapping(uint256 => bool) private _empty;

    /**
     * Get remaining NFT value.
     * @param tokenId_ ID for the NFT.
     * @return uint256 Value.
     */
    function getTokenValue(uint256 tokenId_) public view returns (uint256)
    {
        IPresale _presale_ = _presale();
        require(address(_presale_) != address(0), "Presale contract not found");
        if(_value[tokenId_] != 0) {
            return _value[tokenId_];
        }
        if(_empty[tokenId_]) {
            return 0;
        }
        return _presale_.tokenValue(tokenId_);
    }

    /**
     * Get total value for an owner.
     * @param owner_ Token owner.
     * @return uint256 Value.
     */
    function getOwnerValue(address owner_) public view returns (uint256)
    {
        IPresale _presale_ = _presale();
        require(address(_presale_) != address(0), "Presale contract not found");
        uint256 _balance_ = _presale_.balanceOf(owner_);
        uint256 _value_;
        for(uint256 i = 0; i < _balance_; i++) {
            _value_ += getTokenValue(_presale_.tokenOfOwnerByIndex(owner_, i));
        }
        return _value_;
    }

    /**
     * Owned NFTs.
     * @param owner_ Owner address.
     * @return uint256[] Array of owned tokens.
     */
    function owned(address owner_) public view returns (uint256[] memory)
    {
        IPresale _presale_ = _presale();
        require(address(_presale_) != address(0), "Presale contract not found");
        uint256 _balance_ = _presale_.balanceOf(owner_);
        uint256[] memory _owned_ = new uint256[](_balance_);
        for(uint256 i = 0; i < _balance_; i++) {
            _owned_[i] = _presale_.tokenOfOwnerByIndex(owner_, i);
        }
        return _owned_;
    }

    /**
     * Claim.
     * @param quantity_ Quantity of $FUR to claim.
     * @param address_ Address tokens should be assigned to.
     * @param vault_ Send tokens straight to vault.
     * @return bool True if successful.
     */
    function claim(uint256 quantity_, address address_, bool vault_) external whenNotPaused returns (bool)
    {
        return _claim(quantity_, address_, vault_, address(0));
    }

    /**
     * Claim.
     * @param quantity_ Quantity of $FUR to claim.
     * @param address_ Address tokens should be assigned to.
     * @param vault_ Send tokens straight to vault.
     * @param referrer_ Referrer address.
     * @return bool True if successful.
     */
    function claim(uint256 quantity_, address address_, bool vault_, address referrer_) external returns (bool)
    {
        return _claim(quantity_, address_, vault_, referrer_);
    }

    /**
     * Claim.
     * @param quantity_ Quantity of $FUR to claim.
     * @param address_ Address tokens should be assigned to.
     * @param vault_ Send tokens straight to vault.
     * @param referrer_ Referrer address.
     * @return bool True if successful.
     */
    function _claim(uint256 quantity_, address address_, bool vault_, address referrer_) internal returns (bool)
    {
        IPresale _presale_ = _presale();
        require(address(_presale_) != address(0), "Presale contract not found");
        IToken _token_ = _token();
        require(address(_token_) != address(0), "Token contract not found");
        require(!_token_.paused(), "Token is paused");
        IVault _vault_ = _vault();
        require(address(_vault_) != address(0), "Vault contract not found");
        require(!_vault_.paused(), "Vault is paused");
        require(getOwnerValue(msg.sender) >= quantity_, "Quantity too high");
        uint256[] memory _owned_ = owned(msg.sender);
        uint256 _mintQuantity_ = quantity_;
        for(uint i = 0; i < _owned_.length; i ++) {
            uint256 _value_ = getTokenValue(_owned_[i]);
            if(_value_ <= _mintQuantity_) {
                _value[_owned_[i]] = 0;
                _empty[_owned_[i]] = true;
                _mintQuantity_ -= _value_;
            }
            else {
                _value[_owned_[i]] = _value_ - _mintQuantity_;
                _mintQuantity_ = 0;
            }
        }
        quantity_ = quantity_ * (10 ** 18);
        if(vault_) {
            _token_.mint(address(_vault_), quantity_);
            _vault_.depositFor(address_, quantity_, referrer_);
        }
        else {
            _token_.mint(address_, quantity_);
        }
        return true;
    }

    /**
     * Get presale NFT contract.
     * @return IPresale Presale contract.
     */
    function _presale() internal view returns (IPresale)
    {
        return IPresale(addressBook.get("presale"));
    }

    /**
     * Get token contract.
     * @return IToken Token contract.
     */
    function _token() internal view returns (IToken)
    {
        return IToken(addressBook.get("token"));
    }

    /**
     * Get vault contract.
     * @return IVault Vault contract.
     */
    function _vault() internal view returns (IVault)
    {
        return IVault(addressBook.get("vault"));
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}