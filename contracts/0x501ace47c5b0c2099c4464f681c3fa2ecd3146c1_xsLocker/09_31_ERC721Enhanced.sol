// SPDX-License-Identifier: GPL-3.0-or-later
// code borrowed from OpenZeppelin and @uniswap/v3-periphery
pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./../interfaces/utils/IERC1271.sol";
import "./../interfaces/utils/IERC721Enhanced.sol";

/**
 * @title ERC721Enhancedv1
 * @author solace.fi
 * @notice An extension of `ERC721`.
 *
 * The base is OpenZeppelin's `ERC721Enumerable` which also includes the `Metadata` extension. This extension includes simpler transfers, gasless approvals, and changeable URIs.
 */
abstract contract ERC721Enhanced is ERC721Enumerable, IERC721Enhanced, EIP712 {
    using Strings for uint256;

    /// @dev The nonces used in the permit signature verification.
    /// tokenID => nonce
    mapping(uint256 => uint256) private _nonces;

    /// @dev Value is equal to keccak256("Permit(address spender,uint256 tokenID,uint256 nonce,uint256 deadline)");
    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _PERMIT_TYPEHASH = 0x137406564cdcf9b40b1700502a9241e87476728da7ae3d0edfcf0541e5b49b3e;

    string public baseURI;

    /**
     * @notice Constructs the `ERC721Enhancedv1` contract.
     * @param name_ The name of the token.
     * @param symbol_ The symbol of the token.
     */
    constructor(
        string memory name_,
        string memory symbol_
    ) ERC721(name_, symbol_) EIP712(name_, "1") {
        baseURI = "";
    }

    /***************************************
    SIMPLER TRANSFERS
    ***************************************/

    /**
     * @notice Transfers `tokenID` from `msg.sender` to `to`.
     * @dev This was excluded from the official `ERC721` standard in favor of `transferFrom(address from, address to, uint256 tokenID)`. We elect to include it.
     * @param to The receipient of the token.
     * @param tokenID The token to transfer.
     */
    function transfer(address to, uint256 tokenID) public override {
        super.transferFrom(msg.sender, to, tokenID);
    }

    /**
     * @notice Safely transfers `tokenID` from `msg.sender` to `to`.
     * @dev This was excluded from the official `ERC721` standard in favor of `safeTransferFrom(address from, address to, uint256 tokenID)`. We elect to include it.
     * @param to The receipient of the token.
     * @param tokenID The token to transfer.
     */
    function safeTransfer(address to, uint256 tokenID) public override {
        super.safeTransferFrom(msg.sender, to, tokenID, "");
    }

    /***************************************
    GASLESS APPROVALS
    ***************************************/

    /**
     * @notice Approve of a specific `tokenID` for spending by `spender` via signature.
     * @param spender The account that is being approved.
     * @param tokenID The ID of the token that is being approved for spending.
     * @param deadline The deadline timestamp by which the call must be mined for the approve to work.
     * @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`.
     * @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`.
     * @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`.
     */
    function permit(
        address spender,
        uint256 tokenID,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(_exists(tokenID), "query for nonexistent token");
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp <= deadline, "permit expired");

        uint256 nonce = _nonces[tokenID]++; // get then increment
        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(_PERMIT_TYPEHASH, spender, tokenID, nonce, deadline))
                )
            );
        address owner = ownerOf(tokenID);
        require(spender != owner, "cannot permit to self");

        if (Address.isContract(owner)) {
            require(IERC1271(owner).isValidSignature(digest, abi.encodePacked(r, s, v)) == 0x1626ba7e, "unauthorized");
        } else {
            address recoveredAddress = ecrecover(digest, v, r, s);
            require(recoveredAddress != address(0), "invalid signature");
            require(recoveredAddress == owner, "unauthorized");
        }

        _approve(spender, tokenID);
    }

    /**
     * @notice Returns the current nonce for `tokenID`. This value must be
     * included whenever a signature is generated for `permit`.
     * Every successful call to `permit` increases ``tokenID``'s nonce by one. This
     * prevents a signature from being used multiple times.
     * @param tokenID ID of the token to request nonce.
     * @return nonce Nonce of the token.
     */
    function nonces(uint256 tokenID) external view override returns (uint256 nonce) {
        return _nonces[tokenID];
    }

    /**
     * @notice The permit typehash used in the `permit` signature.
     * @return typehash The typehash for the `permit`.
     */
    // solhint-disable-next-line func-name-mixedcase
    function PERMIT_TYPEHASH() external pure override returns (bytes32 typehash) {
        return _PERMIT_TYPEHASH;
    }

    /**
     * @notice The domain separator used in the encoding of the signature for `permit`, as defined by `EIP712`.
     * @return seperator The domain seperator for `permit`.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() public view override returns (bytes32 seperator) {
        return _domainSeparatorV4();
    }

    /***************************************
    CHANGEABLE URIS
    ***************************************/

    /**
     * @notice Returns the Uniform Resource Identifier (URI) for `tokenID` token.
     */
    function tokenURI(uint256 tokenID) public view virtual override tokenMustExist(tokenID) returns (string memory) {
        string memory baseURI_ = baseURI;
        return string(abi.encodePacked(baseURI_, tokenID.toString()));
    }

    /**
     * @notice Base URI for computing `tokenURI`. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenID`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory baseURI_) {
        return baseURI;
    }

    /**
     * @notice Sets the base URI for computing `tokenURI`.
     * @dev Remember to add access control to inheriting contracts.
     * @param baseURI_ The new base URI.
     */
    function _setBaseURI(string memory baseURI_) internal {
        baseURI = baseURI_;
        emit BaseURISet(baseURI_);
    }

    /***************************************
    MODIFIERS
    ***************************************/

    // Call will revert if the token does not exist.
    modifier tokenMustExist(uint256 tokenID) {
        require(_exists(tokenID), "query for nonexistent token");
        _;
    }

    // Call will revert if not made by owner.
    // Call will revert if the token does not exist.
    modifier onlyOwner(uint256 tokenID) {
        require(ownerOf(tokenID) == msg.sender, "only owner");
        _;
    }

    // Call will revert if not made by owner or approved.
    // Call will revert if the token does not exist.
    modifier onlyOwnerOrApproved(uint256 tokenID) {
        require(_isApprovedOrOwner(msg.sender, tokenID), "only owner or approved");
        _;
    }

    /***************************************
    MORE HOOKS
    ***************************************/

    /**
     * @notice Mints `tokenID` and transfers it to `to`.
     * @param to The receiver of the token.
     * @param tokenID The ID of the token to mint.
     */
    function _mint(address to, uint256 tokenID) internal virtual override {
        super._mint(to, tokenID);
        _afterTokenTransfer(address(0), to, tokenID);
    }

    /**
     * @notice Destroys `tokenID`.
     * @param tokenID The ID of the token to burn.
     */
    function _burn(uint256 tokenID) internal virtual override {
        address owner = ERC721.ownerOf(tokenID);
        super._burn(tokenID);
        _afterTokenTransfer(owner, address(0), tokenID);
    }

    /**
     * @notice Transfers `tokenID` from `from` to `to`.
     * @param from The account to transfer the token from.
     * @param to The account to transfer the token to.
     * @param tokenID The ID of the token to transfer.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenID
    ) internal virtual override {
        super._transfer(from, to, tokenID);
        _afterTokenTransfer(from, to, tokenID);
    }

    /**
     * @notice Hook that is called after any token transfer. This includes minting and burning.
     * @param from The user that sends the token, or zero if minting.
     * @param to The zero that receives the token, or zero if burning.
     * @param tokenID The ID of the token being transferred.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenID
    // solhint-disable-next-line no-empty-blocks
    ) internal virtual {}

    /***************************************
    MISC
    ***************************************/

    /**
     * @notice Determines if a token exists or not.
     * @param tokenID The ID of the token to query.
     * @return status True if the token exists, false if it doesn't.
     */
    function exists(uint256 tokenID) external view override returns (bool status) {
        return _exists(tokenID);
    }
}