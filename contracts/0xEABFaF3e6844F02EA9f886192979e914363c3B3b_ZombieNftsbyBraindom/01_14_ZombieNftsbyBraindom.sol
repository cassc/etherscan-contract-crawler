// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

contract ZombieNftsbyBraindom is ERC165, ReentrancyGuard, ERC721Enumerable{
    
  using SafeMath for uint256;

  string public baseURI;
  string public endingPrefix;

  // Booleans
  bool public isBinanceActive = false;
  bool public isGeneralActive = false;
  bool public isClaim10Active = false;
  bool public isClaim9Active = false;
  bool public isClaim7Active = false;
  bool public isClaim6Active = false;
  bool public isClaim5Active = false;
  bool public isClaim4Active = false;
  bool public isClaim3Active = false;
  bool public isClaim2Active = false;
  bool public isClaim1Active = false;

  bool public isRevealed = false;

  // Base variables
  uint256 public circulatingSupply;
  uint256 public LAUNCH_MAX_SUPPLY = 100;
  uint256 public LAUNCH_SUPPLY = 0;
  address public owner = msg.sender;
  uint256 public Price = 0.0 ether;
  uint256 public constant _totalSupply = 3_000;

  address private LAUNCHPAD;

  // Limits
  uint256 internal binancelimit = 1400;
  uint256 internal limitgeneral = 1500;
  uint256 internal limit10 = 10;
  uint256 internal limit9 = 9;
  uint256 internal limit7 = 7;
  uint256 internal limit6 = 6;
  uint256 internal limit5 = 5;
  uint256 internal limit4 = 4;
  uint256 internal limit3 = 3;
  uint256 internal limit2 = 2;
  uint256 internal limit1 = 1;


  mapping(address => bool) private binance;
  mapping(address => bool) private general;
  mapping(address => bool) private claim10;
  mapping(address => bool) private claim9;
  mapping(address => bool) private claim7;
  mapping(address => bool) private claim6;
  mapping(address => bool) private claim5;
  mapping(address => bool) private claim4;
  mapping(address => bool) private claim3;
  mapping(address => bool) private claim2;
  mapping(address => bool) private claim1;


  mapping(address => uint256) private addressIndices;

  // Variables for random indexed tokens
  uint internal nonce = 0;
  
  constructor() ERC721("Zombie NFTs by Braindom", "Zombie") {
      owner = msg.sender;
  }





    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, ERC165) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
  


function generalMint(uint256 _amount) external payable
    tokensAvailable(_amount)
    generalSaleStarted()
    callerIsUser()
  {
    address minter = msg.sender;
    require(general[minter] == true, "Not allowed to General claim");
    require(addressIndices[minter] + _amount <= limitgeneral, "Max wallet limit reached");
    require(msg.value >= _amount * Price, "Incorrect payable amount");
    
    if(addressIndices[minter] + _amount >= limitgeneral) {
      general[minter] = false;
    }

    for(uint256 i = 0; i < _amount; i++) {
      ++addressIndices[minter];
      _safeMint(minter, ++circulatingSupply);
    }
  }

  function isGeneralSaleAllowed() public view returns(bool) {
    return general[msg.sender] == true;
  }

  function addToGeneralSaleList(address[] calldata _GeneralMinters) external onlyOwner {
    for(uint256 i = 0; i < _GeneralMinters.length; i++)
      general[_GeneralMinters[i]] = true;
  }

  
  function toggleGeneralSale() external onlyOwner {
    isGeneralActive = !isGeneralActive;
  }

  function unlistGeneralMinter(address[] calldata _minters) external onlyOwner {
    for(uint256 i = 0; i < _minters.length; i++)
      general[_minters[i]] = false;
  }

  modifier generalSaleStarted() {
    require(isGeneralActive == true, "General sale not started");
    _;
  }



////////////////
  function binanceMint(uint256 _amount) external payable
    tokensAvailable(_amount)
    binanceSaleStarted()
    callerIsUser()
  {
    address minter = msg.sender;
    require(binance[minter] == true, "Not allowed to Binance mint");
    require(addressIndices[minter] + _amount <= binancelimit, "Max wallet limit reached");
    require(msg.value >= _amount * Price, "Incorrect payable amount");
    
    if(addressIndices[minter] + _amount >= binancelimit) {
      binance[minter] = false;
    }

    for(uint256 i = 0; i < _amount; i++) {
      ++addressIndices[minter];
      _safeMint(minter, ++circulatingSupply);
    }
  }

  function isBinanceSaleAllowed() public view returns(bool) {
    return binance[msg.sender] == true;
  }

  function addToBinanceSaleList(address[] calldata _BinanceMinters) external onlyOwner {
    for(uint256 i = 0; i < _BinanceMinters.length; i++)
      binance[_BinanceMinters[i]] = true;
  }

  
  function toggleBinanceSale() external onlyOwner {
    isBinanceActive = !isBinanceActive;
  }

  function unlistBinanceMinter(address[] calldata _minters) external onlyOwner {
    for(uint256 i = 0; i < _minters.length; i++)
      binance[_minters[i]] = false;
  }

  modifier binanceSaleStarted() {
    require(isBinanceActive == true, "Binance sale not started");
    _;
  }



//////////////////////////////////////////////////////////////////////


function Claim10(uint256 _amount) external payable
    tokensAvailable(_amount)
    claim10SaleStarted()
    callerIsUser()
  {
    address minter = msg.sender;
    require(claim10[minter] == true, "Not allowed to Claim");
    require(addressIndices[minter] + _amount <= limit10, "Max wallet limit reached");
    require(msg.value >= _amount * Price, "Incorrect payable amount");
    
    if(addressIndices[minter] + _amount >= limit10) {
      claim10[minter] = false;
    }

    for(uint256 i = 0; i < _amount; i++) {
      ++addressIndices[minter];
      _safeMint(minter, ++circulatingSupply);
    }
  }

  function claim10SaleAllowed() public view returns(bool) {
    return claim10[msg.sender] == true;
  }

  function addToClaim10SaleList(address[] calldata _Claim10Minters) external onlyOwner {
    for(uint256 i = 0; i < _Claim10Minters.length; i++)
      claim10[_Claim10Minters[i]] = true;
  }

  
  function toggleClaim10Sale() external onlyOwner {
    isClaim10Active = !isClaim10Active;
  }

  function unlistClaim10Minter(address[] calldata _minters) external onlyOwner {
    for(uint256 i = 0; i < _minters.length; i++)
      claim10[_minters[i]] = false;
  }

  modifier claim10SaleStarted() {
    require(isClaim10Active == true, "Claim not started");
    _;
  }


///////////////////////

function Claim9(uint256 _amount) external payable
    tokensAvailable(_amount)
    claim9SaleStarted()
    callerIsUser()
  {
    address minter = msg.sender;
    require(claim9[minter] == true, "Not allowed to Claim");
    require(addressIndices[minter] + _amount <= limit9, "Max wallet limit reached");
    require(msg.value >= _amount * Price, "Incorrect payable amount");
    
    if(addressIndices[minter] + _amount >= limit9) {
      claim9[minter] = false;
    }

    for(uint256 i = 0; i < _amount; i++) {
      ++addressIndices[minter];
      _safeMint(minter, ++circulatingSupply);
    }
  }

  function claim9SaleAllowed() public view returns(bool) {
    return claim9[msg.sender] == true;
  }

  function addToClaim9SaleList(address[] calldata _Claim9Minters) external onlyOwner {
    for(uint256 i = 0; i < _Claim9Minters.length; i++)
      claim9[_Claim9Minters[i]] = true;
  }

  
  function toggleClaim9Sale() external onlyOwner {
    isClaim9Active = !isClaim9Active;
  }

  function unlistClaim9Minter(address[] calldata _minters) external onlyOwner {
    for(uint256 i = 0; i < _minters.length; i++)
      claim9[_minters[i]] = false;
  }

  modifier claim9SaleStarted() {
    require(isClaim9Active == true, "Claim not started");
    _;
  }


///////////////////
function Claim7(uint256 _amount) external payable
    tokensAvailable(_amount)
    claim7SaleStarted()
    callerIsUser()
  {
    address minter = msg.sender;
    require(claim7[minter] == true, "Not allowed to Claim");
    require(addressIndices[minter] + _amount <= limit7, "Max wallet limit reached");
    require(msg.value >= _amount * Price, "Incorrect payable amount");
    
    if(addressIndices[minter] + _amount >= limit7) {
      claim7[minter] = false;
    }

    for(uint256 i = 0; i < _amount; i++) {
      ++addressIndices[minter];
      _safeMint(minter, ++circulatingSupply);
    }
  }

  function claim7SaleAllowed() public view returns(bool) {
    return claim7[msg.sender] == true;
  }

  function addToClaim7SaleList(address[] calldata _Claim7Minters) external onlyOwner {
    for(uint256 i = 0; i < _Claim7Minters.length; i++)
      claim7[_Claim7Minters[i]] = true;
  }

  
  function toggleClaim7Sale() external onlyOwner {
    isClaim7Active = !isClaim7Active;
  }

  function unlistClaim7Minter(address[] calldata _minters) external onlyOwner {
    for(uint256 i = 0; i < _minters.length; i++)
      claim7[_minters[i]] = false;
  }

  modifier claim7SaleStarted() {
    require(isClaim7Active == true, "Claim not started");
    _;
  }


////////////////
function Claim6(uint256 _amount) external payable
    tokensAvailable(_amount)
    claim6SaleStarted()
    callerIsUser()
  {
    address minter = msg.sender;
    require(claim6[minter] == true, "Not allowed to Claim");
    require(addressIndices[minter] + _amount <= limit6, "Max wallet limit reached");
    require(msg.value >= _amount * Price, "Incorrect payable amount");
    
    if(addressIndices[minter] + _amount >= limit6) {
      claim6[minter] = false;
    }

    for(uint256 i = 0; i < _amount; i++) {
      ++addressIndices[minter];
      _safeMint(minter, ++circulatingSupply);
    }
  }

  function claim6SaleAllowed() public view returns(bool) {
    return claim6[msg.sender] == true;
  }

  function addToClaim6SaleList(address[] calldata _Claim6Minters) external onlyOwner {
    for(uint256 i = 0; i < _Claim6Minters.length; i++)
      claim6[_Claim6Minters[i]] = true;
  }

  
  function toggleClaim6Sale() external onlyOwner {
    isClaim6Active = !isClaim6Active;
  }

  function unlistClaim6Minter(address[] calldata _minters) external onlyOwner {
    for(uint256 i = 0; i < _minters.length; i++)
      claim6[_minters[i]] = false;
  }

  modifier claim6SaleStarted() {
    require(isClaim6Active == true, "Claim not started");
    _;
  }


function Claim5(uint256 _amount) external payable
    tokensAvailable(_amount)
    claim5SaleStarted()
    callerIsUser()
  {
    address minter = msg.sender;
    require(claim5[minter] == true, "Not allowed to Claim");
    require(addressIndices[minter] + _amount <= limit5, "Max wallet limit reached");
    require(msg.value >= _amount * Price, "Incorrect payable amount");
    
    if(addressIndices[minter] + _amount >= limit5) {
      claim5[minter] = false;
    }

    for(uint256 i = 0; i < _amount; i++) {
      ++addressIndices[minter];
      _safeMint(minter, ++circulatingSupply);
    }
  }

  function claim5SaleAllowed() public view returns(bool) {
    return claim5[msg.sender] == true;
  }

  function addToClaim5SaleList(address[] calldata _Claim5Minters) external onlyOwner {
    for(uint256 i = 0; i < _Claim5Minters.length; i++)
      claim5[_Claim5Minters[i]] = true;
  }

  
  function toggleClaim5Sale() external onlyOwner {
    isClaim5Active = !isClaim5Active;
  }

  function unlistClaim5Minter(address[] calldata _minters) external onlyOwner {
    for(uint256 i = 0; i < _minters.length; i++)
      claim5[_minters[i]] = false;
  }

  modifier claim5SaleStarted() {
    require(isClaim5Active == true, "Claim not started");
    _;
  }
/////////////

function Claim4(uint256 _amount) external payable
    tokensAvailable(_amount)
    claim4SaleStarted()
    callerIsUser()
  {
    address minter = msg.sender;
    require(claim4[minter] == true, "Not allowed to Claim");
    require(addressIndices[minter] + _amount <= limit4, "Max wallet limit reached");
    require(msg.value >= _amount * Price, "Incorrect payable amount");
    
    if(addressIndices[minter] + _amount >= limit4) {
      claim4[minter] = false;
    }

    for(uint256 i = 0; i < _amount; i++) {
      ++addressIndices[minter];
      _safeMint(minter, ++circulatingSupply);
    }
  }

  function claim4SaleAllowed() public view returns(bool) {
    return claim4[msg.sender] == true;
  }

  function addToClaim4SaleList(address[] calldata _Claim4Minters) external onlyOwner {
    for(uint256 i = 0; i < _Claim4Minters.length; i++)
      claim4[_Claim4Minters[i]] = true;
  }

  
  function toggleClaim4Sale() external onlyOwner {
    isClaim4Active = !isClaim4Active;
  }

  function unlistClaim4Minter(address[] calldata _minters) external onlyOwner {
    for(uint256 i = 0; i < _minters.length; i++)
      claim4[_minters[i]] = false;
  }

  modifier claim4SaleStarted() {
    require(isClaim4Active == true, "Claim not started");
    _;
  }
/////////////

function Claim3(uint256 _amount) external payable
    tokensAvailable(_amount)
    claim3SaleStarted()
    callerIsUser()
  {
    address minter = msg.sender;
    require(claim3[minter] == true, "Not allowed to Claim");
    require(addressIndices[minter] + _amount <= limit3, "Max wallet limit reached");
    require(msg.value >= _amount * Price, "Incorrect payable amount");
    
    if(addressIndices[minter] + _amount >= limit3) {
      claim3[minter] = false;
    }

    for(uint256 i = 0; i < _amount; i++) {
      ++addressIndices[minter];
      _safeMint(minter, ++circulatingSupply);
    }
  }

  function claim3SaleAllowed() public view returns(bool) {
    return claim3[msg.sender] == true;
  }

  function addToClaim3SaleList(address[] calldata _Claim3Minters) external onlyOwner {
    for(uint256 i = 0; i < _Claim3Minters.length; i++)
      claim3[_Claim3Minters[i]] = true;
  }

  
  function toggleClaim3Sale() external onlyOwner {
    isClaim3Active = !isClaim3Active;
  }

  function unlistClaim3Minter(address[] calldata _minters) external onlyOwner {
    for(uint256 i = 0; i < _minters.length; i++)
      claim3[_minters[i]] = false;
  }

  modifier claim3SaleStarted() {
    require(isClaim3Active == true, "Claim not started");
    _;
  }

/////////////////////

function Claim2(uint256 _amount) external payable
    tokensAvailable(_amount)
    claim2SaleStarted()
    callerIsUser()
  {
    address minter = msg.sender;
    require(claim2[minter] == true, "Not allowed to Claim");
    require(addressIndices[minter] + _amount <= limit2, "Max wallet limit reached");
    require(msg.value >= _amount * Price, "Incorrect payable amount");
    
    if(addressIndices[minter] + _amount >= limit2) {
      claim2[minter] = false;
    }

    for(uint256 i = 0; i < _amount; i++) {
      ++addressIndices[minter];
      _safeMint(minter, ++circulatingSupply);
    }
  }

  function claim2SaleAllowed() public view returns(bool) {
    return claim2[msg.sender] == true;
  }

  function addToClaim2SaleList(address[] calldata _Claim2Minters) external onlyOwner {
    for(uint256 i = 0; i < _Claim2Minters.length; i++)
      claim2[_Claim2Minters[i]] = true;
  }

  
  function toggleClaim2Sale() external onlyOwner {
    isClaim2Active = !isClaim2Active;
  }

  function unlistClaim2Minter(address[] calldata _minters) external onlyOwner {
    for(uint256 i = 0; i < _minters.length; i++)
      claim2[_minters[i]] = false;
  }

  modifier claim2SaleStarted() {
    require(isClaim2Active == true, "Claim not started");
    _;
  }

//////////////

function Claim1(uint256 _amount) external payable
    tokensAvailable(_amount)
    claim1SaleStarted()
    callerIsUser()
  {
    address minter = msg.sender;
    require(claim1[minter] == true, "Not allowed to Claim");
    require(addressIndices[minter] + _amount <= limit1, "Max wallet limit reached");
    require(msg.value >= _amount * Price, "Incorrect payable amount");
    
    if(addressIndices[minter] + _amount >= limit1) {
      claim1[minter] = false;
    }

    for(uint256 i = 0; i < _amount; i++) {
      ++addressIndices[minter];
      _safeMint(minter, ++circulatingSupply);
    }
  }

  function claim1SaleAllowed() public view returns(bool) {
    return claim1[msg.sender] == true;
  }

  function addToClaim1SaleList(address[] calldata _Claim1Minters) external onlyOwner {
    for(uint256 i = 0; i < _Claim1Minters.length; i++)
      claim1[_Claim1Minters[i]] = true;
  }

  
  function toggleClaim1Sale() external onlyOwner {
    isClaim1Active = !isClaim1Active;
  }

  function unlistClaim1Minter(address[] calldata _minters) external onlyOwner {
    for(uint256 i = 0; i < _minters.length; i++)
      claim1[_minters[i]] = false;
  }

  modifier claim1SaleStarted() {
    require(isClaim1Active == true, "Claim not started");
    _;
  }


function mintTo(address to, uint size) external onlyLaunchpad {
        require(to != address(0), "can't mint to empty address");
        require(size > 0, "size must greater than zero");
        require(LAUNCH_SUPPLY + size <= LAUNCH_MAX_SUPPLY, "max supply reached");

        for (uint256 i=0; i < size; i++) {
            _safeMint(to, LAUNCH_SUPPLY);
            LAUNCH_SUPPLY++;
            circulatingSupply++;
        }
}
  //QUERIES
  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    return isRevealed ? string(abi.encodePacked(baseURI, '/', Strings.toString(tokenId), endingPrefix)) : baseURI;
  }

  function tokensRemaining() public view returns (uint256) {
    return _totalSupply - circulatingSupply;
  }



  //OWNER ONLY

  function setBaseURI(string memory __baseURI) external onlyOwner {
        baseURI = __baseURI;
    }

  function toggleReveal() external onlyOwner {
    isRevealed = !isRevealed;
  }


  function setEndingPrefix(string calldata _prefix) external onlyOwner {
    endingPrefix = _prefix;
  }

  function withdraw() external onlyOwner nonReentrant callerIsUser() {
      (bool isTransfered, ) = msg.sender.call{value: address(this).balance}("");
      require(isTransfered, "Transfer failed");
  }

  function totalSupply() public override view returns (uint256) {
    return circulatingSupply;
  }

  function burn(
    uint256 _tokenId
  ) external onlyOwner validNFToken(_tokenId)
  {
    circulatingSupply--;
    _burn(_tokenId);
  }

   function getGeneralLimit() public view returns (uint256) {
    return limitgeneral;
  }

    function updateWalletLimit(uint256 _newLimit) external onlyOwner {
    limitgeneral = _newLimit;
  }

    function setAddress(address _address) external onlyOwner{
        LAUNCHPAD = _address;
    }

  //MODIFIERS
  modifier tokensAvailable(uint256 _amount) {
      require(_amount <= tokensRemaining(), "Try minting less tokens");
      _;
  }



  modifier onlyOwner() {
    require(owner == msg.sender, "Ownable: Caller is not the owner");
    _;
  }
    modifier onlyLaunchpad() {
        require(LAUNCHPAD != address(0), "launchpad address must set");
        require(msg.sender == LAUNCHPAD, "must call by launchpad");
        _;
    }
    function getMaxLaunchpadSupply() view public returns (uint256) {
        return LAUNCH_MAX_SUPPLY;
    }

    function getLaunchpadSupply() view public returns (uint256) {
        return LAUNCH_SUPPLY;
    }
    // end
    /**
   * @dev Guarantees that _tokenId is a valid Token.
   * @param _tokenId ID of the NFT to validate.
   */
  modifier validNFToken(
    uint256 _tokenId
  )
  {
    require(ownerOf(_tokenId) != address(0));
    _;
  }
  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }
}