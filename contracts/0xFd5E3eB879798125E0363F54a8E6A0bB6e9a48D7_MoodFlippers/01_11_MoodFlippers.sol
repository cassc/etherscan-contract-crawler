// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
                                  :+*****+-    :+*****+-
                                -%+:     .=%==%+:     .=%+
                               *#.          *#.          *%
                              :@.     [email protected]@%:  .    [email protected]@@-   %=
                              [email protected]      *@@@:       *@@@+   #+
                               %+       .   -+     .:.   [email protected]
                               .#*:       .+%##:       .+%:
             :-==++++++++++++++++#@%*+++*%@%++#@%*+++*%@%++++++++++++++++==-:.
        .=*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#=.
      -#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%=
    -%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@-
   *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
  #@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
 [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@+==#@@@@@@@@@@@@@@@@@@@@@@@@*[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@*
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@.    *@@@@@@@@@@@@@@@@@@@@@@+    :@@@@@@@@@@@@@@@@@@@@@@@@@@.
:@@@@@@@@@@@@@@@@@@@@@@@@@@@@-     #@@@@@@@@@@@@@@@@@@@@#     [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@-
[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@:     [email protected]@@@@@@@@@@@@@@@@@+     [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@-
[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@+      -*@@@@@@@@@@@@%+.     [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@-
[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%-       .-=+++++=:       :#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@:
 %@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%=.                   -#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%
 :@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%+-.           :=*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@-
  [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%#####%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@=
   :%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%:
     =%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@=
       -*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*-
          :=*#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%*=:
                                    XXXXXXXXXXXXXXXXXXX
                                    XXXXXXXXXXXXXXXXXXX
 */

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract MoodFlippers is ERC721A, ERC2981, Ownable {
  using Strings for uint256;

  error ContractMintDisallowedError();
  error EarlyAccessClosedError();
  error ExceedsMaxSupplyError();
  error IncorrectAmountError();
  error InsufficientEarlyAccessSpotsError();
  error InvalidProofError();
  error PublicSaleClosedError();

  string public PROVENANCE_HASH;

  uint256 constant MAX_SUPPLY = 5000;

  enum SaleState {
    Closed,
    Stage1,
    Stage2,
    Public
  }
  SaleState public saleState = SaleState.Closed;

  mapping(SaleState => uint256) private _prices;
  address payable public beneficiary;

  bytes32 public merkleRoot;
  mapping(address => uint256) private _earlyAccessSpotsUsed;

  string public baseURI;
  string private _contractURI;

  constructor(
    address payable _beneficiary,
    address payable royaltiesReceiver,
    string memory _initialBaseURI,
    string memory _initialContractURI
  ) ERC721A("Mood Flippers", "MOODFLIPPERS") {
    _prices[SaleState.Stage1] = 0.075 ether;
    _prices[SaleState.Stage2] = 0.12 ether;
    _prices[SaleState.Public] = 0.16 ether;

    beneficiary = _beneficiary;
    setRoyaltyInfo(royaltiesReceiver, 500);

    baseURI = _initialBaseURI;
    _contractURI = _initialContractURI;
  }

  // Accessors

  function setProvenanceHash(string calldata hash) public onlyOwner {
    PROVENANCE_HASH = hash;
  }

  function setSaleState(SaleState _saleState) public onlyOwner {
    saleState = _saleState;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setBeneficiary(address payable _beneficiary) public onlyOwner {
    beneficiary = _beneficiary;
  }

  function earlyAccessSpotsUsed(address addr) public view returns (uint256) {
    return _earlyAccessSpotsUsed[addr];
  }

  // Metadata

  function setBaseURI(string calldata uri) public onlyOwner {
    baseURI = uri;
  }

  function setContractURI(string calldata uri) public onlyOwner {
    _contractURI = uri;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  // Minting

  function mintListed(
    uint256 amount,
    bytes32[] calldata merkleProof,
    uint256 maxAmount
  ) public payable {
    if (saleState != SaleState.Stage1 && saleState != SaleState.Stage2)
      revert EarlyAccessClosedError();
    if (amount > maxAmount - _earlyAccessSpotsUsed[msg.sender])
      revert InsufficientEarlyAccessSpotsError();
    if (msg.value != _prices[saleState] * amount) revert IncorrectAmountError();
    if (!_verify(merkleProof, msg.sender, maxAmount))
      revert InvalidProofError();

    _earlyAccessSpotsUsed[msg.sender] += amount;
    _internalMint(msg.sender, amount);
  }

  function mintPublic(uint256 amount) public payable {
    if (saleState != SaleState.Public) revert PublicSaleClosedError();
    if (msg.value != _prices[saleState] * amount) revert IncorrectAmountError();
    if (msg.sender != tx.origin) revert ContractMintDisallowedError();

    _internalMint(msg.sender, amount);
  }

  function ownerMint(address to, uint256 amount) public onlyOwner {
    _internalMint(to, amount);
  }

  function withdraw() public onlyOwner {
    beneficiary.transfer(address(this).balance);
  }

  // Private

  function _internalMint(address to, uint256 amount) private {
    if (totalSupply() + amount > MAX_SUPPLY) revert ExceedsMaxSupplyError();
    _mint(to, amount);
  }

  function _verify(
    bytes32[] calldata merkleProof,
    address sender,
    uint256 maxAmount
  ) private view returns (bool) {
    bytes32 leaf = keccak256(abi.encodePacked(sender, maxAmount.toString()));
    return MerkleProof.verify(merkleProof, merkleRoot, leaf);
  }

  // ERC721A

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  // IERC2981

  function setRoyaltyInfo(address payable receiver, uint96 numerator)
    public
    onlyOwner
  {
    _setDefaultRoyalty(receiver, numerator);
  }

  // ERC165

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721A, ERC2981)
    returns (bool)
  {
    return
      ERC721A.supportsInterface(interfaceId) ||
      ERC2981.supportsInterface(interfaceId);
  }
}