// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import 'erc721a-upgradeable/contracts/ERC721AUpgradeable.sol';
import 'erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol';
import './interface/ILilFarmBoy.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import {DefaultOperatorFiltererUpgradeable} from 'operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol';
import '../proof-of-funds/interface/IProofOfFunds.sol';

contract LilFarmBoy is
  ILilFarmBoy,
  ERC721AUpgradeable,
  ERC721AQueryableUpgradeable,
  OwnableUpgradeable,
  DefaultOperatorFiltererUpgradeable
{
  using Strings for uint256;

  Nft public lilFarmBoy;
  Phase public currMintPhase;

  mapping(Phase => Mint) public mintPhaseData;
  mapping(address => User) public userData;
  mapping(address => bool) public allowedTeamAddress;

  /**
   * Events
   */
  event mintLilFarmBoy(address _user, uint256 _qty);

  /**
   * Modifier
   */
  modifier publicMintMod(uint256 _qty) {
    require(currMintPhase == Phase.PUBLIC, 'LFB :: Phase is not yet active.');
    require(lilFarmBoy.sale, 'LFB :: Minting is close!');
    require(
      (totalSupply() + _qty) <= lilFarmBoy.maxSupply,
      'LFB :: Not enough supply!'
    );
    require(
      msg.value >= (mintPhaseData[currMintPhase].price * _qty),
      'LFB :: Not enough payment!'
    );
    require(
      (userData[msg.sender].mintCount[currMintPhase] + _qty) <=
        mintPhaseData[currMintPhase].maxWallet,
      'LFB :: Wallet minted out!'
    );
    _;
  }

  modifier whitelistMintMod(uint256 _qty, bytes32[] memory _proof) {
    require(
      currMintPhase == Phase.WHITELIST,
      'LFB :: Phase is not yet active.'
    );
    require(lilFarmBoy.sale, 'LFB :: Minting is close!');
    require(
      (totalSupply() + _qty) <= lilFarmBoy.maxSupply,
      'LFB :: Not enough supply!'
    );
    require(
      msg.value >= (mintPhaseData[currMintPhase].price * _qty),
      'LFB :: Not enough payment!'
    );
    require(
      (userData[msg.sender].mintCount[currMintPhase] + _qty) <=
        mintPhaseData[currMintPhase].maxWallet,
      'LFB :: Wallet minted out!'
    );

    bytes32 sender = keccak256(abi.encodePacked(msg.sender));
    require(
      MerkleProofUpgradeable.verify(
        _proof,
        mintPhaseData[currMintPhase].merkleRoot,
        sender
      ),
      "LFB :: You're not in the list!"
    );
    _;
  }

  modifier mintOgMod(uint256 _qty, bytes32[] memory _proof) {
    require(lilFarmBoy.sale, 'LFB :: Minting is close!');
    require(
      currMintPhase == Phase.FARMER || currMintPhase == Phase.EARLY,
      'LFB :: Phase not yet active.'
    );
    require(
      (userData[msg.sender].mintCount[currMintPhase] + _qty) <=
        mintPhaseData[currMintPhase].maxWallet,
      'LFB :: Wallet minted out!'
    );

    bytes32 sender = keccak256(abi.encodePacked(msg.sender));
    require(
      MerkleProofUpgradeable.verify(
        _proof,
        mintPhaseData[currMintPhase].merkleRoot,
        sender
      ),
      "LFB :: You're not in the list!"
    );

    if (currMintPhase == Phase.FARMER) {
      require(
        !userData[msg.sender].farmerPhaseMinted,
        'LFB :: Already minted!'
      );
      userData[msg.sender].farmerPhaseMinted = true;
    } else if (currMintPhase == Phase.EARLY) {
      require(!userData[msg.sender].earlyPhaseMinted, 'LFB :: Already minted!');
      userData[msg.sender].earlyPhaseMinted = true;
    }
    _;
  }

  modifier teamMint() {
    require(lilFarmBoy.sale, 'LFB :: Minting is close!');
    require(currMintPhase == Phase.TEAM, 'LFB :: Phase not yet active.');
    require(
      allowedTeamAddress[msg.sender],
      'LFB :: You are not included in team'
    );
    _;
  }

  /**
   * Initialize Contract
   */

  function initialize() external initializerERC721A initializer {
    __ERC721A_init('Lil Farm Boy', 'LFB');
    __ERC721AQueryable_init();
    __Ownable_init();
    __DefaultOperatorFilterer_init();

    lilFarmBoy.maxSupply = 5999;
  }

  /**
   * Main Functions
   */

  function publicMint(uint256 _qty) external payable publicMintMod(_qty) {
    mintPhaseData[Phase.PUBLIC].totalMinted += _qty;
    userData[msg.sender].mintCount[Phase.PUBLIC] += _qty;

    _mint(msg.sender, _qty);
    emit mintLilFarmBoy(msg.sender, _qty);
  }

  function whitelistMint(
    uint256 _qty,
    bytes32[] memory _proof
  ) external payable whitelistMintMod(_qty, _proof) {
    mintPhaseData[currMintPhase].totalMinted += _qty;
    userData[msg.sender].mintCount[currMintPhase] += _qty;

    _mint(msg.sender, _qty);
    emit mintLilFarmBoy(msg.sender, _qty);
  }

  function mintOG(
    bytes32[] memory _proof,
    uint256 _qty
  ) external mintOgMod(_qty, _proof) {
    uint256 qty;
    if (currMintPhase == Phase.FARMER) {
      qty = _qty;
      _mint(msg.sender, qty);
    } else {
      qty = mintPhaseData[Phase.EARLY].maxWallet;
      _mint(msg.sender, qty);
    }

    emit mintLilFarmBoy(msg.sender, qty);
  }

  function mintTeam(uint256 _qty) external teamMint {
    _mint(msg.sender, _qty);
    emit mintLilFarmBoy(msg.sender, _qty);
  }

  /**
   * View Functions
   */
  function tokenURI(
    uint256 _tokenID
  )
    public
    view
    virtual
    override(ERC721AUpgradeable, IERC721AUpgradeable)
    returns (string memory)
  {
    uint256 trueId = _tokenID + 1;
    return
      bytes(lilFarmBoy.baseUri).length > 0
        ? string(
          abi.encodePacked(lilFarmBoy.baseUri, trueId.toString(), '.json')
        )
        : '';
  }

  function batchTokenURI(
    uint256[] memory _tokenIDs
  ) external view returns (string[] memory) {
    uint256 length = _tokenIDs.length;
    string[] memory uris = new string[](length);

    for (uint256 index = 0; index < length; index++) {
      uris[index] = tokenURI(_tokenIDs[index]);
    }

    return uris;
  }

  function viewUserMintCount(
    address _user,
    Phase _phase
  ) external view returns (uint256) {
    return userData[_user].mintCount[_phase];
  }

  function viewMintedNFTs(uint256 _qty) public view returns (string[] memory) {
    string[] memory metadata = new string[](_qty);
    for (uint256 index = 0; index < _qty; index++) {
      metadata[index] = tokenURI(totalSupply() + index);
    }

    return metadata;
  }

  /**
   * Admin Functions
   */

  function setCurrentMintPhase(Phase _phase) external onlyOwner {
    currMintPhase = _phase;
  }

  function setMintPhaseData(
    Phase _phase,
    uint256 _price,
    uint256 _maxSupply,
    uint256 _maxWallet
  ) external onlyOwner {
    mintPhaseData[_phase].price = _price;
    mintPhaseData[_phase].maxSupply = _maxSupply;
    mintPhaseData[_phase].maxWallet = _maxWallet;
  }

  function setMerkleRoot(Phase _phase, bytes32 _merkleRoot) external onlyOwner {
    mintPhaseData[_phase].merkleRoot = _merkleRoot;
  }

  function setSale() external onlyOwner {
    lilFarmBoy.sale = !lilFarmBoy.sale;
  }

  function setAllocation(
    address _user,
    uint256 _allocation
  ) external onlyOwner {
    userData[_user].farmerPhaseAllocation = _allocation;
  }

  function setTreasury(address _treasury) external onlyOwner {
    lilFarmBoy.treasury = _treasury;
  }

  function setBaseUri(string memory _baseUri) external onlyOwner {
    lilFarmBoy.baseUri = _baseUri;
  }

  function setTeamAddress(
    address[] memory _team,
    bool[] memory _isAllowed
  ) external onlyOwner {
    for (uint256 index = 0; index < _team.length; index++) {
      allowedTeamAddress[_team[index]] = _isAllowed[index];
    }
  }

  function withdrawFunds() external onlyOwner {
    require(
      lilFarmBoy.treasury != address(0),
      'LFB :: Treasury is still not set!'
    );
    uint256 balance = address(this).balance;
    address payable treasury = payable(lilFarmBoy.treasury);

    (bool success, ) = treasury.call{value: balance}('');

    require(success, 'LFB :: Transaction not successful');
    // IProofOfFunds pof = IProofOfFunds(treasury);
    // pof.depositNativeFund{
    //    value: balance
    // }('Mint Payments');
  }

  function deposit() external payable {}

  /**
   *  Opensea Operator Filter Registry Impl
   */
  function setApprovalForAll(
    address operator,
    bool approved
  )
    public
    override(ERC721AUpgradeable, IERC721AUpgradeable)
    onlyAllowedOperatorApproval(operator)
  {
    super.setApprovalForAll(operator, approved);
  }

  function approve(
    address operator,
    uint256 tokenId
  )
    public
    payable
    override(ERC721AUpgradeable, IERC721AUpgradeable)
    onlyAllowedOperatorApproval(operator)
  {
    super.approve(operator, tokenId);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  )
    public
    payable
    override(ERC721AUpgradeable, IERC721AUpgradeable)
    onlyAllowedOperator(from)
  {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  )
    public
    payable
    override(ERC721AUpgradeable, IERC721AUpgradeable)
    onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  )
    public
    payable
    override(ERC721AUpgradeable, IERC721AUpgradeable)
    onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId, data);
  }
}