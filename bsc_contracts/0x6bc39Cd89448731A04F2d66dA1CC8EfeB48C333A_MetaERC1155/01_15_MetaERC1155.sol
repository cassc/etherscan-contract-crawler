//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract MetaERC1155 is ERC1155Supply, Pausable, Ownable, ReentrancyGuard {

  using Strings for string;
  using SafeMath for uint256;

  /// @dev fee to mint
  uint public mintFee = 0.00000001 ether;

  address public treasuryAddress;

  uint256 public currentTokenID = 0;

  mapping (uint256 => address) public creators;
  mapping (uint256 => string) public tokenIdToBucketHash;
  mapping (string => uint256) public bucketHashToTokenIds;

  string private baseUri = "";

  event Minted(address indexed creator, address indexed initialOwner, string _bucketHash, uint256 _tokenId, uint256 _quantity);
  event MintedBatch(address indexed token, address indexed owner, uint256[] _tokenIds, uint256[] _quantities);
  event UpdateFee(uint256 fee);
  event UpdateTreasuryAddress(address treasuryAddress);
  event UpdateERCHolder(address treasuryAddress);
  event Pause();
  event Unpause();

  /**
   * @dev Require msg.sender to be the creator of the token id
   */
  modifier creatorOnly(uint256 _id) {
    require(creators[_id] == msg.sender, "ERC1155Tradable#creatorOnly: ONLY_CREATOR_ALLOWED");
    _;
  }

  constructor(string memory _uri, address _address) ERC1155(_uri) {
    baseUri = _uri;
    treasuryAddress = _address;
  }

  function uri(
    uint256 _id
  ) public override view returns (string memory) {
    require(_exists(_id), "MetaERC1155#uri: NONEXISTENT_TOKEN");
    return string(abi.encodePacked(baseUri, Strings.toHexString(_id)));
  }

  function create(
    address _initialOwner,
    uint256 _initialSupply,
    string memory _bucketHash,
    bytes calldata _data
  ) external payable {
    require(treasuryAddress != address(0), 'Should not be zero address');
    require(msg.value == mintFee);

    (bool feeSent, ) = payable(treasuryAddress).call{value: mintFee}("");
    require(feeSent, "MintFee transfer failed");

    if (bucketHashToTokenIds[_bucketHash] > 0) {
        revert("bucket hash already minted.");
    }

    uint256 _id = _getNextTokenID();
    _incrementTokenTypeId();
    creators[_id] = msg.sender;

    _mint(_initialOwner, _id, _initialSupply, _data);
    tokenIdToBucketHash[_id] = _bucketHash;
    bucketHashToTokenIds[_bucketHash] = _id;

    emit Minted(msg.sender, _initialOwner, _bucketHash, _id, _initialSupply);
  }

  function mint(
    address _to,
    uint256 _id,
    uint256 _quantity,
    bytes memory _data
  ) public creatorOnly(_id) {
    _mint(_to, _id, _quantity, _data);
  }

  function setUri(
    string memory _newUri
  ) public onlyOwner {
    _setURI(_newUri);
    baseUri = _newUri;
  }

  function isApprovedForAll(
    address _owner,
    address _operator
  ) public override view returns (bool isOperator) {
    return ERC1155.isApprovedForAll(_owner, _operator);
  }

  function _exists(
    uint256 _id
  ) internal view returns (bool) {
    return creators[_id] != address(0);
  }

  function _getNextTokenID() private view returns (uint256) {
    return currentTokenID.add(1);
  }

  function _incrementTokenTypeId() private  {
    currentTokenID++;
  }

   /**
     * @dev Set fee
     * @param _fee fee to pay for minting
    */
    function setFee(uint256 _fee) external whenNotPaused nonReentrant onlyOwner {
        require(_fee > 0, 'Invalid fee');
        mintFee = _fee;
        emit UpdateFee(_fee);
    }

  /**
     * @dev Set treasuryAddress
     * @param _address address of treasury
    */
    function setTreasuryAddress(address _address) external whenNotPaused nonReentrant onlyOwner {
        require(_address != address(0), 'Invalid address');
        treasuryAddress = _address;
        emit UpdateTreasuryAddress(_address);
    }

    /**
    * @notice Triggers stopped state
    * @dev Only possible when contract not paused.
    */
    function pause() external onlyOwner whenNotPaused {
        super._pause();
        emit Pause();
    }

    /**
    * @notice Returns to normal state
    * @dev Only possible when contract is paused.
    */
    function unpause() external onlyOwner whenPaused {
        super._unpause();
        emit Unpause();
    }
 }