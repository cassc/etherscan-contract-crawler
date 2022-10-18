// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { ERC721A } from "erc721a/contracts/ERC721A.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC165Checker } from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

/*
                              ',l><>l,.
                      ^_1|uUCJJJJJJUUUUUUXx>
                  :?tJLLCCCCCJJJJJJJUUUUUYY|:
               ,}XLLLLLLCCCCCJJJJJJUUUUUUYYc~     {u]"
            '+cQQLLLLLLLCCCCCJJJJJJJUUUYvx["      +nXXx~'
          .-O0QQQLLLLLLCCCCCCJJJJJUYX(,           ^|XXXXX~
         ~0ZO0QQQLLLLLLLCCCCCJJJtI'                1XXXXXXci
       IvmZZO0QQQLLLLLLLCCCj>:`             "^     1XXXXzzzzt:
      iJwmZZO0QQQLLLLLn-!"             ,]/nXY_     -vXXXzzzzzxI
    .-wwwmZZO00QLc{+:              !{jYUUYYYY_     :/XXXzzzzzzc!
   .?pqwwmZOY/}l                  :tUUUUUYYYY}`     1XXXXzzzzz|:
   +dpq0vt>             `Ii"     `1JUUUUUYYYYx!     1XXXXzzzznl
  lzc+             .,l1JCJ{      [JJUUUUUYYYYY+     [cXXzzzzzi
               '"[CLLLLCC)      ]UJUUUUUUYYYYY+     IfXXXzzz<
           `]UCLQLLLLLLLt"     ~cJJUUUUUUYYYYY?'     1XXzzz),     _,
      '-XJ0ZO0QQQLLLLLLu>     ;fJJJUUUUUUYYYYYfI     1XXzznl     ,ti
 '_vXZqwwmZZO0QQQLLLLLY]     `1JJJJUUUUUUYYYYYX~     }zXzX>      |c("
>mbbdpqwwmZZO00QQLLLLL)      ]JJJJJUUUUUUYYYYYY+     irXX+.     1ccuI
~kbddpqwwmZZO00QQQLLL/'     _YJJJJJJUUUUUYYYYYX-     .(X{"     -nzczl
~kbddpqwwmZZO0QQQLLLj:     >vJJJJJJJUUUUUYYYYYY|:     1rl     Ifzzczl
~kbddpqwwmZZO00QQLLc~     ;tCJJJJJJJUUUUUYYYYYYz~     }i     '|zzzccl
~kbddpqwwmZZO0QQQLC1     .[CCJJJJJJUUUUUUYYYYYXY+            (zzzzzzl
~kbddpqwwmmZO0QQQL|      ?CCCJJJJJJJUUUUUYYYYYXY+           {czzzzzcl
~kbddpqwwmZZO0QQQt'     _UCCCJJJJJJUUUUUUYYYYYYY),         >rzzzzzccl
~kbddpqwwmZZO0QQj,     <zCCCCJJJJJJUUUUUUYYYYYYYv>        "/zzzzzzczl
~kbddpqwwmZZO00c<     IjCCCCCJJJJJJUUUUUUYYYYYYYX~        )zzzzzzzccl
IuUOqpqwwmZZO0U[     ^1LCCCCCJJJJJJUUUUUUYYYYYXYX~       [vzzzzzzzzcl
        ^>}frr]     .]LLCCCCCJJJJJJJUUUUUUYYYYYYX?'     <xzzzzzzzzczl
                      '![fuuuucXYJJJUUUUUUYYYYXYv>     "/zzzzzzzzzczl
                                    .;?fczzzzzXX~      )zzzzzzzzzzzzl
<qqwOc1I                                     ...      1zzzzzzzzzzzzzl
~kbbdpqwwmZOQJXcvvuf]l'                              -uXXzzzzzzzzzzzl
~kbddpqqwmZZO0QQQLLLLLLLCCUznfttt(-l`               IfXXzXzzzzzzzzczl
~kbbdpqqwmmZO0QQQLLLLLLLCCCCCJJJJJJUUUUUXuf)[;     `(XXXXzzzzzzzzzzcl
~kbbdpqwwmmZO0QQQLLLLLLLCCCCCJJJJJJUUUUUUYYY-      {XXXXXXzzzzzzzzczl
"?----____++++~~~~~~~~~~<~~<<<<<<<<<<<<<<<>l`     ^!>>>>>>>>>>>>>>>>`
*/

// Contract by @backseats_eth

// Thanks to Dittos for the inspiration for some of this contract
// https://etherscan.io/address/0x18d9125f53316b32131651ebcdcd18af4984f485

contract Splat is ERC721A, Ownable {

  // Checks if your address has minted
  mapping(address => bool) public addressHasMinted;

  // Tracks the SplatId to the URI
  mapping(uint => string) public transformations;

  // Contract address -> token id -> bool
  mapping(address => mapping(uint => bool)) public addressTokenSplatted;

  bytes4 private ERC721InterfaceId = 0x80ac58cd;
  bytes4 private ERC1155MetadataInterfaceId = 0x0e89341c;

  uint public price = 0.05 ether;
  uint public splatCount;
  uint public constant MAX_SUPPLY = 1000;

  string public _baseTokenURI;

  bool mintEnabled;
  bool splatEnabled;

  address public withdrawAddress = 0xEf5C1d031F3b71c15f6DD7b2078a54c6f866DDBf;

  // Errors

  error AlreadyMinted();
  error AlreadySplatted();
  error MintClosed();
  error MintedOut();
  error NoContracts();
  error MuseumSecurity();
  error WrongPrice();

  // Events

  event Setter(uint indexed splatId, address indexed usingContractNFT, uint indexed tokenId);

  // Constructor

  constructor() ERC721A("Splat by Devotion", "SPLAT") {
    _mint(msg.sender, 1);
  }

  // Mint

  function mint() external payable {
    if (msg.sender != tx.origin) revert NoContracts();
    if (mintEnabled == false) revert MintClosed();
    if (totalSupply() + 1 > MAX_SUPPLY) revert MintedOut();
    if (addressHasMinted[msg.sender]) revert AlreadyMinted();
    if (msg.value != price) revert WrongPrice();

    addressHasMinted[msg.sender] = true;

    _mint(msg.sender, 1);
  }

  function hasTokenBeenSplatted(address _contractAddress, uint _tokenId) view public returns (bool){
    return addressTokenSplatted[_contractAddress][_tokenId];
  }

  // Once you splat, you can't splat that piece again
  function splat(uint splatId, address usingContractNFT, uint usingTokenId) external {
    // Security is everywhere, no splatting...yet.
    if (splatEnabled == false) revert MuseumSecurity();

    // Prevents a token from being re-splatted
    if (hasTokenBeenSplatted(usingContractNFT, usingTokenId)) revert AlreadySplatted();

    require(ownerOf(splatId) == msg.sender, "Not your Splat");

    // ERC-721 check
    if (ERC165Checker.supportsInterface(usingContractNFT, ERC721InterfaceId)) {
      (bool success, bytes memory bytesUri) = usingContractNFT.call(
        abi.encodeWithSignature("tokenURI(uint256)", usingTokenId)
      );

      require(success, "Error getting tokenURI data");

      string memory uri = abi.decode(bytesUri, (string));

      transformations[splatId] = uri;
      addressTokenSplatted[usingContractNFT][usingTokenId] = true;
      unchecked { ++splatCount; }

      emit Setter(splatId, usingContractNFT, usingTokenId);

    // ERC-1155
    } else if (ERC165Checker.supportsInterface(usingContractNFT,ERC1155MetadataInterfaceId)) {
      (bool success, bytes memory bytesUri) = usingContractNFT.call(
        abi.encodeWithSignature("uri(uint256)", usingTokenId)
      );

      require(success, "Error getting URI data");
      string memory uri = abi.decode(bytesUri, (string));

      transformations[splatId] = uri;
      addressTokenSplatted[usingContractNFT][usingTokenId] = true;
      unchecked { ++splatCount; }

      emit Setter(splatId, usingContractNFT, usingTokenId);

    // Punks
    } else if (usingContractNFT == 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB) {
      string memory uri = string.concat('punk ', toString(usingTokenId));

      transformations[splatId] = uri;
      addressTokenSplatted[usingContractNFT][usingTokenId] = true;
      unchecked { ++splatCount; }

      emit Setter(splatId, usingContractNFT, usingTokenId);

    } else {
      revert("Not an ERC-721 or ERC-1155");
    }
  }

  // Plucked from OpenZeppelin's Strings.sol
  function toString(uint value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT licence
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

    if (value == 0) {
        return "0";
    }
    uint temp = value;
    uint digits;
    while (temp != 0) {
        digits++;
        temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
        digits -= 1;
        buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
        value /= 10;
    }
    return string(buffer);
  }

  function promoMint(address _to, uint _count) external onlyOwner {
    if (totalSupply() + _count > MAX_SUPPLY) revert MintedOut();
    _mint(_to, _count);
  }

  function _startTokenId() internal view virtual override returns (uint) {
    return 1;
  }

  // Setters

  function setBaseURI(string calldata _baseURI) external onlyOwner {
    _baseTokenURI = _baseURI;
  }

  function setMintOpen(bool _val) external onlyOwner {
    mintEnabled = _val;
  }

  function setSplatOpen(bool _val) external onlyOwner {
    splatEnabled = _val;
  }

  function setPrice(uint _wei) external onlyOwner {
    price = _wei;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  // Withdraw

  function withdraw() external onlyOwner {
    (bool sent, ) = payable(withdrawAddress).call{value: address(this).balance}("");
    require(sent, "Withdraw failed");
  }

}