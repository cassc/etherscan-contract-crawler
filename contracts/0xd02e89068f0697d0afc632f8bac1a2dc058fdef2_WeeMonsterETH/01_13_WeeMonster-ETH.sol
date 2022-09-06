// SPDX-License-Identifier: MIT

//           _______  _______  _______  _______  _        _______ _________ _______  _______ 
// |\     /|(  ____ \(  ____ \(       )(  ___  )( (    /|(  ____ \\__   __/(  ____ \(  ____ )
// | )   ( || (    \/| (    \/| () () || (   ) ||  \  ( || (    \/   ) (   | (    \/| (    )|
// | | _ | || (__    | (__    | || || || |   | ||   \ | || (_____    | |   | (__    | (____)|
// | |( )| ||  __)   |  __)   | |(_)| || |   | || (\ \) |(_____  )   | |   |  __)   |     __)
// | || || || (      | (      | |   | || |   | || | \   |      ) |   | |   | (      | (\ (   
// | () () || (____/\| (____/\| )   ( || (___) || )  \  |/\____) |   | |   | (____/\| ) \ \__
// (_______)(_______/(_______/|/     \|(_______)|/    )_)\_______)   )_(   (_______/|/   \__/
                                                                                          

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract WeeMonsterETH is Ownable, ERC721Enumerable {
  using Strings for uint256;
  address validator = 0x3EF9DE374Bd67217CA74edb1080C61443cA8eE31;

  uint256 constant ORDINARY_MINT_PRICE = 0 ether;
  uint256 constant GOLDEN_MINT_PRICE = 0.04 ether;
  uint256 constant DIAMOND_MINT_PRICE = 0.1 ether;

  uint256 internal devMintMount = 500;
  uint256 public maxSupply = 12000;

  uint256 OrdinaryMinted;
  uint256 GoldenMinted;
  uint256 DiamondMinted;
  uint256 DevMinted;

  bool public saleStart;

  bool private _blindBoxOpened = false;
  string private _blindTokenURI =
      "https://ipfsgateway.weelink.store/ipfs/QmZZesGiwH5RhmpAuTehD7Q7QHqZqjKDfmtQQ8MHBRphs2/box.json";

  address public BRIDGE;
  constructor() ERC721 ("WeeMonster", "WEEMONSTER") {
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "NOT_EOA");
    _;
  }

  modifier mintOpen() {
    require(saleStart, "NOT_OPEN");
    _;
  }

  modifier onlyBridge() {
    require(msg.sender == BRIDGE, "NOT_BRIDGE");
    _;
  }

  function totalSupply() public view override returns (uint256) {
    return OrdinaryMinted + GoldenMinted + DiamondMinted + DevMinted;
  }

  function mintInfo() public view returns (uint256, uint256, uint256) {
    return (OrdinaryMinted, GoldenMinted, DiamondMinted);
  }

  function ordinaryMint(uint256[] memory tokenIds, uint256 expiredTime, bytes memory proof) external callerIsUser mintOpen {
    require(tokenIds[tokenIds.length - 1] < 6000);
    require(_isValidProof(tokenIds, expiredTime, proof), "Invalid proof");
    require(expiredTime >= block.timestamp, "Proof expired");
    require(totalSupply() + tokenIds.length <= maxSupply);
    for (uint256 i = 0; i < tokenIds.length; i++) {
      _safeMint(msg.sender, tokenIds[i]);
    }
    OrdinaryMinted += tokenIds.length;
  }

  function goldenMint(uint256[] memory tokenIds, uint256 expiredTime, bytes memory proof) external payable callerIsUser mintOpen {
    require(tokenIds[tokenIds.length - 1] < 10000);
    require(_isValidProof(tokenIds, expiredTime, proof), "Invalid proof");
    require(expiredTime >= block.timestamp, "Proof expired");
    require(totalSupply() + tokenIds.length <= maxSupply);
    if (msg.sender != owner()) {
      uint256 totalCost = GOLDEN_MINT_PRICE * tokenIds.length;
      refundIfOver(totalCost);
    } else {
      DevMinted += tokenIds.length; 
      require(DevMinted <= devMintMount, "DEVMINT TOO MUCH");
    }
    for (uint256 i = 0; i < tokenIds.length; i++) {
      _safeMint(msg.sender, tokenIds[i]);
    }    
    GoldenMinted += tokenIds.length;
  }

  function diamondMint(uint256[] memory tokenIds, uint256 expiredTime, bytes memory proof) external payable callerIsUser mintOpen {
    require(tokenIds[tokenIds.length - 1] < 12000);
    require(_isValidProof(tokenIds, expiredTime, proof), "Invalid proof");
    require(expiredTime >= block.timestamp, "Proof expired");
    require(totalSupply() + tokenIds.length <= maxSupply);
    if (msg.sender != owner()) {
      uint256 totalCost = DIAMOND_MINT_PRICE * tokenIds.length;
      refundIfOver(totalCost);
    } else {
      DevMinted += tokenIds.length; 
      require(DevMinted <= devMintMount, "DEVMINT TOO MUCH");
    }
    for (uint256 i = 0; i < tokenIds.length; i++) {
      _safeMint(msg.sender, tokenIds[i]);
    }
    DiamondMinted += tokenIds.length;
  }

  //For Ethereum<->Ethereum CrossChainBridge
  function mint(address to, uint256 tokenId) public onlyBridge {
    _safeMint(to, tokenId);
  }

  function refundIfOver(uint256 price) private {
    require(msg.value >= price, "NEED_PAY_MORE");
    if (msg.value > price) {
      payable(msg.sender).transfer(msg.value - price);
    }
  }

  function withdraw() public onlyOwner {
      uint256 balance = address(this).balance;
      payable(msg.sender).transfer(balance);
  }

  function transferFrom(address from, address to, uint256 tokenId) public override {
    if (!_exists(tokenId) && msg.sender == BRIDGE) {
      _safeMint(to, tokenId);
    } else if (_isApprovedOrOwner(msg.sender, tokenId)) {
      _transfer(from, to, tokenId);
		} else {
			revert("Not owner and not approved");
		}
  }

  //metadata URI
  string private _baseTokenURI;
  string private _metaExt = ".json";

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function _metaDataExt() internal view  returns (string memory) {
    return _metaExt;
  }

  function setMetaDataExt(string memory metadataExt) external onlyOwner {
    _metaExt = metadataExt;
  }

  function setSaleStart(bool isStart) external onlyOwner {
    saleStart = isStart;
  }

  function setDevMintMount(uint256 mount) external onlyOwner {
    require(mount <= maxSupply, "Too many dev mint");
    devMintMount = mount;
  }

  function setBridge(address bridge) external onlyOwner {
    BRIDGE = bridge;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function setBlindBoxOpen(bool status) external onlyOwner {
    _blindBoxOpened = status;
  }

  function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (_blindBoxOpened) {
            string memory baseURI = _baseURI();
            string memory metaExt = _metaDataExt();
            return
                bytes(baseURI).length > 0
                    ? string(
                        abi.encodePacked(baseURI, tokenId.toString(), metaExt)
                    )
                    : "";
        } else {
            return _blindTokenURI;
        }
    }

  function holderNFTList(address account) public view returns (uint256[] memory) {
    uint256 balance = balanceOf(account);
    uint256[] memory holderNFTs = new uint256[](balance);
    for (uint256 i = 0; i < balance; i++) {
        uint256 tokenId = tokenOfOwnerByIndex(account, i);
        holderNFTs[i] = tokenId;
    }
    return holderNFTs;
  }

  function _isValidProof(uint256[] memory tokenIds, uint256 expireTime, bytes memory proof) internal view returns (bool) {
    bytes32 hash = keccak256(
                  abi.encodePacked(
                      block.chainid,
                      tokenIds,
                      expireTime
                  )
              );
    return _ecrecovery(hash, proof) == validator;
  }

  function getProof(uint256[] memory tokenIds) public view returns (bytes32, bytes memory) {
    return (keccak256(
                  abi.encodePacked(
                      block.chainid,
                      tokenIds
                  )
              ), abi.encodePacked(
                      block.chainid,
                      tokenIds
                  ));
  }

  function _ecrecovery(bytes32 hash, bytes memory sig) internal pure returns (address)
  {
      bytes32 r;
      bytes32 s;
      uint8 v;

      if (sig.length != 65) {
        return address(0);
      }

      assembly {
        r := mload(add(sig, 32))
        s := mload(add(sig, 64))
        v := and(mload(add(sig, 65)), 255)
      }

      // https://github.com/ethereum/go-ethereum/issues/2053
      if (v < 27) {
        v += 27;
      }

      if (v != 27 && v != 28) {
        return address(0);
      }

      /* prefix might be needed for geth only
      * https://github.com/ethereum/go-ethereum/issues/3731
      */
      // bytes memory prefix = "\x19Ethereum Signed Message:\n32";
      // hash = sha3(prefix, hash);

      return ecrecover(hash, v, r, s);
  }
}