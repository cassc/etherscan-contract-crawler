// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

//                                                       (&&&&&&&&&&&&&&&&&&&&&&&&&&
//                                                         &&&&&&&&&&&&&&&&&&&&&&&&&&%&&&&&&&&&&
//                                 &&&&&&&&                      &&&&&&&&&&&&&&&&&&&&&&&&  &&&&&&&&&
//                                   .&&&&&&&&                           /&%    &&&&&&&&&&&&&&&&&&&&&&
//                                &&&&&&&&&&&&&&&&                          &&&&&&&&&&&&&&&&&&&&&&&&&
//          &&&&&              &&&&&&&&&&&&&&&&&&&&&&&&               &&&&&&&&&&&&&&&&&&&&&&&&&
//            &&&&&&&&&&/  &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
//                    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&* .&&&&&&&&
//  &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& &&&&
//    %&&&&&&&&&&&&   &&&&&&&&&&&&&&&&&&&  &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& &&&&&&&&&&&&&&&&
//                                       &&&&   &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&               &&&&
//                                           %&&&&&   &&&&&&&&&&&&&&&&&&&&&                       &
//                                                  &&&&&&&&&&&&&&&&

contract Pacemaker is
  DefaultOperatorFilterer,
  Ownable,
  ReentrancyGuard,
  ERC721AQueryable
{
  struct PhaseProps {
    bool phaseActive;
    uint256 discount;
    bytes32 root;
  }

  enum Phase {
    PHASE1,
    PHASE2,
    PHASE3,
    FRIENDS,
    ALLOWLIST,
    WAITLIST
  }

  constructor() ERC721A("Pacemaker", "PACE") {}

  uint256 public PRICE_PER_TOKEN = 0.15 ether;
  uint256 public MAX_SUPPLY = 5000;
  string private _tokenUri = "";
  bool public whitelistActive = true;

  mapping(Phase => PhaseProps) public mintPhases;
  mapping(address => mapping(Phase => bool)) public hasMintedPhase;
  mapping(address => uint) public pMinted;

  /**
   * @dev mint function for access controlled phases
   * @param _merkleProof the proof sent by the frontend
   * @param _amount the amount of tokens a user wants to mint
   * @param _max the max discounted mints (depending on masks)
   * @param _phase the phase a user wants to mint in
   */
  function mint(
    bytes32[] calldata _merkleProof,
    uint256 _amount,
    uint256 _max,
    Phase _phase
  ) public payable nonReentrant {
    require(totalSupply() + _amount <= MAX_SUPPLY, "Exceeds max supply");
    require(mintPhases[_phase].phaseActive, "Sale is not active yet");

    require(
      !hasMintedPhase[msg.sender][_phase],
      "Already minted in this phase"
    );
    require(
      isWhitelisted(msg.sender, _max, _merkleProof, _phase),
      "Invalid Merkle Proof"
    );
    require(_amount <= _max * 2, "Can't mint more in this phase");

    uint256 fundsNeeded = calculatePrice(_amount, _max, _phase);
    require(msg.value >= fundsNeeded, "Wrong amount of Ether send");

    hasMintedPhase[msg.sender][_phase] = true;

    _mint(msg.sender, _amount);
  }

  /**
   * Getter Functions
   */

  /**
   * @dev public mint function
   * @param _amount the amount a user wants to mint
   */
  function pmint(uint256 _amount) public payable nonReentrant {
    require(totalSupply() + _amount <= MAX_SUPPLY, "Exceeds max supply");
    require(!whitelistActive, "Mint not open!");
    require(
      msg.value >= _amount * PRICE_PER_TOKEN,
      "Wrong amount of Ether send"
    );
    require(pMinted[msg.sender] + _amount <= 5, "Amount limited");

    pMinted[msg.sender] += _amount;
    _mint(msg.sender, _amount);
  }

  /**
   * @dev airdrop function for pre mint giveaways and team mints
   * @param _address the address of the receiver
   * @param _amount the amount of tokens being airdropped
   */
  function airdrop(address _address, uint256 _amount) public onlyOwner {
    require(totalSupply() + _amount <= MAX_SUPPLY, "Supply is limited");

    _mint(_address, _amount);
  }

  /**
   * @dev the price will be calculated depending on the phase and masks a user owns
   * @param _amount the amount of tokens a user wants to mint.
   * @param _max the max possible discounted mints.
   * @param _phase for discount that needs to be calculated.
   */
  function calculatePrice(
    uint256 _amount,
    uint256 _max,
    Phase _phase
  ) public view returns (uint256 price) {
    uint256 discount = mintPhases[_phase].discount;
    uint256 discounted;

    if (_max >= _amount) {
      discounted = _amount * discount;
    } else {
      discounted = _max * discount;
    }

    uint256 fundsNeeded = PRICE_PER_TOKEN * _amount;

    if (discounted >= fundsNeeded) {
      fundsNeeded = 0;
    } else {
      fundsNeeded = fundsNeeded - discounted;
    }

    return fundsNeeded;
  }

  /**
   * @dev check if a user is eligible to mint in a phase
   * @param _address the address of the minting user
   * @param _max the max discounted mints (depending on masks)
   * @param _merkleProof the merkle proof sent by the frontend
   * @param _phase the phase a user wants to mint in
   */
  function isWhitelisted(
    address _address,
    uint256 _max,
    bytes32[] calldata _merkleProof,
    Phase _phase
  ) public view returns (bool) {
    bytes32 leaf = keccak256(abi.encode(_address, _max));
    return MerkleProof.verify(_merkleProof, mintPhases[_phase].root, leaf);
  }

  /**
   * @dev function to return the parameters of a phase
   * @param _phase the phase which should be queried
   */
  function checkPhase(
    Phase _phase
  ) public view returns (PhaseProps memory props) {
    return mintPhases[_phase];
  }

  /*
    Owner Functions
  */

  /**
   * @dev function to update the phase properties
   * @param _phase the phase which has to be updated
   * @param _phaseProps the different properties which should be changed
   */
  function changePhaseProps(
    Phase _phase,
    PhaseProps calldata _phaseProps
  ) public onlyOwner {
    mintPhases[_phase] = _phaseProps;
  }

  /**
   * @dev activate or deactivate a phase
   * @param _phase the phase which should be changed
   */
  function togglePhaseActive(Phase _phase) public onlyOwner {
    mintPhases[_phase].phaseActive = !mintPhases[_phase].phaseActive;
  }

  /**
   * @dev enable public sale
   */
  function toggleWhitelist() public onlyOwner {
    whitelistActive = !whitelistActive;
  }

  /**
   * @dev set the uri for the tokens
   * @param _uri the token uri
   */
  function setBaseUri(string calldata _uri) external onlyOwner {
    _tokenUri = _uri;
  }

  /**
   * @dev function to change the mint price
   * @param _price the new price
   */
  function setPrice(uint256 _price) external onlyOwner {
    PRICE_PER_TOKEN = _price;
  }

  /**
   * @dev function to release the funds from the contract
   */
  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{ value: address(this).balance }("");
    require(os);
  }

  /*
    Overrides & Opensea Filter
  */

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _tokenUri;
  }

  function setApprovalForAll(
    address operator,
    bool approved
  ) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(
    address operator,
    uint256 tokenId
  )
    public
    payable
    override(ERC721A, IERC721A)
    onlyAllowedOperatorApproval(operator)
  {
    super.approve(operator, tokenId);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }
}