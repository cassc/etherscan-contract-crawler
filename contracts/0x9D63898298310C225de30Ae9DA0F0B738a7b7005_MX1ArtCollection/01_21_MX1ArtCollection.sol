// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./ERC721A/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./MintVoucher/MintVoucherValidator.sol";
import "./MintVoucher/LibMintVoucher.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./ERC2981/ERC2981.sol";

/**
 * @dev Samsung MX1 ART COLLECTION NFT.
 * Learn more on https://nft.samsung.de
 */
contract MX1ArtCollection is
    DefaultOperatorFilterer,
    MintVoucherValidator,
    ERC721A,
    ERC2981,
    AccessControl
{
    using Strings for uint256;
    bytes32 public constant AIRDROPPER_ROLE = keccak256("AIRDROPPER_ROLE");
    bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    bool public mintingEnabled = true;

    // Signatures Dictionary
    mapping(uint256 => uint256) public artistForTokenIdentifier;
    mapping(bytes => bool) public usedSignatures;

    string public _baseTokenURI;

    constructor(string memory name, string memory symbol)
        ERC721A(name, symbol)
        MintVoucherValidator(name, "1")
    {
        _setDefaultRoyalty(msg.sender, 500);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(AIRDROPPER_ROLE, msg.sender);
        _grantRole(WITHDRAWER_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);

        // Define Services
        _grantRole(AIRDROPPER_ROLE, 0x0f55AAe58Fb66F922fa1C0844a1c5ca4617de6f3);
        SIGNER_WALLET = 0x11dF40e3D024C4D938A21616d13FEC7b018D01f9;
    }

    /**
     * @dev Sends all funds sent to this contract to the the `msg.sender`.
     *
     * Requirements:
     * - `msg.sender` needs to have {WITHDRAWER_ROLE} and be payable
     */
    function withdrawalAll() external onlyRole(WITHDRAWER_ROLE) {
        require(payable(msg.sender).send(address(this).balance));
    }

    /**
     * @dev Overwrite Token ID Start to skip Token with ID 0
     *
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @dev Mints a token to the users wallet according to the mintvouchers contents. This
     * function should be called through our minting page to obtain a valid mintpass signature.
     *
     * @param mintvoucher issued by the minting app
     * @param mintvoucherSignature issued by minting app and signed by SIGNER_WALLET
     *
     * Requirements:
     * - `mintvoucher` needs to match the signature contents
     * - `mintvoucherSignature` needs to be obtained from minting app and
     *    signed by SIGNER_WALLET
     */
    function allowlistMint(
        LibMintVoucher.MintVoucher memory mintvoucher,
        bytes memory mintvoucherSignature,
        uint256 artistSelection
    ) public onlyMintingEnabled {
        require(
            !usedSignatures[mintvoucherSignature],
            "MX1ArtCollection: Signature already used"
        );
        require(
            (artistSelection > 0 && artistSelection < 4),
            "MX1ArtCollection: Invalid Artist"
        );

        validateMintVoucher(mintvoucher, mintvoucherSignature);
        artistForTokenIdentifier[_nextTokenId()] = artistSelection;
        _mint(mintvoucher.wallet, 1);
        usedSignatures[mintvoucherSignature] = true;
    }

    /**
     * @dev Airdrop Function.
     *
     * @param minter receiver of the tokens
     * @param artistSelection what artist should we set for the token
     *
     * Requirements:
     * - `minter` user that should receive the token
     * - `artistSelection` what artist should we set for the token
     */
    function airdrop(address minter, uint256 artistSelection)
        public
        onlyRole(AIRDROPPER_ROLE)
        onlyMintingEnabled
    {
        require(
            (artistSelection > 0 && artistSelection < 4),
            "MX1ArtCollection: Invalid Artist"
        );

        artistForTokenIdentifier[_nextTokenId()] = artistSelection;
        _mint(minter, 1);
    }

    /**
     * @dev Airdrop Function to airdrop multiple tokens. However,
     * the artist needs to be set in a second transaction in this case for each token.
     *
     * @param minter receiver of the tokens
     * @param quantity how many tokens should be minted
     *
     * Requirements:
     * - `minter` user that should receive the token
     * - `quantity` how many tokens should be minted
     */
    function airdropMultiple(address minter, uint256 quantity)
        public
        onlyRole(AIRDROPPER_ROLE)
        onlyMintingEnabled
    {
        _mint(minter, quantity);
    }

    /**
     * @dev Sets the minting to be enabled or disabled. Sender must have {OPERATOR_ROLE}.
     *
     * @param _mintingEnabled true/false
     */
    function setMintingEnabled(bool _mintingEnabled)
        public
        virtual
        onlyRole(OPERATOR_ROLE)
    {
        mintingEnabled = _mintingEnabled;
    }

    /**
     * @dev Guard to check if minting is enabled
     */
    modifier onlyMintingEnabled() {
        require(
            mintingEnabled == true,
            "MX1ArtCollection: Minting is not Enabled"
        );
        _;
    }

    /**
     * @dev Sets the {SIGNER_WALLET} that generates MintVouchers signatures
     *
     * @param _signerWallet address
     */
    function setSignerWallet(address _signerWallet)
        public
        virtual
        onlyRole(OPERATOR_ROLE)
    {
        SIGNER_WALLET = _signerWallet;
    }

    /**
     * @dev Sets artist for a token if no artist was set before. Fallback for multiple mints.
     *
     * @param tokenId token that should be set
     * @param artistSelection artist that should be set
     */
    function setArtistForToken(uint256 tokenId, uint256 artistSelection)
        public
        virtual
        onlyRole(AIRDROPPER_ROLE)
    {
        require(
            artistForTokenIdentifier[tokenId] == 0,
            "MX1ArtCollection: Artist already set"
        );
        artistForTokenIdentifier[tokenId] = artistSelection;
    }

    /**
     * @dev Can be called by owner to change base URI. This is recommend to be used
     * after tokens are revealed to freeze metadata on IPFS or similar.
     *
     * @param permanentBaseURI URI to be prefixed before tokenId
     */
    function setBaseURI(string memory permanentBaseURI)
        public
        virtual
        onlyRole(OPERATOR_ROLE)
    {
        _baseTokenURI = permanentBaseURI;
    }

    /**
     * @dev Helper to replace _baseURI dynamically
     */
    function _baseURI() internal view virtual override returns (string memory) {
        if (bytes(_baseTokenURI).length > 0) {
            return _baseTokenURI;
        }
        return
            string(
                abi.encodePacked(
                    "https://mx1metadata.bowline.app/",
                    Strings.toHexString(uint256(uint160(address(this))), 20),
                    "/"
                )
            );
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(_baseURI(), "contract-info.json"));
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        public
        virtual
        onlyRole(OPERATOR_ROLE)
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981, AccessControl)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller. Operator must be an allowed operator.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals. Operator must be an allowed operator.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address and must be an allowed operator.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address and must be an allowed operator.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}