// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Base} from  "../base/Base.sol";
import {ISecurity} from "../interfaces/ISecurity.sol";
import {IToken} from "../interfaces/IToken.sol";

contract SecurityFacet is Base, ISecurity {
    /// @notice Check whether a pass has been flagged
    /// @param tokenId_ the pass's token id
    function isPassFlagged(uint256 tokenId_) public view returns (bool) {
        return s.flaggedPasses[tokenId_] != 0 || s.flaggedPassHead == tokenId_;
    }

    /// @notice Retrieve list of flagged passes
    function getFlaggedPasses() external view returns (uint256[] memory) {
        uint256[] memory flaggedPasses = new uint256[](s.flaggedPassesCount);
        uint256 currentTokenId = 0;
        for (uint256 i = 0; i < s.flaggedPassesCount; i++) {
            flaggedPasses[i] = s.flaggedPasses[currentTokenId];
            currentTokenId = s.flaggedPasses[currentTokenId];
        }
        return flaggedPasses;
    }

    /// @notice Check whether an address has been flagged
    /// @param address_ the address
    function isAddressFlagged(address address_) public view returns (bool) {
        return s.flaggedAddresses[address_] != address(0) || s.flaggedAddressHead == address_;
    }

    /// @notice Get list of flagged addresses
    function getFlaggedAddresses() external view returns (address[] memory) {
        address[] memory flaggedAddresses = new address[](s.flaggedAddressesCount);
        address currentAddress = address(0);
        for (uint256 i = 0; i < s.flaggedAddressesCount; i++) {
            flaggedAddresses[i] = s.flaggedAddresses[currentAddress];
            currentAddress = s.flaggedAddresses[currentAddress];
        }
        return flaggedAddresses;
    }

    function flagAddress(address address_) external {
        if(address_ == address(0)) revert FlagZeroAddress();
        if(isAddressFlagged(address_)) revert AddressAlreadyFlagged();
        s.flaggedAddresses[s.flaggedAddressHead] = address_;
        s.reversedFlaggedAddresses[address_] = s.flaggedAddressHead;
        s.flaggedAddressHead = address_;
        s.flaggedAddressesCount += 1;

        emit AddressFlagged(msg.sender, address_);
    }

    /// @notice used to remove the flag of an address and restore the ability for it to transfer passes
    /// @dev callable by admin or manager
    /// @param address_ the address that will be unflagged
    function unflagAddress(address address_) external {
        if(address_ == address(0)) revert FlagZeroAddress();
        if(!isAddressFlagged(address_)) revert AddressNotFlagged();
        if (address_ == s.flaggedAddressHead) {
            s.flaggedAddressHead = s.reversedFlaggedAddresses[address_];
            s.flaggedAddresses[s.flaggedAddressHead] = address(0);
        } else {
            address previousAddress = s.reversedFlaggedAddresses[address_];
            address nextAddress = s.flaggedAddresses[address_];
            s.flaggedAddresses[previousAddress] = nextAddress;
            s.reversedFlaggedAddresses[nextAddress] = previousAddress;
        }
        s.flaggedAddressesCount -= 1;

        emit AddressUnflagged(msg.sender, address_);
    }

    /// @notice used to flag a pass and make it untransferrable
    /// @dev callable by admin or manager
    /// @param tokenId_ the pass that will be flagged
    function flagPass(uint256 tokenId_) external {
        if(!s.nftStorage.burnedTokens[tokenId_] && s.nftStorage.tokenOwners[tokenId_] == address(0)) revert IToken.QueryNonExistentToken();
        if(isPassFlagged(tokenId_)) revert PassAlreadyFlagged();
        s.flaggedPasses[s.flaggedPassHead] = tokenId_;
        s.reversedFlaggedPasses[tokenId_] = s.flaggedPassHead;
        s.flaggedPassHead = tokenId_;
        s.flaggedPassesCount += 1;

        emit PassFlagged(msg.sender, tokenId_);
    }

    /// @notice used to remove the flag of a pass and restore the ability for it to be transferred
    /// @dev callable by admin or manager
    /// @param tokenId_ the pass that will be unflagged
    function unflagPass(uint256 tokenId_) external {
        if(!s.nftStorage.burnedTokens[tokenId_] && s.nftStorage.tokenOwners[tokenId_] == address(0)) revert IToken.QueryNonExistentToken();
        if(!isPassFlagged(tokenId_)) revert PassNotFlagged();
        if (tokenId_ == s.flaggedPassHead) {
            s.flaggedPassHead = s.reversedFlaggedPasses[tokenId_];
            s.flaggedPasses[s.flaggedPassHead] = 0;
        } else {
            uint256 previousPass = s.reversedFlaggedPasses[tokenId_];
            uint256 nextPass = s.flaggedPasses[tokenId_];
            s.flaggedPasses[previousPass] = nextPass;
            s.reversedFlaggedPasses[nextPass] = previousPass;
        }
        s.flaggedPassesCount -= 1;

        emit PassUnflagged(msg.sender, tokenId_);
    }

    function extraSecurityOptInLockTokens(uint256[] calldata _tokenIds) external {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            if(s.nftStorage.tokenOwners[_tokenIds[i]] != msg.sender) revert TokenNotOwnedByFromAddress();
            s.nftStorage.lockedTokens[_tokenIds[i]] = true;
        }
        emit TokensLocked(msg.sender, _tokenIds);
    }

    function unlockTokens(uint256[] calldata _tokenIds, address _owner) external {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            if(s.nftStorage.tokenOwners[_tokenIds[i]] != _owner) revert TokenNotOwnedByFromAddress();
            s.nftStorage.lockedTokens[_tokenIds[i]] = false;
        }
        emit TokensUnlocked(msg.sender, _owner, _tokenIds);
    }
}