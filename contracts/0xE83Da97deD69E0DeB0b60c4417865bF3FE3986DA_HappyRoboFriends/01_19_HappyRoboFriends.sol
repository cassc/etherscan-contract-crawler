/**
 * Happy Robo Friends is an ERC721 collection of 2,222 unique PFP NFTs on the Ethereum blockchain.
 *
 * Website: https://happyrobofriends.com/
 * Twitter: https://twitter.com/HRFriends_NFT
 * Discord: https://discord.gg/happyrobofriends
 */

// SPDX-License-Identifier: Unlicense

pragma solidity 0.8.18;

import "@openzeppelin/[email protected]/access/Ownable.sol";
import "@openzeppelin/[email protected]/token/ERC721/ERC721.sol";
import "@openzeppelin/[email protected]/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/[email protected]/utils/Strings.sol";
import "@openzeppelin/[email protected]/utils/cryptography/MerkleProof.sol";
import "[email protected]/src/DefaultOperatorFilterer.sol";

contract HappyRoboFriends is Ownable, ERC721, ERC721Royalty, DefaultOperatorFilterer {
  uint256 private constant MAX_SUPPLY = 2222;
  uint96 private constant ROYALTY = 500; // 5%
  uint256 private constant MINT_PRICE = 10000000000000000; // 0.01 ETH

  uint256 private _ids = 778;
  string private _ipfs;
  bytes32 private _whitelistRoot;
  mapping (address => bool) private _redeemedWhitelist;
  bool private _allWhitelisted;
  bool private _minting;

  event SetIPFS(string ipfs);
  event SetWhitelistRoot(bytes32 whitelistRoot);
  event StartMinting(bool allWhitelisted);

  constructor() ERC721("Happy Robo Friends", "HRF") {
    _mint(msg.sender, _ids);
    _setDefaultRoyalty(msg.sender, ROYALTY);
  }

  function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty) {
    super._burn(tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Royalty) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function approve(address to, uint256 tokenId) public override onlyAllowedOperatorApproval(to) {
    super.approve(to, tokenId);
  }

  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    _requireMinted(tokenId);
    return keccak256(abi.encodePacked(_ipfs)) == keccak256(abi.encodePacked("")) ? "https://happyrobofriends.com/assets/metadata/nft.json" : string(abi.encodePacked(_ipfs, Strings.toString(tokenId)));
  }

  function contractURI() external pure returns (string memory) {
    return "https://happyrobofriends.com/assets/metadata/contract.json";
  }

  function setIPFS(string memory ipfs) external onlyOwner {
    require(keccak256(abi.encodePacked(_ipfs)) == keccak256(abi.encodePacked("")), "HappyRoboFriends:setIPFS:: ipfs already set");
    _ipfs = ipfs;
    emit SetIPFS(ipfs);
  }

  function setWhitelistRoot(bytes32 whitelistRoot) external onlyOwner {
    _whitelistRoot = whitelistRoot;
    emit SetWhitelistRoot(whitelistRoot);
  }

  function startMinting(bool allWhitelisted) external onlyOwner {
    _allWhitelisted = allWhitelisted;
    _minting = true;
    emit StartMinting(allWhitelisted);
  }

  function mint() external payable {
    require(_minting, "HappyRoboFriends::mint: minting has not started");
    uint256 id;

    unchecked {
      id = ++_ids;
    }

    require(id < MAX_SUPPLY, "HappyRoboFriends::mint: sold out");
    require(msg.value == MINT_PRICE, "HappyRoboFriends::mint: sent amount does not match price");
    (bool success, ) = owner().call{ value: address(this).balance }(new bytes(0));
    require(success, "HappyRoboFriends::mint: ETH transfer failed");
    _mint(msg.sender, id);
  }

  function whitelistMint(bytes32[] memory proof) external {
    require(_minting, "HappyRoboFriends::whitelistMint: minting has not started");

    if (!_allWhitelisted) {
      require(!_redeemedWhitelist[msg.sender], "HappyRoboFriends::whitelistMint: already redeemed whitelist");
      _redeemedWhitelist[msg.sender] = true;
      require(MerkleProof.verify(proof, _whitelistRoot, keccak256(bytes.concat(keccak256(abi.encode(msg.sender))))), "HappyRoboFriends::whitelistMint: invalid proof");
    }

    uint256 id;

    unchecked {
      id = ++_ids;
    }

    require(id < MAX_SUPPLY, "HappyRoboFriends::whitelistMint: sold out");
    _mint(msg.sender, id);
  }
}