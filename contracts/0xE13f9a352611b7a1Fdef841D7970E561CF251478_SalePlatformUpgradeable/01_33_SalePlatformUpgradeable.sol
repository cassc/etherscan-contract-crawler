// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IQuantumArt.sol";
import "./interfaces/IQuantumMintPass.sol";
import "./interfaces/IQuantumUnlocked.sol";
import "./interfaces/IQuantumKeyRing.sol";
import "./ContinuousDutchAuctionUpgradeable.sol";
import "./solmate/AuthUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/BitMapsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./QuantumBlackListable.sol";
import "./SalePlatformStorage.sol";

contract SalePlatformUpgradeable is
    SalePlatformAccessors,
    Initializable,
    ContinuousDutchAuctionUpgradeable,
    ReentrancyGuardUpgradeable,
    AuthUpgradeable,
    UUPSUpgradeable
{
    using SalePlatformStorage for SalePlatformStorage.Layout;
    using BitMapsUpgradeable for BitMapsUpgradeable.BitMap;
    using StringsUpgradeable for uint256;

    event Purchased(uint256 indexed dropId, uint256 tokenId, address to);
    event DropCreated(uint256 dropId);
    event DropUpdated(uint256 dropId);

    //mapping dropId => struct
    // mapping(uint256 => Sale) public sales;
    // mapping(uint256 => MPClaim) public mpClaims;
    // mapping(uint256 => Whitelist) public whitelists;
    // uint256 public defaultArtistCut; //10000 * percentage
    // IQuantumArt public quantum;
    // IQuantumMintPass public mintpass;
    // IQuantumUnlocked public keyUnlocks;
    // IQuantumKeyRing public keyRing;
    // address[] public privilegedContracts;

    uint256 private constant SEPARATOR = 10**4;

    // uint128 public nextUnlockDropId;
    // mapping(uint256 => UnlockSale) public keySales;

    /// >>>>>>>>>>>>>>>>>>>>>  INITIALIZER  <<<<<<<<<<<<<<<<<<<<<< ///

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        requiresAuth
    {}

    function initialize(
        address deployedQuantum,
        address deployedMP,
        address deployedKeyRing,
        address deployedUnlocks,
        address admin,
        address payable treasury,
        address authority,
        address authorizer,
        address blAddress
    ) public virtual initializer {
        __SalePlatform_init(
            deployedQuantum,
            deployedMP,
            deployedKeyRing,
            deployedUnlocks,
            admin,
            treasury,
            authority,
            authorizer,
            blAddress
        );
    }

    function __SalePlatform_init(
        address deployedQuantum,
        address deployedMP,
        address deployedKeyRing,
        address deployedUnlocks,
        address admin,
        address payable treasury,
        address authority,
        address authorizer,
        address blAddress
    ) internal onlyInitializing {
        __AuthAuction_init(admin, AuthorityUpgradeable(authority));
        __SalePlatform_init_unchained(
            deployedQuantum,
            deployedMP,
            deployedKeyRing,
            deployedUnlocks,
            treasury,
            authorizer,
            blAddress
        );
    }

    function __SalePlatform_init_unchained(
        address deployedQuantum,
        address deployedMP,
        address deployedKeyRing,
        address deployedUnlocks,
        address payable treasury,
        address authorizer,
        address blAddress
    ) internal onlyInitializing {
        SalePlatformStorage.Layout storage s = SalePlatformStorage.layout();
        s.quantum = IQuantumArt(deployedQuantum);
        s.mintpass = IQuantumMintPass(deployedMP);
        s.keyRing = IQuantumKeyRing(deployedKeyRing);
        s.keyUnlocks = IQuantumUnlocked(deployedUnlocks);
        s.quantumTreasury = treasury;
        s.authorizer = authorizer;
        s.defaultArtistCut = 8000; //default 80% for artist
        s.blackListAddress = blAddress;
    }

    /// >>>>>>>>>>>>>>>>>>>>>  BLACKLIST OPS  <<<<<<<<<<<<<<<<<<<<<< ///
    modifier isNotBlackListed(address user) {
        if (
            QuantumBlackListable.isBlackListed(
                user,
                SalePlatformStorage.layout().blackListAddress
            )
        ) {
            revert QuantumBlackListable.BlackListedAddress(user);
        }
        _;
    }

    function getBlackListAddress() public view returns (address) {
        return SalePlatformStorage.layout().blackListAddress;
    }

    function setBlackListAddress(address blAddress) public requiresAuth {
        if (blAddress == address(0)) {
            revert QuantumBlackListable.InvalidBlackListAddress();
        }
        SalePlatformStorage.layout().blackListAddress = blAddress;
    }

    /// >>>>>>>>>>>>>>>>>>>>>

    modifier checkCaller() {
        require(msg.sender.code.length == 0, "Contract forbidden");
        _;
    }

    modifier isFirstTime(uint256 dropId) {
        SalePlatformStorage.Layout storage s = SalePlatformStorage.layout();
        if (!s.disablingLimiter.get(dropId)) {
            require(
                !s.alreadyBought[msg.sender].get(dropId),
                string(
                    abi.encodePacked("Already bought drop ", dropId.toString())
                )
            );
            s.alreadyBought[msg.sender].set(dropId);
        }
        _;
    }

    function setPrivilegedContracts(address[] calldata contracts)
        public
        requiresAuth
    {
        SalePlatformStorage.layout().privilegedContracts = contracts;
    }

    function setAuthorizer(address authorizer) public requiresAuth {
        SalePlatformStorage.layout().authorizer = authorizer;
    }

    function withdraw(address payable to) public requiresAuth {
        AddressUpgradeable.sendValue(to, address(this).balance);
    }

    function premint(uint256 dropId, address[] calldata recipients)
        public
        requiresAuth
    {
        SalePlatformStorage.Layout storage s = SalePlatformStorage.layout();
        for (uint256 i = 0; i < recipients.length; i++) {
            if (
                QuantumBlackListable.isBlackListed(
                    recipients[i],
                    SalePlatformStorage.layout().blackListAddress
                )
            ) {
                revert QuantumBlackListable.BlackListedAddress(recipients[i]);
            }
            uint256 tokenId = s.quantum.mintTo(dropId, recipients[i]);
            emit Purchased(dropId, tokenId, recipients[i]);
        }
    }

    function setMintpass(address deployedMP) public requiresAuth {
        SalePlatformStorage.layout().mintpass = IQuantumMintPass(deployedMP);
    }

    function setQuantum(address deployedQuantum) public requiresAuth {
        SalePlatformStorage.layout().quantum = IQuantumArt(deployedQuantum);
    }

    function setKeyRing(address deployedKeyRing) public requiresAuth {
        SalePlatformStorage.layout().keyRing = IQuantumKeyRing(deployedKeyRing);
    }

    function setKeyUnlocks(address deployedUnlocks) public requiresAuth {
        SalePlatformStorage.layout().keyUnlocks = IQuantumUnlocked(
            deployedUnlocks
        );
    }

    function setDefaultArtistCut(uint256 cut) public requiresAuth {
        SalePlatformStorage.layout().defaultArtistCut = cut;
    }

    function createSale(
        uint256 dropId,
        uint128 price,
        uint64 start,
        uint64 limit
    ) public requiresAuth {
        SalePlatformStorage.layout().sales[dropId] = Sale(price, start, limit);
    }

    function createMPClaim(
        uint256 dropId,
        uint64 mpId,
        uint64 start,
        uint128 price
    ) public requiresAuth {
        SalePlatformStorage.layout().mpClaims[dropId] = MPClaim(
            mpId,
            start,
            price
        );
    }

    function createWLClaim(
        uint256 dropId,
        uint192 price,
        uint64 start,
        bytes32 root
    ) public requiresAuth {
        SalePlatformStorage.layout().whitelists[dropId] = Whitelist(
            price,
            start,
            root
        );
    }

    function flipUint64(uint64 x) internal pure returns (uint64) {
        return x > 0 ? 0 : type(uint64).max;
    }

    function flipSaleState(uint256 dropId) public requiresAuth {
        SalePlatformStorage.Layout storage s = SalePlatformStorage.layout();
        s.sales[dropId].start = flipUint64(s.sales[dropId].start);
    }

    function flipMPClaimState(uint256 dropId) public requiresAuth {
        SalePlatformStorage.Layout storage s = SalePlatformStorage.layout();
        s.mpClaims[dropId].start = flipUint64(s.mpClaims[dropId].start);
    }

    function flipWLState(uint256 dropId) public requiresAuth {
        SalePlatformStorage.Layout storage s = SalePlatformStorage.layout();
        s.whitelists[dropId].start = flipUint64(s.whitelists[dropId].start);
    }

    function flipLimiterForDrop(uint256 dropId) public requiresAuth {
        SalePlatformStorage.Layout storage s = SalePlatformStorage.layout();
        if (s.disablingLimiter.get(dropId)) {
            s.disablingLimiter.unset(dropId);
        } else {
            s.disablingLimiter.set(dropId);
        }
    }

    function overrideArtistcut(uint256 dropId, uint256 cut)
        public
        requiresAuth
    {
        SalePlatformStorage.layout().overridedArtistCut[dropId] = cut;
    }

    function overrideUnlockArtistCut(uint256 dropId, uint256 cut)
        public
        requiresAuth
    {
        SalePlatformStorage.layout().keySales[dropId].overrideArtistcut = cut;
    }

    function setAuction(
        uint256 auctionId,
        uint256 startingPrice,
        uint128 decreasingConstant,
        uint64 start,
        uint64 period
    ) public override requiresAuth {
        super.setAuction(
            auctionId,
            startingPrice,
            decreasingConstant,
            start,
            period
        );
    }

    function curatedPayout(
        address artist,
        uint256 dropId,
        uint256 amount
    ) internal {
        SalePlatformStorage.Layout storage s = SalePlatformStorage.layout();
        uint256 artistCut = s.overridedArtistCut[dropId] == 0
            ? s.defaultArtistCut
            : s.overridedArtistCut[dropId];
        uint256 payout_ = (amount * artistCut) / 10000;
        AddressUpgradeable.sendValue(payable(artist), payout_);
        AddressUpgradeable.sendValue(s.quantumTreasury, amount - payout_);
    }

    function genericPayout(
        address artist,
        uint256 amount,
        uint256 cut
    ) internal {
        SalePlatformStorage.Layout storage s = SalePlatformStorage.layout();
        uint256 artistCut = cut == 0 ? s.defaultArtistCut : cut;
        uint256 payout_ = (amount * artistCut) / 10000;
        AddressUpgradeable.sendValue(payable(artist), payout_);
        AddressUpgradeable.sendValue(s.quantumTreasury, amount - payout_);
    }

    function _isPrivileged(address user) internal view returns (bool) {
        SalePlatformStorage.Layout storage s = SalePlatformStorage.layout();
        uint256 length = s.privilegedContracts.length;
        unchecked {
            for (uint256 i; i < length; i++) {
                /// @dev using this interface because has balanceOf
                if (IQuantumArt(s.privilegedContracts[i]).balanceOf(user) > 0) {
                    return true;
                }
            }
        }
        return false;
    }

    function purchase(uint256 dropId, uint256 amount)
        public
        payable
        isNotBlackListed(msg.sender)
        nonReentrant
        checkCaller
        isFirstTime(dropId)
    {
        SalePlatformStorage.Layout storage s = SalePlatformStorage.layout();
        Sale memory sale = s.sales[dropId];
        require(block.timestamp >= sale.start, "PURCHASE:SALE INACTIVE");
        require(amount <= sale.limit, "PURCHASE:OVER LIMIT");
        require(
            msg.value == amount * sale.price,
            "PURCHASE:INCORRECT MSG.VALUE"
        );
        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = s.quantum.mintTo(dropId, msg.sender);
            emit Purchased(dropId, tokenId, msg.sender);
        }
        curatedPayout(s.quantum.getArtist(dropId), dropId, msg.value);
    }

    function purchaseThroughAuction(uint256 dropId)
        public
        payable
        isNotBlackListed(msg.sender)
        nonReentrant
        checkCaller
    {
        SalePlatformStorage.Layout storage s = SalePlatformStorage.layout();
        Auction memory auction = s.auctions[dropId];

        // Temporary version of isFirstTime to only be active during the decreasing period
        if (auction.start + auction.period >= block.timestamp) {
            if (!s.disablingLimiter.get(dropId)) {
                require(
                    !s.alreadyBought[msg.sender].get(dropId),
                    string(
                        abi.encodePacked(
                            "Already bought drop ",
                            dropId.toString()
                        )
                    )
                );
                s.alreadyBought[msg.sender].set(dropId);
            }
        }

        // if 5 minutes before public auction
        // if holder -> special treatment
        uint256 userPaid = auction.startingPrice;
        if (
            block.timestamp <= auction.start &&
            block.timestamp >= auction.start - 300 &&
            _isPrivileged(msg.sender)
        ) {
            require(msg.value == userPaid, "PURCHASE:INCORRECT MSG.VALUE");
        } else {
            userPaid = verifyBid(dropId);
        }
        uint256 tokenId = s.quantum.mintTo(dropId, msg.sender);
        emit Purchased(dropId, tokenId, msg.sender);
        curatedPayout(s.quantum.getArtist(dropId), dropId, userPaid);
    }

    function authorizedUnlockWithKey(
        UnlockedMintAuthorization calldata mintAuth,
        uint256 variant
    ) public payable {
        SalePlatformStorage.Layout storage s = SalePlatformStorage.layout();
        // require(msg.sender == owner || msg.sender == _minter, "NOT_AUTHORIZED");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encodePacked(
                        mintAuth.id,
                        mintAuth.keyId,
                        mintAuth.dropId,
                        mintAuth.validFrom,
                        mintAuth.validPeriod
                    )
                )
            )
        );
        address signer = ecrecover(digest, mintAuth.v, mintAuth.r, mintAuth.s);
        if (signer != s.authorizer) revert("PURCHASE:INVALID SIGNATURE");
        if (block.timestamp <= mintAuth.validFrom)
            revert("PURCHASE:NOT VALID YET");
        if (
            mintAuth.validPeriod > 0 &&
            block.timestamp > mintAuth.validFrom + mintAuth.validPeriod
        ) revert("PURCHASE:AUTHORIZATION EXPIRED");

        UnlockSale memory sale = s.keySales[mintAuth.dropId];
        address recipient = s.keyRing.ownerOf(mintAuth.keyId);
        _unlockWithKey(
            mintAuth.keyId,
            mintAuth.dropId,
            variant,
            recipient,
            sale
        );
    }

    function _unlockWithKey(
        uint256 keyId,
        uint128 dropId,
        uint256 variant,
        address recipient,
        UnlockSale memory sale
    ) private isNotBlackListed(recipient) {
        SalePlatformStorage.Layout storage s = SalePlatformStorage.layout();
        require(!s.keyUnlockClaims[dropId][keyId], "PURCHASE:KEY ALREADY USED");

        require(
            s.keyUnlocks.dropSupply(dropId) < sale.maxDropSupply,
            "PURCHASE:NO MORE AVAILABLE"
        );
        require(
            sale.numOfVariants == 0 ||
                (variant > 0 && variant < sale.numOfVariants + 1),
            "PURCHASE:INVALID VARIANT"
        );
        //Check is a valid key range (to limit to particular keys)
        bool inRange = false;
        if (sale.enabledKeyRanges.length > 0) {
            for (uint256 i = 0; i < sale.enabledKeyRanges.length; i++) {
                if (
                    (keyId >= (sale.enabledKeyRanges[i] * SEPARATOR)) &&
                    (keyId < (((sale.enabledKeyRanges[i] + 1) * SEPARATOR) - 1))
                ) inRange = true;
            }
        } else inRange = true;
        require(inRange, "PURCHASE:SALE NOT AVAILABLE TO THIS KEY");
        require(msg.value == sale.price, "PURCHASE:INCORRECT MSG.VALUE");

        uint256 tokenId = s.keyUnlocks.mint(recipient, dropId, variant);
        s.keyUnlockClaims[dropId][keyId] = true;
        emit Purchased(dropId, tokenId, recipient);
        genericPayout(sale.artist, msg.value, sale.overrideArtistcut);
    }

    function unlockWithKey(
        uint256 keyId,
        uint128 dropId,
        uint256 variant
    ) public payable nonReentrant checkCaller {
        SalePlatformStorage.Layout storage s = SalePlatformStorage.layout();
        require(
            s.keyRing.ownerOf(keyId) == msg.sender,
            "PURCHASE:NOT KEY OWNER"
        );
        UnlockSale memory sale = s.keySales[dropId];
        require(block.timestamp >= sale.start, "PURCHASE:SALE NOT STARTED");
        require(
            block.timestamp <= (sale.start + sale.period),
            "PURCHASE:SALE EXPIRED"
        );
        _unlockWithKey(keyId, dropId, variant, msg.sender, sale);
    }

    function createUnlockSale(
        uint128 price,
        uint64 start,
        uint64 period,
        address artist,
        uint128 maxSupply,
        uint256 numOfVariants,
        uint256[] calldata enabledKeyRanges
    ) public requiresAuth {
        SalePlatformStorage.Layout storage s = SalePlatformStorage.layout();
        emit DropCreated(s.nextUnlockDropId);
        uint256[] memory blankRanges;
        s.keySales[s.nextUnlockDropId++] = UnlockSale(
            price,
            start,
            period,
            artist,
            0,
            blankRanges,
            numOfVariants,
            maxSupply
        );
        for (uint256 i = 0; i < enabledKeyRanges.length; i++)
            s.keySales[s.nextUnlockDropId - 1].enabledKeyRanges.push(
                enabledKeyRanges[i]
            );
    }

    function updateUnlockSale(
        uint128 dropId,
        uint128 price,
        uint64 start,
        uint64 period,
        address artist,
        uint128 maxSupply,
        uint256 numOfVariants,
        uint256[] calldata enabledKeyRanges
    ) public requiresAuth {
        SalePlatformStorage.Layout storage s = SalePlatformStorage.layout();
        emit DropUpdated(dropId);
        uint256[] memory blankRanges;
        s.keySales[dropId] = UnlockSale(
            price,
            start,
            period,
            artist,
            0,
            blankRanges,
            numOfVariants,
            maxSupply
        );
        for (uint256 i = 0; i < enabledKeyRanges.length; i++)
            s.keySales[s.nextUnlockDropId - 1].enabledKeyRanges.push(
                enabledKeyRanges[i]
            );
    }

    function setKeyUsedBatch(
        uint128 dropId,
        bool set,
        uint256[] calldata keys
    ) public requiresAuth {
        for (uint256 i = 0; i < keys.length; i++) {
            SalePlatformStorage.layout().keyUnlockClaims[dropId][keys[i]] = set;
        }
    }

    function isKeyUsed(uint256 dropId, uint256 keyId)
        public
        view
        returns (bool)
    {
        return SalePlatformStorage.layout().keyUnlockClaims[dropId][keyId];
    }

    function claimWithMintPass(uint256 dropId, uint256 amount)
        public
        payable
        isNotBlackListed(msg.sender)
        nonReentrant
    {
        SalePlatformStorage.Layout storage s = SalePlatformStorage.layout();
        MPClaim memory mpClaim = s.mpClaims[dropId];
        require(block.timestamp >= mpClaim.start, "MP: CLAIMING INACTIVE");
        require(msg.value == amount * mpClaim.price, "MP:WRONG MSG.VALUE");
        s.mintpass.burnFromRedeem(msg.sender, mpClaim.mpId, amount); //burn mintpasses
        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = s.quantum.mintTo(dropId, msg.sender);
            emit Purchased(dropId, tokenId, msg.sender);
        }
        if (msg.value > 0)
            curatedPayout(s.quantum.getArtist(dropId), dropId, msg.value);
    }

    function purchaseThroughWhitelist(
        uint256 dropId,
        uint256 amount,
        uint256 index,
        bytes32[] calldata merkleProof
    ) external payable isNotBlackListed(msg.sender) nonReentrant {
        SalePlatformStorage.Layout storage s = SalePlatformStorage.layout();
        Whitelist memory whitelist = s.whitelists[dropId];
        require(block.timestamp >= whitelist.start, "WL:INACTIVE");
        require(msg.value == whitelist.price * amount, "WL: INVALID MSG.VALUE");
        require(!s.claimedWL[dropId].get(index), "WL:ALREADY CLAIMED");
        bytes32 node = keccak256(abi.encodePacked(msg.sender, amount, index));
        require(
            MerkleProofUpgradeable.verify(
                merkleProof,
                whitelist.merkleRoot,
                node
            ),
            "WL:INVALID PROOF"
        );
        s.claimedWL[dropId].set(index);
        uint256 tokenId = s.quantum.mintTo(dropId, msg.sender);
        emit Purchased(dropId, tokenId, msg.sender);
        curatedPayout(s.quantum.getArtist(dropId), dropId, msg.value);
    }

    function isWLClaimed(uint256 dropId, uint256 index)
        public
        view
        returns (bool)
    {
        return SalePlatformStorage.layout().claimedWL[dropId].get(index);
    }
}