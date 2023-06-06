// SPDX-License-Identifier: MIT
//A SOVRN-OPEN Drop

/*                                                                             
SIGHTSEERS - PERIMETER TOWN                                                                                                                                                                                                       
*/
pragma solidity =0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import "./OperatorFilterer.sol";

contract SIGHTSEERSPERIMETERTOWN is ERC721AQueryable, Ownable, ReentrancyGuard, OperatorFilterer {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;

  string public uriPrefix = 'ipfs://QmPM63oXhSahP1cc3xRu2UWmKSpDpucpCkcQ3en9xckaHf/';
  string public uriSuffix = '.json';
  
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;
  address public adminAddress = 0xbf1aB3DDB7b1F2d8f302C1048a33e3b382887B63;

  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public shuffled = true;

  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
  address public defaultRoyaltyReceiver;
  mapping(uint256 => address) royaltyReceivers;
  uint256 public defaultRoyaltyPercentage;
  mapping(uint256 => uint256) royaltyPercentages;

  uint256[] private numberArr = [10,84,218,64,27,169,170,15,231,222,37,18,45,110,129,16,173,97,72,238,235,212,19,146,136,31,187,153,77,167,202,215,125,46,58,67,181,69,227,247,88,116,50,133,40,24,44,11,25,242,132,78,168,174,147,139,178,23,126,115,249,150,198,163,4,21,8,96,193,82,156,92,196,51,197,124,74,57,209,172,179,117,79,41,189,143,166,239,205,210,138,185,56,5,190,177,145,200,76,176,226,80,122,183,207,141,33,217,219,151,107,137,149,155,201,228,128,221,234,199,7,99,134,184,195,70,61,32,240,211,152,188,157,180,29,206,47,87,48,158,123,39,111,182,62,118,162,159,113,213,119,220,204,103,35,6,148,83,95,224,165,94,28,208,112,161,60,86,3,244,230,89,160,142,114,26,120,131,216,20,14,53,154,232,102,108,203,55,13,81,17,214,223,66,241,65,192,109,90,236,93,43,245,42,229,194,233,101,171,68,191,49,71,225,248,52,63,106,237,250,91,105,9,34,127,22,164,38,175,73,1,121,135,98,140,59,75,246,104,85,144,12,2,130,100,186,36,54,30,243];

  string _tokenName = "SIGHTSEERS - PERIMETER TOWN";
  string _tokenSymbol = "SSPT";  
  uint256 _maxSupply = 250;  
  address _defaultRoyaltyReceiver = 0x69f80347143F81267D291E62f8E5d0EdbC32b1AB; //CHANGED
  uint256 _defaultRoyaltyAmount = 100; // Points out 1000
  
  bool public operatorFilteringEnabled;
  
  constructor() ERC721A(_tokenName, _tokenSymbol) {
    setCost(250000000000000000);
    maxSupply = _maxSupply;
    setMaxMintAmountPerTx(250);
    defaultRoyaltyReceiver = _defaultRoyaltyReceiver;
    defaultRoyaltyPercentage = _defaultRoyaltyAmount;
    _registerForOperatorFiltering();
    operatorFilteringEnabled = true;
   
     
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

  modifier requireAdminOrOwner() {
  require(adminAddress == msg.sender || owner() == msg.sender,"Requires admin or owner privileges");
  _;
  }

  function setAdminAddress(address _adminAddress) public requireAdminOrOwner(){
        adminAddress = _adminAddress;
  }  

  function testPayMint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) requireAdminOrOwner() mintPriceCompliance(_mintAmount) {
    
    _safeMint(_msgSender(), _mintAmount);
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
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) requireAdminOrOwner() {
    _safeMint(_receiver, _mintAmount);
  }

  /*function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }*/

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');
    

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, numberArr[_tokenId].toString(), uriSuffix))
        : '';
  }

  function shuffleArr() requireAdminOrOwner() external {
    require(!shuffled, 'the array has already been shuffled');

    for (uint256 i = 0; i < numberArr.length; i++) {
        uint256 n = i + uint256(keccak256(abi.encode(block.timestamp))) % (numberArr.length - i);
        uint256 temp = numberArr[n];
        numberArr[n] = numberArr[i];
        numberArr[i] = temp;
      }
      shuffled = true;
  }

  
  function setCost(uint256 _cost) public requireAdminOrOwner() {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public requireAdminOrOwner() {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }  

  function setUriPrefix(string memory _uriPrefix) public requireAdminOrOwner() {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public requireAdminOrOwner() {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public requireAdminOrOwner() {
    paused = _state;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public requireAdminOrOwner() {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public requireAdminOrOwner() {
    whitelistMintEnabled = _state;
  }

  function withdraw() public requireAdminOrOwner() nonReentrant {
    
    
    (bool hs, ) = payable(0xC9367730EDE93Bb941e0a5F6509618001b001fa4).call{value: address(this).balance * 15 / 100}('');
    require(hs);
    // =============================================================================

    // This will transfer the remaining contract balance to the owner.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
    // =============================================================================
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  /*//////////////////////////////////////////////////////////////////////////
                        ERC2981 Functions START
  //////////////////////////////////////////////////////////////////////////*/

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override
    returns (bool)
{
    // Supports the following `interfaceId`s:
    // - IERC165: 0x01ffc9a7
    // - IERC721: 0x80ac58cd
    // - IERC721Metadata: 0x5b5e139f
    // - IERC2981: 0x2a55205a
    return
        interfaceId == 0x01ffc9a7 ||
        interfaceId == 0x80ac58cd ||
        interfaceId == 0x5b5e139f ||
        interfaceId == 0x2a55205a ||
        super.supportsInterface(interfaceId);
}

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        public
        view
        virtual
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = royaltyReceivers[_tokenId] != address(0)
            ? royaltyReceivers[_tokenId]
            : defaultRoyaltyReceiver;
        royaltyAmount = royaltyPercentages[_tokenId] != 0 ? (_salePrice * royaltyPercentages[_tokenId]) / 1000 : (_salePrice * defaultRoyaltyPercentage) / 1000;
    }

    function setDefaultRoyaltyReceiver(address _receiver) external requireAdminOrOwner() {
        defaultRoyaltyReceiver = _receiver;
    }

    function setRoyaltyReceiver(uint256 _tokenId, address _newReceiver)
        external requireAdminOrOwner()
    {
        royaltyReceivers[_tokenId] = _newReceiver;
    }

    function setRoyaltyPercentage(uint256 _tokenId, uint256 _percentage)
        external requireAdminOrOwner()
    {
        royaltyPercentages[_tokenId] = _percentage;
    }

  /*//////////////////////////////////////////////////////////////////////////
                        ERC2981 Functions END
  //////////////////////////////////////////////////////////////////////////*/

  /*//////////////////////////////////////////////////////////////////////////
                        OS OPERATOR FILTER START
  //////////////////////////////////////////////////////////////////////////*/
  function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator)
        internal
        pure
        override
        returns (bool)
    {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }
  
  /*//////////////////////////////////////////////////////////////////////////
                        OS OPERATOR FILTER END
  //////////////////////////////////////////////////////////////////////////*/
}