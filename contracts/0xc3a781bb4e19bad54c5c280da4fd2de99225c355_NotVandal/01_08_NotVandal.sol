// SPDX-License-Identifier: MIT
// Not Vandal
// 100 NFTs - free mint reserved for NBE nft owners only
// 1 per wallet
// Once vandalization is open, you can vandalize any nft of the space, you don't need to be the owner
// You can use your VandalSpray token only one time, make your choice well
//
// Thanks to Splat by Devotion for the inspiration of this contract
// https://etherscan.io/address/0x30535831e3244dc15153ce173c2803af4ee7e374

pragma solidity ^0.8.17;


 import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
 import "@openzeppelin/contracts/access/Ownable.sol";
 import "erc721a/contracts/ERC721A.sol";
 import "@openzeppelin/contracts/utils/Counters.sol";


interface OGCollectionInterface {
    function balanceOf(address owner) external view returns (uint256);
    }

contract NotVandal is ERC721A, Ownable {

  // Checks if your address has minted
  mapping(address => bool) public addressHasMinted;

  // Tracks the VandalId to the URI
  mapping(uint => string) public transformations;

  // Contract address -> token id -> bool
  mapping(address => mapping(uint => bool)) public addressTokenVandalized;

  bytes4 private ERC721InterfaceId = 0x80ac58cd;
  bytes4 private ERC1155MetadataInterfaceId = 0x0e89341c;
  uint public price = 0 ether;
  uint public vandalCount;
  uint public constant MAX_SUPPLY = 100;
  uint public constant maxMintAmountPerTx = 1;
  uint public constant maxPerWallet = 1;
  using Counters for Counters.Counter;
  mapping(address => uint) private _mintedCount;
  string public _baseTokenURI = "https://notvandal.ams3.digitaloceanspaces.com/assets/";
  address public ogContractAddress; 
  OGCollectionInterface ogContract;
  bool public mintEnabled = false;
  bool public vandalizationEnabled = false;

  // Constructor

  constructor(address _ogContractAddress) ERC721A("NotVandal", "NV") {
         ogContractAddress = _ogContractAddress;
        ogContract = OGCollectionInterface(ogContractAddress);

    _mint(msg.sender, 1);
  }

// Deployed address of original collection  0x925f7eB0Fe634702049a1344119D4046965B5C8c NBE
    
  address public withdrawAddress = 0xfF1989eEf3a78DB2F55F485423DE00B8f282e128;

  // Errors

  error AlreadyMinted();
  error AlreadyVandalized();
  error MintClosed();
  error MintedOut();
  error NoContracts();
  error MuseumSecurity();
  error WrongPrice();

  // Events

  event Setter(uint indexed vandalId, address indexed usingContractNFT, uint indexed tokenId);

  
  // Mint

  function mint() external payable {
    require(ogContract.balanceOf(msg.sender) > 0, "Don't have NFT from original collection.");
    if (msg.sender != tx.origin) revert NoContracts() ;
    if (mintEnabled == false) revert MintClosed();
    if (totalSupply() + 1 > MAX_SUPPLY) revert MintedOut();
    if (addressHasMinted[msg.sender]) revert AlreadyMinted();
    if (msg.value != price) revert WrongPrice();

    addressHasMinted[msg.sender] = true;

    _mint(msg.sender, 1);
  }

  function hasTokenBeenVandalized(address _contractAddress, uint _tokenId) view public returns (bool){
    return addressTokenVandalized[_contractAddress][_tokenId];
  }

   // Once you vandalize, you can't vandalize that piece again
  function vandalize(uint vandalSprayId, address usingContractNFT, uint usingTokenId) external { 
    // Security is everywhere, no vandalization...yet.
    if (vandalizationEnabled == false) revert MuseumSecurity();

    // Prevents a token from being re-Vandalized
    if (hasTokenBeenVandalized(usingContractNFT, usingTokenId)) revert AlreadyVandalized();

    require(ownerOf(vandalSprayId) == msg.sender, "Not your VandalSprayId");

    // ERC-721 check
    if (ERC165Checker.supportsInterface(usingContractNFT, ERC721InterfaceId)) {
      (bool success, bytes memory bytesUri) = usingContractNFT.call(
        abi.encodeWithSignature("tokenURI(uint256)", usingTokenId )
      );

      require(success, "Error getting tokenURI data");

      string memory uri = abi.decode(bytesUri, (string)); //

      transformations[vandalSprayId] = uri;
      addressTokenVandalized[usingContractNFT][usingTokenId] = true;
      unchecked { ++vandalCount; }

      emit Setter(vandalSprayId, usingContractNFT, usingTokenId);

    // ERC-1155
    } else if (ERC165Checker.supportsInterface(usingContractNFT,ERC1155MetadataInterfaceId)) {
      (bool success, bytes memory bytesUri) = usingContractNFT.call(
        abi.encodeWithSignature("uri(uint256)", usingTokenId )
      );

      require(success, "Error getting URI data");
      string memory uri = abi.decode(bytesUri, (string));

      transformations[vandalSprayId] = uri;
      addressTokenVandalized[usingContractNFT][usingTokenId] = true;
      unchecked { ++vandalCount; }

      emit Setter(vandalSprayId, usingContractNFT, usingTokenId);

    // Bayc
    } else if (usingContractNFT == 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D) {
      string memory uri = string.concat('bayc ', toString(usingTokenId));

      transformations[vandalSprayId] = uri;
      addressTokenVandalized[usingContractNFT][usingTokenId] = true;
      unchecked { ++vandalCount; }

      emit Setter(vandalSprayId, usingContractNFT, usingTokenId);

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
    return string (buffer);
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

  function setVandalizationOpen(bool _val) external onlyOwner {
    vandalizationEnabled = _val;
  }

  function setPrice(uint _wei) external onlyOwner {
    price = _wei;
  }

 function _baseURI() internal view virtual override returns (string memory) {
   return _baseTokenURI;
 }

  function setOgContractAddress(address _ogContractAddress) external onlyOwner {
    ogContractAddress = _ogContractAddress;
  }

  // Withdraw

  function withdraw() external onlyOwner {
    (bool sent, ) = payable(withdrawAddress).call{value: address(this).balance}("");
    require(sent, "Withdraw failed");
  }

}