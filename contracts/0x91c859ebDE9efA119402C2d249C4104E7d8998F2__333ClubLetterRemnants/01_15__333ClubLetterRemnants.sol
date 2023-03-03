// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC4907A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

/**
 * @author Created with HeyMint Launchpad https://launchpad.heymint.xyz
 * @notice This contract handles minting 333 Club Letter Remnants tokens.
 */
contract _333ClubLetterRemnants is
    ERC721A,
    ERC721AQueryable,
    ERC4907A,
    Ownable,
    Pausable,
    ReentrancyGuard,
    ERC2981
{
    address public royaltyAddress = 0xcb1F46d0BA8107c037AdEd570897591d53Aeab23;
    // Used to allow transferring soulbound tokens with admin privileges
    address public soulboundAdminAddress =
        0x72acA6af29b5c8dF2DB90df91884f0a3926ED0F6;
    // Used to allow an admin to transfer soulbound tokens when necessary
    bool private soulboundAdminTransferInProgress;
    // Permanently freezes metadata so it can never be changed
    bool public metadataFrozen = false;
    // If true the soulbind admin address is permanently disabled
    bool public soulbindAdminAddressPermanentlyDisabled = false;
    // If true, tokens can be transferred, if false, tokens are soulbound
    bool public transfersEnabled = false;
    string public baseTokenURI =
        "ipfs://bafybeiev7z5ldrvcxie6doludqqfl2yocqby7trn4qxrdwnz36qn72egbu/";
    // Maximum supply of tokens that can be minted
    uint256 public constant MAX_SUPPLY = 333;
    uint96 public royaltyFee = 0;

    constructor() ERC721A("333 Club Letter Remnants", "333ClubRemnant") {
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    modifier originalUser() {
        require(tx.origin == msg.sender, "Cannot call from contract address");
        _;
    }

    /**
     * @dev Used to directly approve a token for transfers by the current msg.sender,
     * bypassing the typical checks around msg.sender being the owner of a given token
     * from https://github.com/chiru-labs/ERC721A/issues/395#issuecomment-1198737521
     */
    function _directApproveMsgSenderFor(uint256 tokenId) internal {
        assembly {
            mstore(0x00, tokenId)
            mstore(0x20, 6) // '_tokenApprovals' is at slot 6.
            sstore(keccak256(0x00, 0x40), caller())
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * @dev Overrides the default ERC721A _startTokenId() so tokens begin at 1 instead of 0
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @notice Change the royalty fee for the collection
     */
    function setRoyaltyFee(uint96 _feeNumerator) external onlyOwner {
        royaltyFee = _feeNumerator;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    /**
     * @notice Change the royalty address where royalty payouts are sent
     */
    function setRoyaltyAddress(address _royaltyAddress) external onlyOwner {
        royaltyAddress = _royaltyAddress;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    /**
     * @notice Wraps and exposes publicly _numberMinted() from ERC721A
     */
    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    /**
     * @notice Update the base token URI
     */
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        require(!metadataFrozen, "METADATA_HAS_BEEN_FROZEN");
        baseTokenURI = _newBaseURI;
    }

    /**
     * @notice Freeze metadata so it can never be changed again
     */
    function freezeMetadata() external onlyOwner {
        require(!metadataFrozen, "METADATA_HAS_ALREADY_BEEN_FROZEN");
        metadataFrozen = true;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // https://chiru-labs.github.io/ERC721A/#/migration?id=supportsinterface
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC721A, ERC2981, ERC4907A)
        returns (bool)
    {
        // Supports the following interfaceIds:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        // - IERC4907: 0xad092b5c
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId) ||
            ERC4907A.supportsInterface(interfaceId);
    }

    /**
     * @notice Allow owner to send 'mintNumber' tokens without cost to multiple addresses
     */
    function gift(address[] calldata receivers, uint256[] calldata mintNumber)
        external
        onlyOwner
    {
        require(
            receivers.length == mintNumber.length,
            "RECEIVERS_AND_MINT_NUMBERS_MUST_BE_SAME_LENGTH"
        );
        uint256 totalMint = 0;
        for (uint256 i = 0; i < mintNumber.length; i++) {
            totalMint += mintNumber[i];
        }
        require(totalSupply() + totalMint <= MAX_SUPPLY, "MINT_TOO_LARGE");
        for (uint256 i = 0; i < receivers.length; i++) {
            _safeMint(receivers[i], mintNumber[i]);
        }
    }

    /**
     * @notice Change the admin address used to transfer tokens if needed.
     */
    function setSoulboundAdminAddress(address _adminAddress)
        external
        onlyOwner
    {
        require(
            !soulbindAdminAddressPermanentlyDisabled,
            "CHANGING_ADMIN_ADDRESS_PERMANENTLY_DISABLED"
        );
        soulboundAdminAddress = _adminAddress;
    }

    /**
     * @notice Disallow admin transfers of soulbound tokens permanently.
     */
    function disableSoulbindAdminTransfersPermanently() external onlyOwner {
        soulboundAdminAddress = address(0);
        soulbindAdminAddressPermanentlyDisabled = true;
    }

    /**
     * @notice Turn transferability on or off
     */
    function setTransferState(bool _transferState) external onlyOwner {
        transfersEnabled = _transferState;
    }

    /**
     * @notice Allows an admin address to initiate token transfers if user wallets get hacked or lost
     * This function can only be used on soulbound tokens to prevent arbitrary transfers of normal tokens
     */
    function adminTransfer(
        address from,
        address to,
        uint256 tokenId
    ) external {
        require(
            msg.sender == soulboundAdminAddress,
            "CAN_ONLY_BE_CALLED_BY_ADMIN_ADDRESS"
        );
        soulboundAdminTransferInProgress = true;
        _directApproveMsgSenderFor(tokenId);
        safeTransferFrom(from, to, tokenId);
        soulboundAdminTransferInProgress = false;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 tokenId,
        uint256 quantity
    ) internal override(ERC721A) whenNotPaused {
        if (!transfersEnabled && !soulboundAdminTransferInProgress) {
            require(from == address(0), "TOKEN_IS_SOULBOUND");
        }
        super._beforeTokenTransfers(from, to, tokenId, quantity);
    }
}