// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Administration.sol";
import "./GhostBase.sol";
import "./StringLib.sol";


/// @title GhostsProject contract
/// @dev Extends ERC721 Non-Fungible Token Standard basic implementation
contract GhostsProject is ERC721Enumerable, Administration, GhostBase {

    using Strings for uint256;
    using StringLib for uint256;

    /// @notice Event emitted when TokenURI base changes
    /// @param tokenUriBase the base URI for tokenURI calls
    event TokenUriBaseSet(string tokenUriBase);

    /// @notice Event emitted when pick memoryType and memory of Ghost with ghostTokenId
    /// @param tokenId token id of ghost
    /// @param memoryPhrase memory phrase that ghost picked
    event PickMemory(uint256 indexed tokenId, string memoryPhrase);

    string public constant TOKEN_NAME = "GhostsProject";
    string public constant TOKEN_SYMBOL = "GHOST";
    string public constant INVALID_TOKEN_ID = "Invalid Token ID";

    string public GHOST_PROVENANCE = "";

    uint256 public maxPurchasePerMint = 10;
    uint256 public ghostPrice = 0.2 ether;

    uint256 public countGoodMemories = 0;
    uint256 public countEvilMemories = 0;

    uint256 public randomSeed;

    uint256 public currentPioneerRound = 0;

    bool public saleIsActive = false;
    bool public presaleIsActive = false;

    string private tokenUriBase;

    uint256 internal constant MAX_GHOSTS = 10000;
    uint256 internal constant MAX_PIONEER_ROUND = 200;

    uint256[MAX_PIONEER_ROUND] internal _pioneerRoundExpire;
    mapping(address => uint256)[MAX_PIONEER_ROUND] private _pioneerClaimable;
    mapping(address => uint256)[MAX_PIONEER_ROUND] private _pioneerClaimed;

    mapping(uint256 => MemoryType) private _ghostMemoryTypes;
    mapping(uint256 => string) private _ghostMemories;

    constructor() ERC721(TOKEN_NAME, TOKEN_SYMBOL) {
        _mintTeamGhost();
    }

    modifier onlyOwner(uint256 _tokenId) {
        require(msg.sender == ownerOf(_tokenId), "Not owner");
        _;
    }

    modifier onlyOnPresale() {
        require(presaleIsActive, "Not in presale period");
        _;
    }

    modifier onlyOnSale() {
        require(saleIsActive, "Not in public sale period");
        _;
    }

    function isGhostsProject() external pure returns (bool) {
        return true;
    }

    function setProvenanceHash(string memory provenanceHash) external onlyRole(DEFAULT_ADMIN_ROLE) {
        GHOST_PROVENANCE = provenanceHash;
    }

    function setMaxPurchasePerMint(uint256 _maxPurchasePerMint) external onlyRole(MODERATOR_ROLE) {
        maxPurchasePerMint = _maxPurchasePerMint;
    }

    function getMaxGhosts() external pure returns (uint256) {
        return MAX_GHOSTS;
    }

    function setGhostPrice(uint256 _price) external onlyRole(DEFAULT_ADMIN_ROLE) {
        ghostPrice = _price;
    }

    function flipSaleState() external onlyRole(DEFAULT_ADMIN_ROLE) {
        saleIsActive = !saleIsActive;
    }

    function flipPresaleState() external onlyRole(MODERATOR_ROLE) {
        presaleIsActive = !presaleIsActive;
    }

    function setRandomSeed() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setRandomSeed();
    }

    function addToPioneer(uint256 _blockNumberToExpire, address[] calldata _addresses, uint256[] calldata _values) external onlyRole(MODERATOR_ROLE) {
        require(_addresses.length == _values.length, "length of address and values must be same");
        require(block.number < _blockNumberToExpire, "certain block already expired");
        _pioneerRoundExpire[currentPioneerRound] = _blockNumberToExpire;
        for (uint256 i = 0; i < _addresses.length; i++) {
            _pioneerClaimable[currentPioneerRound][_addresses[i]] = _values[i];
        }
        currentPioneerRound += 1;
    }

    function expirePioneerRound(uint256 _roundNum) external onlyRole(MODERATOR_ROLE) {
        require(_roundNum < _pioneerRoundExpire.length, "wrong round");
        _pioneerRoundExpire[_roundNum] = block.number - 1;
    }

    /// @notice Set the base URI for creating `tokenURI` for each Ghost.
    /// Only invokable by system admin role, when contract is paused and not upgraded.
    /// If successful, emits an `TokenUriBaseSet` event.
    /// @param _tokenUriBase base for the ERC721 tokenURI
    function setTokenUriBase(string calldata _tokenUriBase) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenUriBase = _tokenUriBase;
        emit TokenUriBaseSet(_tokenUriBase);
    }

    function getPioneerTicketAvailable(address _address) public view returns (uint256) {
        uint256 ticket = 0;
        for (uint256 i = 0; i < currentPioneerRound; i++) {
            if (block.number > _pioneerRoundExpire[i])
                continue;
            ticket += _pioneerClaimable[i][_address] - _pioneerClaimed[i][_address];
        }
        return ticket;
    }

    function getPioneerTicketAvailablePerRound(address _address) public view returns (uint256[] memory) {
        uint256[] memory tickets = new uint[](currentPioneerRound);
        for (uint256 i = 0; i < currentPioneerRound; i++) {
            if (block.number > _pioneerRoundExpire[i])
                continue;
            tickets[i] = _pioneerClaimable[i][_address] - _pioneerClaimed[i][_address];
        }
        return tickets;
    }

    function getPioneerTicketClaimed(address _address) public view returns (uint256) {
        uint256 ticket = 0;
        for (uint256 i = 0; i < currentPioneerRound; i++) {
            ticket += _pioneerClaimed[i][_address];
        }
        return ticket;
    }

    function getPioneerTicketExpired(address _address) public view returns (uint256) {
        uint256 ticket = 0;
        for (uint256 i = 0; i < currentPioneerRound; i++) {
            if (block.number <= _pioneerRoundExpire[i])
                continue;
            ticket += _pioneerClaimable[i][_address] - _pioneerClaimed[i][_address];
        }
        return ticket;
    }

    function getPioneerRoundExpireBlocks() public view returns (uint256[] memory) {
        uint256[] memory blocks = new uint[](currentPioneerRound);
        for (uint256 i = 0; i < currentPioneerRound; i++) {
            blocks[i] = _pioneerRoundExpire[i];
        }
        return blocks;
    }

    function mintGhostForPioneer(uint256 numGhosts) public payable onlyOnPresale {
        require(totalSupply() + numGhosts <= MAX_GHOSTS, "Purchase would exceed max supply of ghosts");
        require(ghostPrice * numGhosts <= msg.value, "inefficient ether");
        require(numGhosts <= getPioneerTicketAvailable(msg.sender), "Tried to mint too many ghosts");

        uint256 round = 0;
        uint256 ticketInRound = 0;
        uint256 count = 0;
        for (uint256 i = 0; i < numGhosts; i++) {
            if (totalSupply() < MAX_GHOSTS) {
                if (ticketInRound == 0)
                    (round, ticketInRound) = _getRoundToClaim(msg.sender, round);
                _safeMint(msg.sender, totalSupply());
                count += 1;
                _pioneerClaimed[round][msg.sender] += 1;
                ticketInRound -= 1;
            }
        }
        if (ghostPrice * count < msg.value) {
            uint256 ethToRefund = msg.value - ghostPrice * count;
            (bool sent, ) = msg.sender.call{ value: ethToRefund }("");
            require(sent, "Failed to send Ether");
        }
        if (randomSeed == 0 && (totalSupply() == MAX_GHOSTS)) {
            _setRandomSeed();
        }
    }

    function withdraw() public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function supportsInterface(bytes4 interfaceId)
    public view override(AccessControl, ERC721Enumerable)
    returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function mintGhost(uint256 numberOfTokens) public payable onlyOnSale {
        require(numberOfTokens <= maxPurchasePerMint, "Tried to mint too many ghosts");
        require(totalSupply() + numberOfTokens <= MAX_GHOSTS, "Purchase would exceed max supply of ghosts");
        require(ghostPrice * numberOfTokens <= msg.value, "inefficient ether");

        uint256 count = 0;
        for (uint256 i = 0; i < numberOfTokens; i++) {
            if (totalSupply() < MAX_GHOSTS) {
                _safeMint(msg.sender, totalSupply());
                count += 1;
            }
        }
        if (ghostPrice * count < msg.value) {
            uint256 ethToRefund = msg.value - ghostPrice * count;
            (bool sent, ) = msg.sender.call{ value: ethToRefund }("");
            require(sent, "Failed to send Ether");
        }

        if (randomSeed == 0 && (totalSupply() == MAX_GHOSTS)) {
            _setRandomSeed();
        }
    }

    function tokenURI(uint256 _tokenId)
    public view override
    returns (string memory uri) {
        require(_exists(_tokenId), INVALID_TOKEN_ID);
        uri = bytes(tokenUriBase).length > 0 ? string(abi.encodePacked(tokenUriBase, StringLib.uint2str(_tokenId))) : "";
    }

    function hasMemory(uint256 _tokenId) public view returns (bool) {
        require(_exists(_tokenId), INVALID_TOKEN_ID);
        return bytes(_ghostMemories[_tokenId]).length > 0;
    }

    function memoryPicked(uint256 _tokenId)
    public view
    returns (string memory memoryPhrase) {
        require(_exists(_tokenId), INVALID_TOKEN_ID);

        memoryPhrase = bytes(_ghostMemories[_tokenId]).length > 0 ? _ghostMemories[_tokenId] : "";
    }

    function getMemoryType(uint256 _tokenId) public view returns (MemoryType memoryType) {
        return _ghostMemoryTypes[_tokenId];
    }

    function pickMemory(uint256 _tokenId, MemoryType _memoryType, string memory _memoryPhrase) public onlyOwner(_tokenId) {
        require(bytes(_ghostMemories[_tokenId]).length == 0, "Already picked memory");

        if (_memoryType == MemoryType.GOOD)
            countGoodMemories += 1;
        else if (_memoryType == MemoryType.EVIL)
            countEvilMemories += 1;
        _ghostMemoryTypes[_tokenId] = _memoryType;
        _ghostMemories[_tokenId] = _memoryPhrase;
        emit PickMemory(_tokenId, _memoryPhrase);
    }

    function _mintTeamGhost() internal onlyRole(DEFAULT_ADMIN_ROLE) {
        require(totalSupply() == 0, "Team ghost already minted");
        _safeMint(msg.sender, 0);  // MrMisang Ghost
        for (uint256 i = 1; i < 21; i++) {
            _safeMint(msg.sender, i);  // Team Ghost
        }
    }

    function _getRoundToClaim(address _address, uint256 startIndex) private view returns (uint256, uint256) {
        uint256 round = MAX_PIONEER_ROUND;
        uint256 ticketInRound = 0;
        for (uint256 i = startIndex; i < MAX_PIONEER_ROUND; i++) {
            if (_pioneerRoundExpire[i] < block.number)
                continue;
            if (_pioneerClaimed[i][_address] < _pioneerClaimable[i][_address]) {
                round = i;
                ticketInRound = _pioneerClaimable[i][_address] - _pioneerClaimed[i][_address];
                break;
            }
        }
        return (round, ticketInRound);
    }

    function _setRandomSeed() private {
        require(randomSeed == 0, "Seed number is already set");

        randomSeed = uint(keccak256(abi.encodePacked(block.timestamp, blockhash(block.number - 1))));
        // Prevent default sequence
        if (randomSeed == 0) {
            randomSeed += 1;
        }
    }
}