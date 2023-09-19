// ArtWear NFT token
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract ArtWearNFT is ERC721, IERC2981 {
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    address payable private _royaltiesPaymentsAddress;

    uint256 public constant PERCENTS_DIVIDER = 10000;
    uint256 public constant FEE_MAX_PERCENT = 2000; // 20 %
    uint256 public constant FEE_MIN_PERCENT = 100; // 1 %

    string public collection_name;
    string public collection_uri;
    address public factory;
    address public owner;

    mapping(address => bool) public _creators;
    mapping(address => bool) public _managers;

    struct Item {
        uint256 id;
        address creator;
        string uri;
        uint256 royalty;
    }
    uint256 public currentID;
    mapping(uint256 => Item) public Items;

    event CollectionUriUpdated(string collection_uri);
    event CollectionNameUpdated(string collection_name);
    event TokenUriUpdated(uint256 id, string uri);
    event OwnershipTransferred(address oldOwner, address newOwner);

    event ManagerAdded(address manager);
    event ManagerRemoved(address manager);

    event CreatorAdded(address creator);
    event CreatorRemoved(address creator);

    event ItemCreated(uint256 id, address creator, string uri, uint256 royalty);

    constructor(
        string memory _name,
        string memory _uri,
        address _owner
    ) ERC721(_name, _name) {
        factory = msg.sender;
        collection_uri = _uri;
        collection_name = _name;
        owner = _owner;
        _creators[_owner] = true;
        _managers[_owner] = true;
        _royaltiesPaymentsAddress = payable(_owner);
    }

    /**
		Change & Get Collection Information
	 */
    function setCollectionURI(string memory newURI) public onlyOwner {
        collection_uri = newURI;
        emit CollectionUriUpdated(newURI);
    }

    function setName(string memory newname) public onlyOwner {
        collection_name = newname;
        emit CollectionNameUpdated(newname);
    }

    function setOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Owner: address is zero");
        require(newOwner != owner, "Owner: address is already owner");
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function addManager(address managerAddress) public onlyOwner {
        require(managerAddress != address(0), "manager: address is zero");
        require(
            _managers[managerAddress] != true,
            "manager: address is already manager"
        );
        _managers[managerAddress] = true;
        emit ManagerAdded(managerAddress);
    }

    function removeManager(address managerAddress) public onlyOwner {
        require(managerAddress != address(0), "manager: address is zero");
        require(
            _managers[managerAddress] != false,
            "manager: address is already not manager"
        );
        _managers[managerAddress] = false;
        emit ManagerRemoved(managerAddress);
    }

    function setRoyaltiesPaymentAddress(
        address royaltiesReceiver
    ) public onlyOwner {
        _royaltiesPaymentsAddress = payable(royaltiesReceiver);
    }

    function addCreator(address creatorAddress) public onlyManager {
        require(creatorAddress != address(0), "creator: address is zero");
        require(
            _creators[creatorAddress] != true,
            "creator: address is already creator"
        );
        _creators[creatorAddress] = true;
        emit CreatorAdded(creatorAddress);
    }

    function removeCreator(address creatorAddress) public onlyManager {
        require(creatorAddress != address(0), "creator: address is zero");
        require(
            _creators[creatorAddress] != false,
            "creator: address is already not creator"
        );
        _creators[creatorAddress] = false;
        emit CreatorRemoved(creatorAddress);
    }

    function getCollectionURI() external view returns (string memory) {
        return collection_uri;
    }

    function getCollectionName() external view returns (string memory) {
        return collection_name;
    }

    /**
		Change & Get Item Information
	 */
    function addItem(
        address _creator,
        string memory _tokenURI,
        uint256 royalty
    ) public onlyCreator returns (uint256) {
        require(royalty <= FEE_MAX_PERCENT, "Too big royalties");
        require(royalty >= FEE_MIN_PERCENT, "Too small royalties");
        currentID = currentID + 1;
        _safeMint(_creator, currentID);
        Items[currentID] = Item(currentID, _creator, _tokenURI, royalty);
        emit ItemCreated(currentID, _creator, _tokenURI, royalty);
        return currentID;
    }

    function setTokenURI(
        uint256 _tokenId,
        string memory _newURI
    ) public tokenCreatorOnly(_tokenId) {
        Items[_tokenId].uri = _newURI;
        emit TokenUriUpdated(_tokenId, _newURI);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return Items[tokenId].uri;
    }

    function creatorOf(uint256 _tokenId) public view returns (address) {
        return Items[_tokenId].creator;
    }

    function royalties(uint256 _tokenId) public view returns (uint256) {
        return Items[_tokenId].royalty;
    }

    /// @inheritdoc	ERC165
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, IERC165) returns (bool) {
        return
            interfaceId == _INTERFACE_ID_ERC2981 ||
            super.supportsInterface(interfaceId);
    }

    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view override returns (address receiver, uint256 royaltyAmount) {
        return (
            _royaltiesPaymentsAddress,
            (salePrice * Items[tokenId].royalty) / PERCENTS_DIVIDER
        );
    }

    modifier onlyOwner() {
        require(owner == _msgSender(), "caller is not the owner");
        _;
    }

    modifier onlyManager() {
        require(_managers[_msgSender()] == true, "caller is not the manager");
        _;
    }

    modifier onlyCreator() {
        require(
            _creators[_msgSender()] == true,
            "caller is not the whitelisted creator"
        );
        _;
    }

    /**
     * @dev Require _msgSender() to be the creator of the token id
     */
    modifier tokenCreatorOnly(uint256 _id) {
        require(
            Items[_id].creator == _msgSender(),
            "NFT: Only token creator allowed"
        );
        _;
    }
}