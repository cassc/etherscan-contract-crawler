//SPDX-License-Identifier: MIT     

// Apes are back into the Runner race. NFTs have always been a kingdom of Apes and they are back to conquer it again.  

//                                    ,▄▄████████▄▄▄▄
//                                  ▄██████████████████▄
//                                ,██████████████████████▄
//                                ██████▀▀▀▀▀▀▀▀▀▀▀▀███████▄
//                              ▄██▀▀  ▄▄▄▄▄▄▄██████▄▄▄⌐▀████
//                             ▄▀ ,▄██████████████▀▀▀▀███▄▀███▌
//                            ▄▄███▀▀ ¿╓═╖  ▀▐▌  ¿Φ[▌;Ñ▌▐██▄▄▀▀█▄
//                           ▐██▓██████████Å▓ƒ█  ▀▄█▓▓█████████▄▀⌐
//                           ▌H╚╨███▓▀▓X█▓▓███████,▄█▄▄▓████████▌█
//                          ▐Ü▓╤▄█▌▀▌▄▄▄▐▓Å▌▓▓▐▓███▓╝▀█▀████▌▐▓╜▌█
//                          █Å ` ██Z4▄▓▓███ ╛▐▓"▓▌███▓▓▓█████p╬╧▓▐
//                          ▌X   ████▓████▄▄▄ ▄▄▓▓p█████████▀w%╝▐▐
//                         ▐⌠-  ╙██████▀"  ▀▀█▐██▀Kδ▓██████▀W┴ ,▌█
//                         -▄∞j  ▀████▌       ╘   ╓▀ ╩█████H' ¿▐▐
//                          ▐Ω¿   ▀███▌  .  ▐╒ÜΩ╓1▄Ö▓╚▓███└═ -y▄▀
//                           █Yy    ╘█▌,▐ⁿM╧▄4▄▄▄▓▓▌▓▄███h- :P▄▀
//                            ▄Ç     `█⌂▐██████████████▌Å.  ƒ▄
//                           `▄YÇ    ▐▌ ""^▀J÷¢▓Ö▓▀▓▓▌v'. ▄]'
//                             ▀▓¿    ▐▄  X═` ,.▐▄███(.' .Γ█
//                               █Σ═   '7█▄▄▄╖√⌐▓└███'¬  \╜█
//                            ,▄████▌C  ▐█████████████C .▀████▄▄
//                          ▄█▓████████▄,▀███████████▌  ▀████████▄
//                        ▄███▐██████████L▀██████████  Γ███████▓███
//                       ▄████▓███████▀▀▀█ █████▓▓█▀▀"^═███████▓████
//                      ▄██████████▀╒]xwQµ,▀████▀   └¢  <╓▀██████████
//                     █████████▀.─   ''"╗A,"██ '  ╒╢▄ ÷▓j¬,▀████████▄
//                   ▄████████▀ ç         ▄p ,█ ▓;-- H,Ç$Ä╙╬Φ⌐████████
//                  ██████████µ 'j⌐ -   ⌐Å▐╓ Z▐▌Q▌   ▄/P▄4▄╟dp▀▀███████▄
//                 ███████▀█  ╘  É⌐L>'Σ5^Å▄▌~J██'▌H╙⌐╓DQ¬▀4\╩c▐▌▐██ '███▌
//                ▐█████▌  ██  ▀ 'Ç[µ▄▓▄▄▄M▐ ,███▄┐╫▄▄▄▄,µj2╙ Ñr▐██U ▐███▓
//                ▐█████▌  ███▄"t█▄█████▄▄▄▄██████████Ü▓███████K▀██▌. ████
//                 ██████   ▀█╝'████████▌▐████████████▌▓███████▌C▐█H╚▐███
//                  ▀█████▄ <╘,<████████Å███████▀██████║████████ ~█ƒ;██▀
//                       '  ███████████Ü▐██▌▀▓▌⌐▄▀▀████▐█████████▄∞▀
    
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";

pragma solidity >=0.8.0 <0.9.0;

contract ApeRunners is ERC721A, Ownable {

  /** ERRORS */
  error ExceedsMaxSupply();
  error InvalidAmount();
  error FreeMintOver();
  error ExceedsWalletLimit();
  error InsufficientValue();
  error TokenNotFound();
  error ContractMint();
  error SaleInactive();

  using Strings for uint256;

  uint256 public cost = 0.002 ether;
  uint256 public maxSupply = 5555;
  uint256 public maxMintAmountPerTx = 20;
  uint256 public freeMaxMintPerWallet = 10;

  uint256 public FREE_MINT_MAX = 1500;
  
  bool public saleActive = false;
  bool public revealed = false;
  
  mapping(address => uint256) public freeWallets;

  string _baseTokenURI;

  constructor(string memory baseURI) ERC721A("ApeRunners", "APERUNNERS") payable {
      _baseTokenURI = baseURI;
  }

  modifier mintCompliance(uint256 _mintAmount) {
    if (!saleActive) revert SaleInactive();
    if (msg.sender != tx.origin) revert ContractMint();
    if (totalSupply() + _mintAmount > maxSupply) revert ExceedsMaxSupply();
    if (_mintAmount < 1 || _mintAmount > maxMintAmountPerTx) revert InvalidAmount();
    _;
  }

  function freeMint(uint256 _mintAmount) public mintCompliance(_mintAmount) {
    if (!isFreeMint()) revert FreeMintOver();
    if (freeWallets[msg.sender] + _mintAmount > freeMaxMintPerWallet) revert ExceedsWalletLimit();
    unchecked { freeWallets[msg.sender] += _mintAmount; }

    _safeMint(msg.sender, _mintAmount);
  }

  function paidMint(uint256 _mintAmount)
    external
    payable
    mintCompliance(_mintAmount)
  {
    if (msg.value < (cost * _mintAmount)) revert InsufficientValue();
    _safeMint(msg.sender, _mintAmount);
  }

  function _startTokenId()
      internal
      view
      virtual
      override returns (uint256) 
  {
      return 1;
  }

  function isFreeMint() public view returns (bool) {
    return totalSupply() < FREE_MINT_MAX;
  }

  function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }
 
  function setMaxSupply(uint256 _maxSupply) external onlyOwner {
    maxSupply = _maxSupply;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }
  
  function toggleSaleState() public onlyOwner {
    saleActive = !saleActive;
  }

  function setMaxFreeMint(uint256 _max) public onlyOwner {
    FREE_MINT_MAX = _max;
  }

  function setMaxFreeMintPerWallet(uint256 _max) public onlyOwner {
    freeMaxMintPerWallet = _max;
  }

  function withdraw() public onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

  /** METADATA */
  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function setRevealed(bool state) public onlyOwner {
      revealed = state;
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    if (!_exists(_tokenId)) revert TokenNotFound();

    if (!revealed) return _baseURI();
    return string(abi.encodePacked(_baseURI(), _tokenId.toString(), ".json"));
  }

}