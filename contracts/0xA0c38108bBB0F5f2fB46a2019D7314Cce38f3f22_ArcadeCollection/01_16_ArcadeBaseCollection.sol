// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./lib/String.sol";

abstract contract ArcadeBaseCollection is Ownable, ERC721Enumerable {
    using String for bytes32;
    using String for uint256;

    mapping(bytes32 => uint256) internal maxIssuance;
    mapping(bytes32 => uint256) internal issued;
    mapping(uint256 => string) internal _tokenPaths;
    mapping(address => bool) internal allowed;
    mapping(uint256 => mapping(address => string)) internal _interactiveConfURIs;
    mapping(bytes32 => string) internal gameURIs;
    mapping(bytes32 => uint256) internal collectionPrice;

    string[] internal games;

    string internal baseURI; 
    bool internal isComplete;

    event BaseURI(string _oldBaseURI, string _newBaseURI);
    event Allowed(address indexed _operator, bool _allowed);
    event AddGame(
        bytes32 indexed _gameIdKey,
        string _gameId,
        uint256 _maxIssuance
    );
    event Issue(
        address indexed _beneficiary,
        uint256 indexed _tokenId,
        bytes32 indexed _gameIdKey,
        string _gameId,
        uint256 _issuedId
    );
    event ConfigurationURI(
        uint256 indexed tokenId,
        address indexed owner,
        string configurationURI
    );
    event Complete();

    /**
     * @dev Create the contract.
     * @param _name - name of the contract
     * @param _symbol - symbol of the contract
     * @param _operator - Address allowed to mint tokens
     * @param _baseURI - base URI for token URIs
     */
    constructor(
        string memory _name,
        string memory _symbol,
        address _operator,
        string memory _baseURI
    ) ERC721(_name, _symbol) {
        setAllowed(_operator, true);
        setBaseURI(_baseURI);
    }

    modifier onlyAllowed() {
        require(
            allowed[msg.sender],
            "Only an `allowed` address can call this method"
        );
        _;
    }

    /**
     * @dev Set price for collection.
     * @param _gameKey - gameKey to set the price for
     * @param _price - price for the collection
     */
    function setCollectionPrice(bytes32 _gameKey, uint256 _price)
        external
        onlyAllowed
    {
        collectionPrice[_gameKey] = _price;
    }

    /**
     * @dev Set price for collection.
     * @param _gameKey - gameKey to set the uri for
     * @param _uri - uri for the game collection
     */
    function setGameURI(bytes32 _gameKey, string memory _uri)
        external
        onlyAllowed
    {
        gameURIs[_gameKey] = _uri;
    }

    /**
     * @dev Set Base URI.
     * @param _baseURI - base URI for token URIs
     */
    function setBaseURI(string memory _baseURI) public onlyOwner {
        emit BaseURI(baseURI, _baseURI);
        baseURI = _baseURI;
    }

    /**
     * @dev Set allowed account to issue tokens.
     * @param _operator - Address allowed to issue tokens
     * @param _allowed - Whether is allowed or not
     */
    function setAllowed(address _operator, bool _allowed) public onlyOwner {
        require(_operator != address(0), "Invalid address");
        require(
            allowed[_operator] != _allowed,
            "You should set a different value"
        );

        allowed[_operator] = _allowed;
        emit Allowed(_operator, _allowed);
    }

    /**
     * @dev Return url for contract metadata
     * @return contract URI
     */
     function contractURI() public pure returns (string memory) {
        return "https://arcadenfts.com/c_metadata.json";
    }

    /**
     * @dev Withdraw all ether from this contract
     */
    function withdraw() onlyOwner public {
        uint256 amount = address(this).balance;
        payable(msg.sender).transfer(amount);
    }

    /**
     * @dev Returns an URI for a given token ID.
     * Throws if the token ID does not exist. May return an empty string.
     * @param _tokenId - uint256 ID of the token queried
     * @return token URI
     * This will point to specific issue of the game, e.g. #2 with some attributes if needed?
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: received a URI query for a nonexistent token"
        );
        return string(abi.encodePacked(baseURI, _tokenPaths[_tokenId]));
    }

    /**
     * @dev Set configurationURI for the owner
     * @param tokenId - uint256 ID of the token queried
     * @param owner - Address of the owner
     * @param _interactiveConfURI - URI to the configuration
     */
    function setInteractiveConfURI(
        uint256 tokenId,
        address owner,
        string calldata _interactiveConfURI
    ) external onlyAllowed {
        _setInteractiveConfURI(tokenId, owner, _interactiveConfURI);
    }

    /**
     * @dev Set configurationURI for the owner
     * @param tokenId - uint256 ID of the token queried
     * @param owner - Address of the owner
     * @param interactiveConfURI_ - URI to the configuration
     */
    function _setInteractiveConfURI(
        uint256 tokenId,
        address owner,
        string calldata interactiveConfURI_
    ) internal virtual {
        _interactiveConfURIs[tokenId][owner] = interactiveConfURI_;
        emit ConfigurationURI(tokenId, owner, interactiveConfURI_);
    }

    /**
     * Configuration uri for tokenId
     * @return configurationUri for the owner
     */
    function interactiveConfURI(uint256 tokenId, address owner)
        external
        view
        virtual
        returns (string memory)
    {
        return _interactiveConfURIs[tokenId][owner];
    }

    /**
     * @dev Returns the games length.
     * @return game length
     */
    function gamesCount() external view returns (uint256) {
        return games.length;
    }

    /**
     * @dev Complete the collection.
     * @notice that it will only prevent for adding more games.
     * The issuance is still allowed.
     */
    function completeCollection() external onlyOwner {
        require(!isComplete, "The collection is already completed");
        isComplete = true;
        emit Complete();
    }

    /**
     * @dev Add a new game to the collection.
     * @notice that this method allows gameIds of any size. It should be used
     * if a gameId is greater than 32 bytes
     * @param _gameId - game id
     * @param _maxIssuance - total supply for the game
     */
    function addGame(string memory _gameId, uint256 _maxIssuance)
        external
        onlyOwner
    {
        require(!isComplete, "This game has sold out!");
        bytes32 key = getGameKey(_gameId);

        require(maxIssuance[key] == 0, "Can not modify an existing game");
        require(_maxIssuance > 0, "Max issuance should be greater than 0");

        maxIssuance[key] = _maxIssuance;
        games.push(_gameId);

        emit AddGame(key, _gameId, _maxIssuance);
    }

    /**
     * @dev Get keccak256 of a gameId.
     * @param _gameId - token game
     * @return bytes32 keccak256 of the gameId
     */
    function getGameKey(string memory _gameId) public pure  returns (bytes32) {
        return keccak256(abi.encodePacked(_gameId));
    }

    /**
     * @dev Get issued for certain gameId
     * @param _gameId - token game
     * @return uint256 of the issuance of that game
    */
    function getIssued(string memory _gameId) external view returns (uint256) {
        bytes32 _gameIdKey = getGameKey(_gameId);
        return issued[_gameIdKey];
    }

    /**
     * @dev Mint a new NFT of the specified kind.
     * @notice that will throw if kind has reached its maximum or is invalid
     * @param _beneficiary - owner of the token
     * @param _tokenId - token
     * @param _gameIdKey - game key
     * @param _gameId - token game
     * @param _issuedId - issued id
     */
    function _mint(
        address _beneficiary,
        uint256 _tokenId,
        bytes32 _gameIdKey,
        string memory _gameId,
        uint256 _issuedId
    ) internal {
        require(
            _issuedId > 0 && _issuedId <= maxIssuance[_gameIdKey],
            "Invalid issued id"
        );
        require(
            issued[_gameIdKey] < maxIssuance[_gameIdKey],
            "Game exhausted"
        );
        require(
            allowed[_beneficiary]
                ? msg.value >= 0
                : collectionPrice[_gameIdKey] <= msg.value,
            "Ether value sent is not correct"
        );

        // Mint erc721 token
        super._mint(_beneficiary, _tokenId);

        // Increase issuance
        issued[_gameIdKey] = issued[_gameIdKey] + 1;

        // Log
        emit Issue(_beneficiary, _tokenId, _gameIdKey, _gameId, _issuedId);
    }

    /** @notice Enumerate NFTs assigned to an owner
      * @dev Throws if `_index` >= `balanceOf(_owner)` or if
      *  `_owner` is the zero address, representing invalid NFTs.
      * @param _owner An address where we are interested in NFTs owned by them
      * @param _index A counter less than `balanceOf(_owner)`
      * @return The token identifier for the `_index`th NFT assigned to `_owner`,
      *   (sort order not specified)
    */
    function tokenOfOwner(address _owner, uint256 _index)
        external
        view
        returns (uint256)
    {
        return (ERC721Enumerable.tokenOfOwnerByIndex(_owner, _index));
    }

    /**  
     * @notice Count all NFTs assigned to an owner
     * @dev NFTs assigned to the zero address are considered invalid, and this
     * function throws for queries about the zero address.
     * @param _owner An address for whom to query the balance
     * @return The number of NFTs owned by `_owner`, possibly zero
    */
    function balance(address _owner) external view returns (uint256) {
        return ERC721.balanceOf(_owner);
    }
}