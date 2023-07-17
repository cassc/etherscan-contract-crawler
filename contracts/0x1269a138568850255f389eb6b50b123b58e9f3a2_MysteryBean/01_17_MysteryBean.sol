// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "erc721a/contracts/ERC721A.sol";

import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "closedsea/OperatorFilterer.sol";
import "./MultisigOwnable.sol";

error InvalidPresaleSetup();
error InvalidAuctionSetup();
error ChunkAlreadyProcessed();
error MismatchedArrays();
error AuctionMintNotOpen();
error MaxPresaleOrAuctionMintSupplyReached();
error RedeemBeanNotOpen();
error BeanRedeemerNotSet();
error ForceRedeemBeanOwnerMismatch();
error RegistryNotSet();
error NotAllowedByRegistry();
error WithdrawFailed();
error ClaimWindowNotOpen();
error MismatchedTokenOwnerForClaim();
error BeanCannotBeClaimed();
error InitialTransferLockOn();
error MaxAuctionMintForAddress();
error InsufficientFunds();
error RefundFailed();
error InvalidSignature();
error OverMaxSupply();
error AllowlistMintNotOpen();
error PresaleNotOpen();
error MintingTooMuchInPresale();
error InvalidContractSetup();

interface IBeanRedeemer {
    function redeemBeans(address to, uint256[] calldata beanIds)
        external
        returns (uint256[] memory);
}

interface IRegistry {
    function isAllowedOperator(address operator) external view returns (bool);
}

interface Azuki {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract MysteryBean is ERC2981, MultisigOwnable, OperatorFilterer, ERC721A {
    using ECDSA for bytes32;
    using EnumerableSet for EnumerableSet.UintSet;
    using BitMaps for BitMaps.BitMap;

    event AirdroppedChunk(uint256 indexed chunkNum);
    event ClaimedBean(uint256 indexed sourceAzukiId, uint256 indexed beanId);
    event PresaleMint(address indexed minter, uint16 indexed amount);

    // The set of chunks processed for the airdrop.
    // Intent is to help prevent double processing of chunks.
    EnumerableSet.UintSet private _processedChunksForAirdrop;

    bool public operatorFilteringEnabled = true;
    bool public initialTransferLockOn = true;
    bool public isRegistryActive = false;
    address public registryAddress;

    bool public claimBeanOpen = false;
    // Keys are azuki token ids
    BitMaps.BitMap private _azukiCanClaim;

    uint256 public immutable TOTAL_PRESALE_AND_AUCTION_SUPPLY;
    uint16 public totalPresaleAndAuctionMinted;

    struct PresaleInfo {
        uint32 presaleStartTime;
        uint32 presaleEndTime;
        uint64 presalePrice;
    }
    PresaleInfo public presaleInfo;
    mapping(address => uint256) public numMintedInPresale;

    struct AuctionInfo {
        uint32 auctionSaleStartTime;
        uint64 auctionStartPrice;
        uint64 auctionEndPrice;
        uint32 auctionPriceCurveLength;
        uint32 auctionDropInterval;
    }
    AuctionInfo public auctionInfo;

    address private _offchainSigner;

    struct RedeemInfo {
        bool redeemBeanOpen;
        address beanRedeemer;
    }
    RedeemInfo public redeemInfo;

    mapping(address => uint256) public allowlistMintsAlloc;
    uint256 public allowlistMintPrice;

    uint256 public immutable MAX_SUPPLY;

    string private _baseTokenURI;

    Azuki public immutable AZUKI;
    address payable public immutable WITHDRAW_ADDRESS;

    uint256 public constant MINT_BATCH_SIZE = 10;

    constructor(
        address _azukiAddress,
        uint256 _maxSupply,
        uint256 _totalPresaleAndAuctionSupply,
        address payable _withdrawAddress
    ) ERC721A("MysteryBean", "MBEAN") {
        AZUKI = Azuki(_azukiAddress);
        MAX_SUPPLY = _maxSupply;
        TOTAL_PRESALE_AND_AUCTION_SUPPLY = _totalPresaleAndAuctionSupply;
        WITHDRAW_ADDRESS = _withdrawAddress;

        if (TOTAL_PRESALE_AND_AUCTION_SUPPLY >= MAX_SUPPLY)
            revert InvalidContractSetup();

        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
    }

    // ---------------------------
    // Airdrop and privileged mint
    // ---------------------------

    // Thin wrapper around privilegedMint which does chunkNum checks to reduce chance of double processing chunks in a manual airdrop.
    function airdrop(
        address[] calldata receivers,
        uint256[] calldata amounts,
        uint256 chunkNum
    ) external onlyOwner {
        if (_processedChunksForAirdrop.contains(chunkNum))
            revert ChunkAlreadyProcessed();
        _processedChunksForAirdrop.add(chunkNum);
        privilegedMint(receivers, amounts);
        emit AirdroppedChunk(chunkNum);
    }

    // Used for airdrop and minting any of the total supply that's unminted.
    // Does not use safeMint (assumes the caller has checked whether contract receivers can receive 721s)
    function privilegedMint(
        address[] calldata receivers,
        uint256[] calldata amounts
    ) public onlyOwner {
        if (receivers.length != amounts.length || receivers.length == 0)
            revert MismatchedArrays();
        for (uint256 i; i < receivers.length; ) {
            _mintWrapperNoSafeReceiverCheck(receivers[i], amounts[i]);

            unchecked {
                ++i;
            }
        }
        if (_totalMinted() > MAX_SUPPLY) {
            revert OverMaxSupply();
        }
    }

    function _mintWrapperSafeReceiverCheck(address to, uint256 amount) private {
        uint256 numBatches = amount / MINT_BATCH_SIZE;
        for (uint256 i; i < numBatches; ) {
            _safeMint(to, MINT_BATCH_SIZE, "");
            unchecked {
                ++i;
            }
        }
        if (amount % MINT_BATCH_SIZE > 0) {
            _safeMint(to, amount % MINT_BATCH_SIZE, "");
        }
    }

    function _mintWrapperNoSafeReceiverCheck(address to, uint256 amount)
        private
    {
        uint256 numBatches = amount / MINT_BATCH_SIZE;
        for (uint256 i; i < numBatches; ) {
            _mint(to, MINT_BATCH_SIZE);
            unchecked {
                ++i;
            }
        }
        if (amount % MINT_BATCH_SIZE > 0) {
            _mint(to, amount % MINT_BATCH_SIZE);
        }
    }

    // ----------------------------------------------
    // Claim Window
    // ----------------------------------------------

    function claim(uint256[] calldata azukiTokenIds) external {
        if (!claimBeanOpen) {
            revert ClaimWindowNotOpen();
        }
        uint256 numToClaim = azukiTokenIds.length;
        if (_totalMinted() + numToClaim > MAX_SUPPLY) {
            revert OverMaxSupply();
        }
        uint256 nextTokenId = _nextTokenId();
        for (uint256 i; i < numToClaim; ) {
            uint256 azukiId = azukiTokenIds[i];
            if (AZUKI.ownerOf(azukiId) != msg.sender)
                revert MismatchedTokenOwnerForClaim();
            if (!_azukiCanClaim.get(azukiId)) revert BeanCannotBeClaimed();
            _azukiCanClaim.unset(azukiId);
            emit ClaimedBean(azukiId, nextTokenId + i);
            unchecked {
                ++i;
            }
        }
        _mintWrapperSafeReceiverCheck(msg.sender, numToClaim);
    }

    function setClaimBeanState(bool _claimBeanOpen) external onlyOwner {
        claimBeanOpen = _claimBeanOpen;
    }

    function setCanClaim(uint256[] calldata azukiIds) external onlyOwner {
        for (uint256 i; i < azukiIds.length; ) {
            _azukiCanClaim.set(azukiIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    function getCanClaims(uint256[] calldata azukiIds)
        external
        view
        returns (bool[] memory)
    {
        bool[] memory result = new bool[](azukiIds.length);
        for (uint256 i; i < azukiIds.length; ) {
            result[i] = _azukiCanClaim.get(azukiIds[i]);
            unchecked {
                ++i;
            }
        }
        return result;
    }

    // ------------
    // Presale mint
    // ------------
    // maxAllowedForPresaleForAddr: the number the holder is allowed to mint during the entirety of the presale.
    // Its value is verified through the signature. We do this instead of seeding the contract with state to avoid a more complex contract setup.
    function presaleMint(
        uint16 amount,
        uint16 maxAllowedForPresaleForAddr,
        bytes calldata _signature
    ) external payable {
        PresaleInfo memory info = presaleInfo;
        if (
            info.presaleStartTime == 0 ||
            block.timestamp < info.presaleStartTime ||
            block.timestamp >= info.presaleEndTime
        ) {
            revert PresaleNotOpen();
        }
        uint256 numMintedInPresaleLoc = numMintedInPresale[msg.sender];
        if (amount > maxAllowedForPresaleForAddr - numMintedInPresaleLoc) {
            revert MintingTooMuchInPresale();
        }

        uint16 totalPresaleAndAuctionMintedLocal = totalPresaleAndAuctionMinted;
        if (
            amount + totalPresaleAndAuctionMintedLocal >
            TOTAL_PRESALE_AND_AUCTION_SUPPLY
        ) {
            revert MaxPresaleOrAuctionMintSupplyReached();
        }

        if (_totalMinted() + amount > MAX_SUPPLY) {
            revert OverMaxSupply();
        }

        if (!_verifyPresaleSig(amount, maxAllowedForPresaleForAddr, _signature))
            revert InvalidSignature();

        uint256 totalCost = uint256(info.presalePrice) * amount;
        if (msg.value < totalCost) {
            revert InsufficientFunds();
        }
        unchecked {
            numMintedInPresale[msg.sender] = amount + numMintedInPresaleLoc;
            totalPresaleAndAuctionMinted =
                totalPresaleAndAuctionMintedLocal +
                amount;
        }
        _mintWrapperNoSafeReceiverCheck(msg.sender, amount);
        emit PresaleMint(msg.sender, amount);
    }

    function _verifyPresaleSig(
        uint16 amount,
        uint16 maxAllowedForPresaleForAddr,
        bytes memory _signature
    ) private view returns (bool) {
        bytes32 hashVal = keccak256(
            abi.encodePacked(amount, msg.sender, maxAllowedForPresaleForAddr)
        );
        bytes32 signedHash = hashVal.toEthSignedMessageHash();
        address signingAddress = signedHash.recover(_signature);
        return signingAddress == _offchainSigner;
    }

    // Presale price to match starting price of dutch auction
    function setPresaleParams(
        uint32 _presaleStartTime,
        uint32 _presaleEndTime,
        uint64 _presalePrice
    ) external onlyOwner {
        if (
            _presaleStartTime == 0 || _presaleEndTime == 0 || _presalePrice == 0
        ) {
            revert InvalidPresaleSetup();
        }
        if (_presaleStartTime >= _presaleEndTime) {
            revert InvalidPresaleSetup();
        }
        presaleInfo = PresaleInfo(
            _presaleStartTime,
            _presaleEndTime,
            _presalePrice
        );
    }

    function setOffchainSigner(address _signer) external onlyOwner {
        _offchainSigner = _signer;
    }

    // -------------
    // Dutch auction
    // -------------
    uint256 public constant MAX_PER_ADDRESS_PUBLIC_MINT = 3;

    function getAuctionPrice() public view returns (uint256) {
        AuctionInfo memory info = auctionInfo;
        if (block.timestamp < info.auctionSaleStartTime) {
            return info.auctionStartPrice;
        }
        if (
            block.timestamp - info.auctionSaleStartTime >=
            info.auctionPriceCurveLength
        ) {
            return info.auctionEndPrice;
        } else {
            uint256 steps = (block.timestamp - info.auctionSaleStartTime) /
                info.auctionDropInterval;
            uint256 auctionDropPerStep = (info.auctionStartPrice -
                info.auctionEndPrice) /
                (info.auctionPriceCurveLength / info.auctionDropInterval);
            return info.auctionStartPrice - (steps * auctionDropPerStep);
        }
    }

    modifier isEOA() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function auctionMint(uint8 amount, bytes calldata _signature)
        external
        payable
        isEOA
    {
        AuctionInfo memory info = auctionInfo;

        if (
            info.auctionSaleStartTime == 0 ||
            block.timestamp < info.auctionSaleStartTime
        ) {
            revert AuctionMintNotOpen();
        }

        uint16 totalPresaleAndAuctionMintedLocal = totalPresaleAndAuctionMinted;
        if (
            amount + totalPresaleAndAuctionMintedLocal >
            TOTAL_PRESALE_AND_AUCTION_SUPPLY
        ) {
            revert MaxPresaleOrAuctionMintSupplyReached();
        }

        if (_totalMinted() + amount > MAX_SUPPLY) {
            revert OverMaxSupply();
        }

        uint256 numAuctionMintedForThisAddr = _getAux(msg.sender);

        if (
            numAuctionMintedForThisAddr + amount > MAX_PER_ADDRESS_PUBLIC_MINT
        ) {
            revert MaxAuctionMintForAddress();
        }

        if (!_verifySig(_signature)) revert InvalidSignature();

        uint256 totalCost = getAuctionPrice() * amount;
        if (msg.value < totalCost) {
            revert InsufficientFunds();
        }

        unchecked {
            _setAux(msg.sender, uint64(numAuctionMintedForThisAddr) + amount);
            totalPresaleAndAuctionMinted =
                totalPresaleAndAuctionMintedLocal +
                amount;
        }
        _mint(msg.sender, amount);

        if (msg.value > totalCost) {
            (bool sent, ) = msg.sender.call{value: msg.value - totalCost}("");
            if (!sent) {
                revert RefundFailed();
            }
        }
    }

    function getNumAuctionMinted(address addr) external view returns (uint256) {
        return _getAux(addr);
    }

    function setAuctionParams(
        uint32 _startTime,
        uint64 _startPriceWei,
        uint64 _endPriceWei,
        uint32 _priceCurveNumSeconds,
        uint32 _dropIntervalNumSeconds
    ) public onlyOwner {
        if (
            _startTime != 0 &&
            (_startPriceWei == 0 ||
                _priceCurveNumSeconds == 0 ||
                _dropIntervalNumSeconds == 0)
        ) {
            revert InvalidAuctionSetup();
        }
        auctionInfo = AuctionInfo(
            _startTime,
            _startPriceWei,
            _endPriceWei,
            _priceCurveNumSeconds,
            _dropIntervalNumSeconds
        );
    }

    function setAuctionSaleStartTime(uint32 timestamp) external onlyOwner {
        AuctionInfo memory info = auctionInfo;
        if (
            timestamp != 0 &&
            (info.auctionStartPrice == 0 ||
                info.auctionPriceCurveLength == 0 ||
                info.auctionDropInterval == 0)
        ) {
            revert InvalidAuctionSetup();
        }
        auctionInfo.auctionSaleStartTime = timestamp;
    }

    function _verifySig(bytes memory _signature) private view returns (bool) {
        bytes32 hashVal = keccak256(abi.encodePacked(msg.sender));
        bytes32 signedHash = hashVal.toEthSignedMessageHash();
        address signingAddress = signedHash.recover(_signature);
        return signingAddress == _offchainSigner;
    }

    function withdraw() external {
        (bool sent, ) = WITHDRAW_ADDRESS.call{value: address(this).balance}("");
        if (!sent) {
            revert WithdrawFailed();
        }
    }

    // -----------
    // Redeem bean
    // -----------
    function redeemBeans(uint256[] calldata beanIds)
        external
        returns (uint256[] memory)
    {
        RedeemInfo memory info = redeemInfo;
        if (!info.redeemBeanOpen) {
            revert RedeemBeanNotOpen();
        }
        return _redeemBeansImpl(msg.sender, beanIds, true, info.beanRedeemer);
    }

    function _redeemBeansImpl(
        address beanOwner,
        uint256[] memory beanIds,
        bool burnOwnerOrApprovedCheck,
        address beanRedeemer
    ) private returns (uint256[] memory) {
        for (uint256 i; i < beanIds.length; ) {
            _burn(beanIds[i], burnOwnerOrApprovedCheck);
            unchecked {
                ++i;
            }
        }
        return IBeanRedeemer(beanRedeemer).redeemBeans(beanOwner, beanIds);
    }

    function forceRedeemBeans(address beanOwner, uint256[] calldata beanIds)
        external
        onlyOwner
        returns (uint256[] memory)
    {
        for (uint256 i; i < beanIds.length; ) {
            if (ownerOf(beanIds[i]) != beanOwner) {
                revert ForceRedeemBeanOwnerMismatch();
            }
            unchecked {
                ++i;
            }
        }
        return
            _redeemBeansImpl(
                beanOwner,
                beanIds,
                false,
                redeemInfo.beanRedeemer
            );
    }

    function openRedeemBeanState() external onlyOwner {
        RedeemInfo memory info = redeemInfo;
        if (info.beanRedeemer == address(0)) {
            revert BeanRedeemerNotSet();
        }
        redeemInfo = RedeemInfo(true, info.beanRedeemer);
    }

    function setBeanRedeemer(address contractAddress) external onlyOwner {
        redeemInfo = RedeemInfo(redeemInfo.redeemBeanOpen, contractAddress);
    }

    // --------------
    // Allowlist mint
    // --------------
    function allowlistMint() external payable {
        if (allowlistMintPrice == 0) {
            revert AllowlistMintNotOpen();
        }
        uint256 amount = allowlistMintsAlloc[msg.sender];

        uint256 totalCost = allowlistMintPrice * amount;
        if (msg.value < totalCost) {
            revert InsufficientFunds();
        }
        if (_totalMinted() + amount > MAX_SUPPLY) {
            revert OverMaxSupply();
        }
        allowlistMintsAlloc[msg.sender] = 0;

        _safeMint(msg.sender, amount);
    }

    function setAllowlistMintsAlloc(
        address[] calldata addresses,
        uint256[] calldata amounts
    ) external onlyOwner {
        if (addresses.length != amounts.length || addresses.length == 0)
            revert MismatchedArrays();
        for (uint256 i; i < addresses.length; ) {
            allowlistMintsAlloc[addresses[i]] = amounts[i];
            unchecked {
                ++i;
            }
        }
    }

    function setAllowlistMintPrice(uint256 price) external onlyOwner {
        allowlistMintPrice = price;
    }

    // -------------------
    // Break transfer lock
    // -------------------
    function breakTransferLock() external onlyOwner {
        initialTransferLockOn = false;
    }

    // --------
    // Metadata
    // --------

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    // --------
    // EIP-2981
    // --------
    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    // ---------------------------------------------------
    // OperatorFilterer overrides (overrides, values etc.)
    // ---------------------------------------------------
    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        if (initialTransferLockOn) revert InitialTransferLockOn();
        super.setApprovalForAll(operator, approved);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override(ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        if (initialTransferLockOn) revert InitialTransferLockOn();
        super.approve(operator, tokenId);
    }

    // ERC721A calls transferFrom internally in its two safeTransferFrom functions, so we don't need to override those.
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    // --------------
    // Registry check
    // --------------
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        if (initialTransferLockOn && from != address(0) && to != address(0))
            revert InitialTransferLockOn();
        if (_isValidAgainstRegistry(msg.sender)) {
            super._beforeTokenTransfers(from, to, startTokenId, quantity);
        } else {
            revert NotAllowedByRegistry();
        }
    }

    function _isValidAgainstRegistry(address operator)
        internal
        view
        returns (bool)
    {
        if (isRegistryActive) {
            IRegistry registry = IRegistry(registryAddress);
            return registry.isAllowedOperator(operator);
        }
        return true;
    }

    function setIsRegistryActive(bool _isRegistryActive) external onlyOwner {
        if (registryAddress == address(0)) revert RegistryNotSet();
        isRegistryActive = _isRegistryActive;
    }

    function setRegistryAddress(address _registryAddress) external onlyOwner {
        registryAddress = _registryAddress;
    }

    // ----------------------------------------------
    // EIP-165
    // ----------------------------------------------
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }
}