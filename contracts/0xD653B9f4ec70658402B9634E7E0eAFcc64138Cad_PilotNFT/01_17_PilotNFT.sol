pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "hardhat/console.sol";

interface IExordium {
    function getCitadelStaker(uint256 tokenId) external view returns (address);
}

contract PilotNFT is ERC721A, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeMath for uint8;
    using SafeERC20 for IERC20;

    struct Sovereign {
        uint8 kult;
        bool isSovereign;
        uint256[] charges;
        uint8 chargeCount;
    }

    mapping(uint256 => uint8) public levels;
    mapping(uint256 => uint256) public claimed;
    mapping(uint256 => Sovereign) public collective;
    uint256 public constant MAX_PILOT = 2048;
    uint256 public constant MAX_LEVEL = 9;
    uint256 public constant PILOT_CLAIM_PRICE = 64000000000000000000000; //64,000 DK
    uint256 public constant PILOT_UPLEVEL_PRICE = 100000000000000000000000; //100,000 DK
    string private baseTokenURI;
    IExordium public immutable exordium;
    IERC20 public immutable drakma;
    uint256 public pilotPrice = 125000000000000000; //0.125 ETH
    uint256 public pilotMintMax = 128;
    uint256 public pilotMintIndex = 0;
    bool public pilotMintOn = false;
    bool public pilotClaimOn = true;
    uint8 public sovereignCounter = 0;
    uint8 public constant MAX_SOVEREIGN = 64;
    uint256 public sovereignPrice = 4000000000000000000000000; //4M DK
    uint256 public kultPrice = 100000000000000000000000; //100K DK

    constructor(
        IERC20 _drakma,
        IExordium _exordium,
        string memory _baseTokenURI
        ) ERC721A("PILOT", "PILOT") {
        
        baseTokenURI = _baseTokenURI;
        exordium = _exordium;
        drakma = _drakma;
    }

    function claim(uint256 tokenId) external nonReentrant {
        require(pilotClaimOn == true, "PILOT claim is currently off");
        require(msg.sender == exordium.getCitadelStaker(tokenId), "CITADEL must be staked to EXORDIUM to claim PILOT");
        require(totalSupply().add(1) <= MAX_PILOT, "Claim would exceed max supply of pilot nft");
        require(drakma.transferFrom(msg.sender, address(this), PILOT_CLAIM_PRICE));
        require(claimed[tokenId] == 0, "CITADEL has already claimed a PILOT");
        claimed[tokenId] = _currentIndex;
        if(tokenId < 64) {
            initializeSovereign(_currentIndex);
        }
        levels[_currentIndex] = 0;
        _safeMint(msg.sender, 1);
    }

    function mintPilot(uint256 numberOfTokens) public payable nonReentrant {
        require(pilotMintOn == true, "PILOT mint is currently off");
        require(numberOfTokens <= 5, "Cannot mint more than 5 PILOT in one transaction");
        require(totalSupply().add(numberOfTokens) <= MAX_PILOT, "Purchase would exceed max supply of pilot nft");
        require(pilotPrice.mul(numberOfTokens) <= msg.value, "Not enough eth sent with transaction");
        require(pilotMintIndex.add(numberOfTokens) <= pilotMintMax, "Mint amount exceeded max pilot count");
        pilotMintIndex = pilotMintIndex + numberOfTokens;
        initializePILOT(numberOfTokens);
        _safeMint(msg.sender, numberOfTokens);
    }

    function reservePILOT(uint256 num) external onlyOwner {
        require(totalSupply() + num <= MAX_PILOT, "MAX_SUPPLY");
        initializePILOT(num);
        _safeMint(msg.sender, num);
    }

    function upLevel(uint256 tokenId) external nonReentrant {
        uint8 newLevel = levels[tokenId] + 1;
        uint256 upLevelPrice = PILOT_UPLEVEL_PRICE.mul(newLevel);
        require(newLevel <= MAX_LEVEL, "MAX_LEVEL");
        require(drakma.transferFrom(msg.sender, address(this), upLevelPrice));
        levels[tokenId] = newLevel;
    }

    function sovereignty(uint256 tokenId) external nonReentrant {
        require(sovereignCounter + 1 <= MAX_SOVEREIGN, "MAX_SOVEREIGN");
        require(drakma.transferFrom(msg.sender, address(this), sovereignPrice));
        initializeSovereign(tokenId);
        sovereignCounter++;
    }

    function bribeKult(uint256 sovereignId, uint8 kult) external nonReentrant {
        require(collective[sovereignId].isSovereign == true, "Must be sovereign to bribe");
        require(kult >= 0 && kult < 8, "Invalid KULT");
        require(sovereignChargeCount(sovereignId) < 8, "Sovereign is fully charged");
        require(drakma.transferFrom(msg.sender, address(this), kultPrice));
        collective[sovereignId].kult = kult;
        collective[sovereignId].chargeCount = collective[sovereignId].chargeCount + 1;
        uint256 sovereignExpire = block.timestamp + 90 days;
        for (uint8 i = 0; i < collective[sovereignId].charges.length; i++) {
            if(collective[sovereignId].charges[i] <= block.timestamp) {
                collective[sovereignId].charges[i] = sovereignExpire;
                break;
            }
        }
    }

    function overthrowSovereign(uint256 tokenIdIncumbent, uint256 tokenIdInsurgent) external nonReentrant {
        require(collective[tokenIdIncumbent].isSovereign == true, "Must overthrow existing sovereign");
        uint8 sovereignCharges = sovereignChargeCount(tokenIdIncumbent);
        uint256 overthrowPrice = sovereignPrice + kultPrice.mul(sovereignCharges).mul(10);
        require(drakma.transferFrom(msg.sender, address(this), overthrowPrice));
        delete collective[tokenIdIncumbent];
        initializeSovereign(tokenIdInsurgent);
    }

    function initializeSovereign(uint256 tokenId) private {
        collective[tokenId].isSovereign = true;
        collective[tokenId].charges = new uint256[](8);
        collective[tokenId].chargeCount = 0;
    }

    // withdraw DRAKMA from contract
    function withdrawDrakma(uint256 amount) external onlyOwner {
        drakma.safeTransfer(msg.sender, amount);
    }
    
    // withdraw ETH from contract
    function withdrawEth() external onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function initializePILOT(uint256 numberOfTokens) private {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 index = _currentIndex + i;
            levels[index] = 0;
        }
    }

    function updateBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function updateMintParams(uint256 _pilotPrice, uint256 _pilotMintMax, bool _pilotMintOn, uint256 _sovereignPrice, uint256 _kultPrice) external onlyOwner {
        pilotMintIndex = 0;
        pilotPrice = _pilotPrice;
        pilotMintMax = _pilotMintMax;
        pilotMintOn = _pilotMintOn;
        sovereignPrice = _sovereignPrice;
        kultPrice = _kultPrice;
    }

    function updateClaimParams(bool _pilotClaimOn) external onlyOwner {
        pilotClaimOn = _pilotClaimOn;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
    
    function sovereignChargeCount(uint256 sovereignId) internal returns (uint8) {
        uint8 chargeCount = 0;
        if(collective[sovereignId].isSovereign == true) {
            for (uint8 i = 0; i < collective[sovereignId].charges.length; i++) {
                if(collective[sovereignId].charges[i] >= block.timestamp) {
                    chargeCount++;
                }
            }
        }
        collective[sovereignId].chargeCount = chargeCount;
        return chargeCount;
    }

    // public views
    function getSovereign(uint256 sovereignId) public view returns (bool, uint8, uint8) {
        return (
            collective[sovereignId].isSovereign, 
            collective[sovereignId].chargeCount, 
            collective[sovereignId].kult
        );
    }

    function getSovereignCharge(uint256 sovereignId, uint8 chargeIndex) public view returns (uint256) {
        return collective[sovereignId].charges[chargeIndex];
    }

    function getCitadelClaim(uint256 tokenId) public view returns (uint256) {
        return claimed[tokenId];
    }

    function getOnchainPILOT(uint256 tokenId) public view returns (bool, uint8) {
        return (collective[tokenId].isSovereign, levels[tokenId]);
    }
}