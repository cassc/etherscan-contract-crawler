pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ChainFacesHDElixir is ERC1155, Ownable {
    /**
     ** VARIABLES
     **/

    mapping(uint256 => string) metadata;

    /// @dev A mapping of contract addresses that are able to consume elixirs
    mapping(uint256 => mapping(address => bool)) public consumers;
    /// @dev A mapping of contract addresses that are able to mint elixirs
    mapping(uint256 => mapping(address => bool)) public minters;

    /**
     ** MODIFIERS
     **/

    /// @dev Only a valid consumer contract can call a method with this modifier
    modifier onlyConsumer(uint256 _id) {
        require(consumers[_id][_msgSender()], "Not a valid consumer");
        _;
    }

    /// @dev Only a valid minter contract can call a method with this modifier
    modifier onlyMinter(uint256 _id) {
        require(minters[_id][_msgSender()], "Not a valid minter");
        _;
    }

    /**
     ** CONSTRUCTOR
     **/

    constructor() ERC1155("") { }

    /**
     ** PUBLIC
     **/

    function uri(uint256 _id) public view override returns (string memory) {
        return metadata[_id];
    }

    /**
     ** CONSUMER
     **/

    /// @dev Called by an external contract to consume an elixir for whatever purpose
    function consume(address _owner, uint256 _id, uint256 _amount) external onlyConsumer(_id) {
        _burn(_owner, _id, _amount);
    }

    /**
     ** MINTER
     **/

    /// @dev Called by an external contract to mint an elixir
    function mint(address _owner, uint256 _id, uint256 _amount) external onlyMinter(_id) {
        _mint(_owner, _id, _amount, "");
    }

    /**
     ** OWNER
     **/

    /// @dev Sets the metadata returned in calls to uri for given id
    function setMetadata(uint256 _id, string calldata _metadata) external onlyOwner {
        metadata[_id] = _metadata;
    }

    /// @dev Can be called by owner to add a valid consumer address
    function setConsumer(uint256 _id, address _consumer, bool _state) external onlyOwner {
        consumers[_id][_consumer] = _state;
    }

    /// @dev Can be called by owner to add a valid minter address
    function setMinter(uint256 _id, address _minter, bool _state) external onlyOwner {
        minters[_id][_minter] = _state;
    }
}