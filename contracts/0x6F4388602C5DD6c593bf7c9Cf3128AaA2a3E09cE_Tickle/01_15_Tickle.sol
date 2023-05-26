//        .≡╔≡≤≡≡≤≤≤≤≤≡≡»
//  ,,»▒░░φ▒▒░░░░Γ░░░░░░░░░▒░,,
// φ▒░░░░░▒▒▒░░░░░░░░░░░░░░░░░φ░░,,
// ░░░░░░░╚▒▒░░░░░░░░░░░░░░░░░░▒░░░[
// ░░░░░░░φ▒▒░░░░░░░░░░░░░░░░░░░▒░░░░░⌐
// ░░░░░▒▒▒╢╬▒▒║╙╙"╣╬╢╠╠╢╣╣▒▒▒▒Å╠▒░░░░░░⌐
// ▒╠╠╠╠╣╣╬╬╠╠╬╬░  ╬╬╬╬╬╬╬╬╬▓╣╬╬╣╣╣▒▒░░░░
// ╠╠╠╠╬╬╠╠╠╠╠╠╠░  ╬╬╬╬╬╬╬╬╬╬╬▓▓╬╬╬╬╣╬▒▒░░
// ╠╠╢╬╬╠╠╠╠╠╠╠╠░  ╬╬╬╬╬╬╬╬╬╬╬╬╣▓▓╬╬╬╬╬╬╩░⌐
// ╠╠╬╬╠╠╠╠╠╠╠╠╠░  ╣╣╬╠╬╬╬╬╬╬╬╬╬╬╣▓╬╬╬╬╠▒░
// ╠╬╬▒▒▒╠╠╠╠╠╠╠░  ╬╣╬╠╠╠╬╬╬╬╬╬╬╬╬╬▓▓╬╠╙
// ╢╬╩▒▒▒▒▒▒╠╠╠╠└  ╠╣╬╠╠╠╠╬╬╬╬╬╬╬╬╬╬╬╩`
// ╬▒▒▒▒▒▒▒▒▒▒╠╠[  ╠╬╬╣╠╠╠╠╬╬╬╬╝╝╙╙└
// ╬▒╠▒╠▒▒▒▒▒▒▒╠~ ]╠╣╬╝╝╝╝╣╩└└└
// └╙╙╙╙╙╙└╙└└╙╙   ╙╙╙
//              -
//             .
//             .   '
//             '                       Welcome to Tickle Beach
//             '
//             ~
//             '
//             '
//             '                              ,,,,,,,;;;εεεεφφφφφφφεεεεεε;;,,,,,,,,
// ▒▒▒░░░░░░░░░⌐  :░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ╚╚╚╚╚╚╚╚Å##▒∩  :░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░φ░φ░░░░░░░░░░░░░░░░░░░░░░░░░░Γ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░Γ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import './Base64.sol';

// import 'hardhat/console.sol';

interface CustomRender {
  function htmlForToken(uint256 tokenId) external view returns (string memory);

  function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract Tickle is ERC721A, Ownable, ReentrancyGuard {
  using ECDSA for bytes32;

  bool public publicOpen = false;
  bool public accessOpen = false;

  CustomRender public renderer;

  // placeholder for future use
  uint256 public price = 0.2 ether;

  address public accessAddr;

  uint256 public constant TOTAL = 10001;
  // uint256 public constant MAX_TEAM = 111; 111 * 4 => 444
  uint256 public constant PUBLIC_TOTAL = 9557; // 10001-444
  mapping(address => uint16) public accessMinted;

  constructor(uint256 quantity) ERC721A('Tickle', 'TCKL', quantity) {}

  ///////////////// setup /////////////////

  function setAccessAddr(address _accessAddr) public onlyOwner {
    accessAddr = _accessAddr;
  }

  function setAccessOpen(bool _accessOpen) public onlyOwner {
    accessOpen = _accessOpen;
  }

  function setRenderer(address addr) public onlyOwner {
    renderer = CustomRender(addr);
  }

  function setPrice(uint256 _price) public onlyOwner {
    price = _price;
  }

  function setPublicOpen(bool _publicOpen) public onlyOwner {
    publicOpen = _publicOpen;
  }

  ///////////////// minting /////////////////

  modifier callerIsUser() {
    require(tx.origin == msg.sender, 'The caller is another contract');
    _;
  }

  function accessMint(
    uint256 timestamp,
    uint16 quantity,
    uint16 allowed,
    bytes memory signature
  ) external payable callerIsUser nonReentrant {
    require(accessOpen, 'not open');
    require(msg.value >= price * quantity, 'price not met');
    require(accessMinted[msg.sender] + quantity <= allowed, 'too many');
    require(totalSupply() + quantity <= PUBLIC_TOTAL, 'total hit');

    bytes32 msgHash = keccak256(
      abi.encodePacked(msg.sender, timestamp, quantity, allowed)
    );
    require(isValidSignature(msgHash, signature), 'Invalid signature');

    accessMinted[msg.sender] += quantity;
    _safeMint(msg.sender, quantity);
  }

  function publicMint(uint256 quantity)
    external
    payable
    callerIsUser
    nonReentrant
  {
    require(publicOpen, 'not open');
    require(msg.value >= price * quantity, 'price not met');
    require(totalSupply() + quantity <= PUBLIC_TOTAL, 'total hit');

    _safeMint(msg.sender, quantity);
  }

  function teamMint(uint256 quantity, address destAddr)
    external
    onlyOwner
    callerIsUser
    nonReentrant
  {
    require(totalSupply() + quantity <= TOTAL, 'total hit');
    _safeMint(destAddr, quantity);
  }

  ///////////////// finance /////////////////

  function withdrawAll() public onlyOwner {
    require(payable(msg.sender).send(address(this).balance), 'sent');
  }

  ///////////////// art /////////////////

  function htmlForToken(uint256 tokenId) public view returns (string memory) {
    return renderer.htmlForToken(tokenId);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    return renderer.tokenURI(tokenId);
  }

  ///////////////// utils /////////////////

  function isValidSignature(bytes32 message, bytes memory signature)
    internal
    view
    returns (bool isValid)
  {
    bytes32 signedHash = keccak256(
      abi.encodePacked('\x19Ethereum Signed Message:\n32', message)
    );
    return signedHash.recover(signature) == accessAddr;
  }
}