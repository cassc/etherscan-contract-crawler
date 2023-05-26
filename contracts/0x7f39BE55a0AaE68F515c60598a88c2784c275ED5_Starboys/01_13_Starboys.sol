// SPDX-License-Identifier: MIT
// forked from hashlips-lab/nft-erc721-collection
/*
    ***************************************************************************  
    ***************************************************************************  
    ***************************************************************************  
    ***************************************************************************  
    ***********************************@@@@@@@@@*******************************  
    *****************************@@#[email protected]@************************  
    **************************@@[email protected]*********************  
    ************************@[email protected]*******************  
    **********************@@[email protected]*****************  
    **********@@[email protected]@******@[email protected]@,[email protected]@[email protected]****************  
    **********@[email protected]*****@[email protected]***************  
    **********@[email protected]***%@[email protected]**************  
    *******@[email protected]@@**@[email protected]#*************  
    *****@*[email protected]@@[email protected]*@@*@[email protected]*************  
    ****@&[email protected]@[email protected]@[email protected]*************  
    *****@[email protected]@@@[email protected]#@[email protected]*************  
    ******@[email protected]([email protected]*************  
    *******@[email protected]@*************  
    *********@[email protected]@*************  
    **********#@[email protected]@#************  
    *************@[email protected]@@************  
    ***************@@[email protected]@@************  
    ******************@/[email protected]&@************  
    ******************@@[email protected]&@************  
    *******************@[email protected]&@************  
    *******************@............................(@[email protected]@************  
    *******************@[email protected]@@************  
    *******************@[email protected]@%************  
    *******************@[email protected]@*************
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@&      (.     [email protected]*    [email protected]&       @.      %@&      &/  ./  .%      #@@@@@
    @@@@(   /#&@@@%   @@%     ,@(  *(  /&       @.   &(  #%     (/   (#&@@@@@@@
    @@@@@&     @@@   (@&   /  /@     #@@(      &*  (@@,  @&    %@@&     @@@@@@@
    @@@@* %%   &@&   &@       (#  .   %@       %   ##   @@&   &@@, %%   &@@@@@@
    @@@&     *@@@   ,@/   @   %   &&  *     .&@@%    ,@@@@   /@@&     *@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*/
pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract Starboys is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;
  uint16 public salePhase;
  mapping(uint16 => mapping(address => uint256)) public whitelistClaimed; //phase mapping
  uint16 whitelistMintAvailableAmount;
  address[4] public teammates;
  address public DAOsVault;//It will be binded after the muti-sig wallet is created and set up  

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public cost;
  uint256 public maxSupply;
  mapping(uint16 => uint256) public maxSupplyForPhase; //mint amount for phase
  uint256 public maxMintAmountPerTx;

  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    uint256 _maxSupplyForPhase,
    string memory _hiddenMetadataUri,
    address[] memory _teammates
  ) ERC721A(_tokenName, _tokenSymbol) { //azuki ERC721A
    salePhase = 0;
    whitelistMintAvailableAmount = 1;
    cost = _cost;
    maxSupply = _maxSupply;
    maxMintAmountPerTx = _maxMintAmountPerTx;
    setHiddenMetadataUri(_hiddenMetadataUri);
    DAOsVault = owner(); //will be setted DAO's vault address
    maxSupplyForPhase[salePhase] = _maxSupplyForPhase;
    for(uint256 i = 0; i < 4; i++){
        _safeMint(_teammates[i], 100); // mint i'th token to i'th teammate
        teammates[i] = _teammates[i]; //teammate addresses 
    }
  }

  modifier mintCompliance(uint256 _mintAmount) { //민팅 가능한 최대 갯수 검증하는 함수
    require(_mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupplyForPhase[salePhase], 'The remaining sales volume is insufficient!(Adjust the number of purchases)');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) { //민팅 가격 * 민트 갯수 만큼 보냈는지 체크  msg.value** 보낸 웨이 
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) external payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify whitelist requirements
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    require(whitelistClaimed[salePhase][_msgSender()]+_mintAmount <= whitelistMintAvailableAmount , 'Your Number of Guaranteed Remaining Amount is insufficient!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    whitelistClaimed[salePhase][_msgSender()] += _mintAmount;
    _safeMint(_msgSender(), _mintAmount);
  }

   function presaleMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) external payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify presale requirements
    require(whitelistMintEnabled, 'The pre sale is not enabled!');
    require(whitelistClaimed[salePhase][_msgSender()] >= _mintAmount, 'Your Number of Guaranteed Remaining Amount is insufficient!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    whitelistClaimed[salePhase][_msgSender()] -= _mintAmount;
    _safeMint(_msgSender(), _mintAmount);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');

    _safeMint(_msgSender(), _mintAmount);
  }
  
  //airdrop
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
      _safeMint(_receiver, _mintAmount);
  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = _startTokenId();
    uint256 ownedTokenIndex = 0;
    address latestOwnerAddress;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      TokenOwnership memory ownership = _ownerships[currentTokenId];

      if (!ownership.burned && ownership.addr != address(0)) {
        latestOwnerAddress = ownership.addr;
      }

      if (latestOwnerAddress == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
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

  function progressNewSalePhase(uint256 _maxSupplyForPhase) external onlyOwner {
    require(_maxSupplyForPhase <= maxSupply, 'wrong supply value! (must be under maxsupply)');
    uint256 total = totalSupply();
    require(_maxSupplyForPhase >= total, 'wrong supply value! (Please enter a number greater than the minted number))');
    salePhase++;
    maxSupplyForPhase[salePhase] = _maxSupplyForPhase;
  }

  function setSalePhase(uint16 _salePhase) public onlyOwner{
    salePhase = _salePhase;
  }

  function getPhaseSupply() external view returns (uint256){
    return maxSupplyForPhase[salePhase];
  }

  function getPossibleSupply() external view returns (uint256){
    return whitelistClaimed[salePhase][_msgSender()];
  }
  
  function setRevealed(bool _state) external onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) external onlyOwner {
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

  function setPaused(bool _state) external onlyOwner {
    paused = _state;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) external onlyOwner {
    whitelistMintEnabled = _state;
  }

  //for starlist, whitelist(variable amount) sale
  function setWhiteListSeeds(uint16 _amount) external onlyOwner
  {
    require(
      _amount > 0,
      "_amount must bigger than 0"
    );
    whitelistMintAvailableAmount = _amount;
  }

  //og+whitelist sale(multiple whitelist)
  function setPresaleSeeds(address[] memory _addresses, uint256[] memory _amount) external onlyOwner
  {
    require(
      _addresses.length > 0,
      "prelist addresses length must be longer than 0"
    );
    require(_addresses.length == _amount.length, "lists length must be same!");
    for (uint256 i = 0; i < _addresses.length; i++) {
      whitelistClaimed[salePhase][_addresses[i]] = _amount[i];
    }
  }

  function withdraw() public onlyOwner nonReentrant {
    uint256 royalty = address(this).balance * 20 / 100;
    
    //royalty
    (bool os, ) = payable(owner()).call{value: royalty}('');
    require(os);

    //to the DAO's vault 
    (bool ds, ) = payable(DAOsVault).call{value: address(this).balance}('');
    require(ds);
    // =============================================================================
  }

  function onlyTeam(address[] memory _teammates) external onlyOwner {
    require(_teammates.length == 4, 'teammates length must be 4');
    for(uint256 i = 0; i < 4; i++){
        teammates[i] = _teammates[i];
    }
  }

  function setDAOsVaultAddress(address _DAOsVault) external onlyOwner{
    DAOsVault = _DAOsVault;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}