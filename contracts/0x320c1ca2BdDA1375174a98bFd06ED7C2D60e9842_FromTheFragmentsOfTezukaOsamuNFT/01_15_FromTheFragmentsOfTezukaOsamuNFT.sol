//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "./IApprovalProxy.sol";

contract FromTheFragmentsOfTezukaOsamuNFT is
    ERC721,
    AccessControl,
    Pausable,
    Ownable
{
    using Strings for uint256;
    using Address for address;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string public baseURI;
    mapping(uint256 => string) private _tokenURIs;

    IApprovalProxy public approvalProxy;
    event UpdateApprovalProxy(address _newProxyContract);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) ERC721(_name, _symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        baseURI = _uri;
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function mint(address to, uint256 tokenId) public onlyRole(MINTER_ROLE) {
        _mint(to, tokenId);
    }

    function mint(address[] memory tos, uint256[] memory tokenIds) public {
        require(
            tos.length == tokenIds.length,
            "SMCERC721: mint args must be equals"
        );
        for (uint256 i; i < tos.length; i++) {
            mint(tos[i], tokenIds[i]);
        }
    }

    function mintFor(
        address to,
        uint256 tokenId,
        bytes calldata mintingBlob
    ) public {
        mint(to, tokenId);
    }

    function setApprovalProxy(address _new) public onlyOwner {
        approvalProxy = IApprovalProxy(_new);
        emit UpdateApprovalProxy(_new);
    }

    function setApprovalForAll(address _spender, bool _approved)
        public
        virtual
        override(ERC721)
    {
        if (
            address(approvalProxy) != address(0x0) &&
            Address.isContract(_spender)
        ) {
            approvalProxy.setApprovalForAll(msg.sender, _spender, _approved);
        }
        super.setApprovalForAll(_spender, _approved);
    }

    function isApprovedForAll(address _owner, address _spender)
        public
        view
        override(ERC721)
        returns (bool)
    {
        bool original = super.isApprovedForAll(_owner, _spender);
        if (address(approvalProxy) != address(0x0)) {
            return approvalProxy.isApprovedForAll(_owner, _spender, original);
        }
        return original;
    }

    function pause() external onlyRole(MINTER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(MINTER_ROLE) {
        _unpause();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        string memory _tokenURI = _tokenURIs[tokenId];

        if (bytes(_tokenURI).length > 0) {
            return string(_tokenURI);
        }

        string memory URI = _baseURI();
        return
            bytes(URI).length > 0
                ? string(abi.encodePacked(URI, tokenId.toString()))
                : "";
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI)
        external
        onlyRole(MINTER_ROLE)
    {
        _tokenURIs[tokenId] = _tokenURI;
    }

    function setBaseURI(string memory newURI) external onlyRole(MINTER_ROLE) {
        baseURI = newURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        super._beforeTokenTransfer(from, to, tokenId);
        require(!paused(), "ERC721Pausable: token transfer while paused");
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControl, ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}