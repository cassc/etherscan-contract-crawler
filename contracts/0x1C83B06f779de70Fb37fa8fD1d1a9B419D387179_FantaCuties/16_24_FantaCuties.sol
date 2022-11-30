// SPDX-License-Identifier: MIT

/*
+-------------------------------------------------------------------------------------------------------+
|                                                                                                       |
|                                   ,,,               ,gg  ,,                    ,                      |
|     ,[email protected]                    @@@             ,@@@@@@@@            @@@    '@@                     |
|      [email protected]@@[email protected]@     ,,,  ,,       ,@@@,,   ,  ,ggg @@@"`%@@@ ,,,   ,,, ,@@@,  ,,,,     ,               |
|       [email protected]@]Bg  [email protected]@@@@@@[email protected]@@@@@@@@."[email protected]@NN ,@@@@@@@N]@@P   "` @@@@ ]@@@@ %@@@BK [email protected]@@P @@@[email protected]@ ,@@@[email protected]@     |
|       ]@@*@@  @@` ]@@P  [email protected]@P  @@K ]@@   [email protected]  @@@ ]@@@  ,gg  @@L  ]@@   @@P    @@- @@@[email protected]" ]@@Npg,     |
|      ,@@@W    [email protected]@@@@K,@@@g  @@@K]@@[email protected]&@[email protected]@@@B %@@@@@@@@ [email protected]@[email protected]@@@N  @@@[email protected]@@g %@@[email protected]@,gg,,@@@     |
|      "*PP*`    Y*P**P*""*f"" '*f*" "***" "P" *P**   -  -"*"  """ 'ff^  "***^ "**"   - ""*`""""        |
|                                                                                                       |
|                                                                                                       |
|                                          ,ggBNw        ggBNg,                                         |
|                                         ]@@@@@@@W]@gK,@@@@@@@@                                        |
|                                         @@@@@@@@@ @@ ]@@@@@@@@,                                       |
|                                         *[email protected]@@@@@$gC"@[email protected]@@@@@@P`                                       |
|                                        ,]@@@@@@PP*  "[email protected]@@@@@@,                                       |
|                                       ]@@@@@@@@@      ]@@@@@@@@@                                      |
|                                        *"-NBBBNP      -NBBBN-""-                                      |
|                                                                                                       |
+-------------------------------------------------------------------------------------------------------+
*/

pragma solidity ^0.8.0;

import "./erc721/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {
  DefaultOperatorFilterer
} from "./royalties/opensea/DefaultOperatorFilterer.sol";
import "./royalties/rarible/LibPart.sol";
import "./royalties/rarible/LibRoyaltiesV2.sol";
import "./royalties/rarible/impl/RoyaltiesV2Impl.sol";


contract FantaCuties is
  Ownable,
  ERC721A,
  DefaultOperatorFilterer,
  RoyaltiesV2Impl,
  ReentrancyGuard 
{
  using ECDSA for bytes32;
  using Strings for uint256;

  uint256 public constant PRICE = .087 ether;
  uint256 public constant SILVER_PRICE = .069 ether;
  uint256 public constant GOLD_PRICE = .056 ether;

  uint256 public constant MAX_PUBLIC_MINT = 10;
  
  uint256 public maxSupply = 10000;

  bool public presaleActive = false;
  bool public publicActive = false;
  bool public isRevealed = false;

  string private _baseTokenURI;
  string private _preRevealTokenURI;

  bytes32 private _whitelistRoot;
  mapping(address => bool) private _whitelistClaimed;

  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

  constructor() ERC721A("FantaCuties", "FANTACUTIE") {
  }

  modifier callerIsUser() {
    require(
      tx.origin == msg.sender,
      "FantaCuties :: The caller cannot be another contract"
    );
    _;
  }

  // State switches
  function togglePresale(bool isActive) external onlyOwner {
    presaleActive = isActive;
  }

  function togglePublic(bool isActive) external onlyOwner {
    publicActive = isActive;
  }

  function toggleReveal(bool _isRevealed) external onlyOwner {
    isRevealed = _isRevealed;
  }

  function setMaxSupply(uint256 _maxSupply) external onlyOwner {
    maxSupply = _maxSupply;
  }

  // Set merkle root
  function setWhitelistRoot(bytes32 _merkleRoot) external onlyOwner {
    _whitelistRoot = _merkleRoot;
  }

  // Metadata URI
  function _baseURI() 
    internal view virtual override
    returns (string memory) 
  {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function setPreRevealURI(string calldata preRevealURI) external onlyOwner {
    _preRevealTokenURI = preRevealURI;
  }

  // Reserved mint
  function reservedMint(uint256 _quantity) external onlyOwner {
    _safeMint(msg.sender, _quantity);
  }

  // Presale mint
  function presaleMint(
    uint256 _quantity,
    uint256 _tierCode,
    bytes32[] calldata _merkleProof
  )
    external payable callerIsUser nonReentrant 
  {
    require(presaleActive, "FantaCuties :: Presale mint is not currently active");
    require(
      _whitelistClaimed[msg.sender] == false,
      "FantaCuties :: You already claimed your tokens"
    );

    bytes32 leaf = keccak256(
      abi.encodePacked(msg.sender, _quantity, _tierCode)
    );
    require(
      MerkleProof.verify(_merkleProof, _whitelistRoot, leaf),
      "FantaCuties :: You are not admitted to the presale"
    );

    uint256 price = PRICE;
    if (_tierCode == 1) {
      price = SILVER_PRICE;
    } else if (_tierCode == 2) {
      price = GOLD_PRICE;
    }
    require(msg.value >= price * _quantity, "FantaCuties :: Insufficient funds");

    _safeMint(msg.sender, _quantity);
    _whitelistClaimed[msg.sender] = true;
  }

  // Public mint
  function publicMint(uint256 _quantity)
    external payable callerIsUser nonReentrant
  {
    require(publicActive, "FantaCuties :: Public mint is not currently active");
    require(msg.value >= PRICE * _quantity, "FantaCuties :: Insufficient funds");
    require(
      _quantity <= MAX_PUBLIC_MINT,
      "FantaCuties :: Cannot mint more than 10 tokens per transaction"
    );
    require(
      totalSupply() + _quantity <= maxSupply,
      "FantaCuties :: Cannot mint beyond max supply"
    );
    _safeMint(msg.sender, _quantity);
  }

  // Get token IDs of a specific owner
  function getWallet() public view returns (uint256[] memory) {
    uint256 tokenCount = balanceOf(msg.sender);
    uint256[] memory tokenIds = new uint256[](tokenCount);
    for (uint256 i; i < tokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(msg.sender, i);
    }
    return tokenIds;
  }

  // Get token URI
  function tokenURI(uint256 _tokenId) 
    public view virtual override returns (string memory) 
  {
    require(_exists(_tokenId), "FantaCuties: Cannot find a token with that ID");
    
    if (isRevealed == false) {
      return _preRevealTokenURI;
    }
    return bytes(_baseTokenURI).length > 0
      ? string(abi.encodePacked(_baseTokenURI, _tokenId.toString(), ".json"))
      : "";
  }

  function withdraw() external onlyOwner {
    uint256 withdrawAmount = address(this).balance;
    payable(msg.sender).transfer(withdrawAmount);
  }

  // Override ERC721 functions to comply with Opensea's royalties enforcement
  function setApprovalForAll(address operator, bool approved)
    public override onlyAllowedOperatorApproval(operator)
  {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId)
    public override onlyAllowedOperatorApproval(operator)
  {
    super.approve(operator, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId)
    public override onlyAllowedOperator(from)
  {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId)
    public override onlyAllowedOperator(from)
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
    override
    onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  // Set royalties for Rarible
  function setRoyalties(
    uint _tokenId,
    address payable _royaltiesRecipientAddress,
    uint96 _percentageBasisPoints
  )
    public onlyOwner 
  {
    LibPart.Part[] memory _royalties = new LibPart.Part[](1);
    _royalties[0].value = _percentageBasisPoints;
    _royalties[0].account = _royaltiesRecipientAddress;
    _saveRoyalties(_tokenId, _royalties);
  }

  // Set royalties for Mintable (same perc as Rarible)
  function royaltyInfo(
    uint256 _tokenId,
    uint256 _salePrice
  )
    external view returns (address receiver, uint256 royaltyAmount) 
  {
    LibPart.Part[] memory _royalties = royalties[_tokenId];
    if(_royalties.length > 0) {
      return (
        _royalties[0].account, (_salePrice * _royalties[0].value) / 10000
      );
    }
    return (address(0), 0);
  }

  function supportsInterface(bytes4 interfaceId)
    public view virtual override(ERC721A) returns (bool)
  {
    if(interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
      return true;
    }
    if(interfaceId == _INTERFACE_ID_ERC2981) {
      return true;
    }
    return super.supportsInterface(interfaceId);
  }
}