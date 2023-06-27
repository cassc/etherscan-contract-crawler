// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

//       ___           ___           ___
//      /  /\         /  /\         /  /\        ___          _____
//     /  /:/        /  /::\       /  /:/_      /__/\        /  /::\
//    /  /:/        /  /:/\:\     /  /:/ /\     \  \:\      /  /:/\:\
//   /  /:/  ___   /  /::\ \:\   /  /:/ /:/      \__\:\    /  /:/  \:\
//  /__/:/  /  /\ /__/:/\:\_\:\ /__/:/ /:/       /  /::\  /__/:/ \__\:|
//  \  \:\ /  /:/ \__\/~|::\/:/ \  \:\/:/       /  /:/\:\ \  \:\ /  /:/
//   \  \:\  /:/     |  |:|::/   \  \::/       /  /:/__\/  \  \:\  /:/
//    \  \:\/:/      |  |:|\/     \  \:\      /__/:/        \  \:\/:/
//     \  \::/       |__|:|        \  \:\     \__\/          \  \::/
//      \__\/         \__\|         \__\/                     \__\/

import "ERC721A-Upgradeable/extensions/ERC721AQueryableUpgradeable.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import "solady/auth/Ownable.sol";
import "closedsea/OperatorFilterer.sol";
import "src/utils/PaymentSplitter.sol";
import "src/interfaces/ICRFTDERC721A.sol";

/**
 * @title CRFTDERC721A
 * @author CRFTD Labs
 */
contract CRFTDERC721A is ERC721AQueryableUpgradeable, Ownable, PaymentSplitter, OperatorFilterer, ICRFTDERC721A {
    /**
     * @dev Prevents the first-time transfer costs for tokens near the end of large mint batches
     *      via ERC721A from becoming too expensive due to the need to scan many storage slots.
     *      See: https://chiru-labs.github.io/ERC721A/#/tips?id=batch-size
     */
    uint256 private constant BATCH_MINT_LIMIT = 255;
  
    /**
     * @dev The boolean flag on whether the URI is pre-reveal.
     */
    uint16 private constant PREREVEAL_ENABLED_FLAG = 1 << 0;

    /**
     * @dev The boolean flag on whether the URI is pre-reveal.
     */
    uint16 private constant BURN_ENABLED_FLAG = 1 << 1;

    /**
     * @dev The boolean flag on whether the Mint is Paused.
     */
    uint16 private constant MINT_PAUSED_FLAG = 1 << 2;

    /**
     * @dev The boolean flag on whether the Public Sale is enabled.
     */
    uint16 private constant PUBLIC_SALE_ENABLED_FLAG = 1 << 3;

    /**
     * @dev The boolean flag on whether support soul-bound nfts.
     */
    uint16 private constant SOUL_BOUND_ENABLED_FLAG = 1 << 4;

    /**
     * @dev The boolean flag on whether OpenSea operator filtering is enabled.
     */
    uint16 private constant OPERATOR_FILTERING_ENABLED_FLAG = 1 << 5;

    /**
     * @dev The boolean flag on whether the metadata is frozen.
     */
    uint16 private constant METADATA_IS_FROZEN_FLAG = 1 << 6;

    /**
     * @dev The boolean flag on whether the revenue split is frozen.
     */
    uint16 private constant REVENUE_SPLIT_FROZEN_FLAG = 1 << 7;

    /**
     * @dev The boolean flag on whether the revenue split is frozen.
     */
    uint16 private constant ROYALTY_ENABLED_FLAG = 1 << 8;

    /**
     * @dev Basis points denominator used in fee calculations.
     */
    uint16 private constant _MAX_BPS = 10_000;

    /**
     * @dev The interface ID for EIP-2981 (royaltyInfo)
     */
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    /**
     * @dev The interface ID for EIP-5192 (soul-bound nfts)
     */
    bytes4 private constant _INTERFACE_ID_ERC5192 = 0xb45a3c0e;

    /**
     * @dev The address of the CRFTD Wallet for receiving the mint fee.
     */
    address private constant CRFTD_WALLET = 0xAA151eb9839ec480bF69F5dE8Fbeaf96eEe87626;

    /**
     * @dev The fixed flat fee per mint.
     */
    uint64 private constant FLAT_FEE = 0.00089 ether;

    /**
     * @dev The fixed flat fee percentage charged if sale price is greater than 0.05 ether.
     */
    uint16 private constant FEE_PERCENTAGE = 300;

    /**
     * @dev The price in eth for per mint.
     */
    uint128 public price;

    /**
     * @dev The max supply of erc721.
     */
    uint128 public maxSupply;

    /**
     * @dev receiver of the royalites.
     */
    address public royaltyReceiver;

    /**
     * @dev The royalty fee in basis points.
     */
    uint16 public royaltyBPS;

    /**
     * @dev The max mint per wallet.
     */
    uint64 public maxPerWallet;

    /**
     * @dev Packed boolean flags.
     */
    uint16 private _flags;

    /**
     * @dev The contract base URI.
     */
    string internal baseURI;

    /**
     * @dev The minted supply track of user for per phase
     */
    mapping(address user => mapping(uint256 phaseIndex => uint64 numMinted)) public amountMintedForPhase;

    /**
     * @dev The contract phase setting for sale.
     */
    PhaseSetting[] public phaseSettings;

    /**
     * @inheritdoc ICRFTDERC721A
     */
    function init(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        PaymentSplitter.Payees[] memory payee,
        PhaseSetting[] memory phases,
        bytes memory initData
    ) external initializerERC721A {
        (
            uint128 price_,
            uint128 maxSupply_,
            uint64 maxPerWallet_,
            address owner_,
            address royaltyReceiver_,
            uint16 flag_,
            uint16 feeNumerator_
        ) = decodingInitData(initData);

        __ERC721A_init(name_, symbol_);

        _initializeOwner(owner_);
        __PaymentSplitter_init(payee);

        unchecked {
            uint256 len = phases.length;
            for (uint256 i; i < len;) {
                phaseSettings.push(phases[i]);
                ++i;
            }
        }

        baseURI = baseURI_;
        price = price_;
        maxSupply = maxSupply_;
        maxPerWallet = maxPerWallet_;
        _flags = flag_;

        if (flag_ & ROYALTY_ENABLED_FLAG != 0) {
            _setDefaultRoyalty(royaltyReceiver_, feeNumerator_);
        }

        if (flag_ & OPERATOR_FILTERING_ENABLED_FLAG != 0) {
            _registerForOperatorFiltering();
        }

        emit CRFTDCollectionInitialized(name_, symbol_, baseURI_, payee, phases, initData);
    }

    /**
     * @dev Ensure the mint has not paused.
     */
    modifier mintNotPaused() {
        if (_flags & MINT_PAUSED_FLAG != 0) revert MintPaused();
        _;
    }

    /**
     * @dev Ensure the token metadata has not frozen.
     */
    modifier onlyMetadataNotFrozen() {
        if (_flags & METADATA_IS_FROZEN_FLAG != 0) revert MetadataIsFrozen();
        _;
    }

    /**
     * @dev Ensures that the `quantity` does not exceed `ADDRESS_BATCH_MINT_LIMIT`.
     * @param quantity The number of tokens minted per address.
     */
    modifier requireBatchMintLimit(uint64 quantity) {
        if (quantity > BATCH_MINT_LIMIT) revert ExceedsBatchMintLimit();
        _;
    }

    /**
     * Reverts if token has soul-bound.
     */
    modifier checkLock() {
        if (_flags & SOUL_BOUND_ENABLED_FLAG != 0) revert SoulBoundToken();
        _;
    }

    /**
     * @inheritdoc ERC721AUpgradeable
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /**
     * @dev Decode the abi.encodePacked data of `data`.
     *
     * @return price_            The price for the token sale.
     * @return maxSupply_        The max supply for the token.
     * @return maxPerWallet_     The max mint per wallet.
     * @return owner_            The address of the owner.
     * @return royaltyReceiver_  The address of royalty receiver.
     * @return flag_             The flags for the features.
     * @return feeNumerator_     The royalty amount in bps.
     */
    function decodingInitData(bytes memory data)
        private
        pure
        returns (
            uint128 price_,
            uint128 maxSupply_,
            uint64 maxPerWallet_,
            address owner_,
            address royaltyReceiver_,
            uint16 flag_,
            uint16 feeNumerator_
        )
    {
        assembly {
            // decode initdata abi.encodePacked(uint128 price_, uint128 maxSupply_, uint64 maxPerWallet_, address owner,address recevier,uint16 feeBPS, uint16 flag)
            price_ := shr(128, mload(add(data, 32)))
            maxSupply_ := shr(128, mload(add(data, 48)))
            maxPerWallet_ := shr(192, mload(add(data, 64)))
            owner_ := shr(96, mload(add(data, 72)))
            royaltyReceiver_ := shr(96, mload(add(data, 92)))
            flag_ := shr(240, mload(add(data, 112)))
            feeNumerator_ := shr(240, mload(add(data, 114)))
        }
    }

    /**
     * @dev Checks public sale has started.
     */
    function _publicSaleStarted() private view returns (bool) {
        return _flags & PUBLIC_SALE_ENABLED_FLAG != 0;
    }

    /**
     * @dev Checks token mint has paused.
     */
    function _isMintPaused() private view returns (bool) {
        return _flags & MINT_PAUSED_FLAG != 0;
    }

    /**
     * @dev For operator filtering to be toggled on / off.
     */
    function _operatorFilteringEnabled() internal view override returns (bool) {
        return _flags & OPERATOR_FILTERING_ENABLED_FLAG != 0;
    }

    /**
     * @inheritdoc IERC721AUpgradeable
     */
    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        checkLock
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @inheritdoc IERC721AUpgradeable
     */
    function approve(address operator, uint256 tokenId)
        public
        payable
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        checkLock
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    /**
     * @inheritdoc IERC721AUpgradeable
     */
    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        checkLock
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @inheritdoc IERC721AUpgradeable
     */
    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        checkLock
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @inheritdoc IERC721AUpgradeable
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        checkLock
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @dev Ensure user can't exceed global `maxSupply` and `maxPerWallet`.
     *
     * @param user          The address of user
     * @param quantity      The quantity of mint token
     */
    function _checkGlobalMintConditions(address user, uint64 quantity) private view {
        if (_totalMinted() + quantity > maxSupply) {
            revert MaxMinted();
        }

        if (maxPerWallet != 0 && _numberMinted(user) + quantity > maxPerWallet ) {
            revert ExceedsLimit();
        }
    }
    /**
     * @dev Checking the fee for mint and transfer fee to crftd wallet.
     *
     * @param quantity_ The quantity of mint token
     * @param price_ The price of per mint
     *
     */

    function _mintFee(uint64 quantity_, uint128 price_) private {

        // Mint fee of the token
        uint256 mintValue = price_ * quantity_;

        // If mint price is greater than 0.05 ether than charged additional 3% fee per mint else 0.
        uint256 additionalFee = price_ > 0.05 ether ? (mintValue * FEE_PERCENTAGE) / _MAX_BPS : 0;

        // Flat fee for mint
        uint256 flatFee = uint256(FLAT_FEE) * quantity_;

        // Total fee for the mint
        uint256 crftdFee = flatFee + additionalFee;

        if (msg.value != crftdFee + mintValue) {
            revert IncorrectValue();
        }

        // Transfer fee to crftd wallet
        SafeTransferLib.safeTransferETH(CRFTD_WALLET, crftdFee);
    }

    /**
     * @dev Check the all condition is fulfilled of the given phase.
     *
     * @param index         The index of the sale phase
     * @param user          The address of the user
     * @param quantity      The quantity of mint token
     * @param proof         An array of proofs
     */
    function _checkPhaseMintConditions(uint256 index, address user, uint64 quantity, bytes32[] calldata proof)
        private
        view
    {
        PhaseSetting storage phase = phaseSettings[index];

        if (phase.isActive == 0) revert InactivePhase();

        if (phase.mintedSupply + quantity > phase.maxSupply) revert MaxMinted();

        if (phase.merkleRoot != 0) {
            if (!MerkleProof.verify(proof, phase.merkleRoot, keccak256(abi.encodePacked(user)))) {
                revert InvalidProof();
            }
        }

        if (amountMintedForPhase[user][index] + quantity > phase.maxPerWallet && phase.maxPerWallet != 0) {
            revert ExceedsLimit();
        }
    }

    /**
     * @inheritdoc IERC721AUpgradeable
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        returns (bool)
    {
        uint16 flag = _flags;
        return type(ICRFTDERC721A).interfaceId == interfaceId || ERC721AUpgradeable.supportsInterface(interfaceId)
            || (flag & ROYALTY_ENABLED_FLAG == ROYALTY_ENABLED_FLAG && interfaceId == _INTERFACE_ID_ERC2981)
            || (flag & SOUL_BOUND_ENABLED_FLAG == SOUL_BOUND_ENABLED_FLAG && interfaceId == _INTERFACE_ID_ERC5192);
    }

    /**
     * @inheritdoc ICRFTDERC721A
     */
    function mintPhase(uint256 index, uint64 quantity, bytes32[] calldata proof)
        external
        payable
        mintNotPaused
        requireBatchMintLimit(quantity)
    {
        _checkPhaseMintConditions(index, msg.sender, quantity, proof);
        _checkGlobalMintConditions(msg.sender, quantity);

        PhaseSetting storage phase = phaseSettings[index];

        // updating mint supply of phase
        phase.mintedSupply = phase.mintedSupply + quantity;

        // updating user mint supply of the phase
        amountMintedForPhase[msg.sender][index] = amountMintedForPhase[msg.sender][index] + quantity;

        // calculating the mint fee and check msg.value is correct
        _mintFee(quantity, phase.price);
        uint256 fromTokenId = _nextTokenId();

        _mint(msg.sender, quantity);
        emit Minted(msg.sender, msg.value, quantity, fromTokenId);
    }

    /**
     * @inheritdoc ICRFTDERC721A
     */
    function publicMint(uint64 quantity) external payable mintNotPaused requireBatchMintLimit(quantity) {
        if (!_publicSaleStarted()) revert PublicSaleNotStarted();
        _checkGlobalMintConditions(msg.sender, quantity);

        // calculating the mint fee and check msg.value is corrects
        _mintFee(quantity, price);

        uint256 fromTokenId = _nextTokenId();
        _mint(msg.sender, quantity);

        emit Minted(msg.sender, msg.value, quantity, fromTokenId);
    }

    /**
     * @inheritdoc ICRFTDERC721A
     */
    function setPublicSaleSetting(uint128 price_, uint64 maxPerWallet_) external onlyOwner {
        if (price != price_) {
            price = price_;
            emit SalePriceSet(price_);
        }

        if (maxPerWallet != maxPerWallet_) {
            maxPerWallet = maxPerWallet_;
            emit MaxPerWalletSet(maxPerWallet_);
        }
    }

    /**
     * @inheritdoc ICRFTDERC721A
     */
    function burn(uint256 tokenId) external {
        if (_flags & BURN_ENABLED_FLAG == 0) revert BurnNotAllowed();
        _burn(tokenId, true);
    }

    /**
     * @inheritdoc IERC721AUpgradeable
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        returns (string memory)
    {
        return string.concat(super.tokenURI(tokenId), ".json");
    }

    /**
     * @inheritdoc ICRFTDERC721A
     */
    function setOperatorFilteringEnabled(bool operatorFilteringEnabled_) external onlyOwner {
        if (_operatorFilteringEnabled() != operatorFilteringEnabled_) {
            _flags ^= OPERATOR_FILTERING_ENABLED_FLAG;
            if (operatorFilteringEnabled_) {
                _registerForOperatorFiltering();
            }
        }

        emit OperatorFilteringEnabledSet(operatorFilteringEnabled_);
    }

    /**
     * @dev Returns `baseURI` of the token.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @inheritdoc ICRFTDERC721A
     */
    function setBaseURI(string memory baseURI_) external onlyOwner onlyMetadataNotFrozen {
        emit BaseTokenURIUpdated(baseURI, baseURI_);
        baseURI = baseURI_;
    }

    /**
     * @inheritdoc ICRFTDERC721A
     */
    function setPublicSaleStatus(bool status) external onlyOwner {
        if (_publicSaleStarted() != status) {
            _flags = _flags ^ PUBLIC_SALE_ENABLED_FLAG;
        }
        emit PublicSaleEnabledSet(status);
    }

    /**
     * @inheritdoc ICRFTDERC721A
     */
    function freezeMetadata() external onlyOwner {
        _flags = _flags | METADATA_IS_FROZEN_FLAG;
    }

    /**
     * @inheritdoc ICRFTDERC721A
     */
    function freezeRevenueSplit() external onlyOwner {
        _flags = _flags | REVENUE_SPLIT_FROZEN_FLAG;
    }

    /**
     * @inheritdoc ICRFTDERC721A
     */
    function setMintPause(bool status) external onlyOwner {
        if (_isMintPaused() != status) {
            _flags = _flags ^ MINT_PAUSED_FLAG;
        }

        emit MintPauseEnabledSet(status);
    }

    /**
     * @inheritdoc ICRFTDERC721A
     */
    function airdrop(address[] calldata to, uint64[] calldata quantity) external payable onlyOwner {
        uint256 len = to.length;

        if (len != quantity.length) revert ArrayLengthMismatch();

        uint256 fromTokenId = _nextTokenId();

        for (uint256 i; i != len;) {
            uint64 quantity_ = quantity[i];
            if (_totalMinted() + quantity_ > maxSupply) revert ExceedsLimit();
            _mint(to[i], quantity_);

            unchecked {
                ++i;
            }
        }

        emit Airdropped(to, quantity, fromTokenId);
    }

    /**
     * @dev Helper function for sets token royalty.
     *
     * @param receiver_     The address of receiver of royalty
     * @param bps_          The royalty points (in basic points)
     */
    function _setDefaultRoyalty(address receiver_, uint16 bps_) private {
        if (receiver_ == address(0)) revert ZeroAddress();
        if (bps_ > _MAX_BPS) revert ExceedMaxBPS();
        royaltyReceiver = receiver_;
        royaltyBPS = bps_;
    }

    /**
     * @inheritdoc ICRFTDERC721A
     */
    function setMaxSupply(uint128 supply) external onlyOwner onlyMetadataNotFrozen {
        if (_totalMinted() > supply || supply > maxSupply) revert NotAllowed();
        maxSupply = supply;
        emit MaxSupplySet(supply);
    }

    /**
     * @inheritdoc ICRFTDERC721A
     */
    function setRoyalty(address receiver_, uint16 bps_) external onlyOwner {
        _flags = _flags | ROYALTY_ENABLED_FLAG;
        _setDefaultRoyalty(receiver_, bps_);
    }

    /**
     * @inheritdoc ICRFTDERC721A
     */
    function revealTokenURI(string memory uri) external onlyOwner {
        if (_flags & PREREVEAL_ENABLED_FLAG == 0) revert AlreadyReveal();
        _flags = _flags ^ PREREVEAL_ENABLED_FLAG;
        emit BaseTokenURIUpdated(baseURI, uri);
        baseURI = uri;
    }

    /**
     * @inheritdoc ICRFTDERC721A
     */
    function addPhases(PhaseSetting[] calldata _phase) external onlyOwner {
        uint256 len = _phase.length;
        for (uint256 i; i < len;) {
            phaseSettings.push(_phase[i]);
            unchecked {
                ++i;
            }
        }
        emit PhaseAdded(_phase);
    }

    /**
     * @inheritdoc ICRFTDERC721A
     */

    function setPhaseSettings(
        uint256 index,
        uint128 price_,
        uint128 maxSupply_,
        uint64 maxPerWallet_,
        uint64 isActive_,
        bytes32 root_
    ) external onlyOwner {
        PhaseSetting storage phase = phaseSettings[index];

        phase.price = price_;
        phase.maxSupply = maxSupply_;
        phase.maxPerWallet = maxPerWallet_;
        phase.isActive = isActive_;
        phase.merkleRoot = root_;

        emit PhaseSettingUpdate(index, price_, maxSupply_, maxPerWallet_, isActive_, root_);
    }

    /**
     * @inheritdoc ICRFTDERC721A
     */
    function setPhaseStatus(uint256[] calldata indexs, bool[] calldata status) external onlyOwner {
        uint256 indexLen = indexs.length;

        if (indexLen != status.length) revert ArrayLengthMismatch();

        for (uint256 i; i < indexLen;) {
            uint64 value = status[i] ? 1 : 0;

            phaseSettings[indexs[i]].isActive = value;

            unchecked {
                ++i;
            }
        }

        emit PhaseStatusSet(indexs, status);
    }

    /**
     * @inheritdoc ICRFTDERC721A
     */
    function changeRevenueSplit(Payees[] memory payees_) external onlyOwner {
        if (_flags & REVENUE_SPLIT_FROZEN_FLAG != 0) revert RevenueSplitIsFrozen();
        _setPayees(payees_);

        emit RevenueSplitUpdated(payees_);
    }

    /**
     * @inheritdoc ICRFTDERC721A
     */
    function royaltyInfo(uint256, uint256 salePrice) public view returns (address recipient_, uint256 royaltyAmount_) {
        recipient_ = royaltyReceiver;
        royaltyAmount_ = (salePrice * royaltyBPS) / _MAX_BPS;
    }

    /**
     * @inheritdoc ICRFTDERC721A
     */
    function locked(uint256) external view returns (bool status) {
        status = _flags & SOUL_BOUND_ENABLED_FLAG != 0;
    }

    /**
     * @inheritdoc ICRFTDERC721A
     */
    function isRevenueSplitFrozen() external view returns (bool status) {
        status = _flags & REVENUE_SPLIT_FROZEN_FLAG != 0;
    }

    /**
     * @inheritdoc ICRFTDERC721A
     */
    function isMetadataFrozen() external view returns (bool status) {
        status = _flags & METADATA_IS_FROZEN_FLAG != 0;
    }

    /**
     * @inheritdoc ICRFTDERC721A
     */
    function isMintPaused() external view returns (bool status) {
        status = _flags & MINT_PAUSED_FLAG != 0;
    }

    /**
     * @inheritdoc ICRFTDERC721A
     */
    function isBurnable() external view returns (bool status) {
        status = _flags & BURN_ENABLED_FLAG != 0;
    }

    /**
     * @inheritdoc ICRFTDERC721A
     */
    function isPreReveal() external view returns (bool status) {
        status = _flags & PREREVEAL_ENABLED_FLAG != 0;
    }

    /**
     * @inheritdoc ICRFTDERC721A
     */
    function isPublicSaleStart() external view returns (bool status) {
        status = _flags & PUBLIC_SALE_ENABLED_FLAG != 0;
    }

    /**
     * @inheritdoc ICRFTDERC721A
     */
    function isOperatorFiltering() external view returns (bool status) {
        status = _flags & OPERATOR_FILTERING_ENABLED_FLAG != 0;
    }
}