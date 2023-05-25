// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.3;

import "./openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./IERC998.sol";
import "./MoonCatOrderLookup.sol";

//        ##          ##
//      ##  ##      ##  ##
//      ##..  ######  ..##
//    ####              ####
//    ##                  ##
//    ##    ()      ()    ##
//    ##                  ##
//    ##     \  ##  /     ##
//    ##      \/  \/      ##
//      ##              ##
//        ##############
//
//    #AcclimatedMoonCatsGlow
//  https://mooncat.community/


/**
 * @title MoonCat​Acclimator
 * @notice Accepts an original MoonCat and wraps it to present an ERC721- and ERC998-compliant asset
 * @notice Accepts a MoonCat wrapped with the older wrapping contract (at 0x7C40c3...) and re-wraps them
 * @notice Ownable by an admin address. Rights of the Owner are to pause and unpause the contract, and update metadata URL
 */
contract MoonCatAcclimator is
    ERC721,
    ERC721Holder,
    Ownable,
    Pausable,
    IERC998ERC721TopDown,
    IERC998ERC721TopDownEnumerable
{
    bytes32 private constant ERC998_MAGIC_VALUE = 0x00000000000000000000000000000000000000000000000000000000cd740db5;
    bytes4 private constant _INTERFACE_ID_ERC998ERC721TopDown = 0x1efdf36a;

    MoonCatOrderLookup public rescueOrderLookup;

    MoonCatRescue MCR = MoonCatRescue(0x60cd862c9C687A9dE49aecdC3A99b74A4fc54aB6);
    MoonCatsWrapped OLD_MCRW = MoonCatsWrapped(0x7C40c393DC0f283F318791d746d894DdD3693572);

    constructor(string memory baseURI)
        ERC721(unicode"Acclimated​MoonCats", unicode"😺")
        Ownable()
    {
        _registerInterface(_INTERFACE_ID_ERC998ERC721TopDown);
        rescueOrderLookup = new MoonCatOrderLookup();
        setBaseURI(baseURI);
        _pause(); // Start in a paused state
    }

    function pause() public whenNotPaused onlyOwner {
        _pause();
    }
    function unpause() public whenPaused onlyOwner {
        _unpause();
    }

    /**
     * @dev Emitted when `catId` token is wrapped into `tokenId`, owned by `owner`.
     */
    event MoonCatAcclimated(
        uint256 tokenId,
        address indexed owner
    );

    /**
     * @dev Emitted when `catId` token is unwrapped from `tokenId`, owned by `owner`.
     */
    event MoonCatDeacclimated(
        uint256 tokenId,
        address indexed owner
    );

    /**
     * @dev returns tokenId of newly minted wrapped MoonCat
     *
     * Requirements:
     *
     * - Do not need to check if _msgSender() is MoonCat owner as the wrapped token is assigned to owner (even if that's not _msgSender())
     * - Owner needs to call makeAdoptionOfferToAddress() in moonCatRescue first.
     * Emits a {Transfer} ERC721 event.
     * @param _rescueOrder the minting order of the MoonCat to wrap
     * @return the ID (rescue order) of the minted token
     */
    function wrap(uint256 _rescueOrder) public returns (uint256) {
        bytes5 catId = MCR.rescueOrder(_rescueOrder);
        address _owner = MCR.catOwners(catId);
        MCR.acceptAdoptionOffer(catId);
        return _wrap(_owner, _rescueOrder);
    }

    /**
     * @dev returns tokenId of newly minted wrapped MoonCat
     *
     * This method must not allow an adoption offer specifically to the new Wrapper address to be buy-able by anyone,
     * because that is how the real owner sets up a manual wrapping of the MoonCat (where they don't really intend to sell).
     *
     * Requirements:
     *
     * - MoonCat at `_rescueOrder` must be offered for sale to any address.
     * - Must have active makeAdoptionOffer() in moonCatRescue contract.
     * Emits a {Transfer} and {MoonCatAcclimated} event.
     * @param _rescueOrder the minting order of the MoonCat to wrap
     * @return the ID (rescue order) of the minted token
     */
    function buyAndWrap(uint256 _rescueOrder) public payable returns (uint256) {
        bytes5 catId = MCR.rescueOrder(_rescueOrder);
        (bool exists, , , , address onlyOfferTo) = MCR.adoptionOffers(catId);
        require(
            onlyOfferTo == address(0) && exists,
            "That MoonCat is not for sale"
        );
        MCR.acceptAdoptionOffer{value: msg.value}(catId);
        return _wrap(_msgSender(), _rescueOrder);
    }

    /**
     * @dev returns tokenId of burned unwrapped MoonCat
     *
     * Requirements:
     *
     * - msgSender() must be owner.
     * Emits a {Transfer} and {MoonCatDeacclimated} event.
     * @param _tokenId the minting order of the MoonCat to unwrap
     * @return the ID (rescue order) of the burned token
     */
    function unwrap(uint256 _tokenId) public returns (uint256) {
        require(ownerOf(_tokenId) == _msgSender(), "Not your MoonCat!");
        require(
            super._exists(_tokenId),
            "That MoonCat is not wrapped in this contract"
        );
        bytes5 catId = MCR.rescueOrder(_tokenId);
        MCR.giveCat(catId, ownerOf(_tokenId));
        _burn(_tokenId);
        emit MoonCatDeacclimated(_tokenId, _msgSender());
        return _tokenId;
    }

    /**
     * @dev wraps MoonCat that was safeTransferFrom() the old MoonCat wrapper directly in one transaction
     *
     * Requirements:
     * - Owner of old wrapped MoonCat must include the rescueOrder in the calldata as a bytes32
     * Emits a {Transfer} and {MoonCatAcclimated} event.
     * @param _to the address that is to be the owner of the newly-wrapped token
     * @param _oldTokenID the ID of the token in the other wrapping contract
     * @param _rescueOrder the minting order of the MoonCat being wrapped
     * @return the ID (rescue order) of the minted token
     */
    function _wrapOnSafeTransferFromReceipt(
        address _to,
        uint256 _oldTokenID,
        uint256 _rescueOrder
    ) internal returns (uint256) {
        if (
            MCR.rescueOrder(_rescueOrder) !=
            OLD_MCRW._tokenIDToCatID(_oldTokenID)
        ) {
            // Look up rescue order in Lookup contract
            require(
                rescueOrderLookup.oldTokenIdExists(_oldTokenID),
                "Unable to determine proper rescueOrder for this old token ID"
            );
            _rescueOrder = rescueOrderLookup.oldTokenIdToRescueOrder(
                _oldTokenID
            );
            require(
                MCR.rescueOrder(_rescueOrder) ==
                    OLD_MCRW._tokenIDToCatID(_oldTokenID),
                "_oldTokenID and _rescueOrder do not match same catID"
            );
        }
        OLD_MCRW.unwrap(_oldTokenID);
        return _wrap(_to, _rescueOrder);
    }

    /**
     * @dev wraps an unwrapped MoonCat
     *
     * notes:
     * Emits a {Transfer} and {MoonCatAcclimated} event.
     * @param _owner the address that should be the new owner of the newly-created token
     * @param _tokenId the ID of the token to create (rescue order of the MoonCat)
     * @return the ID (rescue order) of the minted token
     */
    function _wrap(address _owner, uint256 _tokenId)
        internal
        returns (uint256)
    {
        require(!paused(), "Attempted wrap while paused");
        _mint(_owner, _tokenId);
        emit MoonCatAcclimated(_tokenId, _msgSender());
        return _tokenId;
    }

    /**
     * @dev Always returns `IERC721Receiver.onERC721Received.selector`
     *
     * This function handles both automatic rewrapping of old-wrapped MoonCats, and assigning ERC721 tokens as "child assets"
     * of MoonCats already wrapped with this contract.
     *
     * If the incoming token is an old-wrapped Mooncat, the `_data` variable is structured as
     * the first 32 bytes are the rescue order of the transferred MoonCat, subsequent 20 bytes
     * are the new owner's address. If the rescue order is not supplied, the `_oldTokenId` is
     * looked up in the {MoonCatOrderLookup} contract. If a new owner's address is not
     * supplied, the new owner will be assigned as the `_from` sender.
     * Emits a {Transfer} and {MoonCatAcclimated} event.
     *
     * If the incoming token is any other type of ERC721, the `_data` variable is structured as
     * the first 32 bytes are the token ID (rescue order) of the MoonCat that is to receive that assest.
     * Emits a {ReceivedChild} event.
     *
     * @param _operator the _msgSender of the transaction
     * @param _from the address of the former owner of the incoming token
     * @param _oldTokenId the ID of the incoming token
     * @param _data additional metdata
     */
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _oldTokenId,
        bytes calldata _data
    ) public override(ERC721Holder, IERC998ERC721TopDown) returns (bytes4) {
        // Using msg.sender here instead of _operator because we want to know the most recent transaction source,
        // not the start of the chain
        if (msg.sender == address(0x7C40c393DC0f283F318791d746d894DdD3693572)) {
            // This is a Wrapped MoonCat incoming. Don't make it a child, instead unwrap and re-wrap it

            // Who should own this MoonCat after wrapping?
            address _to =
                (_data.length >= 32 + 20 && bytesToAddress(_data, 32) != address(0))
                    ? bytesToAddress(_data, 32)
                    : _from;
            require(
                _to != address(0) && _to != address(this),
                "Invalid destination owner specified"
            );

            _wrapOnSafeTransferFromReceipt(
                _to,
                _oldTokenId,
                (_data.length >= 32) ? toUint256(_data, 0) : 0
            );
            return ERC721Holder.onERC721Received(_operator, _from, _oldTokenId, _data);
        }

        // Otherwise, handle as ERC998 Child incoming
        require(_data.length > 0, "_data must contain the uint256 tokenId to transfer the child token to");
        // convert up to 32 bytes of_data to uint256, owner NFT tokenId passed as uint in bytes
        uint256 tokenId;
        assembly {tokenId := calldataload(164)}
        if (_data.length < 32) {
            tokenId = tokenId >> 256 - _data.length * 8;
        }
        _receiveChild(_from, tokenId, msg.sender, _oldTokenId);
        require(ERC721(msg.sender).ownerOf(_oldTokenId) != address(0), "Child token not owned");
        return ERC721Holder.onERC721Received(_operator, _from, _oldTokenId, _data);
    }

    /**
     * @dev sets the base URI
     *
     * notes:
     * - only callable by the contract owner
     */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        _setBaseURI(_newBaseURI);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     * This contract returns the locally-wrapped token count as well as old-wrapped MoonCats
     * that are mapped in the {MoonCatOrderLookup} contract.
     */
    function balanceOf(address _owner) public view override returns (uint256) {
        return
            super.balanceOf(_owner) +
            rescueOrderLookup.entriesPerAddress(_owner);
    }

    /**
    * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     * This contract enumerates the locally-wrapped token count as well as old-wrapped MoonCats
     * that are mapped in the {MoonCatOrderLookup} contract.
    */
    function tokenOfOwnerByIndex(address _owner, uint256 _index)
        public
        view
        override
        returns (uint256)
    {
        uint256 localBalance = super.balanceOf(_owner);
        if (_index < localBalance) {
            // This index is in the range of tokens owned by that address here in this contract
            return super.tokenOfOwnerByIndex(_owner, _index);
        }

        // Looking to enumerate a token that's mapped to the old wrapping contract
        uint16 countFound = 0;
        for (uint256 i = 0; i < OLD_MCRW.balanceOf(_owner); i++) {
            uint256 oldTokenId = OLD_MCRW.tokenOfOwnerByIndex(_owner, i);
            if (rescueOrderLookup.oldTokenIdExists(oldTokenId)) {
                countFound++;
                if (countFound == _index - localBalance + 1) {
                    return
                        rescueOrderLookup.oldTokenIdToRescueOrder(oldTokenId);
                }
            }
        }
        revert("Cannot find token ID for that index");
    }

    /**
    * @dev See {IERC721-ownerOf}.
    */
    function ownerOf(uint256 _tokenId) public view override returns (address) {
        if (super._exists(_tokenId)) {
            return super.ownerOf(_tokenId);
        }

        // Check other wrapper

        // First see if we're dealing with the MoonCat that was the zeroth-wrapped MoonCat in other wrapper
        bytes5 thisMoonCatID = MCR.rescueOrder(_tokenId);
        if (thisMoonCatID == OLD_MCRW._tokenIDToCatID(0)) {
            return OLD_MCRW.ownerOf(0);
        }
        uint256 otherID = OLD_MCRW._catIDToTokenID(thisMoonCatID);
        // We're not dealing with the zeroth-wrapped MoonCat, so a zero here is an indication they don't exist
        require(otherID > 0, "That MoonCat is not wrapped");
        return OLD_MCRW.ownerOf(otherID);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            rescueOrderLookup.entriesPerAddress(_owner) == 0
                ? super.isApprovedForAll(_owner, _operator)
                : super.isApprovedForAll(_owner, _operator) &&
                    OLD_MCRW.isApprovedForAll(_owner, address(this));
    }

    /**
     * @dev See {ERC721-_isApprovedOrOwner}.
     */
    function _isApprovedOrOwner(address _spender, uint256 _tokenId)
        internal
        view
        override
        returns (bool)
    {
        require(
            _exists(_tokenId),
            "ERC721: operator query for nonexistent token"
        );
        // Differs here from OpenZeppelin standard:
        // Calls `ownerOf` instead of `ERC721.ownerOf`
        address _owner = ownerOf(_tokenId);
        return (_spender == _owner ||
            getApproved(_tokenId) == _spender ||
            ERC721.isApprovedForAll(_owner, _spender));
    }

    /**
     * @dev See {ERC721-approve}.
     */
    function approve(address _to, uint256 _tokenId) public override {
        address _owner = ownerOf(_tokenId);
        require(_to != _owner, "ERC721: approval to current owner");
        // Differs here from OpenZeppelin standard:
        // Calls `isApprovedForAll` instead of `ERC721.isApprovedForAll`
        require(
            _msgSender() == _owner || isApprovedForAll(_owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(_to, _tokenId);
    }

    /**
     * @dev rewrap several MoonCats from the old wrapper at once
     * Owner needs to call setApprovalForAll in old wrapper first.
     * @param _rescueOrders an array of MoonCats, identified by rescue order, to rewrap
     * @param _oldTokenIds an array holding the corresponding token ID
     *        in the old wrapper for each MoonCat to be rewrapped
     */
    function batchReWrap(
        uint256[] memory _rescueOrders,
        uint256[] memory _oldTokenIds
    ) public {
        for (uint16 i = 0; i < _rescueOrders.length; i++) {
            address _owner = OLD_MCRW.ownerOf(_oldTokenIds[i]);
            OLD_MCRW.safeTransferFrom(
                _owner,
                address(this),
                _oldTokenIds[i],
                abi.encodePacked(
                    uintToBytes(_rescueOrders[i]),
                    addressToBytes(_owner)
                )
            );
        }
    }

    /**
     * @dev Take a list of unwrapped MoonCat rescue orders and wrap them.
     * @param _rescueOrders an array of MoonCats, identified by rescue order, to rewrap
     */
    function batchWrap(uint256[] memory _rescueOrders) public {
        for (uint16 i = 0; i < _rescueOrders.length; i++) {
            wrap(_rescueOrders[i]);
        }
    }

    /**
     * @dev Take a list of MoonCats wrapped in this contract and unwrap them.
     * @param _rescueOrders an array of MoonCats, identified by rescue order, to unwrap
     */
    function batchUnwrap(uint256[] memory _rescueOrders) public {
        for (uint16 i = 0; i < _rescueOrders.length; i++) {
            unwrap(_rescueOrders[i]);
        }
    }

    /**
     * @dev See {ERC721-_transfer}.
     * If the token being transferred exists in this contract, the standard ERC721 logic is used.
     * If the token does not exist in this contract, look it up in the old wrapping contract,
     * and attempt to wrap-then-transfer it.
     */
    function _transfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal override {
        if (super._exists(_tokenId)) {
            return super._transfer(_from, _to, _tokenId);
        }

        require(_to != address(0), "ERC721: transfer to the zero address");

        if (_to == address(this)) {
            // Sending the token to be owned by this contract? That's not what they meant; make it owned by the original owner after re-wrapping
            _to = _from;
        }
        uint256 oldTokenId =
            OLD_MCRW._catIDToTokenID(MCR.rescueOrder(_tokenId));
        OLD_MCRW.safeTransferFrom(
            _from,
            address(this),
            oldTokenId,
            abi.encodePacked(uintToBytes(_tokenId), addressToBytes(_to))
        );
        rescueOrderLookup.removeEntry(oldTokenId);
    }

    /**
     * @dev See {ERC721-_exists}.
     * If the token being queried exists in this contract, the standard ERC721 logic is used.
     * If the token does not exist in this contract, look it up in the old wrapping contract,
     * and see if it exists there.
     */
    function _exists(uint256 _tokenId) internal view override returns (bool) {
        if (super._exists(_tokenId)) {
            return true;
        }

        // Check if exists in old wrapping contract
        bytes5 realMoonCatZero = OLD_MCRW._tokenIDToCatID(0);
        bytes5 thisMoonCatID = MCR.rescueOrder(_tokenId);
        if (thisMoonCatID == realMoonCatZero) {
            return true;
        }

        return OLD_MCRW._catIDToTokenID(thisMoonCatID) != 0;
    }

    ///// ERC998 /////
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @dev mapping of local token IDs, and which addresses they own children at.
    /// tokenId => child contract
    mapping(uint256 => EnumerableSet.AddressSet) private childContracts;

    /// @dev mapping of local token IDs, addresses they own children at, and IDs of the specific child tokens
    /// tokenId => (child address => array of child tokens)
    mapping(uint256 => mapping(address => EnumerableSet.UintSet)) private childTokens;

    /// @dev mapping of addresses of child tokens, the specific child token IDs, and which local token owns them
    /// child address => childId => tokenId
    mapping(address => mapping(uint256 => uint256)) internal childTokenOwner;
    uint8 constant TOKEN_OWNER_OFFSET = 10;

    /**
     * @dev a token has been transferred to this contract mark which local token is to now own it
     * Emits a {ReceivedChild} event.
     *
     * @param _from the address who sent the token to this contract
     * @param _tokenId the local token ID that is to be the parent
     * @param _childContract the address of the child token's contract
     * @param _childTokenId the ID value of teh incoming child token
     */
    function _receiveChild(address _from, uint256 _tokenId, address _childContract, uint256 _childTokenId) private {
        require(!paused(), "Child received while paused");
        require(super._exists(_tokenId), "That MoonCat is not wrapped in this contract");
        require(childTokens[_tokenId][_childContract].contains(_childTokenId) == false, "Cannot receive child token because it has already been received");
        childContracts[_tokenId].add(_childContract);
        childTokens[_tokenId][_childContract].add(_childTokenId);
        childTokenOwner[_childContract][_childTokenId] = _tokenId + TOKEN_OWNER_OFFSET;
        emit ReceivedChild(_from, _tokenId, _childContract, _childTokenId);
    }

    /**
     * @dev See {IERC998ERC721TopDown-getChild}.
     */
    function getChild(
        address _from,
        uint256 _tokenId,
        address _childContract,
        uint256 _childTokenId
    ) public override {
        _receiveChild(_from, _tokenId, _childContract, _childTokenId);
        IERC721(_childContract).transferFrom(_from, address(this), _childTokenId);
    }

    /**
     * @dev Given a child address/ID that is owned by some token in this contract, return that owning token's owner
     * @param _childContract the address of the child asset being queried
     * @param _childTokenId the specific ID of the child asset being queried
     * @return parentTokenOwner the address of the owner of that child's parent asset
     * @return parentTokenId the local token ID that is the parent of that child asset
     */
    function _ownerOfChild(address _childContract, uint256 _childTokenId) internal view returns (address parentTokenOwner, uint256 parentTokenId) {
        parentTokenId = childTokenOwner[_childContract][_childTokenId];
        require(parentTokenId > 0, "That child is not owned by a token in this contract");
        return (ownerOf(parentTokenId - TOKEN_OWNER_OFFSET), parentTokenId - TOKEN_OWNER_OFFSET);
    }

    /**
     * @dev See {IERC998ERC721TopDown-ownerOfChild}.
     */
    function ownerOfChild(address _childContract, uint256 _childTokenId)
        public
        override
        view
        returns (bytes32 parentTokenOwner, uint256 parentTokenId)
    {
        parentTokenId = childTokenOwner[_childContract][_childTokenId];
        require(parentTokenId > 0, "That child is not owned by a token in this contract");
        return (ERC998_MAGIC_VALUE << 224 | bytes32(uint256(ownerOf(parentTokenId - TOKEN_OWNER_OFFSET))), parentTokenId - TOKEN_OWNER_OFFSET);
    }

    /**
     * @dev See {IERC998ERC721TopDown-rootOwnerOf}.
     */
    function rootOwnerOf(uint256 _tokenId)
        public
        override
        view
        returns (bytes32 rootOwner)
    {
        return rootOwnerOfChild(address(0), _tokenId);
    }

    /**
     * @dev See {IERC998ERC721TopDown-rootOwnerOfChild}.
     */
    function rootOwnerOfChild(address _childContract, uint256 _childTokenId)
        public
        override
        view
        returns (bytes32 rootOwner)
    {
        address rootOwnerAddress;
        if (_childContract != address(0)) {
            (rootOwnerAddress, _childTokenId) = _ownerOfChild(_childContract, _childTokenId);
        } else {
            rootOwnerAddress = ownerOf(_childTokenId);
        }
        // Case 1: Token owner is this contract and token.
        while (rootOwnerAddress == address(this)) {
            (rootOwnerAddress, _childTokenId) = _ownerOfChild(rootOwnerAddress, _childTokenId);
        }

        (bool callSuccess, bytes memory data) = rootOwnerAddress.staticcall(abi.encodeWithSelector(0xed81cdda, address(this), _childTokenId));
        if (data.length != 0) {
            rootOwner = abi.decode(data, (bytes32));
        }

        if(callSuccess == true && rootOwner >> 224 == ERC998_MAGIC_VALUE) {
            // Case 2: Token owner is other top-down composable
            return rootOwner;
        }
        else {
            // Case 3: Token owner is other contract
            // Or
            // Case 4: Token owner is user
            return ERC998_MAGIC_VALUE << 224 | bytes32(uint256(rootOwnerAddress));
        }
    }

    /**
     * @dev remove internal records linking a given child to a given parent
     * @param _tokenId the local token ID that is the parent of the child asset
     * @param _childContract the address of the child asset to remove
     * @param _childTokenId the specific ID representing the child asset to be removed
     */
    function _removeChild(uint256 _tokenId, address _childContract, uint256 _childTokenId) private {
        require(
            childTokens[_tokenId][_childContract].contains(_childTokenId),
            "Child token not owned by token"
        );

        // remove child token
        childTokens[_tokenId][_childContract].remove(_childTokenId);
        delete childTokenOwner[_childContract][_childTokenId];

        // remove contract
        if (childTokens[_tokenId][_childContract].length() == 0) {
            childContracts[_tokenId].remove(_childContract);
        }
    }

    /**
     * @dev check permissions are correct for a transfer of a child asset
     * @param _fromTokenId the local ID of the token that is the parent
     * @param _to the address this child token is being transferred to
     * @param _childContract the address of the child asset's contract
     * @param _childTokenId the specific ID for the child asset being transferred
     */
    function _checkTransferChild(
        uint256 _fromTokenId,
        address _to,
        address _childContract,
        uint256 _childTokenId
    ) private view {
        require(!paused(), "Child transfer while paused");
        uint256 tokenId = childTokenOwner[_childContract][_childTokenId];
        require(tokenId > 0, "Child asset is not owned by a token in this contract");
        tokenId -= TOKEN_OWNER_OFFSET;
        require(tokenId == _fromTokenId, "That MoonCat does not own that asset");
        require(_to != address(0), "Transfer to zero address");
        address rootOwner = address(uint160(uint256(rootOwnerOf(_fromTokenId))));
        require(
            _msgSender() == rootOwner || getApproved(_fromTokenId) == _msgSender() || ERC721.isApprovedForAll(rootOwner, _msgSender()),
            "Not allowed to transfer child assets of that MoonCat"
        );
    }

    /**
     * @dev See {IERC998ERC721TopDown-safeTransferChild}.
     */
    function safeTransferChild(
        uint256 _fromTokenId,
        address _to,
        address _childContract,
        uint256 _childTokenId
    ) public override {
        _checkTransferChild(_fromTokenId, _to, _childContract, _childTokenId);
        _removeChild(_fromTokenId, _childContract, _childTokenId);
        ERC721(_childContract).safeTransferFrom(address(this), _to, _childTokenId);
        emit TransferChild(_fromTokenId, _to, _childContract, _childTokenId);
    }

    /**
     * @dev See {IERC998ERC721TopDown-safeTransferChild}.
     */
    function safeTransferChild(
        uint256 _fromTokenId,
        address _to,
        address _childContract,
        uint256 _childTokenId,
        bytes calldata _data
    ) public override {
        _checkTransferChild(_fromTokenId, _to, _childContract, _childTokenId);
        _removeChild(_fromTokenId, _childContract, _childTokenId);
        ERC721(_childContract).safeTransferFrom(address(this), _to, _childTokenId, _data);
        emit TransferChild(_fromTokenId, _to, _childContract, _childTokenId);
    }

    /**
     * @dev See {IERC998ERC721TopDown-transferChild}.
     */
    function transferChild(
        uint256 _fromTokenId,
        address _to,
        address _childContract,
        uint256 _childTokenId
    ) public override {
        _checkTransferChild(_fromTokenId, _to, _childContract, _childTokenId);
        _removeChild(_fromTokenId, _childContract, _childTokenId);
        //this is here to be compatible with cryptokitties and other old contracts that require being owner and approved
        // before transferring.
        //does not work with current standard which does not allow approving self, so we must let it fail in that case.
        //0x095ea7b3 == "approve(address,uint256)"
        (bool success, bytes memory data) = _childContract.call(abi.encodeWithSelector(0x095ea7b3, this, _childTokenId));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'Failed to Approve'
        );
        ERC721(_childContract).transferFrom(address(this), _to, _childTokenId);
        emit TransferChild(_fromTokenId, _to, _childContract, _childTokenId);
    }

    /**
     * @dev See {IERC998ERC721TopDown-transferChildToParent}.
     */
    function transferChildToParent(
        uint256 _fromTokenId,
        address _toContract,
        uint256 _toTokenId,
        address _childContract,
        uint256 _childTokenId,
        bytes calldata _data
    ) public override {
        _checkTransferChild(_fromTokenId, _toContract, _childContract, _childTokenId);
        _removeChild(_fromTokenId, _childContract, _childTokenId);
        IERC998ERC721BottomUp(_childContract).transferToParent(address(this), _toContract, _toTokenId, _childTokenId, _data);
        emit TransferChild(_fromTokenId, _toContract, _childContract, _childTokenId);
    }

    ///// ERC998 Enumerable

    /**
     * @dev See {IERC998ERC721TopDownEnumerable-totalChildContracts}.
     */
    function totalChildContracts(uint256 _tokenId)
        external
        override
        view
        returns (uint256)
    {
        return childContracts[_tokenId].length();
    }

    /**
     * @dev See {IERC998ERC721TopDownEnumerable-childContractByIndex}.
     */
    function childContractByIndex(uint256 _tokenId, uint256 _index)
        external
        override
        view
        returns (address childContract)
    {
        return childContracts[_tokenId].at(_index);
    }

    /**
     * @dev See {IERC998ERC721TopDownEnumerable-totalChildTokens}.
     */
    function totalChildTokens(uint256 _tokenId, address _childContract) external override view returns (uint256) {
        return childTokens[_tokenId][_childContract].length();
    }

    /**
     * @dev See {IERC998ERC721TopDownEnumerable-childTokenByIndex}.
     */
    function childTokenByIndex(uint256 _tokenId, address _childContract, uint256 _index) external override view returns (uint256 childTokenId) {
        return childTokens[_tokenId][_childContract].at(_index);
    }
}

// UTILITIES

/**
 * @dev converts bytes (which is at least 32 bytes long) to uint256
 */
function toUint256(bytes memory _bytes, uint256 _start) pure returns (uint256) {
    require(_start + 32 >= _start, "toUint256_overflow");
    require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
    uint256 tempUint;

    assembly {
        tempUint := mload(add(add(_bytes, 0x20), _start))
    }

    return tempUint;
}

/**
 * @dev converts uint256 to a bytes(32) object
 */
function uintToBytes(uint256 x) pure returns (bytes memory b) {
    b = new bytes(32);
    assembly {
        mstore(add(b, 32), x)
    }
}

/**
 * @dev converts bytes (which is at least 20 bytes long) to address
 */
function bytesToAddress(bytes memory bys, uint256 _start)
    pure
    returns (address addr)
{
    assembly {
        addr := mload(add(add(bys, 20), _start))
    }
}

/**
 * @dev converts address to a bytes(32) object
 */
function addressToBytes(address a) pure returns (bytes memory) {
    return abi.encodePacked(a);
}