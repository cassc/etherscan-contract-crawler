// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "../utils/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


//  /$$                                         /$$
// | $$                                        |__/
// | $$        /$$$$$$   /$$$$$$  /$$$$$$/$$$$  /$$
// | $$       /$$__  $$ /$$__  $$| $$_  $$_  $$| $$
// | $$      | $$  \ $$| $$  \ $$| $$ \ $$ \ $$| $$
// | $$      | $$  | $$| $$  | $$| $$ | $$ | $$| $$
// | $$$$$$$$|  $$$$$$/|  $$$$$$/| $$ | $$ | $$| $$
// |________/ \______/  \______/ |__/ |__/ |__/|__/
                                                
//  /$$    /$$                    /$$   /$$        
// | $$   | $$                   | $$  | $$        
// | $$   | $$ /$$$$$$  /$$   /$$| $$ /$$$$$$      
// |  $$ / $$/|____  $$| $$  | $$| $$|_  $$_/      
//  \  $$ $$/  /$$$$$$$| $$  | $$| $$  | $$        
//   \  $$$/  /$$__  $$| $$  | $$| $$  | $$ /$$    
//    \  $/  |  $$$$$$$|  $$$$$$/| $$  |  $$$$/    
//     \_/    \_______/ \______/ |__/   \___/      
                                                
                                                
interface ILOOMI {
  function depositLoomiFor(address user, uint256 amount) external;
}

interface ISTAKING {
  function ownerOf(address contractAddress, uint256 tokenId) external view returns (address);
}

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract LoomiVault is Context, ERC721Enumerable, Ownable, ReentrancyGuard  {
    using SafeMath for uint256;
    using Strings for uint256;

    // Base URI
    string private _loomiVaultURI;

    // Max number of NFTs
    uint256 public constant MAX_SUPPLY = 5000;
    uint256 public constant INIT_ALLOCATION = 10000 ether;

    uint256 public _vaultPrice;

    bool public saleIsActive;
    bool public creepzRestriction;
    bool private metadataFinalised;

    // Royalty info
    address public royaltyAddress;
    uint256 private ROYALTY_SIZE = 750;
    uint256 private ROYALTY_DENOMINATOR = 10000;
    mapping(uint256 => address) private _royaltyReceivers;

    // Loomi contract
    ILOOMI public LOOMI;
    ISTAKING public STAKING;
    IERC721 public CREEPZ;

    event TokensMinted(
      address indexed mintedBy,
      uint256 indexed tokensNumber
    );

    event BaseUriUpdated(
      string oldBaseUri,
      string newBaseUri
    );

    constructor(address _royaltyAddress, address _loomi, address _staking, address _creepz, string memory _baseURI)
    ERC721("Loomi Vault", "VAULT")
    {
      royaltyAddress = _royaltyAddress;

      LOOMI = ILOOMI(_loomi);
      STAKING = ISTAKING(_staking);
      CREEPZ = IERC721(_creepz);

      _loomiVaultURI = _baseURI;
      creepzRestriction = true;
    }

    function purchase(uint256 tokensToMint, uint256 tokenId) public payable nonReentrant {
      if (_msgSender() != owner()) {
        require(saleIsActive, "The mint has not started yet");
        require(_validateCreepzOwner(tokenId, _msgSender()), "!Creepz owner");
        require(msg.value == _vaultPrice.mul(tokensToMint), "Wrong ETH value provided");
      }
      
      require(tokensToMint > 0, "Min mint is 1 token");
      require(tokensToMint <= 50, "You can mint max 50 tokens per transaction");
      require(totalSupply().add(tokensToMint) <= MAX_SUPPLY, "Mint more tokens than allowed");


      for(uint256 i = 0; i < tokensToMint; i++) {
        _safeMint(_msgSender(), totalSupply());
      }

      LOOMI.depositLoomiFor(_msgSender(), INIT_ALLOCATION.mul(tokensToMint));

      emit TokensMinted(_msgSender(), tokensToMint);
    }

    function _validateCreepzOwner(uint256 tokenId, address user) internal view returns (bool) {
      if (!creepzRestriction) return true;
      if (STAKING.ownerOf(address(CREEPZ), tokenId) == user) {
        return true;
      }
      return CREEPZ.ownerOf(tokenId) == user;
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
      uint256 amount = _salePrice.mul(ROYALTY_SIZE).div(ROYALTY_DENOMINATOR);
      address royaltyReceiver = _royaltyReceivers[_tokenId] != address(0) ? _royaltyReceivers[_tokenId] : royaltyAddress;
      return (royaltyReceiver, amount);
    }

    function addRoyaltyReceiverForTokenId(address receiver, uint256 tokenId) public onlyOwner {
      _royaltyReceivers[tokenId] = receiver;
    }

    function updateSaleStatus(bool status) public onlyOwner {
      require(_vaultPrice != 0, "Price is not set");
      saleIsActive = status;
    }

    function updateVaultPrice(uint256 _newPrice) public onlyOwner {
      require(!saleIsActive, "Pause sale before price update");
      _vaultPrice = _newPrice;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
      require(!metadataFinalised, "Metadata already finalised");

      string memory currentURI = _loomiVaultURI;
      _loomiVaultURI = newBaseURI;
      emit BaseUriUpdated(currentURI, newBaseURI);
    }

    function tokenURI(uint256 tokenId) external view virtual override returns (string memory) {
      require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

      return string(abi.encodePacked(_loomiVaultURI));
    }

    function finalizeMetadata() public onlyOwner {
      require(!metadataFinalised, "Metadata already finalised");
      metadataFinalised = true;
    }

    function updateCreepzRestriction(bool _restrict) public onlyOwner {
      creepzRestriction = _restrict;
    }

    function withdraw() external onlyOwner {
      uint256 balance = address(this).balance;
      payable(owner()).transfer(balance);
    }
}