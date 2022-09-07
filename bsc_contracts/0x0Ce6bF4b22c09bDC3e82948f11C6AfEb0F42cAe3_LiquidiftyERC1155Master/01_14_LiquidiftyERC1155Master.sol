// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "./GetRoyalties.sol";

contract LiquidiftyERC1155Master is
    Ownable,
    GetRoyalties,
    ERC1155,
    ERC1155URIStorage,
    Initializable
{
    // bytes4(keccak256("mint(Fee[], uint256, string)")) =  0x4877bd3c
    bytes4 private constant interfaceId = 0x4877bd3c;

    uint256 public totalSupply;
    string public name;
    string public symbol;
    string public contractURI;

    mapping(uint256 => address) public creators;
    mapping(uint256 => uint256) public tokenSupply;

    /**
     * @notice constructor is redundant. Initialization takes place in initalize function
     */
    constructor() ERC1155("") {}

    /**
     * @notice initialization
     */
    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        string memory _tokenBaseURI,
        address _collectionCreator
    ) public initializer {
        name = _name;
        symbol = _symbol;
        contractURI = _contractURI;

        _setBaseURI(_tokenBaseURI);
        _transferOwnership(_collectionCreator);
    }

    /**
     * @notice mints a token for a creator's address as owner of the token
     * @param _fees fees array
     * @param _supply initial token supply
     * @param _uri  token uri
     */
    function mint(
        Fee[] memory _fees,
        uint256 _supply,
        string memory _uri
    ) external onlyOwner {
        require(_supply != 0, "Supply should be positive");
        require(bytes(_uri).length > 0, "URI should be set");

        creators[totalSupply] = msg.sender;
        setFees(totalSupply, _fees);

        _mint(msg.sender, totalSupply, _supply, "");
        super._setURI(totalSupply, _uri);

        tokenSupply[totalSupply] = _supply;

        unchecked {
            totalSupply++;
        }
    }

    /**
     * @notice burns a token for an owner's address and reduces supply. Also, can be used by an operator on owner's behalf
     * @param _owner owner of a token or a
     * @param _id token id
     * @param _value amount of a token to burn
     */
    function burn(
        address _owner,
        uint256 _id,
        uint256 _value
    ) public {
        require(
            _owner == msg.sender || isApprovedForAll(_owner, msg.sender),
            "Need operator approval for 3rd party burns."
        );

        _burn(_owner, _id, _value);
        tokenSupply[_id] -= _value;
    }

    /**
     * @notice returns uri for token id with tokenPrefix concatenated
     * @dev _tokenId tokenId
     */
    function uri(uint256 _tokenId)
        public
        view
        override(ERC1155, ERC1155URIStorage)
        returns (string memory)
    {
        return super.uri(_tokenId);
    }

    /**
     * @notice sets new contractURI
     * @param _contractURI new contractURI
     */
    function setContractURI(string memory _contractURI) external onlyOwner {
        contractURI = _contractURI;
    }

    /**
     * @notice sets new tokenBaseURI
     * @param _tokenBaseURI new tokenBaseURI
     */
    function setTokenBaseURI(string memory _tokenBaseURI) public onlyOwner {
        _setBaseURI(_tokenBaseURI);
    }

    /**
     * @notice check for interface support
     * @dev Implementation of the {IERC165} interface.
     */
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(ERC1155, GetRoyalties)
        returns (bool)
    {
        return
            _interfaceId == interfaceId ||
            GetRoyalties.supportsInterface(_interfaceId) ||
            ERC1155.supportsInterface(_interfaceId);
    }
}