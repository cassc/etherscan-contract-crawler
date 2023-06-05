//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol';
import './ERC721/IERC721WithRoyalties.sol';

/// @title ERC721Slim
/// @dev This is a "slim" version of an ERC721 for NiftyForge
///      Slim ERC721 do not have all the bells and whistle that the ERC721Full have
///      Slim is made for series (like PFPs or Generative series)
///      The mint starts from 1 and ups
///      Not even the owner can mint directly on this collection.
///      It has to be the module passed as initialization
/// @author Simon Fremaux (@dievardump)
interface IERC721Slim is IERC721Upgradeable, IERC721WithRoyalties {
    function baseURI() external view returns (string memory);

    function contractURI() external view returns (string memory);

    // receive() external payable {}

    /// @notice This is a generic function that allows this contract's owner to withdraw
    ///         any balance / ERC20 / ERC721 / ERC1155 it can have
    ///         this contract has no payable nor receive function so it should not get any nativ token
    ///         but this could save some ERC20, 721 or 1155
    /// @param token the token to withdraw from. address(0) means native chain token
    /// @param amount the amount to withdraw if native token, erc20 or erc1155 - must be 0 for ERC721
    /// @param tokenId the tokenId to withdraw for ERC1155 and ERC721
    function withdraw(
        address token,
        uint256 amount,
        uint256 tokenId
    ) external;

    /// @notice Helper to know if an address can do the action an Editor can
    /// @param account the address to check
    function canEdit(address account) external view returns (bool);

    /// @notice Allows to get approved using a permit and transfer in the same call
    /// @dev this supposes that the permit is for msg.sender
    /// @param from current owner
    /// @param to recipient
    /// @param tokenId the token id
    /// @param _data optional data to add
    /// @param deadline the deadline for the permit to be used
    /// @param signature of permit
    function safeTransferFromWithPermit(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data,
        uint256 deadline,
        bytes memory signature
    ) external;

    /// @notice Set the base token URI
    /// @dev only an editor can do that (account or module)
    /// @param baseURI_ the new base token uri used in tokenURI()
    function setBaseURI(string memory baseURI_) external;

    /// @notice Allows to change the default royalties recipient
    /// @dev an editor can call this
    /// @param recipient new default royalties recipient
    function setDefaultRoyaltiesRecipient(address recipient) external;

    /// @notice Helper for the owner of the contract to set the new contract URI
    /// @dev needs to be owner
    /// @param contractURI_ new contract URI
    function setContractURI(string memory contractURI_) external;
}