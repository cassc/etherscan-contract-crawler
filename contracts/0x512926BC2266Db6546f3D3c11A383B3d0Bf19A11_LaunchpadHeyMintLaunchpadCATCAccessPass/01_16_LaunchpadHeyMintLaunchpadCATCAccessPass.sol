// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC4907A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

/**
 * @author Created with HeyMint Launchpad https://launchpad.heymint.xyz
 * @notice This contract handles minting HeyMint Launchpad CATC Access Pass tokens.
 */
contract LaunchpadHeyMintLaunchpadCATCAccessPass is
    ERC721A,
    ERC721AQueryable,
    ERC4907A,
    Ownable,
    Pausable,
    ERC2981
{
    using ECDSA for bytes32;

    // Used to validate authorized presale mint addresses
    address private presaleSignerAddress =
        0x3346676dfe42a2C7779d43E41A8Ae4f2e98094aD;
    address public royaltyAddress = 0x52EA5F96f004d174470901Ba3F1984D349f0D3eF;
    // Used to allow transferring soulbound tokens with admin privileges
    address public soulboundAdminAddress =
        0x52EA5F96f004d174470901Ba3F1984D349f0D3eF;
    address[] public payoutAddresses = [
        0x52EA5F96f004d174470901Ba3F1984D349f0D3eF
    ];
    // Used to allow an admin to transfer soulbound tokens when necessary
    bool private soulboundAdminTransferInProgress;
    bool public isPresaleActive = false;
    // Permanently freezes metadata so it can never be changed
    bool public metadataFrozen = false;
    // If true souldbind admin address is permanently disabled
    bool public soulbindAdminAddressPermanentlyDisabled = false;
    // If true, tokens can be transferred, if false, tokens are soulbound
    bool public transfersEnabled = false;
    string public baseTokenURI =
        "ipfs://bafybeigrqbssjbkd3xz4gpnulfgldstri7rv5zcycpgchlyy3ruycalkbu/";
    // Maximum supply of tokens that can be minted
    uint256 public constant MAX_SUPPLY = 5000;
    // Total number of tokens available for minting in the presale
    uint256 public constant PRESALE_MAX_SUPPLY = 5000;
    uint256 public presaleMintsAllowedPerAddress = 1;
    uint256 public presaleMintsAllowedPerTransaction = 5000;
    uint256 public presalePrice = 0 ether;
    uint256[] public payoutPercentages = [100];
    uint96 public royaltyFee = 0;

    constructor() ERC721A("HeyMint Launchpad CATC Access Pass", "CAHMAP") {
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

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
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
    function gift(address[] calldata receivers, uint256 mintNumber)
        external
        onlyOwner
    {
        require(
            (totalSupply() + (receivers.length * mintNumber)) <= MAX_SUPPLY,
            "MINT_TOO_LARGE"
        );

        for (uint256 i = 0; i < receivers.length; i++) {
            _safeMint(receivers[i], mintNumber);
        }
    }

    /**
     * @notice To be updated by contract owner to allow presale minting
     */
    function setPresaleState(bool _saleActiveState) public onlyOwner {
        require(
            isPresaleActive != _saleActiveState,
            "NEW_STATE_IDENTICAL_TO_OLD_STATE"
        );
        isPresaleActive = _saleActiveState;
    }

    /**
     * @notice Update the presale mint price
     */
    function setPresalePrice(uint256 _presalePrice) public onlyOwner {
        presalePrice = _presalePrice;
    }

    /**
     * @notice Set the maximum mints allowed per a given address in the presale
     */
    function setPresaleMintsAllowedPerAddress(uint256 _mintsAllowed)
        public
        onlyOwner
    {
        presaleMintsAllowedPerAddress = _mintsAllowed;
    }

    /**
     * @notice Set the maximum presale mints allowed per a given transaction
     */
    function setPresaleMintsAllowedPerTransaction(uint256 _mintsAllowed)
        public
        onlyOwner
    {
        presaleMintsAllowedPerTransaction = _mintsAllowed;
    }

    /**
     * @notice Set the signer address used to verify presale minting
     */
    function setPresaleSignerAddress(address _presaleSignerAddress)
        external
        onlyOwner
    {
        require(_presaleSignerAddress != address(0));
        presaleSignerAddress = _presaleSignerAddress;
    }

    /**
     * @notice Verify that a signed message is validly signed by the presaleSignerAddress
     */
    function verifySignerAddress(bytes32 messageHash, bytes memory signature)
        private
        view
        returns (bool)
    {
        return
            presaleSignerAddress ==
            messageHash.toEthSignedMessageHash().recover(signature);
    }

    /**
     * @notice Allow for allowlist minting of tokens
     */
    function presaleMint(
        bytes32 messageHash,
        bytes calldata signature,
        uint256 numTokens,
        uint256 maximumAllowedMints
    ) external payable originalUser {
        require(isPresaleActive, "PRESALE_IS_NOT_ACTIVE");

        require(
            numTokens <= presaleMintsAllowedPerTransaction,
            "MAX_MINTS_PER_TX_EXCEEDED"
        );
        require(
            _numberMinted(msg.sender) + numTokens <=
                presaleMintsAllowedPerAddress,
            "MAX_MINTS_EXCEEDED"
        );
        require(
            _numberMinted(msg.sender) + numTokens <= maximumAllowedMints,
            "MAX_MINTS_EXCEEDED"
        );
        require(
            totalSupply() + numTokens <= PRESALE_MAX_SUPPLY,
            "MAX_SUPPLY_EXCEEDED"
        );
        require(msg.value == presalePrice * numTokens, "PAYMENT_INCORRECT");
        require(
            keccak256(abi.encode(msg.sender, maximumAllowedMints)) ==
                messageHash,
            "MESSAGE_INVALID"
        );
        require(
            verifySignerAddress(messageHash, signature),
            "SIGNATURE_VALIDATION_FAILED"
        );

        _safeMint(msg.sender, numTokens);

        if (totalSupply() >= PRESALE_MAX_SUPPLY) {
            isPresaleActive = false;
        }
    }

    /**
     * @notice Withdraws all funds held within contract
     */
    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "CONTRACT_HAS_NO_BALANCE");
        uint256 balance = address(this).balance;
        for (uint256 i = 0; i < 1; i++) {
            require(
                payable(payoutAddresses[i]).send(
                    (balance * payoutPercentages[i]) / 100
                )
            );
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
    function setTransferState(bool _transferState) public onlyOwner {
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
    ) public {
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
            require(from == address(0), "Transferring tokens is disabled");
        }
        super._beforeTokenTransfers(from, to, tokenId, quantity);
    }
}