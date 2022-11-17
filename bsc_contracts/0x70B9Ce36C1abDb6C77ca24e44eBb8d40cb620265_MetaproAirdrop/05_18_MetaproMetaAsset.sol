//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract MetaproMetaAsset is ERC1155Supply, Pausable, Ownable, ReentrancyGuard {

    using Strings for string;
    using SafeMath for uint256;

    uint public mintFee = 0.00000001 ether;

    address public treasuryAddress;

    uint256 public currentTokenID = 1000;

    mapping(uint256 => address) public creators;
    mapping(uint256 => string) public tokenIdToBucketHash;
    mapping(string => uint256) public bucketHashToTokenIds;

    string private baseUri = "";
    string private _name;
    string private _symbol;

    event Minted(address indexed creator, address indexed initialOwner, string _bucketHash, uint256 _tokenId, uint256 _quantity);
    event MintedBatch(address indexed token, address indexed owner, uint256[] _tokenIds, uint256[] _quantities);
    event UpdateFee(uint256 fee);
    event UpdateTreasuryAddress(address treasuryAddress);
    event UpdateERCHolder(address treasuryAddress);
    event Pause();
    event Unpause();

    modifier creatorOnly(uint256 _id) {
        require(creators[_id] == msg.sender, "ERC1155Tradable#creatorOnly: ONLY_CREATOR_ALLOWED");
        _;
    }

    constructor(string memory _uri, address _address) ERC1155(_uri) {
        baseUri = _uri;
        treasuryAddress = _address;
        _name = "metapro NFT meta asset";
        _symbol = "NFTma";
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

        (bool feeSent,) = payable(treasuryAddress).call{value : mintFee}("");
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

    function createReserved(
        uint256 id,
        address _initialOwner,
        uint256 _initialSupply,
        string memory _bucketHash,
        bytes calldata _data
    ) external onlyOwner {
        if (bucketHashToTokenIds[_bucketHash] > 0) {
            revert("bucket hash already minted.");
        }

        creators[id] = msg.sender;

        _mint(_initialOwner, id, _initialSupply, _data);
        tokenIdToBucketHash[id] = _bucketHash;
        bucketHashToTokenIds[_bucketHash] = id;

        emit Minted(msg.sender, _initialOwner, _bucketHash, id, _initialSupply);
    }

    function migrate(
        uint256 id,
        address _creator,
        string memory _bucketHash,
        address to,
        uint256 amount,
        bytes calldata _data
    ) external onlyOwner {
        creators[id] = _creator;
        tokenIdToBucketHash[id] = _bucketHash;
        bucketHashToTokenIds[_bucketHash] = id;
        _mint(to, id, amount, _data);
    }

    function mint(
        address _to,
        uint256 _id,
        uint256 _quantity,
        bytes memory _data
    ) public creatorOnly(_id) {
        _mint(_to, _id, _quantity, _data);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        require(amount != 0, 'Amount should not be zero');

        _safeTransferFrom(from, to, id, amount, data);
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

    function _incrementTokenTypeId() private {
        currentTokenID++;
    }

    function setFee(uint256 _fee) external whenNotPaused nonReentrant onlyOwner {
        require(_fee > 0, 'Invalid fee');
        mintFee = _fee;
        emit UpdateFee(_fee);
    }

    function setTreasuryAddress(address _address) external whenNotPaused nonReentrant onlyOwner {
        require(_address != address(0), 'Invalid address');
        treasuryAddress = _address;
        emit UpdateTreasuryAddress(_address);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function pause() external onlyOwner whenNotPaused {
        super._pause();
        emit Pause();
    }

    function unpause() external onlyOwner whenPaused {
        super._unpause();
        emit Unpause();
    }
}