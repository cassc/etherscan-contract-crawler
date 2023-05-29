// Froggy Friends by Fonzy & Mayan (www.froggyfriendsnft.com) Froggy Soulbounds

//[email protected]@@@@........................
//.......................%@@@@@@@@@*[email protected]@@@#///(@@@@@...................
//[email protected]@@&(//(//(/(@@@.........&@@////////////@@@.................
//[email protected]@@//////////////@@@@@@@@@@@@/////@@@@/////@@@..............
//..................%@@/////@@@@@(////////////////////%@@@@/////#@@...............
//[email protected]@%//////@@@#///////////////////////////////@@@...............
//[email protected]@@/////////////////////////////////////////@@@@..............
//[email protected]@(///////////////(///////////////(////////////@@@............
//...............*@@/(///////////////&@@@@@@(//(@@@@@@/////////////#@@............
//[email protected]@////////////////////////(%&&%(///////////////////@@@...........
//[email protected]@@/////////////////////////////////////////////////&@@...........
//[email protected]@(/////////////////////////////////////////////////@@#...........
//[email protected]@@////////////////////////////////////////////////@@@............
//[email protected]@@/////////////////////////////////////////////#@@/.............
//................&@@@//////////////////////////////////////////@@@...............
//..................*@@@%////////////////////////////////////@@@@.................
//[email protected]@@@///////////////////////////////////////(@@@..................
//............%@@@////////////////............/////////////////@@@................
//..........%@@#/////////////..................... (/////////////@@@..............
//[email protected]@@////////////............................////////////@@@.............
//[email protected]@(///////(@@@................................(@@&///////&@@............
//[email protected]@////////@@@[email protected]@@///////@@@...........
//[email protected]@@///////@@@[email protected]@///////@@%..........
//.....(@@///////@@@[email protected]@/////(/@@..........

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

error SoulboundBlock();
error ClaimOff();
error NotEligible();
error Claimed();
error InvalidProof();

contract FroggySoulbounds is ERC1155, Ownable {
  using Strings for uint256;
  string private baseUrl;
  string private baseUrlSuffix;
  string private contractUrl;
  string private _name;
  string private _symbol;
  bool public claimOn = true;
  mapping(uint256 => bytes32) public roots;

  constructor() ERC1155("") {
    _name = "Froggy Soulbounds";
    _symbol = "FROGGYSBT";
    baseUrl = "https://froggyfriends.mypinata.cloud/ipfs/QmcYcdwiRTED2gw4SyLuKoM7Ts7L5ukyiEARbMBo3Sgyux/";
    contractUrl = "https://froggyfriends.mypinata.cloud/ipfs/QmPiga7eAYUvXarkh1PPJ869mNrEKXo9AFqw4eGYkEcVc9";
    baseUrlSuffix = ".json";
    roots[1] = 0x70d4f525facbf965995cb1114c24a84aeef6abc2de6c64557f5b0a1c80f5b376; // one year anniversary minters
    roots[2] = 0x11c5642add578cbc941ac7f630f769c41aa5c02b055c6a01bc53a508fa1bff69; // one year anniversary holders
  }

  function airdrop(uint256 id, address[] calldata accounts) external onlyOwner {
    for (uint i = 0; i < accounts.length; i++) {
      _mint(accounts[i], id, 1, "");
    }
  }

  function claim(bytes32[] memory proof, uint256 id) public {
    _claim(proof, id);
  }

  function claimMany(bytes32[][] memory proofs, uint256[] calldata ids) public {
    if (proofs.length != ids.length) revert InvalidProof();
    for (uint i = 0; i < ids.length; i++) {
      _claim(proofs[i], ids[i]);
    }
  }

  function _claim(bytes32[] memory proof, uint256 id) internal {
    if (claimOn == false) revert ClaimOff();
    if (isEligible(proof, id, msg.sender) == false) revert NotEligible();
    if (balanceOf(msg.sender, id) > 0) revert Claimed();
    _mint(msg.sender, id, 1, "");
  }

  function isEligible(bytes32[] memory proof, uint256 id, address account) public view returns(bool) {
    bytes32 leaf= keccak256(abi.encodePacked(account));
    return MerkleProof.verify(proof, roots[id], leaf);
  }

  function adminBurn(address account, uint256 id) external onlyOwner {
    _burn(account, id, 1);
  }

  function burn(uint256 id) external {
    _burn(msg.sender, id, 1);
  }

  function name() public view virtual returns (string memory) {
    return _name;
  }

  function symbol() public view virtual returns (string memory) {
    return _symbol;
  }

  function contractURI() public view returns (string memory) {
    return string(abi.encodePacked(contractUrl));
  }

  function setContractURI(string memory _contractUrl) public onlyOwner {
    contractUrl = _contractUrl;
  }

  function uri(uint256 tokenId) public view virtual override returns (string memory) {
    return string(abi.encodePacked(baseUrl, tokenId.toString(), baseUrlSuffix));
  }

  function setURI(string memory _baseUrl) public onlyOwner {
    baseUrl = _baseUrl;
  }

  function setSuffix(string memory _suffix) public onlyOwner {
    baseUrlSuffix = _suffix;
  }

  function setClaim(bool _claimOn) public onlyOwner {
    claimOn = _claimOn;
  }

  function setRoot(uint256 id, bytes32 _root) public onlyOwner {
    roots[id] = _root;
  }

  function getRoot(uint256 id) public view virtual returns (bytes32) {
    return roots[id];
  }

  // Disable approvals and transfers
  function setApprovalForAll(address, bool) public pure override {
    revert SoulboundBlock();
  }

  function safeTransferFrom(address, address, uint256, uint256, bytes memory) public pure override {
    revert SoulboundBlock();
  }

  function safeBatchTransferFrom(address, address, uint256[] memory, uint256[] memory, bytes memory) public pure override {
    revert SoulboundBlock();
  }
}