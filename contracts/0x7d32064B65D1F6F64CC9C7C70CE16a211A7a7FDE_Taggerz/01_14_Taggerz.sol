// SPDX-License-Identifier: MIT
// By @Kokako_Loon
//
//  <O)
//  /))
// ==#===
//
// Taggerz Smart Contract
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

interface CheckTaggerzXL {
    function walletOfOwner(address _owner) external view returns (uint256[] memory);
    function balanceOf(address account) external view returns (uint256);
}

contract Taggerz is ERC721AQueryable, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;
  mapping(uint256 => bool) public taggerzXLClaimed;
  
  address taggerXLContractAddr = 0x3631959CdefdeFFdBb0e3bF900aC10b492F63a92;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
 
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxPhaseAmount;
  uint256 public maxMintAmountPerTx;

  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public taggerXLFreeMintEnabled = false;
  bool public revealed = false;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxPhaseAmount,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost);
    maxSupply = _maxSupply;
    setMaxPhaseAmount(_maxPhaseAmount);
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    setHiddenMetadataUri(_hiddenMetadataUri);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxPhaseAmount, 'Max supply for this phase exceeded!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max total supply exceeded!');
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }

  modifier mintSupplyCompliance(uint256 _mintAmount) {
    require(totalSupply() + _mintAmount <= maxPhaseAmount, 'Max supply for this phase exceeded!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) {
    // Verify whitelist requirements
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    require(!whitelistClaimed[_msgSender()], 'Address already claimed!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    whitelistClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }

  function freeTaggerzXLMint() public {
    require(taggerXLFreeMintEnabled, 'TaggerzXL Free Mint Paused!');
    uint256 validTaggerzXL = 0;
    uint256 taggerzXLAmount = CheckTaggerzXL(taggerXLContractAddr).balanceOf(_msgSender());
    uint256[] memory taggerzXLTokenIds = CheckTaggerzXL(taggerXLContractAddr).walletOfOwner(_msgSender());
    for (uint i = 0; i < taggerzXLAmount; i++) {
      if (taggerzXLClaimed[taggerzXLTokenIds[i]] == false) {
        validTaggerzXL = validTaggerzXL + 1;
        taggerzXLClaimed[taggerzXLTokenIds[i]] = true;
      }
    }
    require(validTaggerzXL > 0, 'Taggerz XL in wallet have been already claimed');    
    require(totalSupply() + validTaggerzXL <= maxPhaseAmount, 'Max supply for this phase exceeded!');
    require(totalSupply() + validTaggerzXL <= maxSupply, 'Max supply exceeded!');
    
    _safeMint(_msgSender(), validTaggerzXL);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');

    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) mintSupplyCompliance(_mintAmount) public onlyOwner {
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
      ? string(abi.encodePacked(currentBaseURI, (_tokenId).toString(), uriSuffix))
      : '';
  }

  function setRevealed() public onlyOwner {
    require(revealed == false, "collection is already revealed!");
    revealed = true;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxPhaseAmount(uint256 _maxPhaseAmount) public onlyOwner {
    maxPhaseAmount = _maxPhaseAmount;
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

  function setTaggerzXLFreeMintEnabled(bool _state) public onlyOwner {
    taggerXLFreeMintEnabled = _state;
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}