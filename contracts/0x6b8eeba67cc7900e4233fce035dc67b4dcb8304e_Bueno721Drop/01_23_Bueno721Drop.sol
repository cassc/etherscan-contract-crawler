// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts-upgradeable/finance/PaymentSplitterUpgradeable.sol";
import "operator-filter-registry/src/upgradeable/OperatorFiltererUpgradeable.sol";

struct PhaseSettings {
    /// @dev phase supply. This can be released to public by ending the phase.
    uint64 maxSupply;
    /// @dev tracks the total amount minted in the phase
    uint64 amountMinted;
    /// @dev wallet maximum for the phase
    uint64 maxPerWallet;
    /// @dev merkle root for the phase (if applicable, otherwise bytes32(0))
    bytes32 merkleRoot;
    /// @dev whether the phase is active
    bool isActive;
    /// @dev price for the phase (or free if 0)
    uint256 price;
}

struct BaseSettings {
    /// @dev public sale supply. ending a phase will carry supply into this value
    uint64 maxSupply;
    /// @dev global wallet maximum across all phases (including public)
    uint64 maxPerWallet;
    /// @dev tracks the total amount minted in the public sale
    uint64 amountMinted;
    /// @dev price for the public sale (or free if 0)
    uint256 price;
}

struct SaleState {
    uint64 numPhases;
    mapping(uint256 => PhaseSettings) phases;
}

struct PaymentSplitterSettings {
    address[] payees;
    uint256[] shares;
}

struct RoyaltySettings {
    address royaltyAddress;
    uint96 royaltyAmount;
}

error SaleInactive();
error SoldOut();
error InvalidPrice();
error ExceedMaxPerWallet();
error InvalidProof();
error PhaseNotActive();
error NotAllowlisted();
error InvalidMintFunction();
error InvalidAirdrop();
error InvalidPhase();
error BurningNotAllowed();

/// @author Bueno.art
/// @title ERC-721 Multi-Phase Drop Contract
contract Bueno721Drop is
    ERC721AQueryableUpgradeable,
    OwnableUpgradeable,
    ERC2981Upgradeable,
    PaymentSplitterUpgradeable,
    OperatorFiltererUpgradeable
{
    string public _baseTokenURI;

    SaleState public saleState;
    BaseSettings public baseSettings;

    uint256 public maxSupply;

    address[] public withdrawAddresses;

    mapping(address => mapping(uint256 => uint64)) private amountMintedForPhase;

    bool public isPublicActive;
    bool private allowBurning;

    event TokensMinted(address indexed to, uint256 quantity);
    event TokenBurned(address indexed owner, uint256 tokenId);
    event TokensAirdropped(uint256 numRecipients, uint256 numTokens);
    event PhasesActivated(uint256[] phaseIds, bool activatedPublic);
    event PhasesPaused(uint256[] phaseIds, bool pausedPublic);
    event PhaseEnded(uint256 phaseIds);
    event BurnStatusChanged(bool burnActive);
    event PhaseSettingsUpdated(uint256 phaseId, PhaseSettings settings);
    event BaseSettingsUpdated(BaseSettings settings);
    event BaseURIUpdated(string baseURI);
    event RoyaltyUpdated(address royaltyAddress, uint96 royaltyAmount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _baseUri,
        RoyaltySettings calldata _royaltySettings,
        PhaseSettings[] calldata _phases,
        BaseSettings calldata _baseSettings,
        PaymentSplitterSettings calldata _paymentSplitterSettings,
        uint256 _maxIntendedSupply,
        bool _allowBurning,
        address _deployer,
        address _operatorFilter
    ) public initializerERC721A initializer {
        __ERC721A_init(_name, _symbol);
        __Ownable_init();
        __PaymentSplitter_init(
            _paymentSplitterSettings.payees,
            _paymentSplitterSettings.shares
        );

        uint64 numPhases = uint64(_phases.length);
        uint256 supplyValidationCount = _baseSettings.maxSupply;

        for (uint256 i = 0; i < numPhases; ) {
            saleState.phases[i] = _phases[i];
            supplyValidationCount += _phases[i].maxSupply;

            // numPhases has a maximum value of 2^64 - 1
            unchecked {
                ++i;
            }
        }

        require(
            supplyValidationCount == _maxIntendedSupply,
            "Supply of all phases must equal maxIntendedSupply"
        );

        _baseTokenURI = _baseUri;
        withdrawAddresses = _paymentSplitterSettings.payees;
        saleState.numPhases = numPhases;
        baseSettings = _baseSettings;
        allowBurning = _allowBurning;
        maxSupply = _maxIntendedSupply;

        _setDefaultRoyalty(
            _royaltySettings.royaltyAddress,
            _royaltySettings.royaltyAmount
        );
        transferOwnership(_deployer);

        OperatorFiltererUpgradeable.__OperatorFilterer_init(
            _operatorFilter,
            _operatorFilter == address(0) ? false : true // only subscribe if a filter is provided
        );
    }

    // ========= EXTERNAL MINTING METHODS =========

    /**
     * @notice Mint tokens for an allowlisted phase
     * @dev Calling this function for a phase that doesn't have an allowlist will fail
     */
    function mintPhaseAllowlist(
        uint256 phaseIndex,
        uint64 quantity,
        bytes32[] calldata proof
    ) external payable {
        uint64 updatedAmountMinted = _checkAllowlistPhaseMintConditions(
            msg.sender,
            quantity,
            proof,
            phaseIndex,
            msg.value
        );

        _checkGlobalPerWalletMax(msg.sender, quantity);

        saleState.phases[phaseIndex].amountMinted += quantity;
        amountMintedForPhase[msg.sender][phaseIndex] = updatedAmountMinted;

        _mint(msg.sender, quantity);

        emit TokensMinted(msg.sender, quantity);
    }

    /**
     * @notice Mint tokens for a non-allowlist phase.
     * @dev Calling this function for a phase that has an allowlist will fail
     */
    function mintPhase(uint256 phaseIndex, uint64 quantity) external payable {
        uint64 updatedAmountMinted = _checkPhaseMintConditions(
            msg.sender,
            quantity,
            phaseIndex,
            msg.value
        );

        _checkGlobalPerWalletMax(msg.sender, quantity);

        saleState.phases[phaseIndex].amountMinted += quantity;
        amountMintedForPhase[msg.sender][phaseIndex] = updatedAmountMinted;

        _mint(msg.sender, quantity);

        emit TokensMinted(msg.sender, quantity);
    }

    /**
     * @notice Mint tokens in the public sale
     */
    function mintPublic(uint64 quantity) external payable {
        uint64 updatedAmountMinted = _checkPublicMintConditions(
            quantity,
            msg.value
        );
        _checkGlobalPerWalletMax(msg.sender, quantity);

        baseSettings.amountMinted = updatedAmountMinted;

        _mint(msg.sender, quantity);

        emit TokensMinted(msg.sender, quantity);
    }

    /**
     * @notice Mint tokens in all possible phases (including public sale)
     */
    function mintBatch(
        uint64[] calldata quantities,
        bytes32[][] calldata proofs,
        uint256[] calldata phaseIndices,
        uint64 publicQuantity
    ) external payable {
        uint256 phaseLength = phaseIndices.length;

        if (
            phaseLength > saleState.numPhases ||
            phaseLength != quantities.length ||
            phaseLength != proofs.length
        ) {
            revert InvalidPhase();
        }

        uint256 balance = msg.value;
        uint256 quantityToMint;

        for (uint256 i = 0; i < phaseLength; ) {
            uint64 updatedAmount;
            uint256 phaseIndex = phaseIndices[i];
            uint64 quantity = quantities[i];
            bytes32[] calldata proof = proofs[i];
            PhaseSettings storage phase = saleState.phases[phaseIndex];
            uint256 priceForPhase = phase.price * quantity;

            // Since price is strictly checked in the _check* functions below,
            // we have an additional check here to ensure that the balance doesn't underflow
            if (balance < priceForPhase) {
                revert InvalidPrice();
            }

            // if the phase has no allowlist, the merkleRoot will be zeroed out.
            if (phase.merkleRoot == bytes32(0)) {
                updatedAmount = _checkPhaseMintConditions(
                    msg.sender,
                    quantity,
                    phaseIndex,
                    priceForPhase
                );
            } else {
                updatedAmount = _checkAllowlistPhaseMintConditions(
                    msg.sender,
                    quantity,
                    proof,
                    phaseIndex,
                    priceForPhase
                );
            }

            // quantity & phaseLength have a maximum value of 2^64 - 1
            // balance underflow is checked above
            unchecked {
                saleState.phases[phaseIndex].amountMinted += quantity;
                amountMintedForPhase[msg.sender][phaseIndex] = updatedAmount;
                balance -= priceForPhase;
                quantityToMint += quantity;
                ++i;
            }
        }

        uint256 totalMintQuantity = quantityToMint;

        if (publicQuantity > 0) {
            _checkPublicMintConditions(publicQuantity, balance);

            // publicQuantity has a max value of 2^64 - 1
            unchecked {
                baseSettings.amountMinted += publicQuantity;
                totalMintQuantity += publicQuantity;
            }
        }

        _checkGlobalPerWalletMax(msg.sender, totalMintQuantity);

        _mint(msg.sender, totalMintQuantity);

        emit TokensMinted(msg.sender, totalMintQuantity);
    }

    /**
     * @notice Burn a token, if the contract allows for it
     */
    function burn(uint256 tokenId) external {
        if (!allowBurning) {
            revert BurningNotAllowed();
        }

        _burn(tokenId, true);

        emit TokenBurned(msg.sender, tokenId);
    }

    // ========= OWNER METHODS =========

    /**
     * @notice Perform a batch airdrop for a particular phase.
     * @dev Minted tokens are pulled from the phase that is specified in the airdropper.
     */
    function airdropForPhase(
        uint256 phaseIndex,
        uint64[] calldata quantities,
        address[] calldata recipients
    ) external onlyOwner {
        uint256 numRecipients = recipients.length;
        uint256 totalAirdropped;
        if (numRecipients != quantities.length) revert InvalidAirdrop();

        PhaseSettings storage phase = saleState.phases[phaseIndex];

        for (uint256 i = 0; i < numRecipients; ) {
            uint64 updatedAmountMinted = phase.amountMinted + quantities[i];
            if (updatedAmountMinted > phase.maxSupply) {
                revert SoldOut();
            }

            // airdrops are not subject to the per-wallet mint limits,
            // but we track how much is minted for the phase
            phase.amountMinted = updatedAmountMinted;
            totalAirdropped += quantities[i];

            _mint(recipients[i], quantities[i]);

            // numRecipients has a maximum value of 2^256 - 1
            unchecked {
                ++i;
            }
        }

        emit TokensAirdropped(numRecipients, totalAirdropped);
    }

    /**
     * @notice Perform a batch airdrop for the public phase.
     * @dev Minted tokens are pulled from the public phase.
     */
    function airdropPublic(
        uint64[] calldata quantities,
        address[] calldata recipients
    ) external onlyOwner {
        uint256 numRecipients = recipients.length;
        uint256 totalAirdropped;
        if (numRecipients != quantities.length) revert InvalidAirdrop();

        for (uint256 i = 0; i < numRecipients; ) {
            uint64 updatedAmountMinted = baseSettings.amountMinted +
                quantities[i];

            if (updatedAmountMinted > baseSettings.maxSupply) {
                revert SoldOut();
            }

            // airdrops are not subject to the per-wallet mint limits,
            // but we track how much is minted for the phase
            baseSettings.amountMinted = updatedAmountMinted;
            totalAirdropped += quantities[i];

            _mint(recipients[i], quantities[i]);

            // numRecipients has a maximum value of 2^256 - 1
            unchecked {
                ++i;
            }
        }

        emit TokensAirdropped(numRecipients, totalAirdropped);
    }

    /**
     * @notice Specify which phases are active.
     * Public sale can be activated by setting `activatePublic` to true.
     */
    function activatePhases(
        uint256[] calldata phaseIndices,
        bool activatePublic
    ) external onlyOwner {
        uint256 numPhases = phaseIndices.length;

        // activate all the phases provided in phaseIndices
        for (uint256 i = 0; i < numPhases; ) {
            uint256 phaseIndex = phaseIndices[i];

            if (phaseIndex >= saleState.numPhases) {
                // phaseIndex is out of bounds
                revert InvalidPhase();
            }

            saleState.phases[phaseIndices[i]].isActive = true;

            // numPhases has a maximum value of 2^256 - 1
            unchecked {
                ++i;
            }
        }

        // calling this function with activatePublic=false only indicates the public sale
        // is not intended to be activated, but it does not pause it.
        if (activatePublic) {
            isPublicActive = true;
        }

        emit PhasesActivated(phaseIndices, activatePublic);
    }

    /**
     * @notice Specify which phases are inactive (paused).
     * Public sale can be paused by setting `pausePublic` to true.
     * Pausing is separate from ending, since ending permanently closes the phase.
     */
    function pausePhases(
        uint256[] calldata phaseIndices,
        bool pausePublic
    ) external onlyOwner {
        uint256 numPhases = phaseIndices.length;

        for (uint256 i = 0; i < numPhases; ) {
            uint256 phaseIndex = phaseIndices[i];

            if (phaseIndex >= saleState.numPhases) {
                // phaseIndex is out of bounds
                revert InvalidPhase();
            }

            saleState.phases[phaseIndex].isActive = false;

            // numPhases has a maximum value of 2^256 - 1
            unchecked {
                ++i;
            }
        }

        // calling this function with pausePublic=false only indicates the public sale
        // is not intended to be paused, but it does not pause it.
        if (pausePublic) {
            isPublicActive = false;
        }

        emit PhasesPaused(phaseIndices, pausePublic);
    }

    /**
     * @notice If enabled, the token can be burned, for approved operators.
     * @dev The burn method will revert unless this is enabled
     */
    function toggleBurning() external onlyOwner {
        allowBurning = !allowBurning;

        emit BurnStatusChanged(allowBurning);
    }

    /**
     * @notice Permanently closes a phase by capping the supply & releasing it
     */
    function endPhase(uint256 phaseIndex) public onlyOwner {
        PhaseSettings storage phase = saleState.phases[phaseIndex];

        // if the phase never had supply, there is nothing to do
        if (phase.maxSupply == 0) {
            revert InvalidPhase();
        }

        // transfer the remaining supply into the base settings (used for public sale accounting)
        baseSettings.maxSupply += phase.maxSupply - phase.amountMinted;

        // remove the supply from the phase
        phase.maxSupply = 0;

        emit PhaseEnded(phaseIndex);
    }

    function endPhases(uint64[] calldata phaseIndices) external onlyOwner {
        uint256 phaseIndicesLength = phaseIndices.length;

        // ensure that phaseIndices argument will only ever be as large as the number of phases
        if (phaseIndicesLength > saleState.numPhases) {
            revert InvalidPhase();
        }

        for (uint256 i = 0; i < phaseIndicesLength; ) {
            endPhase(phaseIndices[i]);

            // phaseIndicesLength has a maximum value of 2^256 - 1
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Updates the minting rules for a particular phase
     * @dev supply & amountMinted are not changeable
     */
    function updatePhaseSettings(
        uint256 phaseIndex,
        PhaseSettings calldata phase
    ) external onlyOwner {
        uint64 existingAmountMinted = saleState.phases[phaseIndex].amountMinted;
        uint64 existingMaxSupply = saleState.phases[phaseIndex].maxSupply;
        bool existingStatus = saleState.phases[phaseIndex].isActive;

        saleState.phases[phaseIndex] = phase;

        // ensure that the amountMinted, maxSupply, and status values cannot be set
        saleState.phases[phaseIndex].amountMinted = existingAmountMinted;
        saleState.phases[phaseIndex].maxSupply = existingMaxSupply;
        saleState.phases[phaseIndex].isActive = existingStatus;

        emit PhaseSettingsUpdated(phaseIndex, phase);
    }

    /**
     * @notice Updates the the base minting settings
     * The global maxPerWallet setting applies to all phases
     * Pricing and other fields will apply to the public sale
     *
     * @dev maxSupply & amountMinted are not changeable
     */
    function updateBaseSettings(
        BaseSettings calldata _baseSettings
    ) external onlyOwner {
        uint64 existingMaxSupply = baseSettings.maxSupply;
        uint64 existingAmountMinted = baseSettings.amountMinted;

        baseSettings = _baseSettings;

        // ensure that the maxSupply & amountMinted value cannot be set
        baseSettings.maxSupply = existingMaxSupply;
        baseSettings.amountMinted = existingAmountMinted;

        emit BaseSettingsUpdated(_baseSettings);
    }

    /**
     * @dev Payment can be pulled via PaymentSplitter.release
     * this method is provided for convenience to release all payee funds
     */
    function withdraw() external onlyOwner {
        uint256 numAddresses = withdrawAddresses.length;

        for (uint256 i = 0; i < numAddresses; ) {
            address payable withdrawAddress = payable(withdrawAddresses[i]);

            if (releasable(withdrawAddress) > 0) {
                release(withdrawAddress);
            }

            // numAddresses has a maximum value of 2^256 - 1
            unchecked {
                ++i;
            }
        }
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;

        emit BaseURIUpdated(baseURI);
    }

    function setRoyaltyInfo(
        address receiver,
        uint96 feeBasisPoints
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, feeBasisPoints);

        emit RoyaltyUpdated(receiver, feeBasisPoints);
    }

    // ========= VIEW METHODS =========

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _checkAllowlistPhaseMintConditions(
        address wallet,
        uint64 quantity,
        bytes32[] calldata proof,
        uint256 phaseIndex,
        uint256 balance
    ) internal view returns (uint64) {
        PhaseSettings storage phase = saleState.phases[phaseIndex];

        if (!phase.isActive) {
            revert PhaseNotActive();
        }

        // there should be a valid merkle root for the phase
        if (phase.merkleRoot == bytes32(0)) {
            revert InvalidMintFunction();
        }

        if (phase.amountMinted + quantity > phase.maxSupply) {
            revert SoldOut();
        }

        if (balance != quantity * phase.price) {
            revert InvalidPrice();
        }

        if (
            !MerkleProof.verify(
                proof,
                phase.merkleRoot,
                keccak256(abi.encodePacked(wallet))
            )
        ) {
            revert InvalidProof();
        }

        uint256 amountMinted = amountMintedForPhase[wallet][phaseIndex];
        uint256 updatedAmountMinted = amountMinted + quantity;

        // phases can have a maxPerWallet
        if (
            phase.maxPerWallet > 0 && updatedAmountMinted > phase.maxPerWallet
        ) {
            revert ExceedMaxPerWallet();
        }

        return uint64(updatedAmountMinted);
    }

    function _checkPhaseMintConditions(
        address wallet,
        uint256 quantity,
        uint256 phaseIndex,
        uint256 balance
    ) internal view returns (uint64) {
        PhaseSettings storage phase = saleState.phases[phaseIndex];

        if (!phase.isActive) {
            revert PhaseNotActive();
        }

        // the phase should not have a merkleRoot
        if (phase.merkleRoot != bytes32(0)) {
            revert InvalidMintFunction();
        }

        if (phase.amountMinted + quantity > phase.maxSupply) {
            revert SoldOut();
        }

        if (balance != quantity * phase.price) {
            revert InvalidPrice();
        }

        uint256 amountMinted = amountMintedForPhase[wallet][phaseIndex];
        uint256 updatedAmountMinted = amountMinted + quantity;

        // phases can have a maxPerWallet
        if (
            phase.maxPerWallet > 0 && updatedAmountMinted > phase.maxPerWallet
        ) {
            revert ExceedMaxPerWallet();
        }

        return uint64(updatedAmountMinted);
    }

    function _checkPublicMintConditions(
        uint256 quantity,
        uint256 balance
    ) internal view returns (uint64) {
        if (!isPublicActive) {
            revert PhaseNotActive();
        }

        uint256 updatedAmountMinted = baseSettings.amountMinted + quantity;

        if (updatedAmountMinted > baseSettings.maxSupply) {
            revert SoldOut();
        }

        if (balance != quantity * baseSettings.price) {
            revert InvalidPrice();
        }

        return uint64(updatedAmountMinted);
    }

    function _checkGlobalPerWalletMax(
        address wallet,
        uint256 quantity
    ) internal view {
        if (
            baseSettings.maxPerWallet > 0 &&
            _numberMinted(wallet) + quantity > baseSettings.maxPerWallet
        ) {
            revert ExceedMaxPerWallet();
        }
    }

    function getDataForPhase(
        uint256 phaseIndex
    ) external view returns (PhaseSettings memory) {
        return saleState.phases[phaseIndex];
    }

    function getMintBalance(address wallet) external view returns (uint256) {
        return _numberMinted(wallet);
    }

    function getAmountMintedForPhase(
        uint256 phaseIndex,
        address wallet
    ) external view returns (uint64) {
        return amountMintedForPhase[wallet][phaseIndex];
    }

    function getAmountMintedForOwner(
        address wallet
    ) external view returns (uint256[] memory) {
        uint256[] memory amountMintedPerPhase = new uint256[](
            saleState.numPhases + 1
        );

        for (uint64 i = 0; i < saleState.numPhases; ) {
            amountMintedPerPhase[i] = amountMintedForPhase[wallet][i];

            // numPhases has a maximum value of 2^64 - 1
            unchecked {
                ++i;
            }
        }

        amountMintedPerPhase[saleState.numPhases] = _numberMinted(wallet);

        return amountMintedPerPhase;
    }

    /**
     * @dev See {ERC721-_baseURI}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(IERC721AUpgradeable, ERC721AUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return
            ERC721AUpgradeable.supportsInterface(interfaceId) ||
            ERC2981Upgradeable.supportsInterface(interfaceId);
    }

    // ========= OPERATOR FILTERER OVERRIDES =========

    function setApprovalForAll(
        address operator,
        bool approved
    )
        public
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    )
        public
        payable
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        payable
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        payable
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    )
        public
        payable
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}