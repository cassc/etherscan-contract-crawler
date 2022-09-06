// SPDX-License-Identifier: MIT

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                            //
//                                                                                                                                                            //
//           -*%@@@@@@@@@@@@@@@@@@@@%*=.         +%@@@@@@@@@@@@@@@@@@#*=.         .+#@@@%*:             :+%@@@%*:     -*%@@@@#-            :*%@@@@#=          //
//          *@@@@@@@@@@@@@@@@@@@@@@@@@@@#-     :@@@@@@@@@@@@@@@@@@@@@@@@@%=      [email protected]@@@@@@@@#           *@@@@@@@@@*   *@@@@@@@@@#          *@@@@@@@@@%         //
//         :@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#.   %@@@@@@@@@@@@@@@@@@@@@@@@@@@%=   [email protected]@@@@@@@@@@=         [email protected]@@@@@@@@@@: [email protected]@@@@@@@@@@=        :@@@@@@@@@@@=        //
//         [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.  %@@@@@@@@@@@@@@@@@@@@@@@@@@@@@+  :@@@@@@@@@@@*         [email protected]@@@@@@@@@@- :@@@@@@@@@@@+        [email protected]@@@@@@@@@@+        //
//         [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%  %@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@- :@@@@@@@@@@@*         [email protected]@@@@@@@@@@- :@@@@@@@@@@@+        [email protected]@@@@@@@@@@+        //
//         [email protected]@@@@@@@@@@=::::::[email protected]@@@@@@@@@@@. %@@@@@@@@@@@%%%%%%%@@@@@@@@@@@@% :@@@@@@@@@@@*         [email protected]@@@@@@@@@@- :@@@@@@@@@@@+        [email protected]@@@@@@@@@@+        //
//         [email protected]@@@@@@@@@#.         #@@@@@@@@@@@: %@@@@@@@@@*         #@@@@@@@@@@@ :@@@@@@@@@@@*         [email protected]@@@@@@@@@@- :@@@@@@@@@@@%++++++++#@@@@@@@@@@@+        //
//         [email protected]@@@@@@@@@@@@%%%%%%%@@@@@@@@@@@@%  %@@@@@@@@@%[email protected]@@@@@@@@@@@ :@@@@@@@@@@@*         [email protected]@@@@@@@@@@- :@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@+        //
//         [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@-  %@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@+ :@@@@@@@@@@@*         [email protected]@@@@@@@@@@- :@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@+        //
//         [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*   %@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%  :@@@@@@@@@@@*         [email protected]@@@@@@@@@@- :@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@+        //
//         [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@=  %@@@@@@@@@@@@@@@@@@@@@@@@@@@@#   :@@@@@@@@@@@*         [email protected]@@@@@@@@@@- :@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@+        //
//         [email protected]@@@@@@@@@@@########%@@@@@@@@@@@@  %@@@@@@@@@@@@@@@@@@@@@@@@@@%:    :@@@@@@@@@@@*         [email protected]@@@@@@@@@@- :@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@+        //
//         [email protected]@@@@@@@@@%          [email protected]@@@@@@@@@@: %@@@@@@@@@@@@@@@@@@@@@@@@@@@+     @@@@@@@@@@@@*:     :*@@@@@@@@@@@@. :@@@@@@@@@@@#[email protected]@@@@@@@@@@+        //
//         [email protected]@@@@@@@@@@*=------=+%@@@@@@@@@@@. %@@@@@@@@@@@===%@@@@@@@@@@@@@%:   *@@@@@@@@@@@@@@###@@@@@@@@@@@@@@#  :@@@@@@@@@@@+        [email protected]@@@@@@@@@@+        //
//         [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*  %@@@@@@@@@@@    [email protected]@@@@@@@@@@@@@-   %@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%.  :@@@@@@@@@@@+        [email protected]@@@@@@@@@@+        //
//         [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#   %@@@@@@@@@@@     .%@@@@@@@@@@@@@    *@@@@@@@@@@@@@@@@@@@@@@@@@@@#.   :@@@@@@@@@@@+        [email protected]@@@@@@@@@@+        //
//         [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@+    #@@@@@@@@@@#       [email protected]@@@@@@@@@@@     -%@@@@@@@@@@@@@@@@@@@@@@@%-     [email protected]@@@@@@@@@@-        :@@@@@@@@@@@=        //
//          [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@+.      #@@@@@@@@%.        .#@@@@@@@@@:       :*@@@@@@@@@@@@@@@@@@@*-        [email protected]@@@@@@@@+          [email protected]@@@@@@@@*         //
//           .=*#%%%%%%%%%%%%%%%%%##+=.          :+#%%#+-            :+#%%#*=            :=*%@@@@@@@@@%*+:            .=*#%%#=.            .=*#%%#=.          //
//                                                                                                                                                            //
//                                                                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract BruhPills is ERC721AQueryable, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;
  uint256 public finalMaxSupply = 3333;

  address public constant creator1Address = 0x5E17Ee0e47BC8343ED88c2d25fb9fBf4456A4056;
  address public constant creator2Address = 0xa4A8C63e797009f5D7E7d2948ca4e2355A973559;
  address public constant creator3Address = 0x0443E05dd3Bcff32AD4E74d32a70aFF2BbD730Cc;
  address public constant businessAddress = 0x24C85bDF352C3036dd343732171D617Bf5AA9424;
  address public constant daoAddress = 0x169E35317D487874E615C9Fb7ea646C744086234;

  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost);
    maxSupply = _maxSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    setHiddenMetadataUri(_hiddenMetadataUri);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }
  function setCurrentMaxSupply(uint256 _supply) public onlyOwner {
    require(_supply <= finalMaxSupply && _supply >= totalSupply());
    maxSupply = _supply;
  }
  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify whitelist requirements
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    require(!whitelistClaimed[_msgSender()], 'Address already claimed!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    whitelistClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');

    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
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

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function withdraw() public onlyOwner nonReentrant {
    // =============================================================================
    (bool hs, ) = payable(0xE2F88E025010B4e513649F94D4301618c2e4830D).call{value: address(this).balance}('BruhPills Primary Sales Split contract');
    require(hs);
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
    // =============================================================================
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}