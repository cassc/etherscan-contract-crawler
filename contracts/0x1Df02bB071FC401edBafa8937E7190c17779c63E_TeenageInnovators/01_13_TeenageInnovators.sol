// SPDX-License-Identifier: MIT
/*
Contract by Novem - https://novem.dev
*/
pragma solidity >=0.8.13 <0.9.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract TeenageInnovators is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer {

  using Strings for uint256;

  bytes32 public merkleRootWl;

  mapping(address => uint256) public whitelistMints;
  mapping(address => uint256) public publicMints;

  string public uriPrefix = "";
  string public uriSuffix = ".json";

  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  uint256 public whitelistMintLimit;
  uint256 public publicMintLimit;

  bool public publicSaleEnabled = false;
  bool public whitelistMintEnabled = false;
  bool public enabledFirstTime = false;

  address public headTeamAddress = 0x81d9bFAef5CB2fbc89E1f1Bf34502842A8adaa48;
  address public devTeamAddress = 0x2bdB46441007C395bcC5B97df3941FDfb9d5D78D;
  address public communityManagerAddress = 0x755A95f3923Bdd53911fdD3C54A869870a9EaCA4;
  address public collabManagerAddress = 0x60B0F05327b0B753fbc7d430B7D2d0fa7788d4b7;
  address public hugAddress = 0x81d9bFAef5CB2fbc89E1f1Bf34502842A8adaa48;
  address public modAddress = 0xDB684a32af1e9BD84BEB28454eF82A18f332a259;
  address public communityWallet = 0xE476858Cf5fBa6D45Bc6F7c082edC5D3C4737a48;
  address public collabManager2Address = 0x29F2c8Bd0BeF39AC246a919e5E5a29632e7856E8;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    uint256 _whitelistMintLimit,
    uint256 _publicMintLimit,
    bytes32 _merkleRoot,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    cost = _cost;
    maxSupply = _maxSupply;
    maxMintAmountPerTx = _maxMintAmountPerTx;
    whitelistMintLimit = _whitelistMintLimit;
    publicMintLimit = _publicMintLimit;
    setUriPrefix(_hiddenMetadataUri);
    merkleRootWl = _merkleRoot;
  }

  // Makes sure the mint amount is valid and not greater than the max supply.
  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount <= maxMintAmountPerTx, "Mint amount exceeds max mint amount per tx.");
    require(totalSupply() + _mintAmount <= maxSupply, "Mint amount exceeds max supply.");
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, "Insufficient ETH sent.");
    _;
  }

  /*
      __  ________   ________
     /  |/  /  _/ | / /_  __/
    / /|_/ // //  |/ / / /
   / /  / // // /|  / / /
  /_/  /_/___/_/ |_/ /_/
  */

  function whitelistMint(address _receiver, uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify whitelist requirements
    require(whitelistMintEnabled, "Whitelist minting is not enabled.");

    // Make sure that the merkle proof is valid and that we first verify that a wallet is in the wl2 list before wl1.
    bytes32 leaf = keccak256(abi.encodePacked(_receiver));
    require(MerkleProof.verify(_merkleProof, merkleRootWl, leaf), "You are not whitelisted.");

    // Make sure the user does not mint more than what he is allowed to
    require((whitelistMints[_receiver]+_mintAmount) <= whitelistMintLimit - 1, "You have already minted your max amount.");

    // Update the number of minted tokens for the whitelist sale
    whitelistMints[_receiver] = whitelistMints[_receiver] + _mintAmount;
    if (whitelistMints[_receiver] == whitelistMintLimit - 1) _mintAmount += 1;

    require(_mintAmount + totalSupply() <= maxSupply, "Mint amount exceeds max supply.");

    _safeMint(_receiver, _mintAmount);
  }

  function mint(address _receiver, uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(publicSaleEnabled, "Public sale is not enabled.");

    require(_mintAmount + totalSupply() <= maxSupply, "Mint amount exceeds max supply.");

    require(publicMints[_receiver] + _mintAmount <= publicMintLimit - 1, "You have already minted your max amount.");

    publicMints[_receiver] = publicMints[_receiver] + _mintAmount;
    if (publicMints[_receiver] == publicMintLimit - 1) _mintAmount += 1;

    _safeMint(_receiver, _mintAmount);
  }

  // Internal function to airdrop multiple tokens to multiple wallets
  function mintForAddresses(uint256 _mintAmount, address[] memory _receivers) public onlyOwner {
    require(totalSupply() + _mintAmount * _receivers.length <= maxSupply, "The quantity exceeds the stock!");
    require(_mintAmount > 0, "The quantity must be greater than 0!");
    for(uint256 i = 0; i<_receivers.length; i++){
      _safeMint(_receivers[i], _mintAmount);
    }
  }

  /*
     _____  ______ ______ ______ ______ ____  _____
    / ___/ / ____//_  __//_  __// ____// __ \/ ___/
    \__ \ / __/    / /    / /  / __/  / /_/ /\__ \
   ___/ // /___   / /    / /  / /___ / _, _/___/ /
  /____//_____/  /_/    /_/  /_____//_/ |_|/____/
  */

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPublicSaleEnabled(bool _state) public onlyOwner {
    publicSaleEnabled = _state;
  }

  function setMerkleRootWl(bytes32 _merkleRoot) public onlyOwner {
    merkleRootWl = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
    if (!enabledFirstTime) {
      enabledFirstTime = true;
      _safeMint(communityWallet, 300);
    }
  }

  /*
   _       ______________  ______  ____  ___ _       __
  | |     / /  _/_  __/ / / / __ \/ __ \/   | |     / /
  | | /| / // /  / / / /_/ / / / / /_/ / /| | | /| / /
  | |/ |/ // /  / / / __  / /_/ / _, _/ ___ | |/ |/ /
  |__/|__/___/ /_/ /_/ /_/_____/_/ |_/_/  |_|__/|__/
  */
  function withdraw() public onlyOwner nonReentrant() {
    // split the contract balance into the above mentioned wallets
    uint256 balance = address(this).balance;
    payable(headTeamAddress).transfer(balance * 27 / 100);
    payable(devTeamAddress).transfer(balance * 18 / 100);
    payable(communityManagerAddress).transfer(balance * 12 / 100);
    payable(collabManagerAddress).transfer(balance * 1 / 100);
    payable(hugAddress).transfer(balance * 8 / 100);
    payable(modAddress).transfer(balance * 3 / 100);
    payable(communityWallet).transfer(balance * 30 / 100);
    payable(collabManager2Address).transfer(balance * 1 / 100);
  }

  /*
     ____ _    ____________  ____  ________  ___________
    / __ \ |  / / ____/ __ \/ __ \/  _/ __ \/ ____/ ___/
   / / / / | / / __/ / /_/ / /_/ // // / / / __/  \__ \
  / /_/ /| |/ / /___/ _, _/ _, _// // /_/ / /___ ___/ /
  \____/ |___/_____/_/ |_/_/ |_/___/_____/_____//____/
  */

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
    ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
    : "";
  }

  // ERC721A baseURI override
  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  //******OperatorFilterer******
  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }
}