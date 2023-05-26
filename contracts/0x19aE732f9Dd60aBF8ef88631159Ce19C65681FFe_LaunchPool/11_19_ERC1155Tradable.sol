// SPDX-License-Identifier: MIT
pragma solidity ^0.6.8;

import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/GSN/Context.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './ERC1155.sol';
import '../utils/Strings.sol';

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title ERC1155Tradable
 * ERC1155Tradable - ERC1155 contract that whitelists an operator address, 
 * has create and mint functionality, and supports useful standards from OpenZeppelin,
  like _exists(), name(), symbol(), and totalSupply()
 */
contract ERC1155Tradable is Context, AccessControl, Ownable, ERC1155 {
    bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');

    using Strings for string;

    string internal baseMetadataURI;
    address proxyRegistryAddress;
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
        string memory _symbol,
        address _proxyRegistryAddress
    ) public ERC1155('') {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());

        name = _name;
        symbol = _symbol;
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    modifier onlyAdminOrOwner() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) || (owner() == _msgSender()),
            'ERC1155Tradable: must have admin or owner role'
        );
        _;
    }

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()), 'ERC1155Tradable: must have minter role');
        _;
    }

    function uri(uint256 _id) public view override returns (string memory) {
        require(_exists(_id), 'ERC1155Tradable: token must exists');
        return Strings.strConcat(baseMetadataURI, Strings.uint2str(_id));
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
    function setBaseMetadataURI(string memory _newBaseMetadataURI) public onlyAdminOrOwner {
        _setBaseMetadataURI(_newBaseMetadataURI);
    }

    /**
     * @dev Creates a new token type and assigns _initial to a sender
     * @param _max max supply allowed
     * @param _initial Optional amount to supply the first owner
     * @param _data Optional data to pass if receiver is contract
     * @return tokenId The newly created token ID
     */
    function create(
        uint256 _max,
        uint256 _initial,
        bytes memory _data
    ) external onlyAdminOrOwner returns (uint256 tokenId) {
        //TODO Need to test lte condition
        require(_initial <= _max, 'ERC1155Tradable: Initial supply cannot be more than max supply');
        uint256 id = _getNextTokenID();
        _incrementTokenTypeId();
        creators[id] = _msgSender();

        if (_initial != 0) {
            _mint(_msgSender(), id, _initial, _data);
        }
        tokenSupply[id] = _initial;
        tokenMaxSupply[id] = _max;
        return id;
    }

    /**
     * @dev Creates some amount of tokens type and assigns initials to a sender
     * @param _maxs max supply allowed
     * @param _initials Optional amount to supply the first owner
     */
    function createBatch(
        uint256[] memory _maxs,
        uint256[] memory _initials,
        bytes memory _data
    ) external onlyAdminOrOwner {
        require(_maxs.length == _initials.length, 'ERC1155Tradable: maxs and initials length mismatch');

        uint256[] memory ids = new uint256[](_maxs.length);
        uint256[] memory quantities = new uint256[](_maxs.length);

        for (uint256 i = 0; i < _maxs.length; i++) {
            uint256 max = _maxs[i];
            uint256 initial = _initials[i];

            //TODO Need to test lte condition
            require(initial <= max, 'ERC1155Tradable: Initial supply cannot be more than max supply');

            uint256 tokenId = _getNextTokenID();
            _incrementTokenTypeId();
            creators[tokenId] = _msgSender();

            tokenSupply[tokenId] = initial;
            tokenMaxSupply[tokenId] = max;

            ids[i] = tokenId;
            quantities[i] = initial;
        }

        _mintBatch(_msgSender(), ids, quantities, _data);
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
        //TODO Need to test lte condition
        require(tokenSupply[_id].add(_quantity) <= tokenMaxSupply[_id], 'ERC1155Tradable: Max supply reached');
        tokenSupply[_id] = tokenSupply[_id].add(_quantity);
        _mint(_to, _id, _quantity, _data);
    }

    /**
     * @dev Mint tokens for each id in _ids
     * @param _to          The address to mint tokens to
     * @param _ids         Array of ids to mint
     * @param _quantities  Array of amounts of tokens to mint per id
     * @param _data        Data to pass if receiver is contract
     */
    function mintBatch(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _quantities,
        bytes memory _data
    ) public onlyMinter {
        require(_to != address(0), 'ERC1155Tradable: mint to the zero address');
        require(_ids.length == _quantities.length, 'ERC1155Tradable: ids and amounts length mismatch');
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 id = _ids[i];
            uint256 quantity = _quantities[i];
            //TODO Need to test lte condition
            require(tokenSupply[id].add(quantity) <= tokenMaxSupply[id], 'ERC1155Tradable: Max supply reached');
            tokenSupply[id] = tokenSupply[id].add(quantity);
        }
        _mintBatch(_to, _ids, _quantities, _data);
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-free listings.
     */
    function isApprovedForAll(address _owner, address _operator) public view override returns (bool isOperator) {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == _operator) {
            return true;
        }

        return ERC1155.isApprovedForAll(_owner, _operator);
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
    function _getNextTokenID() private view returns (uint256) {
        return _currentTokenID.add(1);
    }

    /**
     * @dev increments the value of _currentTokenID
     */
    function _incrementTokenTypeId() private {
        _currentTokenID++;
    }

    /**
     * @notice Will update the base URL of token's URI
     * @param _newBaseMetadataURI New base URL of token's URI
     */
    function _setBaseMetadataURI(string memory _newBaseMetadataURI) internal {
        baseMetadataURI = _newBaseMetadataURI;
    }
}