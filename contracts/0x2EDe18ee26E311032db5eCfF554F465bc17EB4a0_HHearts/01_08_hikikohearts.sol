// SPDX-License-Identifier: Unlicensed

/*
//                                               .-'''-.                                                                                     
//                                              '   _    \                                                                                   
//     .        .--.     .     .--.     .     /   /` '.   \              .              __.....__                                            
//   .'|        |__|   .'|     |__|   .'|    .   |     \  '            .'|          .-''         '.                                          
//  <  |        .--. .'  |     .--. .'  |    |   '      |  '          <  |         /     .-''"'-.  `.           .-,.--.      .|              
//   | |        |  |<    |     |  |<    |    \    \     / /            | |        /     /________\   \    __    |  .-. |   .' |_             
//   | | .'''-. |  | |   | ____|  | |   | ____`.   ` ..' /             | | .'''-. |                  | .:--.'.  | |  | | .'     |       _    
//   | |/.'''. \|  | |   | \ .'|  | |   | \ .'   '-...-'`              | |/.'''. \\    .-------------'/ |   \ | | |  | |'--.  .-'     .' |   
//   |  /    | ||  | |   |/  . |  | |   |/  .                          |  /    | | \    '-.____...---.`" __ | | | |  '-    |  |      .   | / 
//   | |     | ||__| |    /\  \|__| |    /\  \                         | |     | |  `.             .'  .'.''| | | |        |  |    .'.'| |// 
//   | |     | |     |   |  \  \    |   |  \  \                        | |     | |    `''-...... -'   / /   | |_| |        |  '.'.'.'.-'  /  
//    | '.    | '.    '    \  \  \   '    \  \  \                       | '.    | '.                   \ \._,\ '/|_|        |   / .'   \_.'   
//   '---'   '---'  '------'  '---''------'  '---'                     '---'   '---'                   `--'  `"            `'-'              

*/


import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import 'erc721a/contracts/ERC721A.sol';


pragma solidity >=0.8.13 <0.9.0;

contract HHearts is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;


  bytes32 public merkleRoot;
  
  string public uri;
  string public uriSuffix = ".json";

  string public hiddenMetadataUri = "ipfs://CID/filename.json";

  uint256 public price = 0.07 ether;
  uint256 public wlprice = .03 ether;

  uint256 public supplyLimit = 3000;
  uint256 public wlsupplyLimit = 3000;

  uint256 public maxMintAmountPerTx = 2000;
  uint256 public wlmaxMintAmountPerTx = 2000;

  uint256 public maxLimitPerWallet = 1000;
  uint256 public wlmaxLimitPerWallet = 1000;

  bool public whitelistSale = false;
  bool public publicSale = false;

  bool public revealed = true;

  mapping(address => uint256) public wlMintCount;
  mapping(address => uint256) public publicMintCount;

  uint256 public publicMinted;
  uint256 public wlMinted;    




  constructor(
    string memory _uri
  ) ERC721A("Hikiko Hearts", "HIKIH")  {
    seturi(_uri);
  }


  function WlMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable {

    require(whitelistSale, 'The WlSale is paused!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');


    require(_mintAmount > 0 && _mintAmount <= wlmaxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= wlsupplyLimit, 'Max supply exceeded!');
    require(wlMintCount[msg.sender] + _mintAmount <= wlmaxLimitPerWallet, 'Max mint per wallet exceeded!');
    require(msg.value >= wlprice * _mintAmount, 'Insufficient funds!');
     
     _safeMint(_msgSender(), _mintAmount);

    wlMintCount[msg.sender] += _mintAmount; 
    wlMinted += _mintAmount;
  }

  function PublicMint(uint256 _mintAmount) public payable {
    
    require(publicSale, 'The PublicSale is paused!');
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= supplyLimit, 'Max supply exceeded!');
    require(publicMintCount[msg.sender] + _mintAmount <= maxLimitPerWallet, 'Max mint per wallet exceeded!');
    require(msg.value >= price * _mintAmount, 'Insufficient funds!');
     
     _safeMint(_msgSender(), _mintAmount);

    publicMintCount[msg.sender] += _mintAmount;  
    publicMinted += _mintAmount;   
  }  

  function OwnerMint(uint256 _mintAmount, address _receiver) public onlyOwner {
    require(totalSupply() + _mintAmount <= supplyLimit, 'Max supply exceeded!');
    _safeMint(_receiver, _mintAmount);
  }

    function MassAirdrop(address[] calldata receivers) external onlyOwner {
    for (uint256 i; i < receivers.length; ++i) {
      require(totalSupply() + 1 <= supplyLimit, 'Max supply exceeded!');
      _mint(receivers[i], 1);
    }
  }


  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function seturi(string memory _uri) public onlyOwner {
    uri = _uri;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setpublicSale(bool _publicSale) public onlyOwner {
    publicSale = _publicSale;
  }

  function setwlSale(bool _whitelistSale) public onlyOwner {
    whitelistSale = _whitelistSale;
  }

  function setwlMerkleRootHash(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setwlmaxMintAmountPerTx(uint256 _wlmaxMintAmountPerTx) public onlyOwner {
    wlmaxMintAmountPerTx = _wlmaxMintAmountPerTx;
  }

  function setmaxLimitPerWallet(uint256 _maxLimitPerWallet) public onlyOwner {
    maxLimitPerWallet = _maxLimitPerWallet;
  }

  function setwlmaxLimitPerWallet(uint256 _wlmaxLimitPerWallet) public onlyOwner {
    wlmaxLimitPerWallet = _wlmaxLimitPerWallet;
  }  

  function setPrice(uint256 _price) public onlyOwner {
    price = _price;
  }

  function setwlPrice(uint256 _wlprice) public onlyOwner {
    wlprice = _wlprice;
  }  

  function setsupplyLimit(uint256 _supplyLimit) public onlyOwner {
    supplyLimit = _supplyLimit;
  }

  function setwlsupplyLimit(uint256 _wlsupplyLimit) public onlyOwner {
    wlsupplyLimit = _wlsupplyLimit;
  }  


  
  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }


  function tokensOfOwner(address owner) external view returns (uint256[] memory) {
    unchecked {
        uint256[] memory a = new uint256[](balanceOf(owner)); 
        uint256 end = _nextTokenId();
        uint256 tokenIdsIdx;
        address currOwnershipAddr;
        for (uint256 i; i < end; i++) {
            TokenOwnership memory ownership = _ownershipAt(i);
            if (ownership.burned) {
                continue;
            }
            if (ownership.addr != address(0)) {
                currOwnershipAddr = ownership.addr;
            }
            if (currOwnershipAddr == owner) {
                a[tokenIdsIdx++] = i;
            }
        }
        return a;    
    }
}

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uri;
  }


}