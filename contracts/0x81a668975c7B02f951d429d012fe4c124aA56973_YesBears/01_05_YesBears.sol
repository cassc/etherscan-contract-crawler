// SPDX-License-Identifier: MIT

import "./YesBear.sol";

pragma solidity >=0.8.9 <0.9.0;

contract YesBears is ERC721AQueryable, Ownable, ReentrancyGuard {
  using Strings for uint256;

	uint256 public Ownermint;
  uint256 public maxSupply;
  uint256 public maxPerAddress;
	uint256 public maxPerTX;
  uint256 public cost;
	mapping(address => bool) public freeMinted;

    bool public paused = true;

	string public uriPrefix = '';
    string public uriSuffix = '.json';
	
  constructor(string memory baseURI,
    uint256 _supply,
    uint256 _price,
    uint256 _maxPerAddress,
    uint256 _maxPerTx,
    uint256 _ownerMint
  ) ERC721A("Yes Bears", "YES") {
      Ownermint = _ownerMint;
      maxSupply = _supply;
      cost = _price;
      maxPerAddress = _maxPerAddress;
      maxPerTX = _maxPerTx;

      setUriPrefix(baseURI); 
      _safeMint(_msgSender(), Ownermint);

  }

  modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
  }

  function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
  }

  function mint (uint256 _mintAmount) public payable nonReentrant callerIsUser{
        require(!paused, 'The contract is paused!');
        require(numberMinted(msg.sender) + _mintAmount <= maxPerAddress, 'PER_WALLET_LIMIT_REACHED');
        require(_mintAmount > 0 && _mintAmount <= maxPerTX, 'Invalid mint amount!');
        require(totalSupply() + _mintAmount <= (maxSupply), 'Max supply exceeded!');
	if (freeMinted[_msgSender()]){
        require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
  }
    else{
		require(msg.value >= cost * _mintAmount - cost, 'Insufficient funds!');
        freeMinted[_msgSender()] = true;
  }

    _safeMint(_msgSender(), _mintAmount);
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function setMaxSupply(uint256 _supply) public onlyOwner {
      maxSupply = _supply;
  }

  function unpause () public onlyOwner {
    paused = !paused;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setmaxPerTX(uint256 _maxPerTX) public onlyOwner {
    maxPerTX = _maxPerTX;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }
 
  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}