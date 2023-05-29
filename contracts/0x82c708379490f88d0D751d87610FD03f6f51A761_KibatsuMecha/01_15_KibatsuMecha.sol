// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/*
                          .-=*#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%#*+=:
                      :+#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*-
                   :+%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#=
                .+%@@@@@@@@@@@@%#*++==================================++*#%@@@@@@@@@@@@@#-
               [email protected]@@@@@@@@@@*=:                                              :=*@@@@@@@@@@@%.
             :%@@@@@@@@@*:                                                      :*@@@@@@@@@@+
            [email protected]@@@@@@@@+                                                           .*@@@@@@@@@%.
           *@@@@@@@@+.                                                              [email protected]@@@@@@@@-
          #@@@@@@@#.                                                                  .#@@@@@@@@-
         [email protected]@@@@@@*                                                                      *@@@@@@@@
        [email protected]@@@@@@*                                                                        *@@@@@@@=
        [email protected]@@@@@%                                                                          %@@@@@@#
        %@@@@@@=                                                                          [email protected]@@@@@@
        @@@@@@@:                                                                          :@@@@@@@
        @@@@@@@.              :#####.                                .#####.              [email protected]@@@@@@
        @@@@@@@.              :@@@@@.                                :@@@@@:              [email protected]@@@@@@
        @@@@@@@.              :%%%%@#***:                        :***#@%%%%:              [email protected]@@@@@@
        @@@@@@@.                   #@@@@-                        [email protected]@@@#                   [email protected]@@@@@@
        @@@@@@@.                   #@@@@*====                ====*@@@@#                   [email protected]@@@@@@
        @@@@@@@.                       [email protected]@@@@                @@@@@+                       [email protected]@@@@@@
        @@@@@@@.                       [email protected]@@@@                @@@@@+                       [email protected]@@@@@@
        @@@@@@@.                       .:::::                :::::.                       [email protected]@@@@@@
        @@@@@@@.                                                                          [email protected]@@@@@@
        @@@@@@@.                                                                          [email protected]@@@@@@
        @@@@@@@.                           -##################                            [email protected]@@@@@@
        @@@@@@@.                           [email protected]@@@@@@@@@@@@@@@@@                            [email protected]@@@@@@
        @@@@@@@.                       ++++#@%%%%%%%%%%%%%%%%@++++-                       [email protected]@@@@@@
        @@@@@@@.                      [email protected]@@@@+                @@@@@*                       [email protected]@@@@@@
        @@@@@@@.                  [email protected]@@@@+                @@@@@#---:                   [email protected]@@@@@@
        @@@@@@@.                  [email protected]@@@%....                 [email protected]@@@@                   [email protected]@@@@@@
        @@@@@@@.                  [email protected]@@@#                         :@@@@@                   [email protected]@@@@@@
        @@@@@@@:                   ::::.                          ::::.                   :@@@@@@@
        %@@@@@@=                                                                          [email protected]@@@@@@
        *@@@@@@%                                                                          %@@@@@@#
        :@@@@@@@*                                                                        *@@@@@@@=
         *@@@@@@@*                                                                      *@@@@@@@@.
          @@@@@@@@#.                                                                  .#@@@@@@@@=
          .%@@@@@@@@+.                                                              [email protected]@@@@@@@@=
            #@@@@@@@@@+                                                           .*@@@@@@@@@@-
             [email protected]@@@@@@@@@*:                                                      :*@@@@@@@@@@#.
              .#@@@@@@@@@@@*=:                                              :=*@@@@@@@@@@@@=
                -#@@@@@@@@@@@@@%#*++==================================++*#%@@@@@@@@@@@@@@+.
                  .=%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*:
                     .=%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%+:
                         .-=+*#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%#*+=:.

*/

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import { IERC2981, IERC165 } from "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract KibatsuMecha is ERC721, IERC2981, Ownable, ReentrancyGuard {
  using Strings for uint256;

  string public PROVENANCE_HASH;

  uint256 constant MAX_SUPPLY = 2222;
  uint256 public price = 0.3 ether;
  uint256 public royaltyCut = 750;

  uint256 private _currentId;

  string public baseURI;
  string private _contractURI;

  enum SaleState { Closed, Presale, Public }
  SaleState public saleState = SaleState.Closed;

  bytes32 public merkleRoot;
  mapping(address => uint256) private _alreadyMinted;

  address public beneficiary;
  address public royalties;

  constructor(
    address _beneficiary,
    address _royalties,
    string memory _initialBaseURI,
    string memory _initialContractURI
  ) ERC721("Kibatsu Mecha", "KIBATSU") {
    beneficiary = _beneficiary;
    royalties = _royalties;
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

  function alreadyMinted(address addr) public view returns (uint256) {
    return _alreadyMinted[addr];
  }

  function totalSupply() public view returns (uint256) {
    return _currentId;
  }

  function setBeneficiary(address _beneficiary) public onlyOwner {
    beneficiary = _beneficiary;
  }

  function setRoyalties(address _royalties) public onlyOwner {
    royalties = _royalties;
  }

  function setRoyaltyCut(uint256 _royaltyCut) public onlyOwner {
    royaltyCut = _royaltyCut;
  }

  // Metadata

  function setBaseURI(string calldata uri) public onlyOwner {
    baseURI = uri;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  function setContractURI(string calldata uri) public onlyOwner {
    _contractURI = uri;
  }

  // Minting

  function mintListed(
    uint256 amount,
    bytes32[] calldata merkleProof,
    uint256 maxAmount
  ) public payable nonReentrant {
    address sender = _msgSender();

    require(saleState == SaleState.Presale, "Presale is not active");
    require(amount <= maxAmount - _alreadyMinted[sender], "Insufficient mints left");
    require(msg.value == price * amount, "Incorrect payable amount");
    require(_verify(merkleProof, sender, maxAmount), "Invalid proof");

    _alreadyMinted[sender] += amount;
    _internalMint(sender, amount);
  }

  function mintPublic() public payable nonReentrant {
    require(saleState == SaleState.Public, "Public sale is not active");
    require(msg.value == price, "Incorrect payable amount");
    require(_currentId + 1 <= MAX_SUPPLY, "Will exceed maximum supply");
    require(_msgSender() == tx.origin, "Calling with contracts are disallowed");

    _currentId++;
    _safeMint(_msgSender(), _currentId);
  }

  function ownerMint(address to, uint256 amount) public onlyOwner {
    _internalMint(to, amount);
  }

  function withdraw() public onlyOwner {
    payable(beneficiary).transfer(address(this).balance);
  }

  // Private

  function _internalMint(address to, uint256 amount) private {
    require(_currentId + amount <= MAX_SUPPLY, "Will exceed maximum supply");

    for (uint256 i = 1; i <= amount; i++) {
      _currentId++;
      _safeMint(to, _currentId);
    }
  }

  function _verify(
    bytes32[] calldata merkleProof,
    address sender,
    uint256 maxAmount
  ) private view returns (bool) {
    bytes32 leaf = keccak256(abi.encodePacked(sender, maxAmount.toString()));
    return MerkleProof.verify(merkleProof, merkleRoot, leaf);
  }

  // ERC165

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165) returns (bool) {
    return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
  }

  // IERC2981

  function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256 royaltyAmount) {
    _tokenId; // silence solc warning
    royaltyAmount = (_salePrice / 10000) * royaltyCut;
    return (royalties, royaltyAmount);
  }
}