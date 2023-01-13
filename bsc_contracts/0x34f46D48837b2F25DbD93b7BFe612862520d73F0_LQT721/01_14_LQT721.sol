// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./utils/GetRoyalties.sol";

contract LQT721 is Ownable, GetRoyalties, ERC721URIStorage {
    // bytes4(keccak256("mint(Fee[], string)")) = 0xc29b240d
    bytes4 private constant interfaceId = 0xc29b240d;

    uint256 public totalSupply;
    string public contractURI;
    string public tokenBaseURI;
    mapping(uint256 => address) public creators;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        string memory _tokenBaseURI
    ) ERC721(_name, _symbol) {
        contractURI = _contractURI;
        tokenBaseURI = _tokenBaseURI;
    }

    /**
     * @notice mints a token
     * @param _fees fees array
     * @param _uri  token uri
     */
    function mint(Fee[] memory _fees, string memory _uri) public {
        require(bytes(_uri).length > 0, "URI should be set");

        _mint(msg.sender, totalSupply);
        _setTokenURI(totalSupply, _uri);
        setFees(totalSupply, _fees);

        creators[totalSupply] = msg.sender;

        unchecked {
            totalSupply++;
        }
    }

    /**
     * @notice burns a token from an owner's address
     * @param _id token id
     */
    function burn(uint256 _id) external {
        address owner = ownerOf(_id);
        require(
            owner == msg.sender || isApprovedForAll(owner, msg.sender),
            "Need operator approval for 3rd party burns."
        );
        super._burn(_id);
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
    function setTokenBaseURI(string memory _tokenBaseURI) external onlyOwner {
        tokenBaseURI = _tokenBaseURI;
    }

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return tokenBaseURI;
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(GetRoyalties, ERC721)
        returns (bool)
    {
        return
            interfaceId == _interfaceId ||
            GetRoyalties.supportsInterface(_interfaceId) ||
            ERC721.supportsInterface(_interfaceId);
    }
}