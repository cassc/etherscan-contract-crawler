// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @creator: Pak
/// @author: manifold.xyz

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////
//   _____  _____  _____  _____  _____  _____  _____                                             //
//  |     ||  |  ||  _  ||  _  ||_   _||   __|| __  |                                            //
//  |   --||     ||     ||   __|  | |  |   __||    -|                                            //
//  |_____||__|__||__|__||__|     |_|  |_____||__|__|                                            //
//   _____  _ _ _  _____                                                                         //
//  |_   _|| | | ||     |                                                                        //
//    | |  | | | ||  |  |                                                                        //
//    |_|  |_____||_____|                                                                        //
//   _____  _____  _____  _____  _____  _____  _____  _____  _____  _____  _____  _____  _____   //
//  |     ||   __||_   _||  _  ||     ||     || __  ||  _  ||  |  ||     ||   __||     ||   __|  //
//  | | | ||   __|  | |  |     || | | ||  |  ||    -||   __||     ||  |  ||__   ||-   -||__   |  //
//  |_|_|_||_____|  |_|  |__|__||_|_|_||_____||__|__||__|   |__|__||_____||_____||_____||_____|  //
//                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////

contract Metamorphosis is AdminControl, IERC721, IERC721Metadata {

    using Address for address;
    using Strings for uint256;

    struct Creator {
        address address_;
        bool signed;
        uint32 editions;
        uint32 total;
        string name;
    }

    struct CreatorNFT {
        string name;
        string description;
        string imageURI;
        string animationURI;
    }

    struct CreatorNFTConfig {
      address creator;
      CreatorNFT nft;
    }

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // URI tags and data
    string constant private _NAME_TAG = '<NAME>';
    string constant private _DESCRIPTION_TAG = '<DESCRIPTION>';
    string constant private _CREATOR_TAG = '<CREATOR>';
    string constant private _EDITION_TAG = '<EDITION>';
    string constant private _TOTAL_TAG = '<TOTAL>';
    string constant private _IMAGE_TAG = '<IMAGE>';
    string constant private _ANIMATION_TAG = '<ANIMATION>';
    string constant private _FORM_TAG = '<FORM>';
    string[] private _uriParts;
    bool private _transferLock;

    // Token configuration
    uint256 public MAX_TOKENS;
    uint256 public constant CREATOR_TOKENS = 10;
    uint256 public constant CREATOR_MAX_TOKENS = 250;
    uint256 public MAX_FORM;
    
    Creator[] private _creators;
    // tokenId -> form
    mapping(uint256 => uint256) private _tokenForm;
    // form -> creatorIndex -> CreatorNFT
    mapping(uint256 => mapping(uint256 => CreatorNFT)) private _creatorNFTs;

    bool private _activated;

    uint256 private _royaltyBps;
    address payable private _royaltyRecipient;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_CREATORCORE = 0xbb3bafd6;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;

    constructor() {
        _uriParts = [
            'data:application/json;utf8,{"name":"',_NAME_TAG,' #',_EDITION_TAG,'", "description":"',_DESCRIPTION_TAG,
            '", "created_by":"',_CREATOR_TAG,'", "image":"',_IMAGE_TAG,'", "animation_url":"',_ANIMATION_TAG,
            '", "attributes":[{"trait_type":"Creator","value":"',_CREATOR_TAG,'"},{"trait_type":"Form","value":"',_FORM_TAG,'"}]}'
        ];
        _transferLock = true;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId || 
            interfaceId == _INTERFACE_ID_ROYALTIES_CREATORCORE || 
            interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981 ||
            interfaceId == _INTERFACE_ID_ROYALTIES_RARIBLE ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public pure virtual override returns (string memory) {
        return "Metamorphosis";
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return "MORPH";
    }

    /**
     * View list of all creators
     */
    function creators() external view returns(Creator[] memory) {
        return _creators;
    }

    /**
     * Set participating creators
     */
    function setCreators(Creator[] memory creators_) external adminRequired {
        require(!_activated, "Cannot set creators after activation");
        delete _creators;
        for (uint i; i < creators_.length; i++) {
            Creator memory creator = creators_[i];
            require(!creator.signed, "signed must be false");
            require(creator.editions == 0 && creator.total == 0, "edition and total must be 0");
            _creators.push(creator);
        }
    }

    /**
     * Update nft configuration
     */
    function configureNFTs(uint256 form, CreatorNFTConfig[] memory nftConfigs) external adminRequired {
        require(form > 0 && form <= MAX_FORM, "Invalid form");
        for (uint i; i < nftConfigs.length; i++) {
            CreatorNFTConfig memory nftConfig = nftConfigs[i];
            bool found = false;
            uint creatorIndex;
            for (uint j; j < _creators.length; j++) {
              if (_creators[j].address_ == nftConfig.creator) {
                found = true;
                creatorIndex = j;
                break;
              }
            }
            require(found, "Creator does not exist");
            _creatorNFTs[form-1][creatorIndex] = nftConfig.nft;
        }
    }

    /**
     * Activate
     */
    function activate() external adminRequired {
        require(!_activated, "Already activated");
        for (uint i; i < _creators.length; i++) {
            Creator storage creator = _creators[i];
            creator.editions = uint32(CREATOR_TOKENS);
            creator.total = uint32(CREATOR_TOKENS);
        }
        MAX_TOKENS = CREATOR_MAX_TOKENS*_creators.length;
        _activated = true;
    }

    /**
     * Set the max form
     */
    function setMaxForm(uint256 maxForm) external adminRequired {
        MAX_FORM = maxForm;
    }

    function updateTokenURIParts(string[] memory uriParts) external adminRequired {
        _uriParts = uriParts;
    }

    /**
     * Sign the collection as an creator. Mints the first NFT to them
     */
    function sign() external {
        require(_activated, "Not activated");
        bool found;
        for (uint i; i < _creators.length; i++) {
            if (_creators[i].address_ == msg.sender) {
                require(!_creators[i].signed, "You have already signed");
                found = true;
                _creators[i].signed = true;
                for (uint j; j < CREATOR_TOKENS; j++) {
                    uint256 tokenId = i*CREATOR_MAX_TOKENS+j+1;
                    _mint(msg.sender, msg.sender, tokenId);
                }
                break;
            }
        }
        require(found, "You are not an creator");
    }

    /**
     * @dev Deliver tokens to holders
     */
    function deliver(address creatorAddress, address[] calldata recipients) external adminRequired {
        uint256 creatorIndex;
        bool found;
        for (uint i; i < _creators.length; i++) {
            if (_creators[i].address_ == creatorAddress) {
                found = true;
                creatorIndex = i;
                
                break;
            }
        }
        require(found, "Creator not found");
         
        Creator storage creator = _creators[creatorIndex];
        require(creator.editions+recipients.length <= CREATOR_MAX_TOKENS, "Too many requested");
        for (uint i; i < recipients.length; i++) {
            address recipient = recipients[i];
            uint256 tokenId = creatorIndex*CREATOR_MAX_TOKENS+creator.editions+i+1;
            _mint(creatorAddress, recipient, tokenId);
        }
        creator.editions += uint32(recipients.length);
        creator.total += uint32(recipients.length);
    }

    function _mint(address creator, address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _balances[to] += 1;
        _owners[tokenId] = to;

        if (creator == to) {
            emit Transfer(address(0), to, tokenId);
        } else {
            emit Transfer(address(0), creator, tokenId);
            emit Transfer(creator, to, tokenId);
        }
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        uint256 creatorIndex = tokenCreatorIndex(tokenId);
        CreatorNFT memory creatorNFT = _creatorNFTs[_tokenForm[tokenId]][creatorIndex];
        Creator memory creator = _creators[creatorIndex];
        bytes memory byteString;
        for (uint i; i < _uriParts.length; i++) {
            if (_checkTag(_uriParts[i], _NAME_TAG)) {
                byteString = abi.encodePacked(byteString, creatorNFT.name);
            } else if (_checkTag(_uriParts[i], _DESCRIPTION_TAG)) {
                byteString = abi.encodePacked(byteString, creatorNFT.description);
            } else if (_checkTag(_uriParts[i], _CREATOR_TAG)) {
                byteString = abi.encodePacked(byteString, creator.name);
            } else if (_checkTag(_uriParts[i], _IMAGE_TAG)) {
                byteString = abi.encodePacked(byteString, creatorNFT.imageURI);
            } else if (_checkTag(_uriParts[i], _ANIMATION_TAG)) {
                byteString = abi.encodePacked(byteString, creatorNFT.animationURI);
            } else if (_checkTag(_uriParts[i], _FORM_TAG)) {
                byteString = abi.encodePacked(byteString, (_tokenForm[tokenId]+1).toString());
            } else if (_checkTag(_uriParts[i], _EDITION_TAG)) {
                byteString = abi.encodePacked(byteString, (tokenId-creatorIndex*CREATOR_MAX_TOKENS).toString());
             } else if (_checkTag(_uriParts[i], _TOTAL_TAG)) {
                byteString = abi.encodePacked(byteString, uint256(_creators[creatorIndex].total).toString());
            } else {
                byteString = abi.encodePacked(byteString, _uriParts[i]);
            }
        }
        return string(byteString);
    }

    function _checkTag(string storage a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function setTransferLock(bool lock) public adminRequired {
        _transferLock = lock;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );
        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        require(!_transferLock, "ERC721: transfer not permitted");
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        require(!_transferLock, "ERC721: transfer not permitted");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }


    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        // Transfers to 0xdead are burnt
        if (to == address(0xdead)) {
            _burn(tokenId);
            return;
        }

        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        require(!_transferLock, "ERC721: transfer not permitted");
        _burn(tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);

        _creators[tokenCreatorIndex(tokenId)].total--;
        delete _tokenForm[tokenId];

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * Get token form
     */
    function tokenForm(uint256 tokenId) external view returns (uint256) {
        require(_exists(tokenId), "ERC721Metadata: query for nonexistent token");
        return _tokenForm[tokenId]+1;
    }

    /**
     * Get total count for a given token
    */
    function tokenTotalCount(uint256 tokenId) external view returns (uint256) {
        require(_exists(tokenId), "ERC721Metadata: query for nonexistent token");
        return _creators[tokenCreatorIndex(tokenId)].total;
    }

    function tokenCreatorIndex(uint256 tokenId) private pure returns (uint256) {
        return (tokenId - 1) / CREATOR_MAX_TOKENS;
    }

    /**
     * Morph a token
     */
    function morph(uint256 tokenId, uint256[] calldata burnedTokenIds) external {
        require(!_transferLock, "Morph not permitted");
        require(burnedTokenIds.length == 4, "Insufficient tokens");
        address tokenOwner = ownerOf(tokenId);
        require(msg.sender == tokenOwner, "Must be token owner");
        uint256 currentForm = _tokenForm[tokenId];
        require(currentForm+1 < MAX_FORM, "Max form reached");
        for (uint i; i < burnedTokenIds.length; i++) {
            uint256 burnedTokenId = burnedTokenIds[i];
            require(tokenId != burnedTokenId && ownerOf(burnedTokenId) == msg.sender && _tokenForm[burnedTokenId] >= currentForm, "Invalid token to burn");
            for (uint j=i+1; j < burnedTokenIds.length; j++) {
                require(burnedTokenId != burnedTokenIds[j], "Cannot have duplicate tokens");
            }
            _burn(burnedTokenId);
        }
        _tokenForm[tokenId]++;
    }

    /**
     * ROYALTY FUNCTIONS
     */    
    function updateRoyalties(address payable recipient, uint256 bps) external adminRequired {
        _royaltyRecipient = recipient;
        _royaltyBps = bps;
    }

    function getRoyalties(uint256) external view returns (address payable[] memory recipients, uint256[] memory bps) {
        if (_royaltyRecipient != address(0x0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
            bps = new uint256[](1);
            bps[0] = _royaltyBps;
        }
        return (recipients, bps);
    }

    function getFeeRecipients(uint256) external view returns (address payable[] memory recipients) {
        if (_royaltyRecipient != address(0x0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
        }
        return recipients;
    }

    function getFeeBps(uint256) external view returns (uint[] memory bps) {
        if (_royaltyRecipient != address(0x0)) {
            bps = new uint256[](1);
            bps[0] = _royaltyBps;
        }
        return bps;
    }

    function royaltyInfo(uint256, uint256 value) external view returns (address, uint256) {
        return (_royaltyRecipient, value*_royaltyBps/10000);
    }

}