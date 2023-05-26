//SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IBrainDrops {
   function mint(address recipient, uint _projectId) external payable returns (uint256);

   function updateProjectArtistName(uint256 _projectId, string memory _projectArtistName) external;

   function updateProjectDescription(uint256 _projectId, string memory _projectDescription) external;

   function updateProjectWebsite(uint256 _projectId, string memory _projectWebsite) external;

   function updateProjectLicense(uint256 _projectId, string memory _projectLicense) external;

   function updateProjectBaseURI(uint256 _projectId, string memory _projectBaseURI) external;

   function updateProjectPricePerTokenInWei(uint256 _projectId, uint256 _pricePerTokenInWei) external;

   function toggleProjectIsPaused(uint256 _projectId) external;

   function setProvenanceHash(uint256 _projectId, string memory provenanceHash) external;

   function balanceOf(address owner) external view returns (uint256 balance);

   function ownerOf(uint256 tokenId) external view returns (address owner);

   function isWhitelisted(address sender) external view returns (bool whitelisted);

   function transferFrom(address from, address to, uint256 tokenId) external;
}

interface IDelegationRegistry {
   function checkDelegateForContract(address delegate, address vault, address contract_) external returns(bool);
}

contract ArtistProxy is Ownable, ReentrancyGuard {
    constructor(address _braindropsAddress) {
      braindrops = IBrainDrops(_braindropsAddress);
    }

    IBrainDrops public braindrops;
    IDelegationRegistry public delegationRegistry;

    mapping(uint256 => mapping(address => bool)) public projectIdToProxyDropAddressMinted;

    mapping(uint256 => mapping(uint256 => bool)) public projectIdToGenesisDropTokenMinted;
    mapping(uint256 => mapping(uint256 => bool)) public projectIdToProjectSpecificHoldersTokenMinted;

    mapping(uint256 => address) public projectIdToArtistAddress;
    mapping(uint256 => bool) public projectIdToProjectActivated;
    mapping(uint256 => bool) public projectIdToHolderActivated;
    mapping(uint256 => bool) public projectIdToGenesisDropActivated;

    mapping(uint256 => uint256) public projectIdToOlderProjectId;

    modifier onlyArtist(uint256 _projectId) {
        require(msg.sender == projectIdToArtistAddress[_projectId], "Only artist");
        _;
    }

    modifier onlyArtistOrOwner(uint256 _projectId) {
        require(msg.sender == projectIdToArtistAddress[_projectId] || msg.sender == owner(), "Only artist or owner");
        _;
    }

    modifier onlyAllowListed() {
        require(braindrops.isWhitelisted(msg.sender), "Only allowListed");
        _;
    }

    modifier onlyHolders(uint256 _projectId) {
        require(braindrops.balanceOf(msg.sender) > 0, "Holders only");
        _;
    }

    function setDelegationRegistry(address _registryAddress) public onlyOwner {
      delegationRegistry = IDelegationRegistry(_registryAddress);
    }

    function setArtist(uint projectId, address artistAddress) public onlyAllowListed {
        projectIdToArtistAddress[projectId] = artistAddress;
    }

    function updateProjectArtistName(uint256 _projectId, string memory _projectArtistName) onlyArtist(_projectId) public {
        braindrops.updateProjectArtistName(_projectId, _projectArtistName);
    }

    function updateProjectDescription(uint256 _projectId, string memory _projectDescription) onlyArtist(_projectId) public {
        braindrops.updateProjectDescription(_projectId, _projectDescription);
    }

    function updateProjectWebsite(uint256 _projectId, string memory _projectWebsite) onlyArtist(_projectId) public {
        braindrops.updateProjectWebsite(_projectId, _projectWebsite);
    }

    function updateProjectLicense(uint256 _projectId, string memory _projectLicense) onlyArtist(_projectId) public {
        braindrops.updateProjectLicense(_projectId, _projectLicense);
    }

    function updateProjectBaseURI(uint256 _projectId, string memory _projectBaseURI) onlyArtist(_projectId) public {
        braindrops.updateProjectBaseURI(_projectId, _projectBaseURI);
    }

    function updateProjectPricePerTokenInWei(uint256 _projectId, uint256 _pricePerTokenInWei) onlyArtist(_projectId) public {
        braindrops.updateProjectPricePerTokenInWei(_projectId, _pricePerTokenInWei);
    }

    function toggleProjectIsPaused(uint256 _projectId) public onlyArtist(_projectId) {
        braindrops.toggleProjectIsPaused(_projectId);
    }

    function setProvenanceHash(uint256 _projectId, string memory provenanceHash) public onlyArtist(_projectId) {
        braindrops.setProvenanceHash(_projectId, provenanceHash);
    }

    function toggleProjectIsActive(uint256 _projectId) public onlyArtist(_projectId) {
        projectIdToProjectActivated[_projectId] = !projectIdToProjectActivated[_projectId];
    }

    function toggleProjectIsHolderActive(uint256 _projectId) public onlyArtist(_projectId) {
        projectIdToHolderActivated[_projectId] = !projectIdToHolderActivated[_projectId];
    }

    function toggleProjectIsGenesisDropActive(uint256 _projectId) public onlyArtist(_projectId) {
        projectIdToGenesisDropActivated[_projectId] = !projectIdToGenesisDropActivated[_projectId];
    }

    function setProjectIdToOlderProjectId(uint256 _projectId, uint256 _olderProjectId) public onlyArtist(_projectId) {
        projectIdToOlderProjectId[_projectId] = _olderProjectId;
    }

  function mintForArtistsOnly(address recipient, uint _projectId)
        public
        payable
        onlyArtist(_projectId)
        returns (uint256)
      {
          return braindrops.mint{value: msg.value}(recipient, _projectId);
      }

   function reserve(address recipient, uint _projectId, uint amount)
        public
        payable
        onlyArtistOrOwner(_projectId)
      {

          uint b;
          for (b = 0; b < amount; b++) {
            braindrops.mint{value: (msg.value / amount)}(recipient, _projectId);
          }
      }

  function mintForProjectSpecificHoldersOnly(address recipient, uint _projectId, uint _projectTokenId)
        public
        payable
        nonReentrant
        returns (uint256)
      {
          uint olderProjectId = projectIdToOlderProjectId[_projectId];
          require(olderProjectId > 0, "Project must be active for project-holder specific mints");

          uint _projectIdFromTokenId = (_projectTokenId - (_projectTokenId % 1000000)) / 1000000;
          require(_projectIdFromTokenId == olderProjectId, "must pass in a token id from the correct project");
          require(braindrops.ownerOf(_projectTokenId) == msg.sender, "sender must own token id passed in");

          require(projectIdToGenesisDropTokenMinted[_projectId][_projectTokenId] == false, "token already used to mint");

          projectIdToGenesisDropTokenMinted[_projectId][_projectTokenId] = true;

          return braindrops.mint{value: msg.value}(recipient, _projectId);
      }

  function mintForGenesisDropHoldersOnly(address recipient, uint _projectId, uint _project1TokenId, uint _project2TokenId, uint _project3TokenId, address _vault)
        public
        payable
        nonReentrant
        returns (uint256)
      {
          address requester = msg.sender;

          if (_vault != address(0)) {
            bool isDelegateValid = delegationRegistry.checkDelegateForContract(msg.sender, _vault, address(braindrops));
            require(isDelegateValid, "invalid delegate-vault pairing");
            requester = _vault;
          }

          require(projectIdToGenesisDropActivated[_projectId], "Project must be active for genesis set holders");

          uint _project1Id = (_project1TokenId - (_project1TokenId % 1000000)) / 1000000;
          require(_project1Id == 1, "must pass in a token id from project 1");
          require(projectIdToGenesisDropTokenMinted[_projectId][_project1TokenId] == false, "project 1 token already used to mint");

          uint _project2Id = (_project2TokenId - (_project2TokenId % 1000000)) / 1000000;
          require(_project2Id == 2, "must pass in a token id from project 2");
          require(projectIdToGenesisDropTokenMinted[_projectId][_project2TokenId] == false, "project 2 token already used to mint");

          uint _project3Id = (_project3TokenId - (_project3TokenId % 1000000)) / 1000000;
          require(_project3Id == 3, "must pass in a token id from project 3");
          require(projectIdToGenesisDropTokenMinted[_projectId][_project3TokenId] == false, "project 3 token already used to mint");

          require(braindrops.ownerOf(_project1TokenId) == requester, "must own the selected token from project 1");
          require(braindrops.ownerOf(_project2TokenId) == requester, "must own the selected token from project 2");
          require(braindrops.ownerOf(_project3TokenId) == requester, "must own the selected token from project 3");

          projectIdToGenesisDropTokenMinted[_projectId][_project1TokenId] = true;
          projectIdToGenesisDropTokenMinted[_projectId][_project2TokenId] = true;
          projectIdToGenesisDropTokenMinted[_projectId][_project3TokenId] = true;

          return braindrops.mint{value: msg.value}(recipient, _projectId);
      }

  function mintForHoldersOnly(address recipient, uint _projectId)
        public
        payable
        nonReentrant
        onlyHolders(_projectId)
        returns (uint256)
      {
          require(projectIdToHolderActivated[_projectId], "Project must be active for holders");

          return braindrops.mint{value: msg.value}(recipient, _projectId);
      }

  function mint(address recipient, uint _projectId)
        public
        payable
        nonReentrant
        returns (uint256)
      {
          require(tx.origin == msg.sender, "cannot be called from another contract");
          require(projectIdToProjectActivated[_projectId], "Project must be active");
          require(projectIdToProxyDropAddressMinted[_projectId][msg.sender] == false, "One mint per address");

          projectIdToProxyDropAddressMinted[_projectId][msg.sender] = true;
          return braindrops.mint{value: msg.value}(recipient, _projectId);
      }

  function withdraw() public onlyOwner {
    uint balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

}