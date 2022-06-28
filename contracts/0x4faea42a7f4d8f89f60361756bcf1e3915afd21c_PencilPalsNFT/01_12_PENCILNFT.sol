//SPDX-License-Identifier: MIT

pragma solidity >= 0.8.7;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract PencilPalsNFT is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;

  
  //File type
  string public uriSuffix = '.json';

   // =============================================================================//

  //Prices
  uint256 public phase1Cost = 0.00 ether;
  uint256 public phase2Cost = 0.03 ether;
  uint256 public phase3Cost = 0.05 ether;
  uint256 public walletBalanceLimit = 0.05 ether;
   
   // =============================================================================//

  //Inventory
  string public baseURI;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerWallet;  
  uint256 public phase1Supply = 1000;
  uint256 public phase2Supply = 2000;
  uint256 public phase3Supply = 2000;

   // =============================================================================//
  
  //Keep track count
  uint256 public phase1Count = 0;
  uint256 public phase2Count = 0;
  uint256 public phase3Count = 0;

   // =============================================================================//

  //sale status
  bool public paused = false;
  //mapping
  mapping(address => uint256) public addressMintedBalance;

   // =============================================================================//

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerWallet,
    string memory _initialURI
    

       
  ) ERC721A(_tokenName, _tokenSymbol) {
    //set max supply amount (total collection amount)
    maxSupply = _maxSupply;
    //set max mint amount per wallet
    setMaxMintAmountPerWallet(_maxMintAmountPerWallet);
     //set initial URI
    baseURI = _initialURI;
    
  }
 
 // =============================================================================//

    /**
     * Do not allow calls from other contracts.
     */
   modifier noBots() {
        require(msg.sender == tx.origin, "Pencil Pals NFT: No bots");
        _;
    }

 // =============================================================================//

  modifier mintCompliance(uint256 _mintAmount) {
    //minimum mint should be alteast 1
    require(_mintAmount > 0, 'Mint amount should be greater than 0');
    //exceeded the max supply amount
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }


 // =============================================================================//

  /**
   *  mint
   */
  function mint (uint256 _mintAmount) external payable noBots mintCompliance(_mintAmount){
    //sale status
    require(!paused, 'The contract is paused!');
    //per address quota exceeted
    require(_mintAmount + addressMintedBalance[msg.sender] <= maxMintAmountPerWallet, 'Exceeded the limit');
        //check phases      
        if(phase1Count < phase1Supply){
                //check balance of the wallet is eligible to mint
               require(msg.sender.balance >= walletBalanceLimit ,'you need eth to mint');
                //get current supply amount from phase 1
                uint256 currentSupply = phase1Supply - phase1Count;    
                if(_mintAmount + phase1Count > phase1Supply){
                     // too mint from next phase supply amount
                    uint256 nextSupply = _mintAmount - currentSupply; 
                    uint256 totalPrice = phase2Cost * nextSupply + phase1Cost * currentSupply;
                    require(msg.value >= totalPrice, "Insuffient funds ");
                    
                    phase2Count += nextSupply;
                    phase1Count += currentSupply;

                }else{
                    require(msg.value >= phase1Cost * _mintAmount, "Insuffient funds ");
                    phase1Count += _mintAmount;
                }

        }else if(phase2Count < phase2Supply){
       
                //get current supply amount from phase 2
                uint256 currentSupply = phase2Supply - phase2Count;    
                if(_mintAmount + phase2Count > phase2Supply){
                    // too mint from next phase supply amount
                    uint256 nextSupply = _mintAmount - currentSupply; 
                    uint256 totalPrice = phase3Cost * nextSupply + phase2Cost * currentSupply;
                    require(msg.value >= totalPrice, "Insuffient funds ");
                    
                    phase3Count += nextSupply;
                    phase2Count += currentSupply;

                }else{
                    require(msg.value >= phase2Cost * _mintAmount, "Insuffient funds ");
                    phase2Count += _mintAmount;
                }
                
        } else {   
                require(msg.value >= phase3Cost * _mintAmount, "Insuffient funds ");
                require(phase3Count + _mintAmount <= phase3Supply, 'Phase supply exceeded!');
                phase3Count += _mintAmount;
         }
  
    _mintLoop(_msgSender(), _mintAmount);
    addressMintedBalance[msg.sender] += _mintAmount;
  }

 // =============================================================================//
 
  /**
   *  owner can mint for other address 
   */
  function gift(address _receiver, uint256 _mintAmount) external mintCompliance(_mintAmount) onlyOwner {
        _mintLoop(_receiver, _mintAmount);
  }

 // =============================================================================//

  /**
   * Returns the number of tokens minted by `owner`.
   */
  function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
  }

 // =============================================================================//

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

   // =============================================================================//

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

   // =============================================================================//
  
 function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

   // =============================================================================//
  
  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

   // =============================================================================//

  /**
   *  change cost start
   */
  function setPhase1Cost(uint256 _cost) public onlyOwner {
    phase1Cost = _cost;
  }
   function setPhase2Cost(uint256 _cost) public onlyOwner {
    phase2Cost = _cost;
  }
   function setPhase3Cost(uint256 _cost) public onlyOwner {
    phase3Cost = _cost;
  }
  function setWalletBalanceLimit(uint256 _cost) public onlyOwner {
    walletBalanceLimit = _cost;
  }
  /**
   * change cost end
   */

   // =============================================================================//

  /**
   * change supply start
   */
   function setPhase1(uint256 _amount) public onlyOwner {
    phase1Supply = _amount;
  }
   function setPhase2(uint256 _amount) public onlyOwner {
    phase2Supply = _amount;
  }
   function setPhase3(uint256 _amount) public onlyOwner {
    phase3Supply = _amount;
  }

  function setMaxSupply(uint256 _supply) public onlyOwner {
    maxSupply = _supply;
  }
  /**
   * change supply end
   */

   // =============================================================================//

  /**
   * change others start
   */
  function setMaxMintAmountPerWallet(uint256 _maxMintAmountPerWallet) public onlyOwner {
    maxMintAmountPerWallet = _maxMintAmountPerWallet;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function togglePause() public onlyOwner {
        paused = !paused;
  }
  /**
  * change others end
  */

  // =============================================================================//

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
        _safeMint(_receiver, _mintAmount);
  }

  // =============================================================================//
  
  /**
    * wallets addresses
  **/ 
  address private constant WALLET_A = 0x9dC7A7D3c4FD55FaC37f62BA311E9759F142c525;
  address private constant WALLET_B = 0x2e7f7226dD4A08b1FF20Ef3AE0869ee043E82D1F;
  address private constant WALLET_C = 0x114Cd81Af4700E30faFfD404eaCD67ad050157ae;

  // =============================================================================//

 
  /**
    * withdraw funds
  **/ 
  function withdraw() external payable onlyOwner nonReentrant {
        
      uint256 balance = address(this).balance;
      require(balance  > 0,"Not have Eth");
    // splitting the initial sale funds
    // =============================================================================//
      //15%
      (bool hs, ) = payable(WALLET_A).call{value: balance * 15 / 100}("");
      require(hs, "Failed to send to WALLET_A.");
      //30%
      (bool os, ) = payable(WALLET_B).call{value: balance * 30 / 100}("");
      require(os, "Failed to send to WALLET_B.");
      //55%
      (bool success, ) = payable(WALLET_C).call{value: balance * 55 / 100}("");
      require(success, "Failed to send to WALLET_C.");
    // =============================================================================//
        
  }

  // =============================================================================//

}