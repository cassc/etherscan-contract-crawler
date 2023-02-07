// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./IMintableCollection.sol";

contract MoreNFTCollection is IMintableCollection, ERC721Enumerable, ERC2981, AccessControl, Ownable {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string public metadataBaseURI;

    uint256 public cap;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _metadataBaseURI,
        address _creator,
        uint96 _creatorFee,
        address _minter,
        uint256 _cap
    ) ERC721(_name, _symbol) {
        require(bytes(_metadataBaseURI).length > 0, "Metadata base URI is empty");
        metadataBaseURI = _metadataBaseURI;
        _setDefaultRoyalty(_creator, _creatorFee);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, _minter);
        cap = _cap;
    }

    function safeMint(address _to, uint256 _tokenId) external onlyRole(MINTER_ROLE) {
        require(_tokenId > 0 && _tokenId <= cap, "Can't mint 0 or beyond the cap");
        _safeMint(_to, _tokenId);
    }

    function contractURI() public view returns (string memory) {
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, "contract")) : "";
    }

    function _baseURI() internal view override returns (string memory) {
        return metadataBaseURI;
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        override(ERC721Enumerable, ERC2981, AccessControl)
        returns (bool)
    {
        return _interfaceId == type(IMintableCollection).interfaceId || super.supportsInterface(_interfaceId);
    }
}