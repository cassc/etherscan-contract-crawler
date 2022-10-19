// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Base} from "../base/Base.sol";
import {ERC721TransferHooks} from  "../hooks/ERC721TransferHooks.sol";
import {ITransfer} from "../interfaces/ITransfer.sol";
import {LibTokenOwnership} from "../libraries/LibTokenOwnership.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {LibTransfer} from "../libraries/LibTransfer.sol";
import {IERC721} from "../interfaces/IERC721.sol";
import {IOperatorFilter} from "../interfaces/IOperatorFilter.sol";
import {AccessControl} from "../libraries/LibAccessControl.sol";


contract TransferFacet is Base, ERC721TransferHooks, ITransfer {
    function enableTransfers() external {
        s.nftStorage.transfersEnabled = true;
    }

    function disableTransfers() external {
        s.nftStorage.transfersEnabled = false;
    }

    /// @notice admin transfer of token from one address to another and meant to be used with extreme care
    /// @dev only callable from an address with the admin role
    /// @param from_ the address that holds the tokenId
    /// @param to_ the address which will receive the tokenId
    /// @param tokenId_ the pass's tokenId
    function adminTransfer(
        address from_,
        address to_,
        uint256 tokenId_
    ) external {
        LibTransfer.adminTransferFrom(from_, to_, tokenId_, s);
    }

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory data
    ) public {
        transferFrom(_from, _to, _tokenId);
        if (_to.code.length > 0) {
            LibTransfer._checkERC721Received(_from, _to, _tokenId, data);
        }
    }

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public isTransferable tokenLocked(_tokenId) {
        address owner = s.nftStorage.tokenOwners[_tokenId];
        if (owner == address(0)) revert QueryNonExistentToken();


        if (owner != _from) revert TokenNotOwnedByFromAddress();
        if (owner != msg.sender && !s.nftStorage.operators[_from][msg.sender] && s.nftStorage.tokenOperators[_tokenId] != msg.sender)
            revert CallerNotOwnerOrApprovedOperator();
        if (_to == address(0)) revert InvalidTransferToZeroAddress();

        _beforeTokenTransfer(_from, _to, _tokenId);

        s.nftStorage.balances[_from] -= 1;
        s.nftStorage.balances[_to] += 1;

        s.nftStorage.tokenOperators[_tokenId] = address(0);
        s.nftStorage.tokenOwners[_tokenId] = _to;

        emit Transfer(_from, _to, _tokenId);

        _afterTokenTransfer(_from, _to, _tokenId);
    }

    /// @notice Check whether a pass has been flagged
    /// @param tokenId_ the pass's token id
    function isPassFlagged(uint256 tokenId_) public view returns (bool) {
        return s.flaggedPasses[tokenId_] != 0 || s.flaggedPassHead == tokenId_;
    }

    /// @notice Check whether an address has been flagged
    /// @param address_ the address
    function isAddressFlagged(address address_) public view returns (bool) {
        return s.flaggedAddresses[address_] != address(0) || s.flaggedAddressHead == address_;
    }

    /// @notice Before Token Transfer Hook
    /// @param from Token owner
    /// @param to Receiver
    /// @param tokenId The token id
    /* solhint-disable no-empty-blocks */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        if (!_mayTransfer(msg.sender, tokenId)) revert IllegalOperator();
        if (!AccessControl.hasRole(AccessControl.SEC_MULTISIG_ROLE, msg.sender)) {
            if (isAddressFlagged(from)) revert("Caller address is flagged");
            if (isAddressFlagged(to)) revert("Receiver address is flagged");
            if (isPassFlagged(tokenId)) revert("Pass is flagged");
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _mayTransfer(address _operator, uint256 _tokenId)
        internal virtual override
        view
        returns (bool)
    {
        IOperatorFilter filter = IOperatorFilter(s.operatorFilter);
        if (address(filter) == address(0)) return true;
        if (_operator == s.nftStorage.tokenOwners[_tokenId]) return true;
        return filter.mayTransfer(msg.sender);
    }
}