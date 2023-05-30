// SPDX-License-Identifier: MIT

/*
                                                                                                                      ,----,           
        ,--,,-.----.       ,----..                                                              ,--.                ,/   .`|           
      ,--.'|\    /  \     /   /   \   .--.--.      ,---,    ,----..                           ,--.'|    ,---,.    ,`   .'  :           
   ,--,  | :|   :    \   /   .     : /  /    '. ,`--.' |   /   /   \    ,--,              ,--,:  : |  ,'  .' |  ;    ;     /           
,---.'|  : '|   |  .\ : .   /   ;.  \  :  /`. //    /  :  /   .     : ,--.'|           ,`--.'`|  ' :,---.'   |.'___,/    ,'            
|   | : _' |.   :  |: |.   ;   /  ` ;  |  |--`:    |.' ' .   /   ;.  \|  |,            |   :  :  | ||   |   .'|    :     |  .--.--.    
:   : |.'  ||   |   \ :;   |  ; \ ; |  :  ;_  `----':  |.   ;   /  ` ;`--'_            :   |   \ | ::   :  :  ;    |.';  ; /  /    '   
|   ' '  ; :|   : .   /|   :  | ; | '\  \    `.  '   ' ;;   |  ; \ ; |,' ,'|           |   : '  '; |:   |  |-,`----'  |  ||  :  /`./   
'   |  .'. |;   | |`-' .   |  ' ' ' : `----.   \ |   | ||   :  | ; | ''  | |           '   ' ;.    ;|   :  ;/|    '   :  ;|  :  ;_     
|   | :  | '|   | ;    '   ;  \; /  | __ \  \  | '   : ;.   |  ' ' ' :|  | :           |   | | \   ||   |   .'    |   |  ' \  \    `.  
'   : |  : ;:   ' |     \   \  ',  / /  /`--'  / |   | ''   ;  \; /  |'  : |__         '   : |  ; .''   :  '      '   :  |  `----.   \ 
|   | '  ,/ :   : :      ;   :    / '--'.     /  '   : | \   \  ',  / |  | '.'|        |   | '`--'  |   |  |      ;   |.'  /  /`--'  / 
;   : ;--'  |   | :       \   \ .'    `--'---'   ;   |.'  ;   :    /  ;  :    ;        '   : |      |   :  \      '---'   '--'.     /  
|   ,/      `---'.|        `---`                 '---'     \   \ .'   |  ,   /         ;   |.'      |   | ,'                `--'---'   
'---'         `---`                                         `---`      ---`-'          '---'        `----'                             
        If we listen, we can understand that it is a store of value.

             FortheHPOS10Icommunity,bytheHPOS10Icommunity.

Welcome to the HarryPotterObamaSonic10Inu (BITCOIN) NFT Collection!
 
This smart contract is your gateway to the world of HarryPotterObamaSonic10Inu. 

------------------------------------------------------------------------------------------------------------------------------
ABOUT
------------------------------------------------------------------------------------------------------------------------------

It allows degens like you to mint exclusive NFTs using $BITCOIN or ETH.

Prepare to be amazed and join the forefront of a revolutionary movement!
 
Get ready to dive into the mind-blowing NFT collection that unleashes the untapped potential of your $BITCOIN.
 
Embark on an extraordinary journey as you unlock the true value of your wealth.
 
But be warned, the numbers you encounter here are beyond human comprehension, with an unfathomable magnitude of zeros, revealing infinite possibilities.
 
Embrace this audacious leap into the realm of wei, where the true power of your resources awaits.
 
Will you dare to seize this unparalleled opportunity? The choice is yours.

------------------------------------------------------------------------------------------------------------------------------
MINTING INSTRUCTIONS FOR $BITCOIN
------------------------------------------------------------------------------------------------------------------------------

You will need to approve the NFT contract to spend $BITCOIN on your behalf. 
Follow the steps bellow to allow the exact amount to be spent. 
Since this in wei, these are large numbers with a lot of zeros..

------------------------------------------------------------------------------------------------------------------------------
APPROVE THE NFT CONTRACT TO SPEND YOUR $BITCOIN
------------------------------------------------------------------------------------------------------------------------------

1. Visit the HPOS10I token contract at https://etherscan.io/token/0x72e4f9f808c49a2a61de9c5896298920dc4eeea9#writeContract
2. Connect your wallet.
3. Call the approve function in the HPOS10I token contract with the following parameters:
    - spender: 0xC7FD4e740C41D535273C40cE4b79cD7Ec65636b0 
    - amount: 10000000000000000000000

/// If you want to mint more than one NFT, multiply the amount by the desired quantity. ///

------------------------------------------------------------------------------------------------------------------------------
MINT YOUR NFTs
------------------------------------------------------------------------------------------------------------------------------

1. Visit the NFT contract at https://etherscan.io/address/0xC7FD4e740C41D535273C40cE4b79cD7Ec65636b0#writeContract
2. Call the `mintNFTforRealPeoplesBITCOIN` function in the NFT contract, specifying the quantity of NFTs you wish to mint.

------------------------------------------------------------------------------------------------------------------------------
PS: Need to mint quickly? If you're a true degen in a hurry, you can mint NFTs using ETH as well.
Each NFT is priced at 0.025 ETH. Simply call the mintNFTforETH function with the desired quantity of NFTs to mint.

*/

pragma solidity ^0.8.4;

import { RevokableOperatorFilterer } from "./RevokableOperatorFilterer.sol";
import { RevokableDefaultOperatorFilterer } from "./RevokableDefaultOperatorFilterer.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract NFTContract is
  ERC721AQueryable,
  ERC721ABurnable,
  RevokableDefaultOperatorFilterer,
  Ownable,
  ReentrancyGuard
{
  using SafeMath for uint256;

  uint256 private _mintCost;
  uint256 private _currentErc20Cost;

  uint256 private _freeSupply;
  uint256 private _maxSupply;

  address erc20Address;

  bool private _isPublicMintEnabled;
  bool private _isPresaleMintEnabled;
  bool private _isSaleClosed;


  string private _tokenBaseURI =
    "ipfs://QmVvCHjejfMwmyHnKEkzA8QT14PnigDewN7tH94q8NpdJv/"; // IPFS base URI for all tokens

  function setApprovalForAll(address operator, bool approved)
    public
    override(ERC721A, IERC721A)
    onlyAllowedOperatorApproval(operator)
  {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId)
    public
    payable
    override(ERC721A, IERC721A)
    onlyAllowedOperatorApproval(operator)
  {
    super.approve(operator, tokenId);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  function owner()
    public
    view
    virtual
    override(Ownable, RevokableOperatorFilterer)
    returns (address)
  {
    return Ownable.owner();
  }

  /**
   * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
   */

  constructor()
    ERC721A("HPOS10I NFTS", "HPOS10I NFT")
    Ownable()
  {

    _freeSupply = 420;
    _maxSupply = 4200;

    _mintCost = 0.025 ether;
    _currentErc20Cost = 10000 ether;

    _isPublicMintEnabled = false;
    _isSaleClosed = false;

    erc20Address = 0x72e4f9F808C49A2a61dE9C5896298920Dc4EEEa9;
  }

  /**
   * @dev     Changes contract state to enable public access to `mintTokens` function
   * Can only be called by the current owner.
   */
  function allowPublicMint() public onlyOwner {
    _isPublicMintEnabled = true;
  }

  /**
   * @dev     Changes contract state to disable public access to `mintTokens` function
   * Can only be called by the current owner.
   */
  function denyPublicMint() public onlyOwner {
    _isPublicMintEnabled = false;
  }

  /**
   * @dev Changes contract state to enable public access to `burnBackStagePassForRave` function
   * Can only be called by the current owner.
   */
  function closeSale() public onlyOwner {
    _isSaleClosed = true;
  }

  /**
   * @dev Changes contract state to disable public access to `burnBackStagePassForRave` function
   * Can only be called by the current owner.
   */
  function reOpenSale() public onlyOwner {
    _isSaleClosed = false;
  }

  /**
   * @dev     Mint a token to each Address of `recipients`.
   * Can only be called if requirements are satisfied.
   */
  function mintTokensTo(address[] calldata recipients)
    public
    payable
    nonReentrant
  {
    require(recipients.length > 0, "Missing recipient addresses");
    require(owner() == msg.sender, "Only owner can airdrop");
    require(
      recipients.length > 0 && recipients.length <= 20,
      "You can drop minimum 1, maximum 20 NFTs"
    );
    require(
      recipients.length.add(totalSupply()) < (_maxSupply + 1),
      "Exceeds max supply"
    );

    for (uint256 i = 0; i < recipients.length; i++) {
      _safeMint(recipients[i], 1);
    }
  }

  /**
   * @dev Mint `count` tokens if requirements are satisfied.
   *
   */
  function mintNFTforETH(uint256 count) public payable nonReentrant {
    require(_isPublicMintEnabled || owner() == msg.sender, "Mint disabled");
    require(
      count > 0 && count <= 20,
      "You can mint minimum 1, maximum 20 NFTs"
    );
    require(totalSupply() < (_maxSupply + 1), "Exceeds max supply");

    require(
      owner() == msg.sender || msg.value >= _mintCost.mul(count),
      "Ether value sent is below the price"
    );

    _safeMint(msg.sender, count);
  }

  /**
   * @dev Mint token for HPOS10INU
   *
   */
  function mintNFTforRealPeoplesBITCOIN(uint256 count) public nonReentrant {
    require(_isPublicMintEnabled || owner() == msg.sender, "Mint disabled");
    require(
      count > 0 && count <= 20,
      "You can mint minimum 1, maximum 20 NFTs"
    );

    require(totalSupply() < (_maxSupply + 1), "Exceeds max supply");

    IERC20(erc20Address).transferFrom(msg.sender, address(this), count.mul(currentErc20Cost()));

    _safeMint(msg.sender, count);
  }

  function freeMint(uint256 count) public nonReentrant {
    require(_isPublicMintEnabled || owner() == msg.sender, "Mint disabled");
    require(
      count > 0 && count <= 20,
      "You can mint minimum 1, maximum 20 NFTs"
    );

    require(totalSupply() < (_maxSupply + 1), "Exceeds max supply");
    require(totalSupply() <= _freeSupply, "You can only mint for erc20 token");

    _safeMint(msg.sender, count);
  }



  /**
   * @dev Returns the current cost of mint.
   */
  function currentErc20Cost() public view returns (uint256) {
    return _currentErc20Cost;
  }

  /**
   * @dev Update the cost
   * Can only be called by the current owner.
   */
  function setCurrentErc20Cost(uint256 cost) public onlyOwner {
    _currentErc20Cost = cost;
  }

  /**
   * @dev Sets the  ERC20 address
   * @param _erc20Address The RAVE token address
   */

  function setErc20Address(address _erc20Address) public onlyOwner {
    erc20Address = _erc20Address;
  }

  /**
   * @dev     Update the max supply.
   * Can only be called by owner.
   */
  function setMaxSupply(uint256 max) public onlyOwner {
    _maxSupply = max;
  }

  /**
   * @dev Update the cost to mint a token.
   * Can only be called by owner.
   */
  function setCost(uint256 cost) public onlyOwner {
    _mintCost = cost;
  }

  /**
   * @dev     Transfers balance to owner.
   * Can only be called by owner.
   */
  function withdraw() public onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

  /**
   * @dev     Transfers balance to owner.
   * Can only be called by owner.
   */
  function withdrawErc20(address _erc20TokenContractAddress) public onlyOwner {
    IERC20(_erc20TokenContractAddress).transfer(msg.sender, IERC20(_erc20TokenContractAddress).balanceOf(address(this)));
  }

  /**
   * @dev     Returns the maximum supply
   * @return  uint256  maximumSupply
   */
  function getMaxSupply() public view returns (uint256) {
    return _maxSupply;
  }

  /**
   * @dev     Returns the current supply
   * @return  uint256  totalSupply
   */
  function getCurrentSupply() public view returns (uint256) {
    return totalSupply();
  }

  /**
   * @dev     Returns the status of the mint. True if mint is enabled.
   * @return  bool  isPublicMintEnabled
   */
  function getMintStatus() public view returns (bool) {
    return _isPublicMintEnabled;
  }

  /**
   * @dev     Changes the base URI.
   * @param   URI  URI of the metadata directory
   * Can only be called by owner.
   */
  function setBaseURI(string calldata URI) external onlyOwner {
    _tokenBaseURI = URI;
  }

  function _baseURI() internal view override returns (string memory) {
    return _tokenBaseURI;
  }
}