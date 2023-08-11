//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "../interfaces/IMentaportERC721.sol";
import "./MentaportVerify.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
/**                                            
       
             ___           ___           ___                         ___           ___         ___           ___                   
     /\  \         /\__\         /\  \                       /\  \         /\  \       /\  \         /\  \                  
    |::\  \       /:/ _/_        \:\  \         ___         /::\  \       /::\  \     /::\  \       /::\  \         ___     
    |:|:\  \     /:/ /\__\        \:\  \       /\__\       /:/\:\  \     /:/\:\__\   /:/\:\  \     /:/\:\__\       /\__\    
  __|:|\:\  \   /:/ /:/ _/_   _____\:\  \     /:/  /      /:/ /::\  \   /:/ /:/  /  /:/  \:\  \   /:/ /:/  /      /:/  /    
 /::::|_\:\__\ /:/_/:/ /\__\ /::::::::\__\   /:/__/      /:/_/:/\:\__\ /:/_/:/  /  /:/__/ \:\__\ /:/_/:/__/___   /:/__/     
 \:\~~\  \/__/ \:\/:/ /:/  / \:\~~\~~\/__/  /::\  \      \:\/:/  \/__/ \:\/:/  /   \:\  \ /:/  / \:\/:::::/  /  /::\  \     
  \:\  \        \::/_/:/  /   \:\  \       /:/\:\  \      \::/__/       \::/__/     \:\  /:/  /   \::/~~/~~~~  /:/\:\  \    
   \:\  \        \:\/:/  /     \:\  \      \/__\:\  \      \:\  \        \:\  \      \:\/:/  /     \:\~~\      \/__\:\  \   
    \:\__\        \::/  /       \:\__\          \:\__\      \:\__\        \:\__\      \::/  /       \:\__\          \:\__\  
     \/__/         \/__/         \/__/           \/__/       \/__/         \/__/       \/__/         \/__/           \/__/  
       
       
                                                          
**/

/** 
 * @title MentaportERC721
 * @dev Create a sample ERC721 standard token
 */
contract MentaportERC721 is ERC721URIStorage, MentaportVerify, Ownable, Pausable, ReentrancyGuard, IMentaportERC721  {
 
  using Strings for uint256;
  using Counters for Counters.Counter;

  uint256 public immutable maxSupply;
  uint256 public cost = 0.001 ether;
  uint256 public maxMintAmount = 3;
  
  // variables for contracts using static assets
  bool public isStaticAssets = false;

  address internal _mentaportAccount;
  Counters.Counter internal _supply;

  // we intiate our contract with a hidden URI for our content to make sure we control the information at mint.
  constructor(
    string memory _name,
    string memory _symbol,
    uint256 _maxSupply,
    bool _isStaticAssets,
    address _admin,
    address _minter,
    address _signer,
    address _mentaport
  ) ERC721(_name, _symbol) {

    // Grant roles to specified accounts
    _setupRole(CONTRACT_ADMIN, _admin);
    _setupRole(CONTRACT_ROLE, _admin);
    _setupRole(CONTRACT_ROLE, msg.sender); 

    _setupRole(MINTER_ROLE, _minter);
    // contract owner and _signer can sign contracts
    _setupRole(SIGNER_ROLE, msg.sender);
    _setupRole(SIGNER_ROLE, _signer);

    // setting mentaport and overwriting owner to ONLY mentaport 
    _mentaportAccount = _mentaport;
    _setupRole(MENTAPORT_ROLE, _mentaportAccount);
    _setupRole(MENTAPORT_ADMIN, _mentaportAccount);

    // setting contract parameters
    _pause();
    maxSupply = _maxSupply;

    // setting static assets
    isStaticAssets = _isStaticAssets;
  }

  //----------------------------------------------------------------------------
  // Modifiers 
  /**
  * @dev Mint compliance to check:
  *   - Mint amount is less than max amount to mint
  *   - Still suplly available of tokens to mint
  *
  */
  modifier mintCompliance(address _receiver, uint256 valueSent, uint256 amount) {
    require(_supply.current() + 1 <= maxSupply, "Max supply exceeded!");
    require(balanceOf(_receiver) + 1 <= maxMintAmount, "Max mint amount exceeded");
    require(valueSent * amount  == cost , "Insufficient funds!");
    _; // so we execute this modifier before rest of mint function code
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721URIStorage, AccessControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
  //----------------------------------------------------------------------------
  // External functions  
  /**
  * @dev Change Mentaport account
  *
  *  - Emits a {MentaportAccount} event.
  */
  function changeMentaportAccount(address _newAddress) external nonReentrant {
    require(hasRole(MENTAPORT_ROLE, msg.sender), "Caller is not mentaport");
    _mentaportAccount = _newAddress;

    emit MentaportAccount(msg.sender, _mentaportAccount);
  }

  //----------------------------------------------------------------------------
  // External Only ADMIN, MINTER ROLES
  /**
  * @dev Pause contract
  * Requirements:
  *
  * - The contract must not be paused.
  */
  function pause() external whenNotPaused onlyContractAdmin {
    _pause();
  }
  /**
  * @dev Unpause contract
  * Requirements:
  *
  * - The contract must be paused.
  */
  function unpause() external whenPaused onlyContractAdmin {
    _unpause();
  }
  /**
  * @dev Update tokenURI for a toeknId already minted
  */
  function updateTokenURI(uint256 _tokenId, string memory _newTokenURI) external onlyContractAdmin {
    require(!isStaticAssets, "Not allowed in static asset contracts");
    _setTokenURI(_tokenId, _newTokenURI);
  }

  /**
  * @dev Set max mint amount
  *
  *  - Emits a {SetmaxMintAmount} event.
  */
  function setMaxMintAmount(uint256 _newmaxMintAmount) external onlyOwner {
    maxMintAmount = _newmaxMintAmount;
    emit SetMaxMintAmount(maxMintAmount);
  }
  /**
  * @dev Set cost of token at mint
  *
  *  - Emits a {SetCost} event.
  */
  function setCost(uint256 _newCost) external onlyOwner {
    cost = _newCost;
    emit SetCost(cost);
  }
  /**
  * @dev Owner of contract withdraws funds.
  *  At this point Mentaport account will get paid the commision of 97.5%.
  *
  *  - Emits a {Withdraw} event.
  */
  function withdraw() external nonReentrant onlyOwner {
    // This will pay Mentaport 2.5% of the initial sale
    (bool success, ) = payable(_mentaportAccount).call{value: address(this).balance * 25 / 1000}("");
    require(success);

    // This will payout the owner 97.5% of the contract balance.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool successRest, ) = payable(owner()).call{value: address(this).balance}("");
    require(successRest);

    emit Withdraw();
  }
  
  //----------------------------------------------------------------------------
  // Public functions
  /**
  * @dev Total supply of tokens currently available
  */
  function totalSupply() public view returns (uint256) {
    return _supply.current();
  }
  //----------------------------------------------------------------------------
  // Internal functions
  /**
  * @dev Internal mint nft with unique tokenURI 
  */
  function _mintNFT(address _receiver, string memory _tokenURI) internal returns (uint256) {
    _supply.increment();
    uint256 newTokenId = _supply.current();
    _safeMint(_receiver, newTokenId);
    _setTokenURI(newTokenId, _tokenURI);
  
    emit MintLocation(_receiver, newTokenId);
    return newTokenId;
  }

  /**
  * @dev Internal mint loop 
  */
  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount;) {
      _supply.increment();
      _safeMint(_receiver, _supply.current());
      unchecked { i++; }
    }
  }

}