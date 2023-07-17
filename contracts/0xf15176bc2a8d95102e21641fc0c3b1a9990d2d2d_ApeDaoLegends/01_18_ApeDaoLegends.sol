// ..........................................................................
// ..........................................................................
// ..........................................................................
// ..........................................................................
// ..........................*&&&&&,........&&&&&&...........................
// .....................,(....&&&&&(.......&&*..,&&..........................
// .................,&&/.&&....&&&&#.........&&&&&...,&&&&&&.................
// ...................&&&.........................../&#&&&&..................
// ....................#&............***.***.............&&....,.............
// ...........&&&&&&&&...............***.***................*&&&*&&..........
// ............&&&&..........................................&&...&&.........
// .............&&.......&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&%......,&&&&..........
// ....................&&&&&.....,*#&&&&&&&&&#*,.....&&&&%...................
// ....................&&&............&&&&&...........,&&&...................
// ...................&&&&............,&&&,............&&&&..................
// ...................&&&&%........*%&&&&&&&#*........&&&&&..................
// ...................&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&..................
// ..............,......&&&&&&&&%&&&&&&...&&&&&&%&&&&&&&&......*.............
// ...............*.............&&&&&.......&&&&&............**..............
// ...............,**..........&&&&%....&....&&&&&.........***...............
// ................****........&&&&&&&&&&&&&&&&&&&.......****................
// ...............*******.......&&&&&&&&&&&&&&&&&......,******...............
// .................****.......&&&&&&,(&&&&*&&&&&&......****.................
// ..................****..............................****..................
// ..................******.....&&&.*&&&&&&&.,&&&....******..................
// .....................**.......&&&&&&&&&&&&&&&......**.....................
// .......................**......&&&&&&&&&&&&&.....**.......................
// ..................................#&&&&&(.................................
// ..........................................................................
// ....................................***...................................
// ..........................................................................
// ..........................................................................

/*

      ,.  ;-.  ,--.   ,-.   ,.   ,-.
     /  \ |  ) |      |  \ /  \ /   \
     |--| |-'  |-     |  | |--| |   |
     |  | |    |      |  / |  | \   /
     '  ' '    `--'   `-'  '  '  `-'

       ,                      .
       |                      |
       |    ,-. ,-: ,-. ;-. ,-| ,-.
       |    |-' | | |-' | | | | `-.
       `--' `-' `-| `-' ' ' `-' `-'
                `-'
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ApeDaoLegends is ERC1155, ERC1155Burnable, ERC1155Supply, Ownable, Pausable, ReentrancyGuard {
  using Strings for uint256;
  using Counters for Counters.Counter;
  Counters.Counter private tokenCounter;

  address public mintTokenAddress;
  ERC1155Burnable mintToken = ERC1155Burnable(mintTokenAddress);

  struct Token {
    uint256 mintPrice;
    uint256 maxSupply;
    uint256 maxTransactionLimit;
    string name;
    uint256 mintTokenRequired;
    mapping(address => uint256) claimed;
  }

  mapping(uint256 => Token) public tokens;

  bytes32 public currentMerkleRoot;
  string public baseURI;

  mapping(uint256 => string) public tokenName;

  constructor(string memory _baseURI) ERC1155(_baseURI) {
    baseURI = _baseURI;
    pauseSale(); // Start paused
  }

  function uri(uint256 _tokenId) public view override returns (string memory) {
    require(_tokenId <= tokenCounter.current(), "URI requested for invalid token");
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, _tokenId.toString()))
        : baseURI;
  }

  /* Minting */

  function mintLegends(uint256[] memory _tokenIds, uint256[] memory _quantities, bytes32[] calldata _proof) public payable whenNotPaused nonReentrant {
    require(_tokenIds.length == _quantities.length);
    if (currentMerkleRoot != 0) {
      require(verify(leaf(msg.sender, _tokenIds, _quantities), _proof), "Invalid merkle proof");
    }

    uint256 txCost = 0;
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      txCost += tokens[_tokenIds[i]].mintPrice * _quantities[i];
    }
    require(txCost <= msg.value, "Not enough ETH");

    for (uint256 i = 0; i < _tokenIds.length; i++) {
      uint256 mintTokenRequired = tokens[_tokenIds[i]].mintTokenRequired;
      if (mintTokenRequired > 0) {
        require(mintToken.balanceOf(msg.sender, mintTokenRequired) >= 1, "Must own a mint token");
        mintToken.burn(msg.sender, mintTokenRequired, 1);
      }

      mintInternal(msg.sender, _tokenIds[i], _quantities[i]);
    }
  }

  function ownerMint(address _to, uint256 _tokenId, uint256 _quantity) public onlyOwner {
    mintInternal(_to, _tokenId, _quantity);
  }

  function mintInternal(address _account, uint256 _tokenId, uint256 _quantity) internal {
    require(_tokenId <= tokenCounter.current(), "Token not created yet");
    require(totalSupply(_tokenId) + _quantity <= tokens[_tokenId].maxSupply, "Not enough left");
    require(tokens[_tokenId].maxTransactionLimit == 0 || _quantity <= tokens[_tokenId].maxTransactionLimit);

    if (currentMerkleRoot != 0) {
      require(tokens[_tokenId].claimed[_account] == 0);
      tokens[_tokenId].claimed[_account] = _quantity;
    }

    _mint(_account, _tokenId, _quantity, "");
  }

  /* Merkle Tree Helper Functions */

  function leaf(address _account, uint256[] memory _tokenIds, uint256[] memory _quantities) internal pure returns (bytes32) {
    bytes memory concatResult = abi.encodePacked(_account);
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      concatResult = abi.encodePacked(concatResult, ',');
      concatResult = abi.encodePacked(concatResult, _tokenIds[i]);
      concatResult = abi.encodePacked(concatResult, ',');
      concatResult = abi.encodePacked(concatResult, _quantities[i]);
    }
    return keccak256(concatResult);
  }

  function verify(bytes32 _leaf, bytes32[] memory _proof) internal view returns (bool) {
    return MerkleProof.verify(_proof, currentMerkleRoot, _leaf);
  }

  /* Owner Functions */

  function addToken(uint256 _mintPrice, uint256 _maxSupply, uint256 _mintTokenRequired, uint256 _maxTransactionLimit, string memory _name) public onlyOwner {
    require(_mintTokenRequired <= 3);

    tokenCounter.increment();

    Token storage token = tokens[tokenCounter.current()];
    token.mintPrice = _mintPrice;
    token.maxSupply = _maxSupply;
    token.maxTransactionLimit = _maxTransactionLimit;
    token.name = _name;
    token.mintTokenRequired = _mintTokenRequired;
  }

  function editToken(uint256 _tokenIndex, uint256 _mintPrice, uint256 _mintTokenRequired, uint256 _maxTransactionLimit) public onlyOwner {
    require(exists(_tokenIndex));
    require(_mintTokenRequired <= 3);

    tokens[_tokenIndex].mintPrice = _mintPrice;
    tokens[_tokenIndex].maxTransactionLimit = _maxTransactionLimit;
    tokens[_tokenIndex].mintTokenRequired = _mintTokenRequired;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    currentMerkleRoot = _merkleRoot;
  }

  function setMintTokenAddress(address _address) public onlyOwner {
    mintTokenAddress = _address;
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
    Address.sendValue(payable(0xA7Ab7a265F274FA664187698932D3CaBb851023d), address(this).balance);
  }

  function withdrawTokens(IERC20 token) public onlyOwner {
		require(address(token) != address(0));
		token.transfer(_msgSender(), token.balanceOf(address(this)));
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