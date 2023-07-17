// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./SoulboundERC721.sol";
import "@degenscore/degenscore-beacon/contracts/interfaces/IDegenScoreBeaconReader.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

struct ConstructorData {
    address owner;
    string name;
    string symbol;
    string baseURI;
    uint128 ticketPriceWei;
    address payable feeCollector;
    address beaconAddress;
    uint192 requiredDegenScore;
    uint64 maxBeaconAge;
    uint64 availableBeaconSeats;
    uint64 availableInviteSeats;
    uint64 maxSeats;
    bytes32 inviteMerkleRoot;
    uint64 sellingClosesAt;
}

contract Ticket is
    Initializable,
    SoulboundERC721,
    OwnableUpgradeable,
    PausableUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using StringsUpgradeable for uint256;

    uint256 public constant DEGENSCORE_TRAIT = 121371448299756538184036965;
    CountersUpgradeable.Counter public usedBeaconSeats;
    CountersUpgradeable.Counter public usedInviteSeats;

    string private baseURI;

    uint128 public ticketPriceWei;
    address payable public feeCollector;
    IDegenScoreBeaconReader public beacon;
    uint64 public maxBeaconAge;
    uint192 public requiredDegenScore;
    uint64 public availableBeaconSeats;
    uint64 public availableInviteSeats;
    uint64 public maxSeats;

    bytes32 public inviteMerkleRoot;
    mapping(bytes32 => bool) private usedPasswords;

    uint64 public sellingClosesAt;

    event BoughtTicket(uint256 indexed tokenId);
    event BoughtTicketWithInvite(
        uint256 indexed tokenId,
        bytes32 indexed password
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(ConstructorData memory data) public initializer {
        __ERC721_init(data.name, data.symbol);
        __Ownable_init();
        __Pausable_init();
        _pause();

        _transferOwnership(data.owner);

        baseURI = data.baseURI;
        ticketPriceWei = data.ticketPriceWei;
        feeCollector = data.feeCollector;
        beacon = IDegenScoreBeaconReader(data.beaconAddress);
        maxBeaconAge = data.maxBeaconAge;
        requiredDegenScore = data.requiredDegenScore;
        availableBeaconSeats = data.availableBeaconSeats;
        availableInviteSeats = data.availableInviteSeats;
        maxSeats = data.maxSeats;
        inviteMerkleRoot = data.inviteMerkleRoot;
        sellingClosesAt = data.sellingClosesAt;
    }

    function buyTicket() public payable {
        uint192 degenScore = beacon.getTrait(
            msg.sender,
            DEGENSCORE_TRAIT,
            maxBeaconAge
        );
        require(
            degenScore >= requiredDegenScore,
            "Your DegenScore is too low or your beacon is outdated"
        );

        require(
            usedBeaconSeats.current() < availableBeaconSeats,
            "No more seats available"
        );
        usedBeaconSeats.increment();

        uint256 tokenId = _nextId();

        _buyTicket(tokenId);
        emit BoughtTicket(tokenId);
    }

    function buyTicket(
        bytes32 password,
        bytes32[] calldata _proof
    ) public payable {
        bool verified = MerkleProofUpgradeable.verify(
            _proof,
            inviteMerkleRoot,
            password
        );
        if (!verified) revert("Invalid password");

        if (usedPasswords[password]) revert("Password already used");
        usedPasswords[password] = true;

        require(
            usedInviteSeats.current() < availableInviteSeats,
            "No more seats available"
        );
        usedInviteSeats.increment();

        uint256 tokenId = _nextId();

        _buyTicket(tokenId);

        emit BoughtTicketWithInvite(tokenId, password);
    }

    function _nextId() private view returns (uint256) {
        return usedBeaconSeats.current() + usedInviteSeats.current();
    }

    function _buyTicket(uint256 tokenId) internal whenNotPaused {
        require(
            block.timestamp < sellingClosesAt,
            "You can no longer buy tickets"
        );
        require(balanceOf(msg.sender) == 0, "You can only buy one ticket");
        require(msg.value == ticketPriceWei, "Wrong value sent");

        feeCollector.transfer(msg.value);

        _safeMint(msg.sender, tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function tokenIdOf(address owner) public view returns (uint256) {
        uint256 usedSeats = _seatsSold();

        for (uint256 id = 1; id <= usedSeats; id++) {
            if (ownerOf(id) == owner) return id;
        }

        revert("Not a token owner");
    }

    function _seatsSold() internal view returns (uint256) {
        return usedBeaconSeats.current() + usedInviteSeats.current();
    }

    function seatsSold() public view returns (uint256) {
        return _seatsSold();
    }

    ////////////////// Management methods //////////////////

    function burnTickets(uint256[] calldata ids) public onlyOwner {
        for (uint i = 0; i < ids.length; i++) {
            _burn(ids[i]);
        }
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function setTicketPrice(uint128 ticketPriceWei_) public onlyOwner {
        ticketPriceWei = ticketPriceWei_;
    }

    function setFeeCollector(address payable feeCollector_) public onlyOwner {
        feeCollector = feeCollector_;
    }

    function setBeaconAddress(address beaconAddress_) public onlyOwner {
        beacon = IDegenScoreBeaconReader(beaconAddress_);
    }

    function setMaxBeaconAge(uint64 maxBeaconAge_) public onlyOwner {
        maxBeaconAge = maxBeaconAge_;
    }

    function setRequiredDegenScore(
        uint192 requiredDegenScore_
    ) public onlyOwner {
        requiredDegenScore = requiredDegenScore_;
    }

    function setAvailableBeaconSeats(
        uint64 availableBeaconSeats_
    ) public onlyOwner {
        availableBeaconSeats = availableBeaconSeats_;
        require(
            (availableBeaconSeats + availableInviteSeats) <= maxSeats,
            "Not enough seats available"
        );
    }

    function setAvailableInviteSeats(
        uint64 availableInviteSeats_
    ) public onlyOwner {
        availableInviteSeats = availableInviteSeats_;
        require(
            (availableBeaconSeats + availableInviteSeats) <= maxSeats,
            "Not enough seats available"
        );
    }

    function setMaxSeats(uint64 maxSeats_) public onlyOwner {
        maxSeats = maxSeats_;
    }

    function setInviteMerkleRoot(bytes32 inviteMerkleRoot_) public onlyOwner {
        inviteMerkleRoot = inviteMerkleRoot_;
    }

    function setSellingClosesAt(uint64 sellingClosesAt_) public onlyOwner {
        sellingClosesAt = sellingClosesAt_;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}