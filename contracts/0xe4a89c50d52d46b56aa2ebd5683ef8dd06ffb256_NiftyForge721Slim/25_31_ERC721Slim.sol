//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "./ERC721/ERC721WithRoyalties.sol";
import "./ERC721/ERC721WithPermit.sol";
import "./ERC721/IERC4494.sol";

/// @title ERC721Slim
/// @dev This is a "slim" version of an ERC721 for NiftyForge
///      Slim ERC721 do not have all the bells and whistle that the ERC721Full have
///      Slim is made for series (like PFPs or Generative series)
///      The mint starts from 1 and ups
///      Not even the owner can mint directly on this collection.
///      It has to be the module passed as initialization
/// @author Simon Fremaux (@dievardump)
abstract contract ERC721Slim is
    OwnableUpgradeable,
    ERC721Upgradeable,
    ERC721BurnableUpgradeable,
    ERC721WithRoyalties,
    ERC721WithPermit
{
    event NewContractURI(string contractURI);

    // base token uri
    string public baseURI;

    /// @notice contract URI (collection description)
    string public contractURI;

    /// @notice constructor
    /// @param name_ name of the contract (see ERC721)
    /// @param symbol_ symbol of the contract (see ERC721)
    /// @param contractURI_ The contract URI (containing its metadata) - can be empty ""
    /// @param baseURI_ the contract baseURI (if there is)  - can be empty ""
    /// @param owner_ Address to whom transfer ownership (can be address(0), then owner is deployer)
    function __ERC721Slim__init(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        string memory baseURI_,
        address owner_
    ) internal {
        __Ownable_init();
        __ERC721_init_unchained(name_, symbol_);

        __ERC721WithPermit_init();

        // set contract uri if present
        if (bytes(contractURI_).length > 0) {
            contractURI = contractURI_;
        }

        // set base uri if present
        if (bytes(baseURI_).length > 0) {
            baseURI = baseURI_;
        }

        if (address(0) != owner_) {
            transferOwnership(owner_);
        }
    }

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
    ) external onlyOwner {
        if (token == address(0)) {
            require(
                amount == 0 || address(this).balance >= amount,
                "!WRONG_VALUE!"
            );
            (bool success, ) = msg.sender.call{value: amount}("");
            require(success, "!TRANSFER_FAILED!");
        } else {
            // if token is ERC1155
            if (
                IERC165Upgradeable(token).supportsInterface(
                    type(IERC1155Upgradeable).interfaceId
                )
            ) {
                IERC1155Upgradeable(token).safeTransferFrom(
                    address(this),
                    msg.sender,
                    tokenId,
                    amount,
                    ""
                );
            } else if (
                IERC165Upgradeable(token).supportsInterface(
                    type(IERC721Upgradeable).interfaceId
                )
            ) {
                //else if ERC721
                IERC721Upgradeable(token).safeTransferFrom(
                    address(this),
                    msg.sender,
                    tokenId,
                    ""
                );
            } else {
                // we consider it's an ERC20
                require(
                    IERC20Upgradeable(token).transfer(msg.sender, amount),
                    "!TRANSFER_FAILED!"
                );
            }
        }
    }

    /// @inheritdoc	ERC165Upgradeable
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        // all moved here to have less "jumps" when checking an interface
        return
            interfaceId == type(IERC2981Royalties).interfaceId ||
            interfaceId == type(IRaribleSecondarySales).interfaceId ||
            interfaceId == type(IFoundationSecondarySales).interfaceId ||
            interfaceId == type(IERC4494).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @notice Helper to know if an address can do the action an Editor can
    /// @param account the address to check
    function canEdit(address account) public view virtual returns (bool) {
        return owner() == account;
    }

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
    ) external {
        // use the permit to get msg.sender approved
        permit(msg.sender, tokenId, deadline, signature);

        // do the transfer
        safeTransferFrom(from, to, tokenId, _data);
    }

    /// @notice Set the base token URI
    /// @dev only an editor can do that (account or module)
    /// @param baseURI_ the new base token uri used in tokenURI()
    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    /// @notice Allows to change the default royalties recipient
    /// @dev an editor can call this
    /// @param recipient new default royalties recipient
    function setDefaultRoyaltiesRecipient(address recipient)
        external
        onlyOwner
    {
        require(!hasPerTokenRoyalties(), "!PER_TOKEN_ROYALTIES!");
        _setDefaultRoyaltiesRecipient(recipient);
    }

    /// @notice Helper for the owner of the contract to set the new contract URI
    /// @dev needs to be owner
    /// @param contractURI_ new contract URI
    function setContractURI(string memory contractURI_) external onlyOwner {
        contractURI = contractURI_;
    }

    /// @inheritdoc ERC721Upgradeable
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Upgradeable, ERC721WithPermit) {
        super._transfer(from, to, tokenId);
    }

    /// @inheritdoc	ERC721Upgradeable
    function _burn(uint256 tokenId) internal virtual override {
        // remove royalties
        _removeRoyalty(tokenId);

        // burn ERC721URIStorage
        super._burn(tokenId);
    }

    /// @inheritdoc	ERC721Upgradeable
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}