// SPDX-License-Identifier: MIT

/*     


BBBBBBBBBBBBBBBBB                                     kkkkkkkk                  CCCCCCCCCCCCC                   iiii                   
B::::::::::::::::B                                    k::::::k               CCC::::::::::::C                  i::::i                  
B::::::BBBBBB:::::B                                   k::::::k             CC:::::::::::::::C                   iiii                   
BB:::::B     B:::::B                                  k::::::k            C:::::CCCCCCCC::::C                                          
  B::::B     B:::::B   ooooooooooo      ooooooooooo    k:::::k    kkkkkkkC:::::C       CCCCCC   ooooooooooo   iiiiiiinnnn  nnnnnnnn    
  B::::B     B:::::B oo:::::::::::oo  oo:::::::::::oo  k:::::k   k:::::kC:::::C               oo:::::::::::oo i:::::in:::nn::::::::nn  
  B::::BBBBBB:::::B o:::::::::::::::oo:::::::::::::::o k:::::k  k:::::k C:::::C              o:::::::::::::::o i::::in::::::::::::::nn 
  B:::::::::::::BB  o:::::ooooo:::::oo:::::ooooo:::::o k:::::k k:::::k  C:::::C              o:::::ooooo:::::o i::::inn:::::::::::::::n
  B::::BBBBBB:::::B o::::o     o::::oo::::o     o::::o k::::::k:::::k   C:::::C              o::::o     o::::o i::::i  n:::::nnnn:::::n
  B::::B     B:::::Bo::::o     o::::oo::::o     o::::o k:::::::::::k    C:::::C              o::::o     o::::o i::::i  n::::n    n::::n
  B::::B     B:::::Bo::::o     o::::oo::::o     o::::o k:::::::::::k    C:::::C              o::::o     o::::o i::::i  n::::n    n::::n
  B::::B     B:::::Bo::::o     o::::oo::::o     o::::o k::::::k:::::k    C:::::C       CCCCCCo::::o     o::::o i::::i  n::::n    n::::n
BB:::::BBBBBB::::::Bo:::::ooooo:::::oo:::::ooooo:::::ok::::::k k:::::k    C:::::CCCCCCCC::::Co:::::ooooo:::::oi::::::i n::::n    n::::n
B:::::::::::::::::B o:::::::::::::::oo:::::::::::::::ok::::::k  k:::::k    CC:::::::::::::::Co:::::::::::::::oi::::::i n::::n    n::::n
B::::::::::::::::B   oo:::::::::::oo  oo:::::::::::oo k::::::k   k:::::k     CCC::::::::::::C oo:::::::::::oo i::::::i n::::n    n::::n
BBBBBBBBBBBBBBBBB      ooooooooooo      ooooooooooo   kkkkkkkk    kkkkkkk       CCCCCCCCCCCCC   ooooooooooo   iiiiiiii nnnnnn    nnnnnn


*/       

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IMintableERC1155.sol";

/**
 * @title BoinCoinNFT 
 * BoinCoinNFT (modified ERC1155PresetMinterPauser) - See OpenZeppelin
 * /// bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
 * /// 
 */
contract BookCoinNFT is Ownable, AccessControlEnumerable, ERC1155Burnable, IERC2981, IMintableERC1155 {
  bytes32 public constant CAT_ROLE = keccak256("CAT_ROLE");
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  // fallback name used for collection on OpenSea if contractURI does not exist
  string public name = "BookCoin 2.0"; 
  mapping(address => bool) private _whitelisted;

  /* Royalties */
  address internal _royaltyFeeRecipient;
  uint8 internal _royaltyFee; // out of 1000
  string internal _contractUri;

  constructor(string memory baseUriwithTrailingSlash, string memory contractUri, string memory collectionName, address owner, address royaltyFeeRecipient,
        uint8 royaltyFee) ERC1155(baseUriwithTrailingSlash)  {
    name = collectionName;
    _setupRole(CAT_ROLE, _msgSender());
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(MINTER_ROLE, _msgSender());
    transferOwnership(owner);

    _contractUri = contractUri;

    setRoyaltyFeeRecipient(royaltyFeeRecipient);
    _royaltyFee = type(uint8).max;
    if (royaltyFee != 0) setRoyaltyFee(royaltyFee);
  }

  function contractURI() public view returns (string memory) {
        return _contractUri;
  }

  function setContractURI(string memory newContractUri) public {
      require(hasRole(CAT_ROLE, _msgSender()), "CAT_ROLE required");
      _contractUri = newContractUri;
  }

  /* Minting functionality */
  /**
     * @dev Creates `amount` new tokens for `to`, of token type `id`.
     *
     * See {ERC1155-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external override {
        require(hasRole(MINTER_ROLE, _msgSender()), "MINTER_ROLE required");

        _mint(to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] variant of {mint}.
     */
    function mintBatch(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external override {
        require(hasRole(MINTER_ROLE, _msgSender()), "must have minter role to mint");

        _mintBatch(to, ids, amounts, data);
    }

  /**
   * Overriding isApprovedForAll to auto-approve OpenSea's ERC1155 proxy contract and Venly's marketplaces.
   * TODO: Only add addresses for their respective networks or this becomes a potential security issue.
   */
  function isApprovedForAll(
      address _owner,
      address _operator
  ) public override view returns (bool isOperator) {
      if (_whitelisted[_operator]) {
        return true;
      }
      
    return ERC1155.isApprovedForAll(_owner, _operator);
  }

  function setWhitelist(address _operator, bool approved) external {
    require(hasRole(CAT_ROLE, _msgSender()), "CAT_ROLE required");

    _whitelisted[_operator] = approved;
    emit WhitelistModified(_operator, approved);
  }

  event WhitelistModified(address indexed account, bool approved);

  /**
  * Should look like https://token-cdn-domain/{id}.json where receiver is responsible for interpolating the tokenId where {id} exists in the uri.
  */
  function setUri(string memory newUri) external {
    require(hasRole(CAT_ROLE, _msgSender()), "CAT_ROLE required");
    ERC1155._setURI(newUri);
  }

  function uri(uint256 _id) public view override returns (string memory) {
    return string(abi.encodePacked(baseUri(_id), Strings.toString(_id), ".json"));
  }

  function baseUri(uint256 _id) public view returns (string memory) {
    return super.uri(_id);
  }

  event SetRoyaltyFee(uint8 royaltyFee);
  event SetRoyaltyFeeRecipient(address indexed royaltyFeeRecipient);

  function royaltyFeeInfo() public view returns (address recipient, uint8 permil) {
        return (_royaltyFeeRecipient, _royaltyFee);
  }

  function royaltyInfo(uint256, uint256 _salePrice) external view override returns (address, uint256) {
      return (_royaltyFeeRecipient, (_salePrice * _royaltyFee) / 1000);
  }

  function setRoyaltyFeeRecipient(address royaltyFeeRecipient) public {
    require(hasRole(CAT_ROLE, _msgSender()), "CAT_ROLE required");
      require(royaltyFeeRecipient != address(0), "INVALID_FEE_RECIPIENT");

      _royaltyFeeRecipient = royaltyFeeRecipient;

      emit SetRoyaltyFeeRecipient(royaltyFeeRecipient);
  }

  function setRoyaltyFee(uint8 royaltyFee) public {
    require(hasRole(CAT_ROLE, _msgSender()), "CAT_ROLE required");
      if (_royaltyFee == type(uint8).max) {
          require(royaltyFee <= type(uint8).max, "INVALID_FEE");
      } else {
          require(royaltyFee < _royaltyFee, "INVALID_FEE");
      }

      _royaltyFee = royaltyFee;

      emit SetRoyaltyFee(royaltyFee);
  }

  /**
    * @dev See {IERC165-supportsInterface}.
    */
  function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC1155, AccessControlEnumerable) returns (bool) {
      return
          interfaceId == type(IERC2981).interfaceId ||
          super.supportsInterface(interfaceId);
  }
}