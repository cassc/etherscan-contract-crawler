///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                          ██████╗  ██████╗ ██████╗ ███████╗██╗    ██╗ ██████╗ ██████╗ ██╗     ██████╗                              //
//                          ██╔═══██╗██╔════╝ ██╔══██╗██╔════╝██║    ██║██╔═══██╗██╔══██╗██║     ██╔══██╗                            //
//                          ██║   ██║██║  ███╗██████╔╝█████╗  ██║ █╗ ██║██║   ██║██████╔╝██║     ██║  ██║                            //
//                          ██║   ██║██║   ██║██╔══██╗██╔══╝  ██║███╗██║██║   ██║██╔══██╗██║     ██║  ██║                            //
//                          ╚██████╔╝╚██████╔╝██║  ██║███████╗╚███╔███╔╝╚██████╔╝██║  ██║███████╗██████╔╝                            //
//                          ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚══════╝ ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═════╝                              //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.11.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./MerkleProof.sol";

error ApprovalCallerNotOwnerNorApproved();
error ApprovalQueryForNonexistentToken();
error MaxLimitExceeded();
error MaxLimitPerTransactionExceeded();
error MintPriceIncorrect();
error MintToZeroAddress();
error MintZeroQuantity();
error NotAnAdmin();
error OwnerQueryForNonexistentToken();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferIsLocked();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error URIQueryForNonexistentToken();
error SaleNotActive();
error WhitelistSaleNotActive();
error NotAWhitelistMember();
error MerkleRootNotFound();

contract OgreWorld is ERC165, IERC721, IERC721Metadata, Ownable, ReentrancyGuard {
    using Address for address;
    using Strings for uint256;

	address private constant STREAM = 0xF87f7075A4B43428d118c8Fbd3a28BE2dbeFeDe8;

    string public name;
    string public symbol;
    string public baseUri;
    string public preRevealUri;

    uint256 private constant MAX_LIMIT = 6667;
    uint256 public constant MAX_MINT_PER_TRANSACTION = 5;
	uint256 public publicMintPrice = 0.045 ether;
    uint256 public whitelistMintPrice = 0.039 ether;
    uint256 private nextId = 1;

    mapping(uint256 => address) private owners;
    mapping(address => uint256) private balances;
    mapping(uint256 => address) private tokenApprovals;
    mapping(address => mapping(address => bool)) private operatorApprovals;

    bool public publicStatus = false;
	bool public whitelistStatus = false;
	bool public revealed = false;

    bytes32 internal merkleRoot = "";

    /**
		Construct a new instance of this ERC-721 contract.
		@param _name The name to assign to this item collection contract.
		@param _symbol The ticker symbol of this item collection.
		@param _baseUri The metadata URI to perform later token ID substitution with.
	*/
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseUri,
        string memory _preRevealUri,
        bytes32 _merkleRoot
    ) {
        name = _name;
        symbol = _symbol;
        baseUri = _baseUri;
        preRevealUri = _preRevealUri;
        merkleRoot = _merkleRoot;
    }

    /**
		Flag this contract as supporting the ERC-721 standard, the ERC-721 metadata
		extension, and the enumerable ERC-721 extension.
		@param _interfaceId The identifier, as defined by ERC-165, of the contract
		interface to support.
		@return Whether or not the interface being tested is supported.
	*/
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            (_interfaceId == type(IERC721).interfaceId) ||
            (_interfaceId == type(IERC721Metadata).interfaceId) ||
            (super.supportsInterface(_interfaceId));
    }

    /**
		Return the total number of this token that have ever been minted.
		@return The total supply of minted tokens.
	*/
    function totalSupply() external view returns (uint256) {
        return nextId - 1;
    }

	function intMint(uint256 _amount) internal {
        if (_amount == 0) { revert MintZeroQuantity(); }
        if (msg.sender == address(0)) { revert MintToZeroAddress(); }
        if (nextId - 1 + _amount > MAX_LIMIT) { revert MaxLimitExceeded(); }

        /**
			Inspired by the Chiru Labs implementation, we use unchecked math here.
			Only enormous minting counts that are unrealistic for our purposes would
			cause an overflow.
		*/
        uint256 startTokenId = nextId;
        unchecked {
            balances[msg.sender] += _amount;
            owners[startTokenId] = msg.sender;

            uint256 updatedIndex = startTokenId;
            for (uint256 i = 0; i < _amount; i++) {
                emit Transfer(address(0), msg.sender, updatedIndex);
                updatedIndex++;
            }
            nextId = updatedIndex;
        }
	}

    /**
		This function allows minters to mint one or more tokens dictated by the `_amount` parameter.
		Any minted tokens are sent to the caller address
		@param _amount The amount of tokens to mint.
	*/
    function mint(uint256 _amount) external payable {
        if (_amount > MAX_MINT_PER_TRANSACTION) { revert MaxLimitPerTransactionExceeded(); }
		if (!publicStatus) { revert SaleNotActive(); }
		if (msg.value < publicMintPrice * _amount) { revert MintPriceIncorrect(); }
        intMint(_amount);
    }

	/**
		This function allows minters to mint one or more tokens dictated by the `_amount` parameter.
		This function can be executed only by whitelisted members
		Any minted tokens are sent to the caller address
		@param _amount The amount of tokens to mint.
	*/
    function whitelistMint(uint256 _amount, bytes32[] calldata _proof) external payable {
        if (!_verify(_leaf(msg.sender), _proof)) { revert NotAWhitelistMember(); }
        if (_amount > MAX_MINT_PER_TRANSACTION) { revert MaxLimitPerTransactionExceeded(); }
		if (!whitelistStatus) { revert WhitelistSaleNotActive(); }
		if (msg.value < whitelistMintPrice * _amount) { revert MintPriceIncorrect(); }
        intMint(_amount);
    }

    /**
		This function allows admin to mint tokens for giveaways
		Any minted tokens are sent to the caller address
		@param _amount The amount of tokens to mint.
	*/
    function raaah(uint256 _amount) external onlyOwner {
        intMint(_amount);
    }

    /**
		Retrieve the number of distinct token IDs held by `_owner`.
		@param _owner The address to retrieve a count of held tokens for.
		@return The number of tokens held by `_owner`.
	*/
    function balanceOf(address _owner)
        external
        view
        override
        returns (uint256)
    {
        return balances[_owner];
    }

    /**
		Just as Chiru Labs does, we maintain a sparse list of token owners; for
		example if Alice owns tokens with ID #1 through #3 and Bob owns tokens #4
		through #5, the ownership list would look like:
		[ 1: Alice, 2: 0x0, 3: 0x0, 4: Bob, 5: 0x0, ... ].
		This function is able to consume that sparse list for determining an actual
		owner. Chiru Labs says that the gas spent here starts off proportional to
		the maximum mint batch size and gradually moves to O(1) as tokens get
		transferred.
		@param _id The ID of the token which we are finding the owner for.
		@return owner The owner of the token with ID of `_id`.
	*/
    function _ownershipOf(uint256 _id) private view returns (address owner) {
        if (!_exists(_id)) { revert OwnerQueryForNonexistentToken(); }
        unchecked {
            for (uint256 curr = _id; ; curr--) {
                owner = owners[curr];
                if (owner != address(0)) {
                    return owner;
                }
            }
        }
    }

    /**
		Return the address that holds a particular token ID.
		@param _id The token ID to check for the holding address of.
		@return The address that holds the token with ID of `_id`.
	*/
    function ownerOf(uint256 _id) external view override returns (address) {
        return _ownershipOf(_id);
    }

    /**
		Return whether a particular token ID has been minted or not.
		@param _id The ID of a specific token to check for existence.
		@return Whether or not the token of ID `_id` exists.
	*/
    function _exists(uint256 _id) public view returns (bool) {
        return _id > 0 && _id < nextId;
    }

    /**
		Return the address approved to perform transfers on behalf of the owner of
		token `_id`. If no address is approved, this returns the zero address.
		@param _id The specific token ID to check for an approved address.
		@return The address that may operate on token `_id` on its owner's behalf.
	*/
    function getApproved(uint256 _id) public view override returns (address) {
        if (!_exists(_id)) { revert ApprovalQueryForNonexistentToken(); }
        return tokenApprovals[_id];
    }

    /**
		This function returns true if `_operator` is approved to transfer items
		owned by `_owner`.
		@param _owner The owner of items to check for transfer ability.
		@param _operator The potential transferrer of `_owner`'s items.
		@return Whether `_operator` may transfer items owned by `_owner`.
	*/
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        virtual
        override
        returns (bool)
    { return operatorApprovals[_owner][_operator]; }

    /**
		Return the token URI of the token with the specified `_id`. The token URI is
		dynamically constructed from this contract's `baseUri`.
		@param _id The ID of the token to retrive a metadata URI for.
		@return The metadata URI of the token with the ID of `_id`.
	*/
    function tokenURI(uint256 _id)
        external
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(_id)) { revert URIQueryForNonexistentToken(); }
        return revealed ? string(abi.encodePacked(baseUri, _id.toString())) : preRevealUri;
    }

    /**
		This private helper function updates the token approval address of the token
		with ID of `_id` to the address `_to` and emits an event that the address
		`_owner` triggered this approval. This function emits an {Approval} event.

		@param _owner The owner of the token with the ID of `_id`.
		@param _to The address that is being granted approval to the token `_id`.
		@param _id The ID of the token that is having its approval granted.
	*/
    function _approve(
        address _owner,
        address _to,
        uint256 _id
    ) private {
        tokenApprovals[_id] = _to;
        emit Approval(_owner, _to, _id);
    }

    /**
		Allow the owner of a particular token ID, or an approved operator of the
		owner, to set the approved address of a particular token ID.

		@param _approved The address being approved to transfer the token of ID `_id`.
		@param _id The token ID with its approved address being set to `_approved`.
	*/
    function approve(address _approved, uint256 _id) external override {
        address owner = _ownershipOf(_id);
        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) { revert ApprovalCallerNotOwnerNorApproved(); }
        _approve(owner, _approved, _id);
    }

    /**
		Enable or disable approval for a third party `_operator` address to manage
		all of the caller's tokens.

		@param _operator The address to grant management rights over all of the
		caller's tokens.
		@param _approved The status of the `_operator`'s approval for the caller.
	*/
    function setApprovalForAll(address _operator, bool _approved)
        external
        override
    {
        operatorApprovals[_msgSender()][_operator] = _approved;
        emit ApprovalForAll(_msgSender(), _operator, _approved);
    }

    /**
		This private helper function handles the portion of transferring an ERC-721
		token that is common to both the unsafe `transferFrom` and the
		`safeTransferFrom` variants.

		This function does not support burning tokens and emits a {Transfer} event.

		@param _from The address to transfer the token with ID of `_id` from.
		@param _to The address to transfer the token to.
		@param _id The ID of the token to transfer.
	*/
    function _transfer(
        address _from,
        address _to,
        uint256 _id
    ) private {
        address previousOwner = _ownershipOf(_id);
        bool isApprovedOrOwner = (_msgSender() == previousOwner) ||
            (isApprovedForAll(previousOwner, _msgSender())) ||
            (getApproved(_id) == _msgSender());

        if (!isApprovedOrOwner) { revert TransferCallerNotOwnerNorApproved(); }
        if (previousOwner != _from) { revert TransferFromIncorrectOwner(); }
        if (_to == address(0)) { revert TransferToZeroAddress(); }

        // Clear any token approval set by the previous owner.
        _approve(previousOwner, address(0), _id);

        /*
			Another Chiru Labs tip: we may safely use unchecked math here given the
			sender balance check and the limited range of our expected token ID space.
		*/
        unchecked {
            balances[_from] -= 1;
            balances[_to] += 1;
            owners[_id] = _to;

            /*
				The way the gappy token ownership list is setup, we can tell that
				`_from` owns the next token ID if it has a zero address owner. This also
				happens to be what limits an efficient burn implementation given the
				current setup of this contract. We need to update this spot in the list
				to mark `_from`'s ownership of this portion of the token range.
			*/
            uint256 nextTokenId = _id + 1;
            if (owners[nextTokenId] == address(0) && _exists(nextTokenId)) {
                owners[nextTokenId] = previousOwner;
            }
        }

        // Emit the transfer event.
        emit Transfer(_from, _to, _id);
    }

    /**
		This function performs an unsafe transfer of token ID `_id` from address
		`_from` to address `_to`. The transfer is considered unsafe because it does
		not validate that the receiver can actually take proper receipt of an
		ERC-721 token.

		@param _from The address to transfer the token from.
		@param _to The address to transfer the token to.
		@param _id The ID of the token being transferred.
	*/
    function transferFrom(
        address _from,
        address _to,
        uint256 _id
    ) external virtual override {
        _transfer(_from, _to, _id);
    }

    /**
		This is an private helper function used to, if the transfer destination is
		found to be a smart contract, check to see if that contract reports itself
		as safely handling ERC-721 tokens by returning the magical value from its
		`onERC721Received` function.

		@param _from The address of the previous owner of token `_id`.
		@param _to The destination address that will receive the token.
		@param _id The ID of the token being transferred.
		@param _data Optional data to send along with the transfer check.

		@return Whether or not the destination contract reports itself as being able
		to handle ERC-721 tokens.
	*/
    function _checkOnERC721Received(
        address _from,
        address _to,
        uint256 _id,
        bytes memory _data
    ) private returns (bool) {
        if (_to.isContract()) {
            try
                IERC721Receiver(_to).onERC721Received(
                    _msgSender(),
                    _from,
                    _id,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver(_to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0)
                    revert TransferToNonERC721ReceiverImplementer();
                else {
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
		This function performs transfer of token ID `_id` from address `_from` to
		address `_to`. This function validates that the receiving address reports
		itself as being able to properly handle an ERC-721 token.

		@param _from The address to transfer the token from.
		@param _to The address to transfer the token to.
		@param _id The ID of the token being transferred.
	*/
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id
    ) external virtual override {
        safeTransferFrom(_from, _to, _id, "");
    }

    /**
		This function performs transfer of token ID `_id` from address `_from` to
		address `_to`. This function validates that the receiving address reports
		itself as being able to properly handle an ERC-721 token. This variant also
		sends `_data` along with the transfer check.

		@param _from The address to transfer the token from.
		@param _to The address to transfer the token to.
		@param _id The ID of the token being transferred.
		@param _data Optional data to send along with the transfer check.
	*/
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        bytes memory _data
    ) public override {
        _transfer(_from, _to, _id);
        if (!_checkOnERC721Received(_from, _to, _id, _data)) { revert TransferToNonERC721ReceiverImplementer(); }
    }

    /**
		Set the base uri for the metadata
		@param _uri The new URI to update to.
	*/
    function setURI(string calldata _uri) external virtual onlyOwner {
        baseUri = _uri;
    }

	/**
		To stop public sale whenever and admin needs
		@param _status true for enabled, false for disabled.
	*/
	function setPublicStatus(bool _status) external onlyOwner {
        publicStatus = _status;
    }

	/**
		To stop whitelist sale whenever admin needs
		@param _status true for enabled, false for disabled.
	*/
	function setWhitelistStatus(bool _status) external onlyOwner {
        whitelistStatus = _status;
    }

    function setPublicMintPrice(uint256 _newPrice) external onlyOwner {
        publicMintPrice = _newPrice;
    }

    function setWhitelistMintPrice(uint256 _newPrice) external onlyOwner {
        whitelistMintPrice = _newPrice;
    }

	/**
		To reveal art whenever admin wants
		@param _status true to reveal and false for default art
	*/
	function setRevealStatus(bool _status) external onlyOwner {
        revealed = _status;
    }

	function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        payable(STREAM).transfer(balance);
    }

    // START - Merkle whitelisting
    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }
    // Verify that a given leaf is in the tree.
    function _verify(bytes32 _leafNode, bytes32[] memory proof) internal view returns (bool) {
        if(merkleRoot.length < 1) { revert MerkleRootNotFound(); }
        return MerkleProof.verify(proof, merkleRoot, _leafNode);
    }
    // END - Merkle whitelisting
}