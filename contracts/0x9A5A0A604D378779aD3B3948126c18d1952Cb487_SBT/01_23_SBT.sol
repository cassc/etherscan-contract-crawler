// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./IERC721Metadata.sol";
import "./IERC4671.sol";
import "./IERC5192.sol";
import "./IERC4973.sol";
import "./ISBT.sol";
import "./ISBTReceiver.sol";

contract SBT is
    Initializable,
    OwnableUpgradeable,
    ERC165Upgradeable,
    EIP712Upgradeable,
    IERC721Metadata,
    IERC4671,
    IERC5192,
    IERC4973,
    ISBT
{
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    struct Token {
        address owner;
        uint256 expiration;
        bool revoked;
    }

    string public constant VERSION = "1";
    bytes32 public constant AGREEMENT_TYPEHASH = keccak256("Agreement(address active,address passive,string tokenURI)");

    bool public claimable;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    address[] internal _minters;
    CountersUpgradeable.Counter internal _tokenIdCounter;

    string internal _baseTokenURI;
    string internal _contractURI;

    // Mapping from token ID to Token
    mapping(uint256 => Token) internal _tokens;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping(address => EnumerableSetUpgradeable.UintSet) internal _holderTokens;

    // Optional mapping for token URIs
    mapping(uint256 => string) internal _tokenURIs;

    /// prevent implementation-contract init() from getting called
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // function as a constructor's alternative
    function initialize(
        address owner,
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        string memory baseURI,
        bool claimable_
    ) public initializer {
        __Ownable_init();
        // Factory's transfering proxy ownership
        transferOwnership(owner);

        _name = name_;
        _symbol = symbol_;
        _contractURI = contractURI_;
        claimable = claimable_;
        _baseTokenURI = baseURI;

        // set default minters
        _minters.push(owner);

        __Context_init();
        __EIP712_init(name_, VERSION);
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() external view override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) external view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];

        if (bytes(_tokenURI).length > 0) {
            return _tokenURI;
        }

        return bytes(_baseTokenURI).length > 0 ? string(abi.encodePacked(_baseTokenURI, tokenId.toString())) : "";
    }

    /**
     * @dev See {IERC4671-isValid}.
     */
    function isValid(uint256 tokenId) external view override returns (bool) {
        /* solhint-disable */
        return (_exists(tokenId) &&
            !_tokens[tokenId].revoked &&
            (_tokens[tokenId].expiration == 0 || _tokens[tokenId].expiration > block.timestamp));
    }

    /**
     * @dev See {IERC4671-hasValid}.
     */
    function hasValid(address owner) external view override returns (bool) {
        return this.balanceOf(owner) > 0;
    }

    /**
     * @dev See {IERC4671-balanceOf}.
     */
    function balanceOf(address owner) external view override(IERC4671, IERC4973) returns (uint256) {
        require(owner != address(0), "Invalid owner");

        uint256 count = 0;
        uint256 len = _holderTokens[owner].length();
        for (uint256 i = 0; i < len; i++) {
            uint256 tokenId = _holderTokens[owner].at(i);
            if (this.isValid(tokenId)) count++;
        }

        return count;
    }

    /**
     * @dev See {IERC4671-ownerOf}.
     */
    function ownerOf(uint256 tokenId) external view override(IERC4671, IERC4973) returns (address) {
        _requireMinted(tokenId);

        return _tokens[tokenId].owner;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Upgradeable, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC4671).interfaceId ||
            interfaceId == type(IERC5192).interfaceId ||
            interfaceId == type(IERC4973).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @dev See {IERC5192-locked}.
    /// @return always return True
    function locked(uint256 tokenId) external view override returns (bool) {
        _requireMinted(tokenId);

        return true;
    }

    /**
     * @dev See {IERC4973-unequip}.
     */
    function unequip(uint256 tokenId) external override {
        _requireMinted(tokenId);

        _burn(tokenId);
    }

    /**
     * @dev See {IERC4973-give}.
     */
    function give(
        address to,
        string calldata uri,
        bytes calldata signature
    ) external override returns (uint256) {
        require(_msgSender() != to, "cannot give from self");

        uint256 tokenId = _safeCheckAgreement(_msgSender(), to, uri, signature);
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);

        return tokenId;
    }

    /**
     * @dev See {IERC4973-take}.
     */
    function take(
        address from,
        string calldata uri,
        bytes calldata signature
    ) external override returns (uint256) {
        _requireClaimable();
        require(_msgSender() != from, "cannot take from self");

        uint256 tokenId = _safeCheckAgreement(_msgSender(), from, uri, signature);
        _safeMint(from, tokenId);
        _setTokenURI(tokenId, uri);

        return tokenId;
    }

    // ============================================================
    // SBT Standard
    // ============================================================

    /// @notice Mark the token as revoked
    /// @param tokenId Identifier of the token
    function revoke(uint256 tokenId, string calldata reason) external virtual onlyOwner {
        _requireMinted(tokenId);
        require(!_tokens[tokenId].revoked, "Token already revoked");

        _tokens[tokenId].revoked = true;

        // // TODO: consider remove token from _holderTokens
        // _holderTokens[_tokens[tokenId].owner].remove(tokenId);

        // emit event {IERC4671-Revoked}
        emit Revoked(_tokens[tokenId].owner, tokenId);

        emit RevokedByReason(_tokens[tokenId].owner, tokenId, reason);
    }

    /// @notice claim a SBT
    /// @dev TODO: User should be able to claim token by proof/signature!?
    /// @dev TODO: This is free for claiming?
    function claim() external virtual {
        _requireClaimable();

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _safeMint(_msgSender(), newTokenId);
    }

    /// @notice mint to receivers
    /// @dev TODO: This is free for claiming?
    /// @param receivers The SBT receiver list
    /// @param expiration expired block timestamp
    function mint(address[] calldata receivers, uint256 expiration) external virtual onlyMinter {
        require(expiration == 0 || expiration > block.timestamp, "Invalid expiration");

        for (uint256 i = 0; i < receivers.length; i++) {
            _tokenIdCounter.increment();
            uint256 newTokenId = _tokenIdCounter.current();
            _safeMint(receivers[i], newTokenId);

            if (expiration > 0) {
                _tokens[newTokenId].expiration = expiration;
                emit ExpirationSet(newTokenId, expiration);
            }
        }
    }

    /// @notice burn a SBT
    /// @dev only owner/winner can burn owned SBT
    /// @param tokenId SBT ID
    function burn(uint256 tokenId) external virtual {
        _burn(tokenId);
    }

    /// @notice set SBT expiration
    /// @param tokenId SBT ID
    /// @param expiration expired block timestamp
    function setExpiration(uint256 tokenId, uint256 expiration) external virtual onlyOwner {
        _requireMinted(tokenId);
        require(!_tokens[tokenId].revoked, "Token already revoked");
        require(expiration == 0 || expiration > block.timestamp, "Invalid expiration");

        _tokens[tokenId].expiration = expiration;

        emit ExpirationSet(tokenId, expiration);
    }

    /**
     * @dev If set, the resulting URI for each token will be the concatenation of the `baseURI` and the `tokenId`. Empty by default
     */
    function setBaseURI(string calldata baseURI) external virtual onlyOwner {
        _baseTokenURI = baseURI;

        emit BaseURISet(_baseTokenURI);
    }

    /// @notice set a minter list
    /// @param minters list of minter address
    function setMinters(address[] calldata minters) external onlyOwner {
        _minters = minters;
    }

    /// @notice enable/disable claiming SBT
    /// @param claimable_ flag to enable/disable claiming SBT
    function setClaimable(bool claimable_) external onlyOwner {
        claimable = claimable_;

        emit ClaimableSet(claimable);
    }

    /// @notice Return the contract URI
    /// @return contractUri The contract URI.
    function contractURI() external view returns (string memory) {
        return _contractURI;
    }

    /// @notice Set the contract URI
    /// @param contractURI_ The contract URI to be set
    function setContractURI(string calldata contractURI_) external onlyOwner {
        _contractURI = contractURI_;
        emit ContractURISet(_contractURI);
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "Mint to the zero address");
        require(!_exists(tokenId), "Token already minted");

        _tokens[tokenId].owner = to;
        _holderTokens[to].add(tokenId);

        // emit event {IERC5192-Locked}
        emit Locked(tokenId);

        // emit event {IERC4671-Minted}
        emit Minted(to, tokenId);

        // emit event {IERC4973-Transfer}
        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = _tokens[tokenId].owner;
        require(_msgSender() == owner, "Invalid owner");

        _holderTokens[owner].remove(tokenId);
        delete _tokens[tokenId];

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        emit Transfer(owner, address(0), tokenId);

        emit Burned(tokenId);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {ISBTReceiver-onSBTReceived}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {ISBTReceiver-onSBTReceived} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(_checkOnSBTReceived(address(0), to, tokenId, data), "transfer to non SBTReceiver implementer");
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to invoke {ISBTReceiver-onSBTReceived} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnSBTReceived(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        /* solhint-disable */
        if (to.isContract()) {
            try ISBTReceiver(to).onSBTReceived(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == ISBTReceiver.onSBTReceived.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("transfer to non SBTReceiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        Token memory token = _tokens[tokenId];
        return token.owner != address(0);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view {
        require(_exists(tokenId), "Invalid token ID");
    }

    /**
     * @dev Reverts if _claimable is false.
     */
    function _requireClaimable() internal view {
        require(claimable, "Not allowed to claim");
    }

    function _existsMinter(address minter) internal view returns (bool) {
        for (uint256 i = 0; i < _minters.length; i++) {
            if (_minters[i] == minter) {
                return true;
            }
        }

        return false;
    }

    function _safeCheckAgreement(
        address active,
        address passive,
        string calldata uri,
        bytes calldata signature
    ) internal virtual returns (uint256) {
        bytes32 hash = _hashTypedDataV4(
            keccak256(abi.encode(AGREEMENT_TYPEHASH, active, passive, keccak256(bytes(uri))))
        );
        uint256 tokenId = uint256(hash);

        require(SignatureCheckerUpgradeable.isValidSignatureNow(passive, hash, signature), "invalid signature");

        return tokenId;
    }

    modifier onlyMinter() {
        require(_existsMinter(_msgSender()), "Restricted to minters");
        _;
    }
}