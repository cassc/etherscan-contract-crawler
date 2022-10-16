// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IMetaSportsNFTETH.sol";

contract MetaSportsNFTETH is
    ERC721,
    Pausable,
    AccessControl,
    IMetaSportsNFTETH
{
    using Strings for uint256;
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    string public baseURI;
    string public suffixURI = ".json";
    uint256 public totalSupply = 1500;

    event BaseURISet(string _baseTokenURI);
    event SuffixURISet(string _suffixURI);

    constructor() ERC721("MetaSportsNFTETH", "MSNFT") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _uri)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        baseURI = _uri;
        emit BaseURISet(_uri);
    }

    function setSuffixURI(string memory _suffixURI)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        suffixURI = _suffixURI;
        emit SuffixURISet(_suffixURI);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721AMetadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        suffixURI
                    )
                )
                : "";
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function setTotalSupply(uint256 _totalSupply)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        totalSupply = _totalSupply;
    }

    function exisit(uint256 _tokenId) external override view returns (bool) {
        return _exists(_tokenId);
    }

    function safeMint(address _to, uint256 _tokenId)
        external
        override
        onlyRole(MINTER_ROLE)
    {
        require(_tokenId <= totalSupply, "Exceeds supply");
        _safeMint(_to, _tokenId);
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(_from, _to, _tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControl, ERC721, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}