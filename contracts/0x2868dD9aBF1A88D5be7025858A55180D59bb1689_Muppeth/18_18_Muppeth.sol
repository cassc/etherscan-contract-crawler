// SPDX-License-Identifier: MIT

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%((///#&@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@&.     ,%@@@&      *@@@&,     (@@&*     (@@%,         .*%@@@@#.         ./%@@@@(           #&.            /@#.    .%@@&,     /@@@@@@#(((###((((/*//&@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@(       *&@@.       &@@&.     (@@%,     /@@#.             ,@@#              *@@/           (&             *@(     .%@@&.     /@@@@#///(#((((/**/////(@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@,        (@,        (@@&,     (@@%,     (@@#.     (&#.     (@#      %&(.     %@/     ,@@@@@@@***,      ***#@(      (##(.     /@@@#/((/((((///(((/(/***@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@#.    .    /    .    [email protected]@&.     (@@%,     /@@#.     ,*.      #@#      ,*.      &@/          ,&@@@@#      @@@@@(                /@@@//(((((///(//((((((//#@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@*     (*       //     #@&,     (@@%,     (@@#.             %@@#             .&@@/          *&@@@@#      @@@@@(                /@&&(####(//(((((///((//*@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@%.    .&%,     *@#     ,@&/      ..       &@@#.     (&&&&@@@@@@#      #&&&@@@@@@@/      ,,,,,#@@@@#      @@@@@(     .%@@&.     /@&%@(((/((/((((/////***&@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@/     ,@@#.   [email protected]@%.     %@@(.           *&@@@#.     #@@@@@@@@@@#      %@@@@@@@@@@/           (@@@@#      @@@@@(     .%@@&.     /@@%&@&(/((//(#/(/(///%@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@%#####&@@@%###&@@@%#####&@@@@@%(/////#@@@@@@@&%#####&@@@@@@@@@@&######@@@@@@@@@@@&###########&@@@@&######@@@@@&%####%&@@@%#####&@@&%@@@@&%#((/#((#&@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@       @   @@   *@      #@@@@@*  ,@&      ,@@@   @@@,      @@.      &@@@@@@.    /@@      [email protected]@@   *@&   @       @,      (@@@    #@@@@     (       @@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@   &@@   @@   *@   ,##@@@@@@*  ,@&   @@   &@   @&   @@@   #@@.  #@@@@@@%   @@@@&   @@@   &@     &   @@@   %@@,  (@   @@.  *  %@#   @@@@@@   &@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@   &@@   ##.  *@   *@@@@@@@@*  ,@&   @@   &@   &@    #.   &@@.  #@@@@@@&   .#,/@   .#.   @@   @     @@@   %@@,      @@*       &&   .#.(@@   &@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@   @@@   @@   *@      (@@@@@/  ,@&      @@@@   @@@@,    &@@@@.  #@@@@@@@@&    (@@@.    @@@@   @@#   @@@   %@@,  (@   ,   @@&   @@&    #@@   %@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";     

error WithrawMissMatch();
error SoldOut();
error MaxMinted();
error CannotSetZeroAddress();
error NotWhitelisted();
error MissingProof();
error PriceNotMet();
error AlreadyMinted();
error AlreadyFreeMinted();
error AlreadyReveled();
error ExccedsMaxFreemint();
error MintZeroQuantity();
error NonExistentToken();
error PercentageOutOfBound();
error PercentageMissMatch();

/** 
  * Muppeth aims to bring together the world of fashion and web3.
  * Basically the biggest assholes on the internet.
  */

contract Muppeth is ERC721Enumerable, ERC2981, Ownable {
  using Address for address;
  using Strings for uint256;
  using Counters for Counters.Counter;

  uint constant PRICE = 5 ether / 100; // 0.05 ETH
  uint256 public MAX_SUPPLY = 6969;
  uint constant MAX_MINT_PER_IDIOT = 3;
  string public baseURI;
  bool public PUBLIC_SALE;
  bool private REVEALED;
  bool private TEAM_MINT;

  // Sets Treasury Address for ERC2981 royaltyInfo
  address public treasuryAddress;

  // Withdraw params
  // FUCK YELLOW NAMES ! 
  address[] private _yellowNames;
  mapping(address => uint256) private _percentage;

  bytes32 public immutable root;
  bytes32 public immutable freeMintRoot;

  // Check freemints
  mapping(address => bool) public freemints;

  Counters.Counter private _tokenIdCounter;
      
  
  constructor(
      address defaultTreasury,
      bytes32 defaultRoot,
      bytes32 defaultFreeMintRoot,
      string memory defaultUri,
      address[] memory addresses_,
      uint256[] memory percentage_
  ) ERC721 ("Muppeth", "MPTH") {
      if(addresses_.length != percentage_.length) revert WithrawMissMatch();
      uint256 totalPercentage = 0;
      for (uint256 i = 0; i < addresses_.length; i++) {
        if (addresses_[i] == address(0x0)) revert CannotSetZeroAddress();
        if (percentage_[i] <= 0 || percentage_[i] > 10000) revert PercentageOutOfBound();
        _percentage[addresses_[i]] = percentage_[i];
        totalPercentage = totalPercentage + percentage_[i];
      }
      if (totalPercentage != 10000) revert PercentageMissMatch();
      _yellowNames = addresses_;

      setTreasuryAddress(payable(defaultTreasury));
      setRoyaltyInfo(500);
      setSale(false);
      baseURI = defaultUri;
      root = defaultRoot;
      freeMintRoot = defaultFreeMintRoot;
      _tokenIdCounter.increment();
      REVEALED = false;
      TEAM_MINT = false;
  }

  /**
    * @notice This function allows you to obtain your fucking NFTs.
    * 
    * @param quantity the quantity of tokens to mint
    * @param proof the Merkle proof for this claimer
    */
  function mint(uint256 quantity, bytes32[] calldata proof) external payable {
      if(!MerkleProof.verify(proof, freeMintRoot, keccak256(abi.encodePacked(msg.sender)))) {
        if(!PUBLIC_SALE) {
          if(proof.length == 0) revert MissingProof();
          if(!MerkleProof.verify(proof, root, keccak256(abi.encodePacked(msg.sender)))) revert NotWhitelisted();
        }
        if(msg.value < PRICE * quantity) revert PriceNotMet();
      } else {
        if(freemints[msg.sender]) revert AlreadyFreeMinted();
        if(quantity > 1) revert ExccedsMaxFreemint();
        freemints[msg.sender] = true;
      }

      if(totalSupply() + quantity > MAX_SUPPLY) revert SoldOut();
      if(balanceOf(msg.sender) + quantity > MAX_MINT_PER_IDIOT) revert MaxMinted();

      _batchMint(msg.sender, quantity);
  }
  
  /**
   * Mint Team supply
   */
  function mintTeam(address teamAddress_, uint256 teamSupply_) external notMinted {
    _batchMint(teamAddress_, teamSupply_);
  }

  // OWNER FUNCTIONS ---------
  /** 
    * @dev Update whitelist root
    */
  function setSale(bool sale) public onlyOwner {
      PUBLIC_SALE = sale;
  }
  /**
   * @dev Execute when team supply is minted to lock it
   */
  function setTeamMint() public onlyOwner {
      if (!TEAM_MINT)
        TEAM_MINT = true;
  }

  /**
    * @notice This function allows us to reveal why you paid 0.05 ETH.
    * 
    * @dev Update base URI
    */
  function reveal(string memory uri) public onlyOwner notRevealed {
      baseURI = uri;
      REVEALED = true;
  }
  
  /**
    * @dev Update the royalty percentage (500 = 5%)
    */
  function setRoyaltyInfo(uint96 newRoyaltyPercentage) public onlyOwner {
      _setDefaultRoyalty(treasuryAddress, newRoyaltyPercentage);
  }

  /**
    * @dev Update the royalty wallet address
    */
  function setTreasuryAddress(address payable newAddress) public onlyOwner {
      if (newAddress == address(0)) revert CannotSetZeroAddress();
      treasuryAddress = newAddress;
  }

  /**
    * @notice This function allows us to retrieve the money and launder it.
    * 
    * @dev Withdraw funds to _yellowNames
    */    
  function withdraw() external onlyOwner {
      uint256 balance = address(this).balance;
      for(uint256 i = 0; i < _yellowNames.length; i++) {
        Address.sendValue(payable(_yellowNames[i]), balance * _percentage[_yellowNames[i]] /  10000);  
      }
  }

  // OVERRIDES

  /**
    * @dev Batch mint
    */
  function _batchMint(address to, uint256 quantity) internal {
      if (quantity == 0) revert MintZeroQuantity();
      
      for (uint256 i = 0; i < quantity; ++i) { 
          uint256 tokenId = _tokenIdCounter.current();
          _tokenIdCounter.increment();
          _mint(to, tokenId);
      }
  }

  /**
    * @dev Variation of {ERC721Metadata-tokenURI}.
    */
  function tokenURI(uint256 tokenID) public view override returns (string memory) {
      if(!_exists(tokenID)) revert NonExistentToken();
      if (REVEALED)
        return string(abi.encodePacked(baseURI, tokenID.toString()));
      else
        return string(baseURI);
  }


  /**
    * @dev {ERC165-supportsInterface} Adding IERC2981 
    */
  function supportsInterface(bytes4 interfaceId)
      public
      view
      override(ERC721Enumerable, ERC2981)
      returns (bool)
  {
      return
          ERC2981.supportsInterface(interfaceId) ||
          super.supportsInterface(interfaceId);
  }

  // MODIFIERS
  modifier notRevealed() {
      if(REVEALED) revert AlreadyReveled();
        _;
  }

  modifier notMinted() {
      if (TEAM_MINT) revert AlreadyMinted();
        _;
  }
}