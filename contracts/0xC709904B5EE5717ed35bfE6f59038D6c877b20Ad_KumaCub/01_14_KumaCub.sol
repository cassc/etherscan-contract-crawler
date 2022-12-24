// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./ERC721ACustom.sol";
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/utils/Strings.sol';


contract KumaCub is ERC721ACustom, Ownable {
    using Strings for uint128;

    // 1 = tribal / 2 = tech / 3 = astral / 4 = mutant / 5 = spirit
    struct FactionInfos {
        uint128 faction;
        uint128 factionIndex;
    }

    string public baseTokenURI;
    bool regularUri = false;
    bool public cubLive = false;
    uint256 public immutable maxSupply;

    IERC721 genesisContract;
    IERC1155 trackerContract;
    IERC20 pawContract;

    mapping(uint256 => FactionInfos) public faction;
    uint256 public maxSupplyPerFaction = 935;

    mapping(uint256 => uint256) public factionSupply;

    uint256 public breedCost = 900 ether;

    bool public spiritEventActive = false;
    uint256 public maxSpiritSupply = 260;
    uint256 public currentEventMaxSupply = 0;
    uint256 public currentEvent = 0;
    mapping(uint256 => mapping(address => uint256)) public currentEventClaimed;

    uint256 lastPawSplitId = 0;

    error NotLive();
    error NotEnoughGenesis();
    error NoTracker();
    error SpiritEventInactive();
    error WrongFaction();
    error MaxSupply();
    error AlreadyClaimed();

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI,
        uint256 _maxSupply,
        address _genesisContract,
        address _trackerContract,
        address _pawContract
    ) ERC721ACustom(_name, _symbol){
        baseTokenURI = _baseTokenURI;
        maxSupply = _maxSupply;
        genesisContract = IERC721(_genesisContract);
        trackerContract = IERC1155(_trackerContract);
        pawContract = IERC20(_pawContract);
    }

    function mintCub(uint256 factionId, uint256 _quantity) external {
        if (!cubLive) revert NotLive();
        if (genesisContract.balanceOf(msg.sender) < 2) revert NotEnoughGenesis();
        if (factionId > 4) revert WrongFaction();
        if (factionSupply[factionId] + _quantity > maxSupplyPerFaction) revert MaxSupply();

        if (pawContract.transferFrom(msg.sender, address(this), breedCost * _quantity)) {
            for (uint i = 1; i <= _quantity; i++) {
                factionSupply[factionId] += 1;
                faction[totalSupply() + i] = FactionInfos(uint128(factionId), uint128(factionSupply[factionId]));
            }
            _safeMint(msg.sender, _quantity);
        }
    }

    function mintSpirit(uint256 _quantity) external {
        if (!spiritEventActive) revert SpiritEventInactive();
        if (genesisContract.balanceOf(msg.sender) < 2) revert NotEnoughGenesis();
        uint256 trackerBalance = trackerContract.balanceOf(msg.sender, 1);
        if (trackerBalance == 0) revert NoTracker();
        uint256 _factionSupply =  factionSupply[5];
        if (currentEventClaimed[currentEvent][msg.sender] + _quantity > trackerBalance) revert AlreadyClaimed();
        if (_factionSupply + _quantity > currentEventMaxSupply) revert MaxSupply();
        if (_factionSupply + _quantity > maxSpiritSupply) revert MaxSupply();

        if (pawContract.transferFrom(msg.sender, address(this), breedCost * _quantity)) {
            currentEventClaimed[currentEvent][msg.sender] += _quantity;
            for (uint i = 1; i <= _quantity; i++) {
                factionSupply[5] += 1;
                faction[totalSupply() + i] = FactionInfos(uint128(5), uint128(factionSupply[5]));
            }
            _safeMint(msg.sender, _quantity);
        }
    }

    function setCurrentEvent(uint256 _currentEvent, uint256 _maxSupply) external onlyOwner{
        currentEvent = _currentEvent;
        currentEventMaxSupply = _maxSupply;
    }

    function triggerSpiritEvent() external onlyOwner{
        spiritEventActive = !spiritEventActive;
    }

    function splitRewards() external onlyOwner {
        address a1 = genesisContract.ownerOf(2001);
        address a2 = genesisContract.ownerOf(2002);
        address a3 = genesisContract.ownerOf(2003);
        address a4 = genesisContract.ownerOf(2004);
        address a5 = genesisContract.ownerOf(2005);
        address a6 = genesisContract.ownerOf(2006);
        address a7 = genesisContract.ownerOf(2007);
        address a8 = genesisContract.ownerOf(2008);
        address a9 = genesisContract.ownerOf(2009);
        address a10 = genesisContract.ownerOf(2010);

        uint256 split = totalSupply() - lastPawSplitId;
        uint256 share = ((split * 10) * 1 ether) / 10;

        pawContract.transfer(a1, share);
        pawContract.transfer(a2, share);
        pawContract.transfer(a3, share);
        pawContract.transfer(a4, share);
        pawContract.transfer(a5, share);
        pawContract.transfer(a6, share);
        pawContract.transfer(a7, share);
        pawContract.transfer(a8, share);
        pawContract.transfer(a9, share);
        pawContract.transfer(a10, share);

        lastPawSplitId = totalSupply();
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(
        string calldata _baseTokenURI
    ) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function toggleCubLive() external onlyOwner{
        cubLive = !cubLive;
    }

    function toggleRegularUri() external onlyOwner {
        regularUri = !regularUri;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}