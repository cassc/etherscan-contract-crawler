// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "contracts-lib/token/ERC721A.sol";
import "contracts-lib/openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import "contracts-lib/openzeppelin-contracts/contracts/token/common/ERC2981.sol";
import "contracts-lib/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import "contracts-lib/openzeppelin-contracts/contracts/access/AccessControl.sol";
import "contracts-lib/openzeppelin-contracts/contracts/access/AccessControlCrossChain.sol";

///
///
///       $$\      $$\  $$$$$$\   $$$$$$\ $$$$$$$$\ $$$$$$$$\ $$$$$$$\        $$\   $$\ $$$$$$$$\ $$\     $$\
///       $$$\    $$$ |$$  __$$\ $$  __$$\\__$$  __|$$  _____|$$  __$$\       $$ | $$  |$$  _____|\$$\   $$  |
///       $$$$\  $$$$ |$$ /  $$ |$$ /  \__|  $$ |   $$ |      $$ |  $$ |      $$ |$$  / $$ |       \$$\ $$  /
///       $$\$$\$$ $$ |$$$$$$$$ |\$$$$$$\    $$ |   $$$$$\    $$$$$$$  |      $$$$$  /  $$$$$\      \$$$$  /
///       $$ \$$$  $$ |$$  __$$ | \____$$\   $$ |   $$  __|   $$  __$$<       $$  $$<   $$  __|      \$$  /
///       $$ |\$  /$$ |$$ |  $$ |$$\   $$ |  $$ |   $$ |      $$ |  $$ |      $$ |\$$\  $$ |          $$ |
///       $$ | \_/ $$ |$$ |  $$ |\$$$$$$  |  $$ |   $$$$$$$$\ $$ |  $$ |      $$ | \$$\ $$$$$$$$\     $$ |
///       \__|     \__|\__|  \__| \______/   \__|   \________|\__|  \__|      \__|  \__|\________|    \__|
///
///

contract MasterKey is ERC721A, ERC2981, AccessControl {
    bytes32 public constant CONTRACT_OPERATOR_ROLE = keccak256("CONTRACT_OPERATOR_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    error DisabledWhileSaleIsActive();
    error WhitelistSaleIsClosed();
    error PrivateSaleIsClosed();
    error PublicSaleIsClosed();
    error SaleAlreadyClosed();

    error ExceedsMaxPerWallet();
    error ExceedsMaxSupply();
    error ExceedsCollaboratorsSupply();
    error InvalidNewSupplyCap();
    error InvalidNewMaxPerWallet();

    error MintZeroItems();
    error WrongValueSent();
    error InvalidProof();
    error CannotUseFavorYet();
    error NotOwnerOfTokenId();
    error NonExistingToken();

    error InvalidDevsPaymentMode();
    error CreatorsPaymentFailed();
    error DevsPaymentFailed();
    error InvalidRoyalty();

    // only direction is (CLOSED -> PRIVATE -> WHITELIST -> PUBLIC) ==> Next Round ...
    enum Phase {
        CLOSED, // no mints
        PRIVATE,
        WHITELIST, // whitelist and private mints (mintTo)
        PUBLIC // anyone can mint
    }

    event NextPhaseInitiated(Phase phase);

    bytes32 private merkleRoot;

    uint256 public constant COLLABORATORS_HARD_CAP = 100; // these go on top of the current round cap
    uint256 public constant SUPPLY_HARD_CAP = 10_000;

    // These are not set constant, but can only be modified while phase is CLOSED
    uint256 public MAX_PER_WALLET = 5;
    uint256 public MINT_PRICE = 0.11 ether;

    // default is CLOSED
    Phase public phase;

    uint256 public CURRENT_ROUND_ALLOCATION;
    uint256 public CURRENT_WHITELIST_ALLOCATION;

    uint256 public collaboratorsSupply;
    uint256 public whitelistSupply;

    // favours tracker: This only stores the last date a favour was redeemed by a tokenId
    mapping(uint256 => uint256) public lastFavourRedeemedTime;
    // the number of seconds of one month is averaged accross month to get 1 year = 12 * 2628000
    uint256 public favorPeriodDuration = 4 * (365 days) / 12;
    uint256 public referenceDate;

    // metadata info
    bool public isRevealed;
    string private baseTokenURI =
        "https://sapphire-final-jaguar-610.mypinata.cloud/ipfs/QmbxvKEs7k7aLqvth8nP87ja6mSwhTjnVxGdxZwsj5RVJn";
    string private collectionContractURI =
        "https://sapphire-final-jaguar-610.mypinata.cloud/ipfs/QmX6LYTHiKpaLaKiXdJ6ixuiiWuaZQVAgo516w3cdVAxfg";

    // debt with devs is approx 5 eth:
    // eth price = 1800 usd
    // devs share = 9000 usd
    // approx devs value in eth = 5 eth
    uint256 public debtWithDevs = 5 ether;
    uint256 public shareToDevs = 0;
    uint256 public BASIS_POINTS = 10_000;

    address public creatorsAddress = 0x5e48d1872D41d81782050cB552205F9f6380cEC1;
    address public devsAddress = 0xCFA03E72b571e36719f005166E2a02EADF488F2b;

    constructor() ERC721A("Master Key", "MKEY") {
        // standardized royalties for other marketplaces. 10000 for 100%, 5%==500

        // 10% royalties for creators in secondary market purchases
        _setDefaultRoyalty(creatorsAddress, 1000);
        referenceDate = block.timestamp;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(CONTRACT_OPERATOR_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);

        // this max supply is only for the first round
        CURRENT_ROUND_ALLOCATION = 1000;
        CURRENT_WHITELIST_ALLOCATION = 900;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // external functions

    function publicMint(uint256 amount) external payable {
        if (phase != Phase.PUBLIC) revert PublicSaleIsClosed();

        _batchMint(msg.sender, amount);
    }

    // @dev  This method should only be called during the whitelist phase
    function whitelistMint(uint256 amount, bytes32[] calldata proof) external payable {
        if ((phase != Phase.WHITELIST) && (phase != Phase.PUBLIC)) revert WhitelistSaleIsClosed();
        if (!_verifyProof(msg.sender, proof)) revert InvalidProof();

        if (whitelistSupply + amount > CURRENT_WHITELIST_ALLOCATION) revert("Exceeds whitelist allocation");
        whitelistSupply += amount;

        _batchMint(msg.sender, amount);
    }

    function useFavor(uint256 tokenId) external {
        if (!_exists(tokenId)) revert NonExistingToken();
        if (!_canUseFavor(tokenId)) revert CannotUseFavorYet();
        if (ownerOf(tokenId) != msg.sender) revert NotOwnerOfTokenId();
        lastFavourRedeemedTime[tokenId] = block.timestamp;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // View functions
    function isWhitelistSaleOpen() public view returns (bool) {
        return phase == Phase.WHITELIST;
    }

    function isPublicSaleOpen() public view returns (bool) {
        return phase == Phase.PUBLIC;
    }

    // @notice  Number of mints left (this doesnt know in which phase are we. This is just the hard cap mints left for
    //          a specific wallet
    function allowedMintsLeft(address wallet) public view returns (uint256) {
        uint256 leftForWallet = MAX_PER_WALLET - balanceOf(wallet);
        uint256 leftForSupply = CURRENT_ROUND_ALLOCATION - totalSupply();
        return leftForWallet < leftForSupply ? leftForWallet : leftForSupply;
    }

    function verifyProof(address wallet, bytes32[] calldata proof) public view returns (bool) {
        return _verifyProof(wallet, proof);
    }

    function canUseFavor(uint256 tokenId) public view returns (bool) {
        return _canUseFavor(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!isRevealed) return _baseURI();
        return super.tokenURI(tokenId);
    }

    function contractURI() public view returns (string memory) {
        return collectionContractURI;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981, AccessControl)
        returns (bool)
    {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Management functions

    function mintTo(address[] calldata wallets, uint256[] calldata amounts) external payable onlyRole(MINTER_ROLE) {
        // this type of mint is allowed in any phase except CLOSED
        require(wallets.length < 100, "Max 100 wallets per tx");
        require(wallets.length == amounts.length, "arrays lengths mismatch");
        if (phase == Phase.CLOSED) revert PrivateSaleIsClosed();

        uint256 totalMinted = 0;
        uint256 ethRequired = 0;

        for (uint256 i = 0; i < wallets.length; i++) {
            if (amounts[i] == 0) continue;
            if (balanceOf(wallets[i]) + amounts[i] > MAX_PER_WALLET) revert ExceedsMaxPerWallet();

            totalMinted += amounts[i];
            ethRequired += amounts[i] * MINT_PRICE;

            _mint(wallets[i], amounts[i]);
        }
        whitelistSupply += totalMinted;

        // we do these checks after the loop to avoid two loops (one for checking and another one for minting)
        if (msg.value != ethRequired) revert WrongValueSent();
        if (totalSupply() + totalMinted > CURRENT_ROUND_ALLOCATION) revert ExceedsMaxSupply();
        if (whitelistSupply + totalMinted > CURRENT_WHITELIST_ALLOCATION) revert("Exceeds whitelist allocation");
    }

    /// @notice This function is used to mint a single token to a collaborator. Free of charge. This supply is limited
    function mintOneToCollaborator(address[] calldata wallets) external onlyRole(MINTER_ROLE) {
        uint256 amount = wallets.length;
        if (amount == 0) revert("No wallets provided");
        if (amount > 10) revert("Maximum 10 wallets at a time");
        // this can happen in any round except when sale is closed. The PRIVATE round is when this function is exclusive
        if (phase == Phase.CLOSED) revert PrivateSaleIsClosed();
        if (collaboratorsSupply + amount > COLLABORATORS_HARD_CAP) revert ExceedsCollaboratorsSupply();

        collaboratorsSupply += amount;
        for (uint256 i = 0; i < wallets.length; i++) {
            // We don't check the total supply or the max per wallet in this case
            _mint(wallets[i], 1);
        }
    }

    function nextPhase() external onlyRole(CONTRACT_OPERATOR_ROLE) {
        // store in memory to avoid multiple reads from storge to save gas
        Phase _phase = phase;

        if (_phase == Phase.CLOSED) {
            phase = Phase.PRIVATE;
        } else if (_phase == Phase.PRIVATE) {
            phase = Phase.WHITELIST;
        } else if (_phase == Phase.WHITELIST) {
            phase = Phase.PUBLIC;
        } else {
            closeCurrentRound();
        }
        emit NextPhaseInitiated(phase);
    }

    // @notice  This can finalize the reound regardless of being in whitelist/public phase
    function closeCurrentRound() public onlyRole(CONTRACT_OPERATOR_ROLE) {
        if (phase == Phase.CLOSED) revert SaleAlreadyClosed();
        phase = Phase.CLOSED;
    }

    // @notice  Sets up the configuration of a new round, without opening it
    function setRoundCaps(uint256 newSupplyCap, uint256 newMaxPerWallet, uint256 newWhitelistCap)
        external
        onlyRole(CONTRACT_OPERATOR_ROLE)
    {
        if (phase != Phase.CLOSED) revert DisabledWhileSaleIsActive();
        // newSupplyCap == currentRoundMaxSupply is allowed, and will effectively allow 0 new mints
        if ((newSupplyCap < CURRENT_ROUND_ALLOCATION) || (newSupplyCap > SUPPLY_HARD_CAP)) revert InvalidNewSupplyCap();
        if (newMaxPerWallet < MAX_PER_WALLET) revert InvalidNewMaxPerWallet();
        if (newWhitelistCap < CURRENT_WHITELIST_ALLOCATION) revert("Invalid new Whitelist supply cap");

        CURRENT_ROUND_ALLOCATION = newSupplyCap;
        CURRENT_WHITELIST_ALLOCATION = newWhitelistCap;
        MAX_PER_WALLET = newMaxPerWallet;
    }

    function setMintPrice(uint256 newPrice) external onlyRole(CONTRACT_OPERATOR_ROLE) {
        if (phase != Phase.CLOSED) revert DisabledWhileSaleIsActive();
        MINT_PRICE = newPrice;
    }

    function setMerkleRoot(bytes32 _root) external onlyRole(CONTRACT_OPERATOR_ROLE) {
        merkleRoot = _root;
    }

    function setBaseTokenURI(string calldata _baseTokenURI) public onlyRole(CONTRACT_OPERATOR_ROLE) {
        baseTokenURI = _baseTokenURI;
    }

    function setContractURI(string memory _newContractURI) public onlyRole(CONTRACT_OPERATOR_ROLE) {
        collectionContractURI = _newContractURI;
    }

    function reveal(string calldata _baseTokenURI) external onlyRole(CONTRACT_OPERATOR_ROLE) {
        setBaseTokenURI(_baseTokenURI);
        isRevealed = true;
    }

    function withdrawCollectedFees() external onlyRole(CONTRACT_OPERATOR_ROLE) {
        uint256 balance = address(this).balance;
        uint256 _debt = debtWithDevs;

        uint256 devsPayment = _debt > balance ? balance : _debt;
        debtWithDevs -= devsPayment;

        uint256 toShare = balance - devsPayment;
        uint256 devsSalesShare = (toShare * shareToDevs) / BASIS_POINTS;
        // if the share to devs is 0, all goes to creators
        uint256 toCreators = toShare - devsSalesShare;
        uint256 toDevs = devsPayment + devsSalesShare;

        // there is no risk of reentrancy because the two wallets are known to be EOA, not contracts
        bool success;
        if (toCreators > 0) {
            (success,) = payable(creatorsAddress).call{value: toCreators}("");
            if (!success) revert CreatorsPaymentFailed();
        }
        if (toDevs > 0) {
            (success,) = payable(devsAddress).call{value: toDevs}("");
            if (!success) revert DevsPaymentFailed();
        }
    }

    /// @notice  Sets the new payment conditions between the creators and the devs. It can only be set before the round
    ///          is opened. Once any sale is opened, the payment distribution is locked.
    function setNewPaymentModeToDevs(uint256 newDebtToDevs, uint256 newShareToDevs)
        external
        onlyRole(CONTRACT_OPERATOR_ROLE)
    {
        if (phase != Phase.CLOSED) revert DisabledWhileSaleIsActive();
        if (newShareToDevs > BASIS_POINTS) revert InvalidDevsPaymentMode();

        // the absolute debt accumulates, but the shares of the sales it is overwriten
        debtWithDevs += newDebtToDevs;
        shareToDevs = newShareToDevs;
    }

    function setDefaultRoyalty(address receiver, uint96 numerator) public onlyRole(CONTRACT_OPERATOR_ROLE) {
        if (numerator > _feeDenominator()) revert InvalidRoyalty();
        _setDefaultRoyalty(receiver, numerator);
    }

    function setFavorPeriodDuration(uint256 newPeriodDuration) external onlyRole(CONTRACT_OPERATOR_ROLE) {
        // as a new refernce date, set the last time a favorPeriod was completed
        referenceDate = block.timestamp - (block.timestamp - referenceDate) % favorPeriodDuration;
        favorPeriodDuration = newPeriodDuration;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // internal functions
    function _batchMint(address to, uint256 amount) internal {
        // check first the ones that require less gas in reading operations
        if (amount == 0) revert MintZeroItems();
        if (msg.value != amount * MINT_PRICE) revert WrongValueSent();
        if (totalSupply() + amount > CURRENT_ROUND_ALLOCATION) revert ExceedsMaxSupply();
        if (balanceOf(to) + amount > MAX_PER_WALLET) revert ExceedsMaxPerWallet();

        _mint(to, amount);
    }

    function _canUseFavor(uint256 tokenId) internal view returns (bool) {
        // save variables into memory to save gas
        uint256 _lastFavor = lastFavourRedeemedTime[tokenId];
        uint256 _refDate = referenceDate;
        uint256 _periodDuration = favorPeriodDuration;

        if (block.timestamp - _lastFavor > _periodDuration) {
            return (block.timestamp - _refDate > _periodDuration);
        } else {
            // as soon as we hit next checkpoint, the reminder of the first term will be 0, and therefore lower than
            // the reminder of the second term. And we only get here if the reminder of the second term is
            // lower than the _periodDuration, therefore, (block.timestamp - _lastFavor) % _periodDuration
            // is equivalent to (block.timestamp - _lastFavor)
            return ((block.timestamp - _refDate) % _periodDuration) <= (block.timestamp - _lastFavor);
        }
    }

    function _timeUntilNextFavor(uint256 tokenId) internal view returns (uint256) {
        if (_canUseFavor(tokenId)) return 0;

        uint256 _periodDuration = favorPeriodDuration;

        uint256 timeSinceLastFavor = (block.timestamp - referenceDate) % _periodDuration;
        return _periodDuration - timeSinceLastFavor;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function _verifyProof(address minter, bytes32[] calldata proof) internal view returns (bool) {
        bytes32 leaf = keccak256((abi.encodePacked(minter)));
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }
}