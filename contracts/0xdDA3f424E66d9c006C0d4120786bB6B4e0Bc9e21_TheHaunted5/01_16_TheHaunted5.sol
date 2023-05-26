/*

'########:'##::::'##:'########::::'##::::'##::::'###::::'##::::'##:'##::: ##:'########:'########:'########:::::'########:
... ##..:: ##:::: ##: ##.....::::: ##:::: ##:::'## ##::: ##:::: ##: ###:: ##:... ##..:: ##.....:: ##.... ##:::: ##.....::
::: ##:::: ##:::: ##: ##:::::::::: ##:::: ##::'##:. ##:: ##:::: ##: ####: ##:::: ##:::: ##::::::: ##:::: ##:::: ##:::::::
::: ##:::: #########: ######:::::: #########:'##:::. ##: ##:::: ##: ## ## ##:::: ##:::: ######::: ##:::: ##:::: #######::
::: ##:::: ##.... ##: ##...::::::: ##.... ##: #########: ##:::: ##: ##. ####:::: ##:::: ##...:::: ##:::: ##::::...... ##:
::: ##:::: ##:::: ##: ##:::::::::: ##:::: ##: ##.... ##: ##:::: ##: ##:. ###:::: ##:::: ##::::::: ##:::: ##::::'##::: ##:
::: ##:::: ##:::: ##: ########:::: ##:::: ##: ##:::: ##:. #######:: ##::. ##:::: ##:::: ########: ########:::::. ######::
:::..:::::..:::::..::........:::::..:::::..::..:::::..:::.......:::..::::..:::::..:::::........::........:::::::......:::

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TheHaunted5 is ERC1155, ERC1155Burnable, ERC1155Supply, Ownable, Pausable, ReentrancyGuard {
  using Strings for uint256;

  bytes32 public currentMerkleRoot;
  string public baseURI;

  uint256 internal MAX_TOKEN_COUNT = 77;
  uint256 internal SUPPLY_PER_MINTABLE_TOKEN = 20;
  uint256 internal SUPPLY_PER_CHALLENGE_TOKEN = 21;
  uint256[] internal mintableTokens = [36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70];
  uint256 public constant mintPrice = 100000000000000000; // 0.1 ETH
  mapping(address => uint256) public numberOfTokensMinted;

  constructor(string memory _baseURI) ERC1155(_baseURI) {
    baseURI = _baseURI;
    pauseSale(); // Start paused
  }

  function uri(uint256 _tokenId) public view override returns (string memory) {
    require(_tokenId > 0 && _tokenId <= MAX_TOKEN_COUNT, "URI requested for invalid token");
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, _tokenId.toString()))
        : baseURI;
  }

  function totalMinted() public view returns (uint256) {
    uint256 total = 0;
    for (uint256 i = 1; i <= MAX_TOKEN_COUNT; i++) {
      total += totalSupply(i);
    }
    return total;
  }

  /* Allowlist */

  bool public allowlistMintingActive = false;

  function toggleAllowlistMintingActive() public onlyOwner {
    allowlistMintingActive = !allowlistMintingActive;
  }

  function allowlistMint(bytes32[] calldata _proof) public payable nonReentrant {
    require(allowlistMintingActive, "Sale not active");
    require(numberOfTokensMinted[msg.sender] == 0, "Already minted");
    require(verify(leaf(msg.sender), _proof), "Invalid merkle proof");
    require(mintPrice <= msg.value, "Not enough ETH");

    uint256 seed = uint256(keccak256(abi.encodePacked(_proof[0], block.difficulty, block.timestamp, msg.sender)));
    uint256 tokenIndex = seed % mintableTokens.length;
    uint256 tokenId = mintableTokens[tokenIndex];

    if (totalSupply(tokenId) + 1 == SUPPLY_PER_MINTABLE_TOKEN) {
      // Remove from array of mintable tokens
      mintableTokens[tokenIndex] = mintableTokens[mintableTokens.length - 1];
      mintableTokens.pop();
    }

    numberOfTokensMinted[msg.sender] = 1;
    mintInternal(msg.sender, tokenId, 1);
  }

  /* Main and Owner Minting */

  function mint() public payable whenNotPaused nonReentrant {
    require(numberOfTokensMinted[msg.sender] == 0, "Already minted");
    require(mintPrice <= msg.value, "Not enough ETH");

    uint256 seed = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, msg.sender)));
    uint256 tokenIndex = seed % mintableTokens.length;
    uint256 tokenId = mintableTokens[tokenIndex];

    if (totalSupply(tokenId) + 1 == SUPPLY_PER_MINTABLE_TOKEN) {
      // Remove from array of mintable tokens
      mintableTokens[tokenIndex] = mintableTokens[mintableTokens.length - 1];
      mintableTokens.pop();
    }

    numberOfTokensMinted[msg.sender] = 1;
    mintInternal(msg.sender, tokenId, 1);
  }

  function ownerMint(address _to, uint256 _tokenId, uint256 _quantity) public onlyOwner {
    mintInternal(_to, _tokenId, _quantity);
  }

  function hauntedFirstM1nt(address _to, uint256 _startTokenId) public onlyOwner {
    require(_startTokenId > 0 && _startTokenId <= 5);

    mintInternal(_to, _startTokenId, 1);
    mintInternal(_to, _startTokenId + 5, 1);
    mintInternal(_to, _startTokenId + 10, 1);
    mintInternal(_to, _startTokenId + 15, 1);
    mintInternal(_to, _startTokenId + 20, 1);
    mintInternal(_to, _startTokenId + 25, 1);
    mintInternal(_to, _startTokenId + 30, 1);
  }

  event TokenMinted(
    address account,
    uint256 tokenId,
    uint256 quantity
  );

  function mintInternal(address _account, uint256 _tokenId, uint256 _quantity) internal {
    require(_tokenId > 0 && _tokenId <= MAX_TOKEN_COUNT, "Not a valid token");
    if (_tokenId <= 35) {
      require(totalSupply(_tokenId) + _quantity <= 1, "Not enough left");
    } else if (_tokenId <= 70) {
      require(totalSupply(_tokenId) + _quantity <= SUPPLY_PER_MINTABLE_TOKEN, "Not enough left");
    } else {
      require(totalSupply(_tokenId) + _quantity <= SUPPLY_PER_CHALLENGE_TOKEN, "Not enough left");
    }

    _mint(_account, _tokenId, _quantity, "");

    emit TokenMinted(_account, _tokenId, _quantity);
  }

  /* Merkle Tree Helper Functions */

  function leaf(address _account) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_account));
  }

  function verify(bytes32 _leaf, bytes32[] memory _proof) internal view returns (bool) {
    return MerkleProof.verify(_proof, currentMerkleRoot, _leaf);
  }

  /* Owner Functions */

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    currentMerkleRoot = _merkleRoot;
  }

  function pauseSale() public onlyOwner {
    _pause();
  }

  function unpauseSale() public onlyOwner {
    _unpause();
  }

  function setBaseURI(string memory _baseURI) public onlyOwner {
    baseURI = _baseURI;
  }

  function withdraw() public onlyOwner {
    Address.sendValue(payable(0x8Dc6c6732E25C2D6d12B5dAb20093c07ba299006), address(this).balance);
  }

  receive() external payable {}

  /* Overrides */

  function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal override(ERC1155, ERC1155Supply) {
    super._mint(account, id, amount, data);
  }

  function _mintBatch(address account, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override(ERC1155, ERC1155Supply) {
    super._mintBatch(account, ids, amounts, data);
  }

  function _burn(address account, uint256 id, uint256 amount) internal override(ERC1155, ERC1155Supply) {
    super._burn(account, id, amount);
  }

  function _burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) internal override(ERC1155, ERC1155Supply) {
    super._burnBatch(account, ids, amounts);
  }
}

/* Contract by: _            _       _             _
   ____        | |          (_)     | |           | |
  / __ \   ___ | |__   _ __  _  ___ | |__    ___  | |
 / / _` | / __|| '_ \ | '__|| |/ __|| '_ \  / _ \ | |
| | (_| || (__ | | | || |   | |\__ \| | | || (_) || |
 \ \__,_| \___||_| |_||_|   |_||___/|_| |_| \___/ |_|
  \____/  */