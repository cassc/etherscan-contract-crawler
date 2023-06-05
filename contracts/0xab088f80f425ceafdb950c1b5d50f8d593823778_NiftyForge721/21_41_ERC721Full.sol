//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';

import './ERC721Ownable.sol';
import './ERC721WithRoles.sol';
import './ERC721WithRoyalties.sol';
import './ERC721WithPermit.sol';
import './ERC721WithMutableURI.sol';

/// @title ERC721Full
/// @dev This contains all the different overrides needed on
///      ERC721 / URIStorage / Royalties
///      This contract does not use ERC721enumerable because Enumerable adds quite some
///      gas to minting costs and I am trying to make this cheap for creators.
///      Also, since all NiftyForge contracts will be fully indexed in TheGraph it will easily
///      Be possible to get tokenIds of an owner off-chain, before passing them to a contract
///      which can verify ownership at the processing time
/// @author Simon Fremaux (@dievardump)
abstract contract ERC721Full is
    ERC721Ownable,
    ERC721BurnableUpgradeable,
    ERC721URIStorageUpgradeable,
    ERC721WithRoles,
    ERC721WithRoyalties,
    ERC721WithPermit,
    ERC721WithMutableURI
{
    bytes32 public constant ROLE_EDITOR = keccak256('EDITOR');
    bytes32 public constant ROLE_MINTER = keccak256('MINTER');

    // base token uri
    string public baseURI;

    /// @notice modifier allowing only safe listed addresses to mint
    ///         safeListed addresses have roles Minter, Editor or Owner
    modifier onlyMinter(address minter) virtual {
        require(canMint(minter), '!NOT_MINTER!');
        _;
    }

    /// @notice only editor
    modifier onlyEditor(address sender) virtual override {
        require(canEdit(sender), '!NOT_EDITOR!');
        _;
    }

    /// @notice constructor
    /// @param name_ name of the contract (see ERC721)
    /// @param symbol_ symbol of the contract (see ERC721)
    /// @param contractURI_ The contract URI (containing its metadata) - can be empty ""
    /// @param openseaProxyRegistry_ OpenSea's proxy registry to allow gas-less listings - can be address(0)
    /// @param owner_ Address to whom transfer ownership (can be address(0), then owner is deployer)
    function __ERC721Full_init(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        address openseaProxyRegistry_,
        address owner_
    ) internal {
        __ERC721Ownable_init(
            name_,
            symbol_,
            contractURI_,
            openseaProxyRegistry_,
            owner_
        );

        __ERC721WithPermit_init(name_);
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
                '!WRONG_VALUE!'
            );
            (bool success, ) = msg.sender.call{value: amount}('');
            require(success, '!TRANSFER_FAILED!');
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
                    ''
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
                    ''
                );
            } else {
                // we consider it's an ERC20
                require(
                    IERC20Upgradeable(token).transfer(msg.sender, amount),
                    '!TRANSFER_FAILED!'
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
            interfaceId == type(IERC721WithMutableURI).interfaceId ||
            interfaceId == type(IERC2981Royalties).interfaceId ||
            interfaceId == type(IRaribleSecondarySales).interfaceId ||
            interfaceId == type(IFoundationSecondarySales).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @inheritdoc	ERC721Ownable
    function isApprovedForAll(address owner_, address operator)
        public
        view
        override(ERC721Upgradeable, ERC721Ownable)
        returns (bool)
    {
        return super.isApprovedForAll(owner_, operator);
    }

    /// @inheritdoc	ERC721URIStorageUpgradeable
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /// @notice Helper to know if an address can do the action an Editor can
    /// @param user the address to check
    function canEdit(address user) public view virtual returns (bool) {
        return isEditor(user) || owner() == user;
    }

    /// @notice Helper to know if an address can do the action an Editor can
    /// @param user the address to check
    function canMint(address user) public view virtual returns (bool) {
        return isMinter(user) || canEdit(user);
    }

    /// @notice Helper to know if an address is editor
    /// @param user the address to check
    function isEditor(address user) public view returns (bool) {
        return hasRole(ROLE_EDITOR, user);
    }

    /// @notice Helper to know if an address is minter
    /// @param user the address to check
    function isMinter(address user) public view returns (bool) {
        return hasRole(ROLE_MINTER, user);
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
    function setBaseURI(string memory baseURI_)
        external
        onlyEditor(msg.sender)
    {
        baseURI = baseURI_;
    }

    /// @notice Set the base mutable meta URI for tokens
    /// @param baseMutableURI_ the new base for mutable meta uri used in mutableURI()
    function setBaseMutableURI(string memory baseMutableURI_)
        external
        onlyEditor(msg.sender)
    {
        _setBaseMutableURI(baseMutableURI_);
    }

    /// @notice Set the mutable URI for a token
    /// @dev    Mutable URI work like tokenURI
    ///         -> if there is a baseMutableURI and a mutableURI, concat baseMutableURI + mutableURI
    ///         -> else if there is only mutableURI, return mutableURI
    //.         -> else if there is only baseMutableURI, concat baseMutableURI + tokenId
    /// @dev only an editor (account or module) can call this
    /// @param tokenId the token to set the mutable URI for
    /// @param mutableURI_ the mutable URI
    function setMutableURI(uint256 tokenId, string memory mutableURI_)
        external
        onlyEditor(msg.sender)
    {
        require(_exists(tokenId), '!UNKNOWN_TOKEN!');
        _setMutableURI(tokenId, mutableURI_);
    }

    /// @notice Helper for the owner to add new editors
    /// @dev needs to be owner
    /// @param users list of new editors
    function addEditors(address[] memory users) public onlyOwner {
        for (uint256 i; i < users.length; i++) {
            _grantRole(ROLE_MINTER, users[i]);
        }
    }

    /// @notice Helper for the owner to remove editors
    /// @dev needs to be owner
    /// @param users list of removed editors
    function removeEditors(address[] memory users) public onlyOwner {
        for (uint256 i; i < users.length; i++) {
            _revokeRole(ROLE_MINTER, users[i]);
        }
    }

    /// @notice Helper for an editor to add new minter
    /// @dev needs to be owner
    /// @param users list of new minters
    function addMinters(address[] memory users) public onlyEditor(msg.sender) {
        for (uint256 i; i < users.length; i++) {
            _grantRole(ROLE_MINTER, users[i]);
        }
    }

    /// @notice Helper for an editor to remove minters
    /// @dev needs to be owner
    /// @param users list of removed minters
    function removeMinters(address[] memory users)
        public
        onlyEditor(msg.sender)
    {
        for (uint256 i; i < users.length; i++) {
            _revokeRole(ROLE_MINTER, users[i]);
        }
    }

    /// @notice Allows to change the default royalties recipient
    /// @dev an editor can call this
    /// @param recipient new default royalties recipient
    function setDefaultRoyaltiesRecipient(address recipient)
        external
        onlyEditor(msg.sender)
    {
        require(!hasPerTokenRoyalties(), '!PER_TOKEN_ROYALTIES!');
        _setDefaultRoyaltiesRecipient(recipient);
    }

    /// @notice Allows a royalty recipient of a token to change their recipient address
    /// @dev only the current token royalty recipient can change the address
    /// @param tokenId the token to change the recipient for
    /// @param recipient new default royalties recipient
    function setTokenRoyaltiesRecipient(uint256 tokenId, address recipient)
        external
    {
        require(hasPerTokenRoyalties(), '!CONTRACT_WIDE_ROYALTIES!');

        (address currentRecipient, ) = _getTokenRoyalty(tokenId);
        require(msg.sender == currentRecipient, '!NOT_ALLOWED!');

        _setTokenRoyaltiesRecipient(tokenId, recipient);
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
    function _burn(uint256 tokenId)
        internal
        virtual
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        // remove royalties
        _removeRoyalty(tokenId);

        // remove mutableURI
        _setMutableURI(tokenId, '');

        // burn ERC721URIStorage
        super._burn(tokenId);
    }

    /// @inheritdoc	ERC721Upgradeable
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}