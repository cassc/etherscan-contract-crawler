//SPDX-License-Identifier: MIT
// contracts/ERC721.sol

pragma solidity >=0.6.2;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface Randomizer {
   function random() external view returns(uint32);
}

contract BrainDrops is ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    constructor(address _randomizerContract) ERC721("BrainDrops", "BRAIN") {
      isWhitelisted[msg.sender] = true;
      randomizerContract = Randomizer(_randomizerContract);
    }

    Randomizer public randomizerContract;

    event Mint(
        address indexed _to,
        uint256 indexed _tokenId,
        uint256 indexed _projectId
    );

    struct Project {
        string name;
        string artist;
        string description;
        string website;
        string license;
        string projectBaseURI;
        uint256 invocations;
        uint256 maxInvocations;
        bool active;
        bool locked;
        bool paused;
    }

    function projectDetails(uint256 _projectId) view public returns (string memory projectName, string memory artist, string memory description, string memory website, string memory license, uint256 invocations, uint256 maxInvocations) {
        projectName = projects[_projectId].name;
        artist = projects[_projectId].artist;
        description = projects[_projectId].description;
        website = projects[_projectId].website;
        license = projects[_projectId].license;
        invocations = projects[_projectId].invocations;
        maxInvocations = projects[_projectId].maxInvocations;
    }

    function updateProjectArtistName(uint256 _projectId, string memory _projectArtistName) onlyUnlocked(_projectId) onlyArtistOrWhitelisted(_projectId) public {
        projects[_projectId].artist = _projectArtistName;
    }

    function updateProjectDescription(uint256 _projectId, string memory _projectDescription) onlyArtist(_projectId) public {
        projects[_projectId].description = _projectDescription;
    }

    function updateProjectWebsite(uint256 _projectId, string memory _projectWebsite) onlyArtist(_projectId) public {
        projects[_projectId].website = _projectWebsite;
    }

    function updateProjectLicense(uint256 _projectId, string memory _projectLicense) onlyUnlocked(_projectId) onlyArtistOrWhitelisted(_projectId) public {
        projects[_projectId].license = _projectLicense;
    }

    function updateProjectBaseURI(uint256 _projectId, string memory _projectBaseURI) onlyUnlocked(_projectId) onlyArtistOrWhitelisted(_projectId) public {
        projectIdToBaseURI[_projectId] = _projectBaseURI;
    }

    function updateProjectPricePerTokenInWei(uint256 _projectId, uint256 _pricePerTokenInWei) onlyUnlocked(_projectId) onlyArtistOrWhitelisted(_projectId) public {
        projectIdToPricePerTokenInWei[_projectId] = _pricePerTokenInWei;
    }

    uint256 constant ONE_MILLION = 1_000_000;
    mapping(uint256 => Project) projects;

    mapping(uint256 => address) public projectIdToArtistAddress;
    mapping(uint256 => string) public projectIdToCurrencySymbol;
    mapping(uint256 => address) public projectIdToCurrencyAddress;
    mapping(uint256 => uint256) public projectIdToPricePerTokenInWei;
    mapping(uint256 => address) public projectIdToAdditionalPayee;
    mapping(uint256 => uint256) public projectIdToAdditionalPayeePercentage;
    mapping(uint256 => uint256) public projectIdToSecondaryMarketRoyaltyPercentage;

    mapping(uint256 => string) public projectIdToProvenanceHash; // arweave
    mapping(uint256 => string) public projectIdToBaseURI;
    mapping(uint256 => uint256) public projectIdToStartingIndex;

    mapping(uint256 => string) public staticIpfsImageLink;
    mapping(uint256 => uint256) public tokenIdToProjectId;
    mapping(uint256 => uint256[]) internal projectIdToTokenIds;

    mapping(address => bool) public isWhitelisted;

    uint256 public nextProjectId = 1;

    modifier onlyUnlocked(uint256 _projectId) {
        require(!projects[_projectId].locked, "Only unlocked");
        _;
    }

    modifier onlyArtist(uint256 _projectId) {
        require(msg.sender == projectIdToArtistAddress[_projectId], "Only artist");
        _;
    }

    modifier onlyWhitelisted() {
        require(isWhitelisted[msg.sender], "Only whitelisted");
        _;
    }

    modifier onlyArtistOrWhitelisted(uint256 _projectId) {
        require(isWhitelisted[msg.sender] || msg.sender == projectIdToArtistAddress[_projectId], "Only artist or whitelisted");
        _;
    }

    function updateRandomizerAddress(address _randomizerAddress) public onlyWhitelisted {
      randomizerContract = Randomizer(_randomizerAddress);
    }

    function addWhitelisted(address _address) public onlyOwner {
        isWhitelisted[_address] = true;
    }

    function removeWhitelisted(address _address) public onlyOwner {
        isWhitelisted[_address] = false;
    }

    function setProjectStartingIndex(uint256 _projectId) public {
        require(projectIdToStartingIndex[_projectId] == 0, "Starting index is already set");

        projectIdToStartingIndex[_projectId] = uint(block.number.mul(randomizerContract.random())) % projects[_projectId].maxInvocations;

        if (projectIdToStartingIndex[_projectId] == 0) {
            projectIdToStartingIndex[_projectId] = projectIdToStartingIndex[_projectId].add(1);
        }
    }

    function addProject(string memory _projectName, string memory _projectBaseURI, address _artistAddress, uint256 _pricePerTokenInWei, uint _maxAmount) public onlyWhitelisted {
        uint256 projectId = nextProjectId;
        projectIdToArtistAddress[projectId] = _artistAddress;
        projects[projectId].name = _projectName;
        projectIdToBaseURI[projectId] = _projectBaseURI;
        projectIdToCurrencySymbol[projectId] = "ETH";
        projectIdToPricePerTokenInWei[projectId] = _pricePerTokenInWei;
        projects[projectId].paused=true;
        projects[projectId].maxInvocations = _maxAmount;
        nextProjectId = nextProjectId.add(1);
    }

    function toggleProjectIsLocked(uint256 _projectId) public onlyWhitelisted onlyUnlocked(_projectId) {
        projects[_projectId].locked = true;
    }

    function toggleProjectIsActive(uint256 _projectId) public onlyWhitelisted {
        projects[_projectId].active = !projects[_projectId].active;
    }

    function toggleProjectIsPaused(uint256 _projectId) public onlyArtist(_projectId) {
        projects[_projectId].paused = !projects[_projectId].paused;
    }

    function setProvenanceHash(uint256 _projectId, string memory provenanceHash) public onlyArtist(_projectId) onlyUnlocked(_projectId) {
        projectIdToProvenanceHash[_projectId] = provenanceHash;
    }

    function mint(address recipient, uint _projectId)
      public
      payable
      returns (uint256)
    {
      require(projects[_projectId].invocations.add(1) <= projects[_projectId].maxInvocations, "Must not exceed max invocations");
      require(projects[_projectId].active || msg.sender == projectIdToArtistAddress[_projectId], "Project must exist and be active");
      require(!projects[_projectId].paused || msg.sender == projectIdToArtistAddress[_projectId], "Purchases are paused.");
      require(projectIdToPricePerTokenInWei[_projectId] <= msg.value, "Ether value sent is not correct");

      if (projectIdToStartingIndex[_projectId] == 0) {
        setProjectStartingIndex(_projectId);
      }

      uint tokenIdToBe = ((projects[_projectId].invocations + projectIdToStartingIndex[_projectId]) % projects[_projectId].maxInvocations) + (_projectId * ONE_MILLION);

      projects[_projectId].invocations = projects[_projectId].invocations.add(1);

      _mint(recipient, tokenIdToBe);

      tokenIdToProjectId[tokenIdToBe] = _projectId;
      projectIdToTokenIds[_projectId].push(tokenIdToBe);

      emit Mint(recipient, tokenIdToBe, _projectId);

      return tokenIdToBe;
    }

    function tokenURI(uint _tokenId) public view override returns(string memory) {
      uint projectId = tokenIdToProjectId[_tokenId];
      return string(abi.encodePacked(projectIdToBaseURI[projectId], toString(_tokenId)));
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}