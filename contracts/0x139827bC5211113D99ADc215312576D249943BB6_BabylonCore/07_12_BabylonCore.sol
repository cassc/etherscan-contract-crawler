// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./interfaces/IBabylonCore.sol";
import "./interfaces/IBabylonMintPass.sol";
import "./interfaces/ITokensController.sol";
import "./interfaces/IRandomProvider.sol";
import "./interfaces/IEditionsExtension.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract BabylonCore is Initializable, IBabylonCore, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    ITokensController internal _tokensController;
    IRandomProvider internal _randomProvider;
    IEditionsExtension internal _editionsExtension;
    string internal _mintPassBaseURI;
    //listing ids start from 1st, not 0
    uint256 internal _lastListingId;
    uint256 internal _maxListingDuration;

    address internal _treasury;

    // collection address -> tokenId -> id of a listing
    mapping(address => mapping(uint256 => uint256)) internal _ids;
    // id of a listing -> a listing info
    mapping(uint256 => ListingInfo) internal _listingInfos;
    // id of a listing -> a listing restrictions
    mapping(uint256 => ListingRestrictions) internal _listingRestrictions;
    // id of a listing -> participant address -> num of mint passes
    mapping(uint256 => mapping(address => uint256)) internal _participations;

    uint256 public constant BASIS_POINTS = 10000;

    event NewParticipant(uint256 listingId, address participant, uint256 ticketsAmount);
    event ListingStarted(uint256 listingId, address creator, address token, uint256 tokenId, address mintPass);
    event ListingResolving(uint256 listingId, uint256 randomRequestId);
    event ListingSuccessful(uint256 listingId, address claimer);
    event ListingCanceled(uint256 listingId);
    event ListingFinalized(uint256 listingId);
    event ListingRestrictionsUpdated(
        uint256 indexed listingId,
        bytes32 allowlistRoot,
        uint256 reserved,
        uint256 mintedFromReserve,
        uint256 maxPerAddress
    );

    function initialize(
        ITokensController tokensController,
        IRandomProvider randomProvider,
        IEditionsExtension editionsExtension,
        address treasury
    ) public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();
        _tokensController = tokensController;
        _randomProvider = randomProvider;
        _editionsExtension = editionsExtension;
        _maxListingDuration = 7 days;
        _treasury = treasury;
        transferOwnership(msg.sender);
    }

    function startListing(
        ListingItem calldata item,
        IEditionsExtension.EditionInfo calldata edition,
        ListingRestrictions calldata restrictions,
        uint256 timeStart,
        uint256 price,
        uint256 totalTickets,
        uint256 donationBps
    ) external {
        uint256 listingId = _ids[item.token][item.identifier];

        if (listingId != 0) {
            require(
                _listingInfos[listingId].state != ListingState.Active &&
                _listingInfos[listingId].state != ListingState.Resolving,
                "BabylonCore: Active listing for this token already exists"
            );
        }

        require(
            _tokensController.checkApproval(msg.sender, item),
            "BabylonCore: Token should be owned and approved to the controller"
        );

        require(totalTickets > 0, "BabylonCore: Number of tickets is too low");
        require(donationBps <= BASIS_POINTS, "BabylonCore: Donation out of range");

        require(
            restrictions.reserved <= totalTickets &&
            restrictions.maxPerAddress <= totalTickets,
            "BabylonCore: Incorrect restrictions"
        );

        listingId = _lastListingId + 1;
        address mintPass = _tokensController.createMintPass(listingId);
        _editionsExtension.registerEdition(edition, msg.sender, listingId);
        _ids[item.token][item.identifier] = listingId;
        ListingInfo storage listing = _listingInfos[listingId];
        listing.item = item;
        listing.state = ListingState.Active;
        listing.creator = msg.sender;
        listing.mintPass = mintPass;
        listing.price = price;
        listing.timeStart = timeStart > block.timestamp ? timeStart : block.timestamp;
        listing.totalTickets = totalTickets;
        listing.donationBps = donationBps;
        listing.creationTimestamp = block.timestamp;
        ListingRestrictions storage listingRestrictions = _listingRestrictions[listingId];
        listingRestrictions.allowlistRoot = restrictions.allowlistRoot;
        listingRestrictions.reserved = restrictions.reserved;
        listingRestrictions.maxPerAddress = restrictions.maxPerAddress;
        _lastListingId = listingId;

        emit ListingStarted(listingId, msg.sender, item.token, item.identifier, mintPass);
        emit ListingRestrictionsUpdated(
            listingId,
            restrictions.allowlistRoot,
            restrictions.reserved,
            0,
            restrictions.maxPerAddress
        );
    }

    function participate(
        uint256 id,
        uint256 tickets,
        bytes32[] calldata allowlistProof
    ) external payable nonReentrant {
        ListingInfo storage listing =  _listingInfos[id];
        require(
            _tokensController.checkApproval(listing.creator, listing.item),
            "BabylonCore: Token is no longer owned or approved to the controller"
        );
        require(listing.state == ListingState.Active, "BabylonCore: Listing state should be active");
        require(block.timestamp >= listing.timeStart, "BabylonCore: Too early to participate");
        uint256 current = listing.currentTickets;
        require(current + tickets <= listing.totalTickets, "BabylonCore: No available tickets");
        uint256 totalPrice = listing.price * tickets;
        require(msg.value == totalPrice, "BabylonCore: msg.value doesn't match price for tickets");

        ListingRestrictions storage restrictions = _listingRestrictions[id];

        uint256 participations = _participations[id][msg.sender] + tickets;
        require(participations <= restrictions.maxPerAddress, "BabylonCore: Tickets exceed maxPerAddress");
        _participations[id][msg.sender] = participations;

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (MerkleProof.verify(allowlistProof, restrictions.allowlistRoot, leaf)) {
            uint256 allowlistLeft = restrictions.reserved - restrictions.mintedFromReserve;
            if (allowlistLeft > 0) {
                if (allowlistLeft <= tickets) {
                    restrictions.mintedFromReserve = restrictions.reserved;
                } else {
                    restrictions.mintedFromReserve += tickets;
                }

                emit ListingRestrictionsUpdated(
                    id,
                    restrictions.allowlistRoot,
                    restrictions.reserved,
                    restrictions.mintedFromReserve,
                    restrictions.maxPerAddress
                );
            }
        } else {
            uint256 available = (listing.totalTickets + restrictions.mintedFromReserve) - current - restrictions.reserved;
            require((available >= tickets), "BabylonCore: No available tickets outside the allowlist");
        }

        IBabylonMintPass(listing.mintPass).mint(msg.sender, tickets);

        listing.currentTickets = current + tickets;

        emit NewParticipant(id, msg.sender, tickets);

        if (listing.currentTickets == listing.totalTickets) {
            listing.randomRequestId = _randomProvider.requestRandom(id);
            listing.state = ListingState.Resolving;

            emit ListingResolving(id, listing.randomRequestId);
        }
    }

    function updateListingRestrictions(uint256 id, ListingRestrictions calldata newRestrictions) external {
        ListingInfo storage listing =  _listingInfos[id];
        uint256 totalTickets = listing.totalTickets;
        require(listing.state == ListingState.Active, "BabylonCore: Listing state should be active");
        require(msg.sender == listing.creator, "BabylonCore: Only the creator can update the restrictions");

        ListingRestrictions storage restrictions = _listingRestrictions[id];
        restrictions.allowlistRoot = newRestrictions.allowlistRoot;

        uint256 reserveFloor = restrictions.mintedFromReserve;
        uint256 reserveCeiling = (totalTickets - listing.currentTickets + restrictions.mintedFromReserve);

        if (newRestrictions.reserved <= reserveCeiling) {
            restrictions.reserved = newRestrictions.reserved <= reserveFloor ? reserveFloor : newRestrictions.reserved;
        } else {
            restrictions.reserved = reserveCeiling;
        }

        restrictions.maxPerAddress = newRestrictions.maxPerAddress >= totalTickets ?
            totalTickets : newRestrictions.maxPerAddress;

        emit ListingRestrictionsUpdated(
            id,
            restrictions.allowlistRoot,
            restrictions.reserved,
            restrictions.mintedFromReserve,
            restrictions.maxPerAddress
        );
    }

    function cancelListing(uint256 id) external {
        ListingInfo storage listing =  _listingInfos[id];
        if (listing.state == ListingState.Resolving) {
            require(_randomProvider.isRequestOverdue(listing.randomRequestId), "BabylonCore: Random is not overdue");
        } else {
            require(listing.state == ListingState.Active, "BabylonCore: Listing state should be active");
            require(msg.sender == listing.creator, "BabylonCore: Only listing creator can cancel active listing");
        }

        listing.state = ListingState.Canceled;

        emit ListingCanceled(id);
    }

    function transferETHToCreator(uint256 id) external nonReentrant {
        ListingInfo storage listing =  _listingInfos[id];
        require(listing.state == ListingState.Successful, "BabylonCore: Listing state should be successful");

        bool sent;
        uint256 creatorPayout = listing.totalTickets * listing.price;
        uint256 donation = creatorPayout * listing.donationBps / BASIS_POINTS;

        if (donation > 0) {
            creatorPayout -= donation;
            (sent, ) = payable(_treasury).call{value: donation}("");
            require(sent, "BabylonCore: Unable to send donation to the treasury");
        }

        if (creatorPayout > 0) {
            (sent, ) = payable(listing.creator).call{value: creatorPayout}("");
            require(sent, "BabylonCore: Unable to send ETH to the creator");
        }

        listing.state = ListingState.Finalized;
        emit ListingFinalized(id);
    }

    function refund(uint256 id) external nonReentrant {
        ListingInfo storage listing =  _listingInfos[id];

        if (
            (
                (listing.state == ListingState.Active || listing.state == ListingState.Resolving) &&
                !_tokensController.checkApproval(listing.creator, listing.item)
            ) ||
            (
                listing.state == ListingState.Active &&
                (listing.timeStart + _maxListingDuration <= block.timestamp)
            )
        ) {
            listing.state = ListingState.Canceled;

            emit ListingCanceled(id);
        }

        require(listing.state == ListingState.Canceled, "BabylonCore: Listing state should be canceled to refund");

        uint256 tickets = IBabylonMintPass(listing.mintPass).burn(msg.sender);

        uint256 amount = tickets * listing.price;
        (bool sent, ) = payable(msg.sender).call{value: amount}("");

        require(sent, "BabylonCore: Unable to refund ETH");
    }

    function mintEdition(uint256 id) external {
        ListingInfo storage listing =  _listingInfos[id];
        require(
            listing.state == ListingState.Successful ||
            listing.state == ListingState.Finalized,
            "BabylonCore: Listing should be successful"
        );

        uint256 tickets = IBabylonMintPass(listing.mintPass).burn(msg.sender);
        _editionsExtension.mintEdition(id, msg.sender, tickets);
    }

    function resolveClaimer(
        uint256 id,
        uint256 random
    ) external override {
        require(msg.sender == address(_randomProvider), "BabylonCore: msg.sender is not the Random Provider");
        ListingInfo storage listing =  _listingInfos[id];
        require(listing.state == ListingState.Resolving, "BabylonCore: Listing state should be resolving");
        uint256 claimerIndex = random % listing.totalTickets;
        address claimer = IBabylonMintPass(listing.mintPass).ownerOf(claimerIndex);
        listing.claimer = claimer;
        listing.state = ListingState.Successful;
        _tokensController.sendItem(listing.item, listing.creator, claimer);

        emit ListingSuccessful(id, claimer);
    }

    function setMaxListingDuration(uint256 maxListingDuration) external onlyOwner {
        _maxListingDuration = maxListingDuration;
    }

    function setMintPassBaseURI(string calldata mintPassBaseURI) external onlyOwner {
        _mintPassBaseURI = mintPassBaseURI;
    }

    function setTreasury(address treasury) external onlyOwner {
        _treasury = treasury;
    }

    function getAvailableToParticipate(
        uint256 id,
        address user,
        bytes32[] calldata allowlistProof
    ) external view returns (uint256) {
        ListingInfo storage listing =  _listingInfos[id];
        ListingRestrictions storage restrictions = _listingRestrictions[id];
        uint256 current = listing.currentTickets;
        uint256 total = listing.totalTickets;
        uint256 available = total - current;

        if (
            (listing.state == ListingState.Active) &&
            _tokensController.checkApproval(listing.creator, listing.item) &&
            (block.timestamp >= listing.timeStart) &&
            (available > 0) &&
            (restrictions.maxPerAddress > _participations[id][user])
        ) {
            uint256 leftForAddress = restrictions.maxPerAddress - _participations[id][user];
            bytes32 leaf = keccak256(abi.encodePacked(user));
            if (!MerkleProof.verify(allowlistProof, restrictions.allowlistRoot, leaf)) {
                available = (total + restrictions.mintedFromReserve) - current - restrictions.reserved;
            }

            return available >= leftForAddress ? leftForAddress : available;
        }

        return 0;
    }

    function getLastListingId() external view returns (uint256) {
        return _lastListingId;
    }

    function getTreasury() external view returns (address) {
        return _treasury;
    }

    function getListingId(address token, uint256 tokenId) external view returns (uint256) {
        return _ids[token][tokenId];
    }

    function getListingInfo(uint256 id) external view returns (ListingInfo memory) {
        return _listingInfos[id];
    }

    function getListingParticipations(uint256 id, address user) external view returns (uint256) {
        return _participations[id][user];
    }

    function getListingRestrictions(uint256 id) external view returns (ListingRestrictions memory) {
        return _listingRestrictions[id];
    }

    function getTokensController() external view returns (ITokensController) {
        return _tokensController;
    }

    function getRandomProvider() external view returns (IRandomProvider) {
        return _randomProvider;
    }

    function getEditionsExtension() external view returns (IEditionsExtension) {
        return _editionsExtension;
    }

    function getMaxListingDuration() external view returns (uint256) {
        return _maxListingDuration;
    }

    function getMintPassBaseURI() external view returns (string memory) {
        return _mintPassBaseURI;
    }
}