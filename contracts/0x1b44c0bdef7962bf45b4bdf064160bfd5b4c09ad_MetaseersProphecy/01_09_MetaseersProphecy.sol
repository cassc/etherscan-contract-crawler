// SPDX-License-Identifier: Unlicensed


import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import 'erc721a/contracts/ERC721A.sol';


pragma solidity >=0.8.17 <0.9.0;

contract MetaseersProphecy is ERC721A, Ownable, ReentrancyGuard{
  
  using Strings for uint256;

// ================== Variables Start =======================
  
  // merkletree root hash - p.s set it after deploy from scan
  bytes32 public merkleRoot;
  
  // reveal uri - p.s set it in contructor (if sniper proof, else put some dummy text and set the actual revealed uri just before reveal)
  string internal uri;
  string public uriExtension = ".json";

  // hidden uri - replace it with yours
  string public hiddenMetadataUri = "ipfs://bafybeifah3zl4z7zyhr2zf7fkr5cxwp6y4lz7qnixvrkoramkperwijbfi/1.json";

  // eth prices - replace it with yours
  uint256 public price = 0.012 ether;
  uint256 public wlprice = 0.01 ether;

  // usdc prices - replace it with yours | Please note 1 usdc = 1,000,000 points
  uint256 public usdcprice = 15000000;
  uint256 public usdcwlprice = 10000000;  
  
  // supply - replace it with yours
  uint256 public supplyLimit = 100;
  uint256 public wlsupplyLimit = 100;

  // max per tx - replace it with yours
  uint256 public maxMintAmountPerTx = 100;
  uint256 public wlmaxMintAmountPerTx = 100;

  // max per wallet - replace it with yours
  uint256 public maxLimitPerWallet = 100;
  uint256 public wlmaxLimitPerWallet = 100;

  // enabled
  bool public whitelistSale = false;
  bool public publicSale = false;

  // reveal
  bool public revealed = false;

  // mapping to keep track
  mapping(address => uint256) public wlMintCount;
  mapping(address => uint256) public publicMintCount;

  // total mint trackers
  uint256 public publicMinted;
  uint256 public wlMinted;    

  // usdc address and interface - mainnet address is 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
  address usdcAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
  IERC20 usdcContract = IERC20(usdcAddress);

  // Transfer lock
  bool public transferLock= false;

// ================== Variables End =======================  

// ================== Constructor Start =======================

  // Token NAME and SYMBOL - Replace it with yours
  constructor(
    string memory _uri
  ) ERC721A("Metaseer's Prophecy", "MSP")  {
    seturi(_uri);
  }

// ================== Constructor End =======================

// ================== Mint Functions Start =======================

  // Minting with eth functions

  function WlMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable {

    // Verify wl requirements
    require(whitelistSale, 'The WlSale is paused!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');


    // Normal requirements 
    require(_mintAmount > 0 && _mintAmount <= wlmaxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= wlsupplyLimit, 'Max supply exceeded!');
    require(wlMintCount[msg.sender] + _mintAmount <= wlmaxLimitPerWallet, 'Max mint per wallet exceeded!');
    require(msg.value >= wlprice * _mintAmount, 'Insufficient funds!');
     
    // Mint
     _safeMint(_msgSender(), _mintAmount);

    // Mapping update 
    wlMintCount[msg.sender] += _mintAmount; 
    wlMinted += _mintAmount;
  }

  function PublicMint(uint256 _mintAmount) public payable {
    
    // Normal requirements 
    require(publicSale, 'The PublicSale is paused!');
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= supplyLimit, 'Max supply exceeded!');
    require(publicMintCount[msg.sender] + _mintAmount <= maxLimitPerWallet, 'Max mint per wallet exceeded!');
    require(msg.value >= price * _mintAmount, 'Insufficient funds!');
     
    // Mint
     _safeMint(_msgSender(), _mintAmount);

    // Mapping update 
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

  // Minting with usdc functions

  function WlMintWithUSDC(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable {

    // Verify wl requirements
    require(whitelistSale, 'The WlSale is paused!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');


    // Normal requirements 
    require(_mintAmount > 0 && _mintAmount <= wlmaxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= wlsupplyLimit, 'Max supply exceeded!');
    require(wlMintCount[msg.sender] + _mintAmount <= wlmaxLimitPerWallet, 'Max mint per wallet exceeded!');

    // transfer usdc from minter to the contract
    uint256 amountToSend = usdcwlprice * _mintAmount;
    require(usdcContract.allowance(msg.sender, address(this)) >= amountToSend, "Allowance not met");
    usdcContract.transferFrom(msg.sender,address(this), amountToSend);
     
    // Mint
     _safeMint(_msgSender(), _mintAmount);

    // Mapping update 
    wlMintCount[msg.sender] += _mintAmount; 
    wlMinted += _mintAmount;
  }  

  function PublicMintWithUSDC(uint256 _mintAmount) public payable {
    
    // Normal requirements 
    require(publicSale, 'The PublicSale is paused!');
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= supplyLimit, 'Max supply exceeded!');
    require(publicMintCount[msg.sender] + _mintAmount <= maxLimitPerWallet, 'Max mint per wallet exceeded!');

    // transfer usdc from minter to the contract
    uint256 amountToSend = usdcprice * _mintAmount;
    require(usdcContract.allowance(msg.sender, address(this)) >= amountToSend, "Allowance not met");    
    usdcContract.transferFrom(msg.sender,address(this), amountToSend);    
     
    // Mint
     _safeMint(_msgSender(), _mintAmount);

    // Mapping update 
    publicMintCount[msg.sender] += _mintAmount;  
    publicMinted += _mintAmount;   
  }    
  

// ================== Mint Functions End =======================  

// ================== Set Functions Start =======================

// reveal
  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

// uri
  function seturi(string memory _uri) public onlyOwner {
    uri = _uri;
  }

  function seturiExtension(string memory _uriExtension) public onlyOwner {
    uriExtension = _uriExtension;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

// sales toggle
  function setpublicSale(bool _publicSale) public onlyOwner {
    publicSale = _publicSale;
  }

  function setwlSale(bool _whitelistSale) public onlyOwner {
    whitelistSale = _whitelistSale;
  }

// hash set
  function setwlMerkleRootHash(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

// max per tx
  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setwlmaxMintAmountPerTx(uint256 _wlmaxMintAmountPerTx) public onlyOwner {
    wlmaxMintAmountPerTx = _wlmaxMintAmountPerTx;
  }

// pax per wallet
  function setmaxLimitPerWallet(uint256 _maxLimitPerWallet) public onlyOwner {
    maxLimitPerWallet = _maxLimitPerWallet;
  }

  function setwlmaxLimitPerWallet(uint256 _wlmaxLimitPerWallet) public onlyOwner {
    wlmaxLimitPerWallet = _wlmaxLimitPerWallet;
  }  

// price
  function setPrice(uint256 _price) public onlyOwner {
    price = _price;
  }

  function setwlPrice(uint256 _wlprice) public onlyOwner {
    wlprice = _wlprice;
  }  

  function setusdcPrice(uint256 _usdcprice) public onlyOwner {
    usdcprice = _usdcprice;
  }

  function setusdcwlPrice(uint256 _usdcwlprice) public onlyOwner {
    usdcwlprice = _usdcwlprice;
  } 

// set usdc contract address
  function setUSDCcontractAddress(address _address) public onlyOwner{
    usdcAddress = _address;  
  }

// supply limit
  function setsupplyLimit(uint256 _supplyLimit) public onlyOwner {
    supplyLimit = _supplyLimit;
  }

  function setwlsupplyLimit(uint256 _wlsupplyLimit) public onlyOwner {
    wlsupplyLimit = _wlsupplyLimit;
  }

// transfer lock
  function setTransferLock(bool _state) public onlyOwner{
      transferLock = _state;
  }    

// ================== Set Functions End =======================

// ================== Withdraw Function Start =======================
  
  function withdraw() public onlyOwner nonReentrant {
    //owner withdraw
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function withdrawUSDC() public onlyOwner nonReentrant {
        uint balance = usdcContract.balanceOf(address(this));
        usdcContract.transferFrom(address(this),msg.sender, balance);
    }  

// ================== Withdraw Function End=======================  

// ================== Read Functions Start =======================

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

    /*
     * @notice Block transfers.
     */

      function _beforeTokenTransfers (
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
      if(transferLock == true){
      require(from == address(0) || to == address(0),"Transfers are not available at the moment.");   
     }
    }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriExtension))
        : '';
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uri;
  }

  event ethReceived(address, uint);
    receive() external payable {
        emit ethReceived(msg.sender, msg.value);
    }
// ================== Read Functions End =======================  

}