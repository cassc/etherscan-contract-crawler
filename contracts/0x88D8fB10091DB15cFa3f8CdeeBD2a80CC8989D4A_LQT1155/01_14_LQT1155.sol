// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./utils/ERC1155URIStorage.sol";
import "./utils/GetRoyalties.sol";

contract LQT1155 is
    Ownable,
    GetRoyalties,
    ERC1155,
    ERC1155URIStorage
{
    // bytes4(keccak256("mint(Fee[], uint256, string)")) =  0x4877bd3c
    bytes4 private constant interfaceId = 0x4877bd3c;

    uint256 public totalSupply;
    string public name;
    string public symbol;
    string public contractURI;

    mapping(uint256 => address) public creators;
    mapping(uint256 => uint256) public tokenSupply;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        string memory _tokenBaseURI
    ) ERC1155("") {
        name = _name;
        symbol = _symbol;
        contractURI = _contractURI;

        _setBaseURI(_tokenBaseURI);
    }

    /**
     * @notice mints a token
     * @param _fees fees array
     * @param _supply initial token supply
     * @param _uri  token uri
     */
    function mint(
        Fee[] memory _fees,
        uint256 _supply,
        string memory _uri
    ) external {
        require(_supply > 0, "Supply should be positive");
        require(bytes(_uri).length > 0, "URI should be set");

        _mint(msg.sender, totalSupply, _supply, "");
        _setURI(totalSupply, _uri);
        setFees(totalSupply, _fees);

        creators[totalSupply] = msg.sender;

        tokenSupply[totalSupply] = _supply;

        unchecked {
            totalSupply++;
        }
    }

    /**
     * @notice burns a token for an owner's address and reduces supply. Also, it can be used by an operator on the owner's behalf
     * @param _owner address of token owner
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
     * @notice returns uri for token id with concatenated tokenPrefix
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
        override(GetRoyalties, ERC1155)
        returns (bool)
    {
        return
            interfaceId == _interfaceId ||
            GetRoyalties.supportsInterface(_interfaceId) ||
            ERC1155.supportsInterface(_interfaceId);
    }
}