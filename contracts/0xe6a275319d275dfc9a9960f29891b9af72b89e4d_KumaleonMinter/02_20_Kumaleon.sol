// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./IERC998.sol";
import "./KumaleonGenArt.sol";

// LICENSE
// Kumaleon.sol is a modified version of MoonCatAcclimator.sol:
// https://github.com/cryptocopycats/contracts/blob/master/mooncats-acclimated/MoonCatAcclimator.sol
//
// MoonCatAcclimator.sol source code licensed under the GPL-3.0-only license.
// Additional conditions of GPL-3.0-only can be found here: https://spdx.org/licenses/GPL-3.0-only.html
//
// MODIFICATIONS
// Kumaleon.sol modifies MoonCatAcclimator to use IERC2981 and original mint().
// And it controls the child tokens so that only authorized tokens are reflected in the NFT visual.

contract Kumaleon is
    ERC721,
    ERC721Holder,
    Ownable,
    IERC998ERC721TopDown,
    IERC998ERC721TopDownEnumerable,
    IERC2981,
    ReentrancyGuard
{
    // ERC998
    bytes32 private constant ERC998_MAGIC_VALUE =
        0x00000000000000000000000000000000000000000000000000000000cd740db5;
    bytes4 private constant _INTERFACE_ID_ERC998ERC721TopDown = 0xcde244d9;
    bytes4 private constant _INTERFACE_ID_ERC998ERC721TopDownEnumerable = 0xa344afe4;

    // kumaleon
    struct AllowlistEntry {
        uint256 minTokenId;
        uint256 maxTokenId;
        address beneficiary;
    }

    uint256 public constant MAX_SUPPLY = 3_000;
    uint256 public totalSupply;
    uint256 public royaltyPercentage = 10;
    uint256 public parentLockAge = 25;
    uint256 private constant FEE_DENOMINATOR = 100;
    address public minter;
    address public moltingHelper;
    address public genArt;
    address private defaultBeneficiary;
    address public constant OKAZZ = 0x783dFB5811B0540875f451c48C13aF6Dd8D42DF5;
    string private baseURI;
    mapping(uint256 => bytes32) public tokenIdToHash;
    mapping(uint256 => bool) public isMolted;
    mapping(uint256 => uint256) public lastTransferChildBlockNumbers;
    mapping(address => AllowlistEntry[]) public childTokenAllowlist;
    bool public isMetadataFrozen;
    bool public isGenArtFrozen;
    bool public isRevealStarted;
    bool public isChildTokenAcceptable;

    event KumaleonTransfer(uint256 tokenId, address childToken, uint256 childTokenId);
    event StartReveal();
    event BaseURIUpdated(string baseURI);
    event SetChildTokenAllowlist(address _address, uint256 minTokenId, uint256 maxTokenId);
    event DeleteChildTokenAllowlist(address _address, uint256 _index);
    event SetGenArt(address _address);

    constructor(address _defaultBeneficiary) ERC721("KUMALEON", "KUMA") {
        setDefaultBeneficiary(_defaultBeneficiary);
    }

    function mint(address _to, uint256 _quantity) external nonReentrant {
        require(totalSupply + _quantity <= MAX_SUPPLY, "Kumaleon: invalid quantity");
        require(msg.sender == minter, "Kumaleon: call from only minter");

        for (uint256 i = 0; i < _quantity; i++) {
            uint256 tokenId = totalSupply;
            totalSupply++;
            tokenIdToHash[tokenId] = keccak256(
                abi.encodePacked(tokenId, block.number, blockhash(block.number - 1), _to)
            );
            _safeMint(OKAZZ, tokenId);
            _safeTransfer(OKAZZ, _to, tokenId, "");
        }
    }

    function molt(
        address _to,
        uint256[] memory _tokenIds,
        uint256[] memory _childTokenIds
    ) external nonReentrant {
        require(msg.sender == moltingHelper, "Kumaleon: call from only molting helper");
        require(_tokenIds.length == _childTokenIds.length, "Kumaleon: invalid length");

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            address rootOwner = address(uint160(uint256(rootOwnerOf(_tokenIds[i]))));
            require(rootOwner == _to, "Kumaleon: Token not owned");

            isMolted[_tokenIds[i]] = true;
            lastTransferChildBlockNumbers[_tokenIds[i]] = block.number;
            KumaleonGenArt(genArt).mintWithHash(
                address(this),
                _to,
                _childTokenIds[i],
                tokenIdToHash[_tokenIds[i]]
            );
            IERC721(genArt).safeTransferFrom(address(this), _to, _childTokenIds[i]);
            emit TransferChild(_tokenIds[i], _to, genArt, _childTokenIds[i]);
        }
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        require(!isMetadataFrozen, "Kumaleon: Already frozen");
        baseURI = _newBaseURI;
        emit BaseURIUpdated(_newBaseURI);
    }

    function freezeMetadata() external onlyOwner {
        require(!isMetadataFrozen, "Kumaleon: Already frozen");
        isMetadataFrozen = true;
    }

    function startReveal() external onlyOwner {
        require(!isRevealStarted, "Kumaleon: Already revealed");
        isRevealStarted = true;
        emit StartReveal();
    }

    function setIsChildTokenAcceptable(bool _bool) external onlyOwner {
        isChildTokenAcceptable = _bool;
    }

    function setMinterAddress(address _minterAddress) external onlyOwner {
        minter = _minterAddress;
    }

    function setMoltingHelperAddress(address _helperAddress) external onlyOwner {
        moltingHelper = _helperAddress;
        isChildTokenAcceptable = true;
    }

    function setChildTokenAllowlist(
        address _address,
        uint256 _minTokenId,
        uint256 _maxTokenId,
        address _beneficiary
    ) external onlyOwner {
        childTokenAllowlist[_address].push(AllowlistEntry(_minTokenId, _maxTokenId, _beneficiary));
        emit SetChildTokenAllowlist(_address, _minTokenId, _maxTokenId);
    }

    function updateChildTokenAllowlistBeneficiary(
        address _childContract,
        uint256 _index,
        address _beneficiary
    ) public onlyOwner {
        childTokenAllowlist[_childContract][_index].beneficiary = _beneficiary;
    }

    function updateChildTokenAllowlistsBeneficiary(
        address[] memory _childContracts,
        uint256[] memory _indices,
        address[] memory _beneficiaries
    ) external onlyOwner {
        require(
            _childContracts.length == _indices.length && _indices.length == _beneficiaries.length,
            "Kumaleon: invalid length"
        );

        for (uint256 i = 0; i < _childContracts.length; i++) {
            updateChildTokenAllowlistBeneficiary(
                _childContracts[i],
                _indices[i],
                _beneficiaries[i]
            );
        }
    }

    // This function could break the original order of array to save gas fees.
    function deleteChildTokenAllowlist(address _address, uint256 _index) external onlyOwner {
        require(_index < childTokenAllowlist[_address].length, "Kumaleon: allowlist not found");

        childTokenAllowlist[_address][_index] = childTokenAllowlist[_address][
            childTokenAllowlist[_address].length - 1
        ];
        childTokenAllowlist[_address].pop();
        if (childTokenAllowlist[_address].length == 0) {
            delete childTokenAllowlist[_address];
        }
        emit DeleteChildTokenAllowlist(_address, _index);
    }

    function childTokenAllowlistByAddress(address _childContract)
        external
        view
        returns (AllowlistEntry[] memory)
    {
        return childTokenAllowlist[_childContract];
    }

    function setGenArt(address _address) external onlyOwner {
        require(!isGenArtFrozen, "Kumaleon: Already frozen");
        genArt = _address;
        emit SetGenArt(_address);
    }

    function freezeGenArt() external onlyOwner {
        require(!isGenArtFrozen, "Kumaleon: Already frozen");
        isGenArtFrozen = true;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _childTokenId,
        bytes memory _data
    ) public override(ERC721Holder, IERC998ERC721TopDown) returns (bytes4) {
        require(
            _data.length > 0,
            "Kumaleon: _data must contain the uint256 tokenId to transfer the child token to."
        );
        // convert up to 32 bytes of_data to uint256, owner nft tokenId passed as uint in bytes
        uint256 tokenId;
        assembly {
            tokenId := calldataload(164)
        }
        if (_data.length < 32) {
            tokenId = tokenId >> (256 - _data.length * 8);
        }
        require(
            IERC721(msg.sender).ownerOf(_childTokenId) == address(this),
            "Kumaleon: Child token not owned."
        );
        _receiveChild(_from, tokenId, msg.sender, _childTokenId);
        return ERC721Holder.onERC721Received(_operator, _from, _childTokenId, _data);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        require(isParentTransferable(tokenId), "Kumaleon: transfer is not allowed");
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        address childContract = childContracts[tokenId].length() > 0
            ? childContractByIndex(tokenId, 0)
            : address(0);
        emit KumaleonTransfer(
            tokenId,
            childContract,
            childContract != address(0) ? childTokenByIndex(tokenId, childContract, 0) : 0
        );
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

    /**
     * @dev a token has been transferred to this contract mark which local token is to now own it
     * Emits a {ReceivedChild} event.
     *
     * @param _from the address who sent the token to this contract
     * @param _tokenId the local token ID that is to be the parent
     * @param _childContract the address of the child token's contract
     * @param _childTokenId the ID value of teh incoming child token
     */
    function _receiveChild(
        address _from,
        uint256 _tokenId,
        address _childContract,
        uint256 _childTokenId
    ) private {
        // kumaleon <--
        require(isChildTokenAcceptable, "Kumaleon: Child received while paused");
        require(isMolted[_tokenId], "Kumaleon: Child received before molt");
        require(
            _msgSender() == _childContract || _msgSender() == _from,
            "Kumaleon: invalid msgSender"
        );
        address rootOwner = address(uint160(uint256(rootOwnerOf(_tokenId))));
        require(_from == rootOwner, "Kumaleon: only owner can transfer child tokens");
        require(_isTokenAllowed(_childContract, _childTokenId), "Kumaleon: Token not allowed");

        if (childContracts[_tokenId].length() != 0) {
            address oldChildContract = childContractByIndex(_tokenId, 0);
            uint256 oldChildTokenId = childTokenByIndex(_tokenId, oldChildContract, 0);

            _removeChild(_tokenId, oldChildContract, oldChildTokenId);
            ERC721(oldChildContract).safeTransferFrom(address(this), rootOwner, oldChildTokenId);
            emit TransferChild(_tokenId, rootOwner, oldChildContract, oldChildTokenId);
        }
        require(
            childContracts[_tokenId].length() == 0,
            "Kumaleon: Cannot receive child token because it has already had"
        );
        // kumaleon -->
        childContracts[_tokenId].add(_childContract);
        childTokens[_tokenId][_childContract].add(_childTokenId);
        childTokenOwner[_childContract][_childTokenId] = _tokenId;
        emit ReceivedChild(_from, _tokenId, _childContract, _childTokenId);
    }

    function _isTokenAllowed(address _childContract, uint256 _childTokenId)
        private
        view
        returns (bool)
    {
        bool allowed;
        for (uint256 i = 0; i < childTokenAllowlist[_childContract].length; i++) {
            if (
                childTokenAllowlist[_childContract][i].minTokenId <= _childTokenId &&
                _childTokenId <= childTokenAllowlist[_childContract][i].maxTokenId
            ) {
                allowed = true;
                break;
            }
        }
        return allowed;
    }

    /**
     * @dev See {IERC998ERC721TopDown-getChild}.
     */
    function getChild(
        address _from,
        uint256 _tokenId,
        address _childContract,
        uint256 _childTokenId
    ) external override {
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
    function _ownerOfChild(address _childContract, uint256 _childTokenId)
        internal
        view
        returns (address parentTokenOwner, uint256 parentTokenId)
    {
        parentTokenId = childTokenOwner[_childContract][_childTokenId];
        require(
            childTokens[parentTokenId][_childContract].contains(_childTokenId),
            "Kumaleon: That child is not owned by a token in this contract"
        );
        return (ownerOf(parentTokenId), parentTokenId);
    }

    /**
     * @dev See {IERC998ERC721TopDown-ownerOfChild}.
     */
    function ownerOfChild(address _childContract, uint256 _childTokenId)
        external
        view
        override
        returns (bytes32 parentTokenOwner, uint256 parentTokenId)
    {
        parentTokenId = childTokenOwner[_childContract][_childTokenId];
        require(
            childTokens[parentTokenId][_childContract].contains(_childTokenId),
            "Kumaleon: That child is not owned by a token in this contract"
        );
        return (
            (ERC998_MAGIC_VALUE << 224) | bytes32(uint256(uint160(ownerOf(parentTokenId)))),
            parentTokenId
        );
    }

    /**
     * @dev See {IERC998ERC721TopDown-rootOwnerOf}.
     */
    function rootOwnerOf(uint256 _tokenId) public view override returns (bytes32 rootOwner) {
        return rootOwnerOfChild(address(0), _tokenId);
    }

    /**
     * @dev See {IERC998ERC721TopDown-rootOwnerOfChild}.
     */
    function rootOwnerOfChild(address _childContract, uint256 _childTokenId)
        public
        view
        override
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

        (bool callSuccess, bytes memory data) = rootOwnerAddress.staticcall(
            abi.encodeWithSelector(0xed81cdda, address(this), _childTokenId)
        );
        if (data.length != 0) {
            rootOwner = abi.decode(data, (bytes32));
        }

        if (callSuccess == true && rootOwner >> 224 == ERC998_MAGIC_VALUE) {
            // Case 2: Token owner is other top-down composable
            return rootOwner;
        } else {
            // Case 3: Token owner is other contract
            // Or
            // Case 4: Token owner is user
            return (ERC998_MAGIC_VALUE << 224) | bytes32(uint256(uint160(rootOwnerAddress)));
        }
    }

    /**
     * @dev remove internal records linking a given child to a given parent
     * @param _tokenId the local token ID that is the parent of the child asset
     * @param _childContract the address of the child asset to remove
     * @param _childTokenId the specific ID representing the child asset to be removed
     */
    function _removeChild(
        uint256 _tokenId,
        address _childContract,
        uint256 _childTokenId
    ) private {
        require(
            childTokens[_tokenId][_childContract].contains(_childTokenId),
            "Kumaleon: Child token not owned by token"
        );

        // remove child token
        childTokens[_tokenId][_childContract].remove(_childTokenId);
        delete childTokenOwner[_childContract][_childTokenId];

        // kumaleon
        lastTransferChildBlockNumbers[_tokenId] = block.number;

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
        uint256 tokenId = childTokenOwner[_childContract][_childTokenId];
        require(
            childTokens[tokenId][_childContract].contains(_childTokenId),
            "Kumaleon: Child asset is not owned by a token in this contract"
        );
        require(tokenId == _fromTokenId, "Kumaleon: Parent does not own that asset");
        address rootOwner = address(uint160(uint256(rootOwnerOf(_fromTokenId))));
        require(
            _msgSender() == rootOwner ||
                getApproved(_fromTokenId) == _msgSender() ||
                isApprovedForAll(rootOwner, _msgSender()),
            "Kumaleon: Not allowed to transfer child assets of parent"
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
        (bool success, bytes memory data) = _childContract.call(
            abi.encodeWithSelector(0x095ea7b3, this, _childTokenId)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "Kumaleon: Failed to Approve"
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
        IERC998ERC721BottomUp(_childContract).transferToParent(
            address(this),
            _toContract,
            _toTokenId,
            _childTokenId,
            _data
        );
        emit TransferChild(_fromTokenId, _toContract, _childContract, _childTokenId);
    }

    ///// ERC998 Enumerable

    /**
     * @dev See {IERC998ERC721TopDownEnumerable-totalChildContracts}.
     */
    function totalChildContracts(uint256 _tokenId) public view override returns (uint256) {
        return childContracts[_tokenId].length();
    }

    /**
     * @dev See {IERC998ERC721TopDownEnumerable-childContractByIndex}.
     */
    function childContractByIndex(uint256 _tokenId, uint256 _index)
        public
        view
        override
        returns (address childContract)
    {
        return childContracts[_tokenId].at(_index);
    }

    /**
     * @dev See {IERC998ERC721TopDownEnumerable-totalChildTokens}.
     */
    function totalChildTokens(uint256 _tokenId, address _childContract)
        external
        view
        override
        returns (uint256)
    {
        return childTokens[_tokenId][_childContract].length();
    }

    /**
     * @dev See {IERC998ERC721TopDownEnumerable-childTokenByIndex}.
     */
    function childTokenByIndex(
        uint256 _tokenId,
        address _childContract,
        uint256 _index
    ) public view override returns (uint256 childTokenId) {
        return childTokens[_tokenId][_childContract].at(_index);
    }

    // kumaleon ERC998

    function isParentTransferable(uint256 _tokenId) public view returns (bool) {
        return
            lastTransferChildBlockNumbers[_tokenId] + parentLockAge < block.number;
    }

    function updateParentLockAge(uint256 _age) external onlyOwner {
        parentLockAge = _age;
    }

    function childTokenDetail(uint256 _tokenId)
        external
        view
        returns (address _childContract, uint256 _childTokenId)
    {
        require(super._exists(_tokenId), "Kumaleon: _tokenId does not exist");

        _childContract = childContracts[_tokenId].length() > 0
            ? childContractByIndex(_tokenId, 0)
            : address(0);
        _childTokenId = _childContract != address(0)
            ? childTokenByIndex(_tokenId, _childContract, 0)
            : 0;
    }

    // interface

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(IERC165, ERC721)
        returns (bool)
    {
        return
            interfaceId == _INTERFACE_ID_ERC998ERC721TopDown ||
            interfaceId == _INTERFACE_ID_ERC998ERC721TopDownEnumerable ||
            interfaceId == type(IERC721Receiver).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // royalty

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        public
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        bool isTokenHasChild = totalChildContracts(_tokenId) != 0;
        uint256 defaultRoyaltyAmount = (_salePrice * royaltyPercentage) / FEE_DENOMINATOR;
        if (!isTokenHasChild) {
            return (defaultBeneficiary, defaultRoyaltyAmount);
        }

        address childContract = Kumaleon(address(this)).childContractByIndex(_tokenId, 0);
        uint256 childTokenId = Kumaleon(address(this)).childTokenByIndex(
            _tokenId,
            childContract,
            0
        );

        for (uint256 i = 0; i < childTokenAllowlist[childContract].length; i++) {
            if (
                childTokenAllowlist[childContract][i].minTokenId <= childTokenId &&
                childTokenId <= childTokenAllowlist[childContract][i].maxTokenId
            ) {
                receiver = childTokenAllowlist[childContract][i].beneficiary;
                royaltyAmount = (_salePrice * royaltyPercentage) / FEE_DENOMINATOR;
                return (receiver, royaltyAmount);
            }
        }

        return (defaultBeneficiary, defaultRoyaltyAmount);
    }

    function setDefaultBeneficiary(address _receiver) public onlyOwner {
        require(_receiver != address(0), "Kumaleon: invalid receiver");

        defaultBeneficiary = _receiver;
    }

    function setRoyaltyPercentage(uint256 _feeNumerator) external onlyOwner {
        require(_feeNumerator <= FEE_DENOMINATOR, "Kumaleon: royalty fee will exceed salePrice");

        royaltyPercentage = _feeNumerator;
    }
}