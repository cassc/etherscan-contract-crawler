// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract Moonsie is ERC721AQueryable, Ownable, ReentrancyGuard {
  string public baseURI;

  bytes32 private hashRoot_A;
  bytes32 private hashRoot_B;
  bytes32 private hashRoot_C;

  uint256 public price = 0.055 ether;
  uint256 public maxSupply = 5555;
  uint256 private constant MAX_MINT_PER_WALLET_A = 2;
  uint256 private constant MAX_MINT_PER_WALLET_B = 1;
  uint256 private constant MAX_MINT_PER_WALLET_C = 1;
  uint256 private constant MAX_MINT_PER_WALLET_D = 2;

  bool public phaseOneIsActive = false;
  bool public phaseTwoIsActive = false;
  bool public phaseThreeIsActive = false;

  mapping(address => uint256) private mapAddressToLimit_A;
  mapping(address => uint256) private mapAddressToLimit_B;
  mapping(address => uint256) private mapAddressToLimit_C;
  mapping(address => uint256) private mapAddressToLimit_D;

  address CommunityWalletAdd = 0x26Cf8e797f45E3ed41AF8fcD49583897675a603d;
  address MoonlightCapitalAdd = 0xbEdfC597dCcF21DccBF5c23EF686CAAFcbd5B11B;
  address LeadDeveloperAdd = 0x2d1ED08E4f7CE56e15930Af9F215b78Dd0328465;
  address PartnerAdd = 0x38065BbF795f8ed34E9Ca47F2A51825A9c50EaEf;
  address MarketingLeadAdd = 0x419F2E40EacFB8e636E644A4e65f3A533c40679a;
  address AdvisorAdd = 0xA4942B518eDd88B34474148E7cd9fd661DAEEc26;
  address LegendaryAdvisorRyckAdd = 0xbea2014BDA7b632c574763720Ee7708c92356407;
  address LegendaryAdvisorZerocoolAdd = 0x49f2b78458B553229c51a389C811C4A73ae84C73;

  constructor() ERC721A('Moonsie', 'MOONSIE') {}

  modifier nonContract() {
    require(tx.origin == msg.sender, 'The caller is another contract');
    _;
  }

  // override
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  // Owner only
  function setBaseURI(string memory newBaseURI) external onlyOwner {
    baseURI = newBaseURI;
  }

  function summoningCost(uint256 newPrice) external onlyOwner {
    price = newPrice;
  }

  function maxPopulation(uint256 newMaxSupply) external onlyOwner {
    maxSupply = newMaxSupply;
  }

  function setMerkleRootA(bytes32 newRoot) external onlyOwner {
    hashRoot_A = newRoot;
  }

  function setMerkleRootB(bytes32 newRoot) external onlyOwner {
    hashRoot_B = newRoot;
  }

  function setMerkleRootC(bytes32 newRoot) external onlyOwner {
    hashRoot_C = newRoot;
  }

  function moonsieBegins() external onlyOwner {
    phaseOneIsActive = !phaseOneIsActive;
  }

  function moonsieRising() external onlyOwner {
    phaseTwoIsActive = !phaseTwoIsActive;
  }

  function moonsieSequel() external onlyOwner {
    phaseThreeIsActive = !phaseThreeIsActive;
  }

  function ritualSummoning(uint256 amount) external onlyOwner {
    require(amount <= 6, 'Too large per batch');
    require(totalSupply() + amount <= maxSupply, 'Max supply exceeded');
    _safeMint(msg.sender, amount);
  }

  function boolishSummoning(uint256 mintAmount, bytes32[] calldata merkleProof)
    external
    payable
    nonContract
  {
    require(phaseOneIsActive, 'Mint not started');
    require(totalSupply() + mintAmount <= maxSupply, 'Max supply exceeded');
    require(msg.value == price * mintAmount, 'Insufficient funds');
    require(
      mintAmount > 0 && mintAmount <= MAX_MINT_PER_WALLET_A,
      'Invalid mint amount'
    );
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(
      MerkleProof.verify(merkleProof, hashRoot_A, leaf),
      'Not whitelisted'
    );
    uint256 mintedByWallet = mapAddressToLimit_A[msg.sender] + mintAmount;
    require(
      mintedByWallet <= MAX_MINT_PER_WALLET_A,
      'Max mint per wallet exceeded'
    );
    mapAddressToLimit_A[msg.sender] += mintAmount;
    _safeMint(msg.sender, mintAmount);
  }

  function soloSummoning(uint256 mintAmount, bytes32[] calldata merkleProof)
    external
    payable
    nonContract
  {
    require(phaseOneIsActive, 'Mint not started');
    require(totalSupply() + mintAmount <= maxSupply, 'Max supply exceeded');
    require(msg.value == price * mintAmount, 'Insufficient funds');
    require(
      mintAmount > 0 && mintAmount <= MAX_MINT_PER_WALLET_B,
      'Invalid mint amount'
    );
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(
      MerkleProof.verify(merkleProof, hashRoot_B, leaf),
      'Not whitelisted'
    );
    uint256 mintedByWallet = mapAddressToLimit_B[msg.sender] + mintAmount;
    require(
      mintedByWallet <= MAX_MINT_PER_WALLET_B,
      'Max mint per wallet exceeded'
    );
    mapAddressToLimit_B[msg.sender] += mintAmount;
    _safeMint(msg.sender, mintAmount);
  }

  function lfgSummoning(uint256 mintAmount, bytes32[] calldata merkleProof)
    external
    payable
    nonContract
  {
    require(phaseTwoIsActive, 'Mint not started');
    require(totalSupply() + mintAmount <= maxSupply, 'Max supply exceeded');
    require(msg.value == price * mintAmount, 'Insufficient funds');
    require(
      mintAmount > 0 && mintAmount <= MAX_MINT_PER_WALLET_C,
      'Invalid mint amount'
    );
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(
      MerkleProof.verify(merkleProof, hashRoot_C, leaf),
      'Not whitelisted'
    );
    uint256 mintedByWallet = mapAddressToLimit_C[msg.sender] + mintAmount;
    require(
      mintedByWallet <= MAX_MINT_PER_WALLET_C,
      'Max mint per wallet exceeded'
    );
    mapAddressToLimit_C[msg.sender] += mintAmount;
    _safeMint(msg.sender, mintAmount);
  }

  function summoning(uint256 mintAmount) external payable nonContract {
    require(phaseThreeIsActive, 'Mint not started');
    require(
      mintAmount > 0 && mintAmount <= MAX_MINT_PER_WALLET_D,
      'Invalid mint amount'
    );
    require(totalSupply() + mintAmount <= maxSupply, 'Max supply exceeded');
    require(msg.value == price * mintAmount, 'Insufficient funds');
    uint256 mintedByWallet = mapAddressToLimit_D[msg.sender] + mintAmount;
    require(
      mintedByWallet <= MAX_MINT_PER_WALLET_D,
      'Max mint per wallet exceeded'
    );
    mapAddressToLimit_D[msg.sender] += mintAmount;
    _safeMint(msg.sender, mintAmount);
  }

  function mooonsieTeamFeeding() external onlyOwner nonReentrant {
    uint256 CurrentContractBalance = address(this).balance;

    uint256 communityWallet = (CurrentContractBalance * 4000) / 10000;
    uint256 moonlightCapital = (CurrentContractBalance * 4320) / 10000;
    uint256 leadDeveloper = (CurrentContractBalance * 480) / 10000;
    uint256 partner = (CurrentContractBalance * 180) / 10000;
    uint256 marketingLead = (CurrentContractBalance * 240) / 10000;
    uint256 advisor = (CurrentContractBalance * 180) / 10000;
    uint256 legendaryAdvisorRyck = (CurrentContractBalance * 300) / 10000;
    uint256 legendaryAdvisorZerocool = (CurrentContractBalance * 300) / 10000;

    (bool scw, ) = payable(CommunityWalletAdd).call{value: communityWallet}('');
    require(scw);
    (bool smc, ) = payable(MoonlightCapitalAdd).call{value: moonlightCapital}('');
    require(smc);
    (bool sld, ) = payable(LeadDeveloperAdd).call{value: leadDeveloper}('');
    require(sld);
    (bool sp, ) = payable(PartnerAdd).call{value: partner}('');
    require(sp);
    (bool sml, ) = payable(MarketingLeadAdd).call{value: marketingLead}('');
    require(sml);
    (bool sa, ) = payable(AdvisorAdd).call{value: advisor}('');
    require(sa);
    (bool sr, ) = payable(LegendaryAdvisorRyckAdd).call{value: legendaryAdvisorRyck}('');
    require(sr);
    (bool sz, ) = payable(LegendaryAdvisorZerocoolAdd).call{value: legendaryAdvisorZerocool}('');
    require(sz);
  }

  function emergencyMeeting() external onlyOwner nonReentrant {
    (bool success, ) = payable(CommunityWalletAdd).call{value: address(this).balance}('');
    require(success);
  }
}