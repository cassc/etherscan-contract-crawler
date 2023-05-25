// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../burn/IBurnVF.sol";
import "../token/ERC721VF.sol";
import "./VFTokenAllExtensions.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract VFTokenBurnToMint is ERC721VF, VFTokenAllExtensions, ReentrancyGuard {
    using ECDSA for bytes32;

    //Token base URI
    string private _baseUri;

    //Address of burn signer
    address private _mintSigner;

    //Address to burn tokens from
    address private _burnFromContractAddress;

    //Address to burn tokens to
    address public constant BURN_ADDRESS =
        0x000000000000000000000000000000000000dEaD;

    error InvalidMintSignature();

    /**
     * @dev Initializes the contract by setting a `initialBaseUri`, `name`, `symbol`,
     * and a `controlContractAddress` to the token collection.
     */
    constructor(
        string memory initialBaseUri,
        string memory name,
        string memory symbol,
        address controlContractAddress,
        address royaltiesContractAddress,
        address renderingContractAddress,
        address mintSigner,
        address burnFromContractAddress
    )
        ERC721VF(name, symbol)
        VFTokenAllExtensions(
            controlContractAddress,
            royaltiesContractAddress,
            renderingContractAddress
        )
    {
        string memory contractAddress = Strings.toHexString(
            uint160(address(this)),
            20
        );
        setBaseURI(
            string(
                abi.encodePacked(initialBaseUri, contractAddress, "/tokens/")
            )
        );
        _mintSigner = mintSigner;
        _burnFromContractAddress = burnFromContractAddress;
    }

    /**
     * @dev Update the mint signer address with `signer`
     *
     * Requirements:
     *
     * - the caller must be an admin role
     */
    function setMintSigner(address signer) external onlyRole(getAdminRole()) {
        _mintSigner = signer;
    }

    /**
     * @dev Get the base token URI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseUri;
    }

    /**
     * @dev Update the base token URI
     *
     * Requirements:
     *
     * - the caller must be an admin role
     */
    function setBaseURI(string memory baseUri) public onlyRole(getAdminRole()) {
        _baseUri = baseUri;
    }

    /**
     * @dev Permanently lock minting
     *
     * Requirements:
     *
     * - the caller must be an admin role
     */
    function lockMintingPermanently() external onlyRole(getAdminRole()) {
        _lockMintingPermanently();
    }

    /**
     * @dev Set the active/inactive state of minting
     *
     * Requirements:
     *
     * - the caller must be an admin role
     */
    function toggleMintActive() external onlyRole(getAdminRole()) {
        _toggleMintActive();
    }

    /**
     * @dev Set the active/inactive state of burning
     *
     * Requirements:
     *
     * - the caller must be an admin role
     */
    function toggleBurnActive() external onlyRole(getAdminRole()) {
        _toggleBurnActive();
    }

    /**
     * @dev mint batch `to` for `quantity` starting at `startTokenId`
     *
     * Requirements:
     *
     * - the caller must be a minter role
     * - minting must not be locked and must be active
     */
    function mintBatch(
        address to,
        uint8 quantity
    ) external onlyRoles(getMinterRoles()) nonReentrant notLocked mintActive {
        _mintBatch(to, quantity, totalMinted() + 1);
    }

    /**
     * @dev Send tokens to burn island
     *
     * Requirements:
     *
     * - `contractAddress` must support the IERC721 interface
     * - `signature` must be signed by the burn signer address
     * - `nonce` must be unique
     * - `tokenIds` must be owned by the sender
     */
    function burnAndMint(
        string calldata mintId,
        uint256[] calldata tokenIds,
        uint256 nonce,
        bytes calldata signature
    ) external nonReentrant notLocked mintActive {
        bytes32 txHash = _getTxHash(
            mintId,
            _msgSender(),
            tokenIds,
            nonce
        );

        if (!_isValidMintSignature(txHash, signature)) {
            revert InvalidMintSignature();
        }

        for (uint256 i = 0; i < tokenIds.length; i++) {
            IBurnVF(_burnFromContractAddress).transferFrom(
                _msgSender(),
                BURN_ADDRESS,
                tokenIds[i]
            );
        }

        _mintBatch(_msgSender(), tokenIds.length, totalMinted() + 1);
    }

    /**
     * @dev burn `from` token `tokenId`
     *
     * Requirements:
     *
     * - the caller must be a burner role
     * - burning must be active
     */
    function burn(
        address from,
        uint256 tokenId
    ) external onlyRole(getBurnerRole()) burnActive {
        _burn(from, tokenId, false);
    }

    /**
     * @dev If renderingContract is set then returns its tokenURI(tokenId)
     * return value, otherwise returns the standard baseTokenURI + tokenId.
     */
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        if (getRenderingContract() != address(0)) {
            return renderingContractTokenURI(tokenId);
        }
        return super.tokenURI(tokenId);
    }

    /**
     * @dev Validate a burn id is signed by the burn signer address
     */
    function _isValidMintSignature(
        bytes32 txHash,
        bytes calldata signature
    ) internal view returns (bool isValid) {
        address signer = txHash.toEthSignedMessageHash().recover(signature);
        return signer == _mintSigner;
    }

    /**
     * @dev Get the hash of a mint transaction
     */
    function _getTxHash(
        string calldata mintId,
        address sender,
        uint256[] calldata tokenIds,
        uint256 nonce
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(mintId, sender, tokenIds, nonce)
            );
    }
}