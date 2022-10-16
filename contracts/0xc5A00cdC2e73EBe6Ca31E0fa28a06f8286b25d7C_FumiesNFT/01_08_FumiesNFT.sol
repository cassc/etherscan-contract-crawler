import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import 'erc721a/contracts/ERC721A.sol';

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

contract FumiesNFT is Ownable, ERC721A, ReentrancyGuard, Pausable {
  using SafeMath for uint256;

  bool public isURIFrozen = false;

  string public baseURI = 'https://mint.fumies.io/meta/';

  uint256 public constant MAX_SUPPLY = 4444;

  uint256 public constant MAX_MINT_SUPPLY = 3694;

  uint256 public constant MAX_AIRDROP = 750;

  uint256 public airdrop_count = 0;

  uint256 public mint_count = 0;

  bool public publicMint = false;

  bool public aLMint = false;

  uint256 public constant MINT_PRICE = 0.15 ether;

  uint256 public constant WL_MINT_PRICE = 0.1 ether;

  uint256 public constant WL_MAX_MINT = 4;

  address public verifier = 0x5D17B9c69f458a435a406Cd533E72Ff58F71d7e1;

  constructor() ERC721A('Fumies NFT', 'FUMIES') {}

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function toggleURI() external onlyOwner {
    isURIFrozen = !isURIFrozen;
  }

  function setBaseURI(string calldata newURI) external onlyOwner {
    require(!isURIFrozen, 'URI is Frozen');
    baseURI = newURI;
  }

  function setVerifier(address _verifier) external onlyOwner {
    verifier = _verifier;
  }

  function toggleAL() external onlyOwner {
    aLMint = !aLMint;
  }

  function togglePublicMint() external onlyOwner {
    publicMint = !publicMint;
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function fumiesPublicMint(uint256 tokenQuantity) external payable nonReentrant {
    require(publicMint, 'Public mint disabled');
    require(totalSupply() < MAX_SUPPLY, 'Sold Out!');
    require(mint_count < MAX_MINT_SUPPLY, 'Sold Out!');
    require(mint_count + tokenQuantity <= MAX_MINT_SUPPLY, 'Quantity Less than Available');
    require(MINT_PRICE * tokenQuantity <= msg.value, 'Insufficient Eth');
    _safeMint(msg.sender, tokenQuantity);
    mint_count++;
  }

  function allowListMint(
    uint256 tokenQuantity,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external payable nonReentrant {
    require(aLMint, 'Allowlist mint disabled');
    require(totalSupply() < MAX_SUPPLY, 'Sold Out!');
    require(mint_count < MAX_MINT_SUPPLY, 'Sold Out!');
    require(mint_count + tokenQuantity <= MAX_MINT_SUPPLY, 'Quantity Less than Available');
    require(tokenQuantity <= WL_MAX_MINT, 'You can only mint 4');
    require(balanceOf(msg.sender) + tokenQuantity <= WL_MAX_MINT, 'You can only mint 4');
    require(WL_MINT_PRICE * tokenQuantity <= msg.value, 'Insufficient Eth');
    address addr2;
    addr2 = ecrecover(keccak256(abi.encodePacked('\x19Ethereum Signed Message:\n20', msg.sender)), v, r, s);
    require(addr2 == verifier, 'Unauthorised for Allow list');
    _safeMint(msg.sender, tokenQuantity);
    mint_count++;
  }

  function fumiesAirdrop(address[] memory recepients) external onlyOwner {
    require(totalSupply() < MAX_SUPPLY, 'Sold Out!');
    require(airdrop_count < MAX_AIRDROP, 'All Airdropped!');
    require(airdrop_count + recepients.length <= MAX_AIRDROP, 'Too many recipients for available Airdrop!');
    for (uint256 i = 0; i < recepients.length; i++) {
      _safeMint(recepients[i], 1);
      airdrop_count++;
    }
  }

  function withdrawAll(address treasury) external payable onlyOwner {
    require(payable(treasury).send(address(this).balance));
  }
}