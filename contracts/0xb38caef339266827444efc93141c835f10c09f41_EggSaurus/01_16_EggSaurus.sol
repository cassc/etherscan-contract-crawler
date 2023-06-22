//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IImage {
  function generateSVG(uint256 id, uint256 saurusItem, uint256 saurusCollar) external view returns(string memory);
  function generateEggSVG() external view returns(string memory);
}

interface ICoin is IERC20{
  function burn(uint256 amount) external;
}

contract EggSaurus is ERC721, ERC721Enumerable, Ownable {
  using Counters for Counters.Counter;
  using SafeMath for uint256;

  uint256 private constant _FEED_PRICE = 60 * (10 ** 18);
  uint256 private constant _REVIVE_PRICE = 500 * (10 ** 18);
  uint256 private constant _ITEM_PRICE = 100 * (10 ** 18);
  uint256 private constant _COLLAR_PRICE = 300 * (10 ** 18);
  uint256 private constant _ETERNAL_PRICE = 10000 * (10 ** 18);
  
  mapping(address => uint) public whitelistRemaining;
  mapping(address => bool) public whitelistUsed;
  uint256 public saleStart;
  uint256 public whitelistSaleStart;
  address public devAddress = 0x55C650B9b3F15596932fFd5f046bA1bd2E6B3dD4;
  uint256 public salePrice = 0.06 * (10 ** 18);
  uint256 public maxSupply = 3333;

  Counters.Counter private _tokenIdCounter;
  mapping (uint256 => uint256) private _birth;
  mapping (uint256 => uint256) private _feed;
  mapping (uint256 => uint256) private _item;
  mapping (uint256 => uint256) private _collar;
  mapping (uint256 => uint256) private _eternal;
  bytes32 private _merkleRoot;
  uint256 private _randomNum;
  address private _coinAddress;
  address private _imageAddress;

  event Feed(uint256 indexed tokenId);

  constructor(string memory tokenName, string memory tokenSymbol) ERC721(tokenName, tokenSymbol) {}

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
      require(_exists(tokenId));
      string memory svgData = returnImage(tokenId);
      string memory json = Base64.encode(bytes(string(abi.encodePacked(
        '{"name": "EggSaurus #',
        uint2str(tokenId),
        '","image_data": "',
        bytes(svgData),
        '","attributes": [{"trait_type": "Age","value": ',
        uint2str(returnAge(tokenId)),
        '},{"trait_type": "Virus","value": ',
        uint2str(returnVirusNum(tokenId)),
        '}]}'
      ))));
      return string(abi.encodePacked('data:application/json;base64,', json));
  }

  function feed(uint256 tokenId) external {
    require(_msgSender() == ownerOf(tokenId));
    require(_isAlive(tokenId), "dead");
    ICoin(_coinAddress).transferFrom(msg.sender, address(this), _FEED_PRICE);

    _feed[tokenId] = block.timestamp;
    ICoin(_coinAddress).burn(_FEED_PRICE);

    emit Feed(tokenId);
  }

  function revive(uint256 tokenId) external {
    require(_msgSender() == ownerOf(tokenId));
    require(_isAlive(tokenId) == false, "alive");

    ICoin(_coinAddress).transferFrom(msg.sender, address(this), _REVIVE_PRICE);

    _birth[tokenId] = block.timestamp;
    ICoin(_coinAddress).burn(_REVIVE_PRICE);
  }

  function buyItem(uint256 tokenId) external {
    require(_msgSender() == ownerOf(tokenId));
    require(_isAlive(tokenId), "dead");

    ICoin(_coinAddress).transferFrom(msg.sender, address(this), _ITEM_PRICE);

    _item[tokenId] = block.timestamp + (block.number % 8);
    ICoin(_coinAddress).burn(_ITEM_PRICE);
  }

  function buyCollar(uint256 tokenId) external {
    require(_msgSender() == ownerOf(tokenId));
    require(_isAlive(tokenId), "dead");

    ICoin(_coinAddress).transferFrom(msg.sender, address(this), _COLLAR_PRICE);

    _collar[tokenId] = block.timestamp + (block.number % 6);
    ICoin(_coinAddress).burn(_COLLAR_PRICE);
  }

  function giveEternalLife(uint256 tokenId) external {
    require(_msgSender() == ownerOf(tokenId));
    require(returnAge(tokenId) >= 3000, "invalid");

    ICoin(_coinAddress).transferFrom(msg.sender, address(this), _ETERNAL_PRICE);

    _eternal[tokenId] = block.timestamp;
    ICoin(_coinAddress).burn(_ETERNAL_PRICE);
  }

  function returnVirusNum(uint256 tokenId) public view returns (uint256) {
    require(_exists(tokenId));

    uint256 lastFeed = _feed[tokenId];

    if (lastFeed == 0 || lastFeed <= _birth[tokenId]) {
      lastFeed = _birth[tokenId];
    }

    if(_eternal[tokenId] == 0){
      return (block.timestamp - lastFeed).div(24 * 60 * 60);
    }else{
      return 0;
    }
  }

  function returnIsAlive(uint256 tokenId) external view returns (bool) {
    require(_exists(tokenId));

    return _isAlive(tokenId);
  }

  function returnAge(uint256 tokenId) public view returns (uint256) {
    require(_exists(tokenId));

    if (_isAlive(tokenId)) {
      return (block.timestamp - _birth[tokenId]).div(24 * 60 * 60);
    } else {
      return 0;
    }
  }

  function mintNFT(uint256 nftNum, address toAddress) external payable {
    require(_tokenIdCounter.current().add(nftNum) <= maxSupply, "Exceeds");
    require(nftNum > 0 && nftNum <= 20, "invalid");
    
    // skip for giveaway
    if (msg.sender != owner()) {
      require(saleStart != 0 && block.timestamp > saleStart, "yet");
      require(salePrice.mul(nftNum) == msg.value, "incorrect eth");
    }

    for (uint256 i = 0; i < nftNum; i++) {
      uint256 tokenId = _tokenIdCounter.current() + 1;
      if(msg.sender == owner()) {
        _safeMint(toAddress, tokenId);
      }else{
        _safeMint(msg.sender, tokenId);
      }
      _birth[tokenId] = block.timestamp;
      _tokenIdCounter.increment();
    }
  }

  function whitelistMint(uint256 nftNum, uint256 totalAllocation, bytes32 leaf, bytes32[] memory proof) external payable {
    require(whitelistSaleStart != 0 && block.timestamp > whitelistSaleStart , "yet");

    if(!whitelistUsed[msg.sender]){        
      require(keccak256(abi.encodePacked(msg.sender, totalAllocation)) == leaf, "invalid");
      require(MerkleProof.verify(proof, _merkleRoot, leaf), "invalid");

      whitelistUsed[msg.sender] = true;
      whitelistRemaining[msg.sender] = totalAllocation;
    }
    
    require(nftNum > 0);
    require(salePrice.mul(nftNum) == msg.value, "incorrect eth");
    require(_tokenIdCounter.current().add(nftNum) <= maxSupply, "Exceeds");
    require(whitelistRemaining[msg.sender] >= nftNum, "Exceeds");
    
    for (uint256 i = 0; i < nftNum; i++) {
      whitelistRemaining[msg.sender] -= 1;
      uint256 tokenId = _tokenIdCounter.current() + 1;
      _safeMint(msg.sender, tokenId);
      _birth[tokenId] = block.timestamp;
      _tokenIdCounter.increment();
    }
  }

  function setAddresses(address coinAddress_, address imageAddress_, address devAddress_) external onlyOwner {
    _coinAddress = coinAddress_;
    _imageAddress = imageAddress_;
    devAddress = devAddress_;
  }

  function _isAlive(uint256 tokenId) internal view returns(bool) {
    if(_eternal[tokenId] == 0) {
      return returnVirusNum(tokenId) <= 60;
    }
    return true;
  }

  function returnImage(uint256 tokenId) public view returns (string memory) {
    require(_exists(tokenId));

    if(_isAlive(tokenId) != true || _randomNum == 0) {
      return IImage(_imageAddress).generateEggSVG();
    }

    // reset item and collar if EggSaurus died
    uint256 item = _item[tokenId];
    if(item < _birth[tokenId]){
      item = 0;
    }

    uint256 collar = _collar[tokenId];
    if(collar < _birth[tokenId]){
      collar = 0;
    }

    return IImage(_imageAddress).generateSVG((_randomNum - 1).mul(1000).add(tokenId), item, collar);
  }

  function makeRandomNum() external onlyOwner{
    require(_randomNum == 0);
    _randomNum = block.timestamp % 3 + 1;
  }

  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0);
    (bool success, ) = devAddress.call{value: address(this).balance}("");
    require(success);
  }

  function setMerkleRootAndSaleTime(bytes32 merkleRoot_, uint256 whitelistSaleStart_, uint256 saleStart_, uint256 price_, uint256 maxSupply_) public onlyOwner {
      // max of maxSupply is 3333.
      require(maxSupply_ <= 3333);

      _merkleRoot = merkleRoot_;
      whitelistSaleStart = whitelistSaleStart_;
      saleStart = saleStart_;
      salePrice = price_;
      maxSupply = maxSupply_;
  }

  function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
    if (_i == 0) {
        return "0";
    }
    uint j = _i;
    uint len;
    while (j != 0) {
        len++;
        j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint k = len;
    while (_i != 0) {
        k = k-1;
        uint8 temp = (48 + uint8(_i - _i / 10 * 10));
        bytes1 b1 = bytes1(temp);
        bstr[k] = b1;
        _i /= 10;
    }
    return string(bstr);
  }
}

library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}