// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

contract MinterRole is Context {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor() {
        _addMinter(_msgSender());
    }

    modifier onlyMinter() {
        require(isMinter(_msgSender()), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(_msgSender());
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

/**
 * @title WhitelistAdminRole
 * @dev WhitelistAdmins are responsible for assigning and removing Whitelisted accounts.
 */
contract WhitelistAdminRole is Context {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor() {
        _addWhitelistAdmin(_msgSender());
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(_msgSender()), "WhitelistAdminRole: caller does not have the WhitelistAdmin role");
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(_msgSender());
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}

/**
 * @title ERC1155Tradable
 * ERC1155Tradable - ERC1155 contract that whitelists an operator address,
 * has create and mint functionality, and supports useful standards from OpenZeppelin,
  like _exists(), name(), symbol(), and totalSupply()
 */
abstract contract ERC1155Tradable is ERC1155Burnable, Ownable, MinterRole, WhitelistAdminRole {
    using Strings for string;
    using Strings for uint256;

    // 	address proxyRegistryAddress;
    uint256 private _currentTokenID = 0;
    mapping(uint256 => address) public creators;
    mapping(uint256 => uint256) public tokenSupply;
    mapping(uint256 => uint256) public tokenMaxSupply;
    // Contract name
    string public name;
    // Contract symbol
    string public symbol;

    constructor(
        string memory _name,
        string memory _symbol
    ) {
        name = _name;
        symbol = _symbol;
    }

    function removeWhitelistAdmin(address account) public onlyOwner {
        _removeWhitelistAdmin(account);
    }

    function removeMinter(address account) public onlyOwner {
        _removeMinter(account);
    }

    function uri(uint256 _id) override public view returns (string memory) {
        require(_exists(_id), "ERC721Tradable#uri: NONEXISTENT_TOKEN");
        return string(abi.encodePacked(super.uri(1), _id.toString(), ".json"));
    }

    /**
     * @dev Returns the total quantity for a token ID
     * @param _id uint256 ID of the token to query
     * @return amount of token in existence
     */
    function totalSupply(uint256 _id) public view returns (uint256) {
        return tokenSupply[_id];
    }

    /**
     * @dev Returns the max quantity for a token ID
     * @param _id uint256 ID of the token to query
     * @return amount of token in existence
     */
    function maxSupply(uint256 _id) public view returns (uint256) {
        return tokenMaxSupply[_id];
    }

    /**
     * @dev Will update the base URL of token's URI
     * @param _newBaseMetadataURI New base URL of token's URI
     */
    // function setBaseMetadataURI(string memory _newBaseMetadataURI) public onlyWhitelistAdmin {
    // 	_setBaseMetadataURI(_newBaseMetadataURI);
    // }

    /**
     * @dev Creates a new token type and assigns _initialSupply to an address
     * @param _maxSupply max supply allowed
     * @param _initialSupply Optional amount to supply the first owner
     * @param _uri Optional URI for this token type
     * @param _data Optional data to pass if receiver is contract
     * @return tokenId The newly created token ID
     */
    function create(
        uint256 _maxSupply,
        uint256 _initialSupply,
        string calldata _uri,
        bytes calldata _data
    ) external onlyWhitelistAdmin returns (uint256 tokenId) {
        require(_initialSupply <= _maxSupply, "Initial supply cannot be more than max supply");
        uint256 _id = _getNextTokenID();
        _incrementTokenTypeId();
        creators[_id] = msg.sender;

        if (bytes(_uri).length > 0) {
            emit URI(_uri, _id);
        }

        if (_initialSupply != 0) _mint(owner(), _id, _initialSupply, _data);
        tokenSupply[_id] = _initialSupply;
        tokenMaxSupply[_id] = _maxSupply;
        return _id;
    }

    /**
     * @dev Mints some amount of tokens to an address
     * @param _to          Address of the future owner of the token
     * @param _id          Token ID to mint
     * @param _quantity    Amount of tokens to mint
     * @param _data        Data to pass if receiver is contract
     */
    function mint(
        address _to,
        uint256 _id,
        uint256 _quantity,
        bytes memory _data
    ) public onlyMinter {
        require(tokenSupply[_id] < tokenMaxSupply[_id], "Max supply reached");
        _mint(_to, _id, _quantity, _data);
        tokenSupply[_id] = tokenSupply[_id] + (_quantity);
    }

    /**
     * @dev Returns whether the specified token exists by checking to see if it has a creator
     * @param _id uint256 ID of the token to query the existence of
     * @return bool whether the token exists
     */
    function _exists(uint256 _id) internal view returns (bool) {
        return creators[_id] != address(0);
    }

    /**
     * @dev calculates the next token ID based on value of _currentTokenID
     * @return uint256 for the next token ID
     */
    function _getNextTokenID() internal view returns (uint256) {
        return _currentTokenID + 1;
    }

    /**
     * @dev increments the value of _currentTokenID
     */
    function _incrementTokenTypeId() internal {
        _currentTokenID++;
    }
}

contract Guard is ERC1155Tradable {

    uint public mintStartAt;
    uint public mintEndAt;

    uint public mintPrice;
    uint public mintFee;

    mapping(address => uint) public userMinted;
    uint public maxMintPerUser;

    event TokenRedeemed(address indexed account, uint indexed tokenId, uint indexed amount, bytes metadata);
    event ErrorMoneySend();

    modifier withinMintWindow() {
        require(mintStartAt < block.timestamp && block.timestamp < mintEndAt, "Not a mint window");
        _;
    }

    constructor() ERC1155Tradable("Devon DeJardin's Vitruvian Guardian", "Guard") ERC1155("https://europa-assets-list.s3.amazonaws.com/static/devon-dejarden/") {
        maxMintPerUser = 3;
    }

    function setURI(string memory _newURI, uint _tokenId) public onlyOwner {
        _setURI(_newURI);
        emit URI(_newURI, _tokenId);
    }

    function setMintWindow(uint _mintStartAt, uint _mintEndAt) public onlyOwner {
        mintStartAt = _mintStartAt;
        mintEndAt = _mintEndAt;
    }

    function mint() external payable withinMintWindow {
        require(userMinted[msg.sender] < maxMintPerUser, "mint limit reached");
        userMinted[msg.sender]++;

        _mint(msg.sender, 1, 1, "0x");
    }


    function mintBatch(uint amount) external payable withinMintWindow {
        require(userMinted[msg.sender] + amount <= maxMintPerUser, "mint limit reached");
        require(msg.value == mintPrice * amount);
        userMinted[msg.sender]+= amount;

        _mint(msg.sender, 1, amount, "0x");
    }

    function mintBatchOwnable(uint amount) external onlyOwner {
        _mint(msg.sender, 1, amount, "0x");
    }
}