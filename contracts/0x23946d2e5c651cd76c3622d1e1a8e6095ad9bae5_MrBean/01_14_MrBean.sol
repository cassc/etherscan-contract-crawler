// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import './ERC721A.sol';

contract MrBean is ERC721A, Ownable, AccessControl {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    string private _baseTokenURI;
    string private _contractUri;

    string private name_ = "Mr Bean Official";
    string private symbol_ = "MrBean";

    constructor() ERC721A(name_, symbol_) {

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        
         _baseTokenURI = "https://metadata.theavenue.market/v1/token/mrbean/";
         _contractUri = "https://theavenue-market.s3.amazonaws.com/MrBean/contract.json";
    }

    function safeMint(address to, uint256 quantity) public onlyRole(MINTER_ROLE) {
        _safeMint(to, quantity);
    }

    function safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) public onlyRole(MINTER_ROLE) {
        _safeMint(to, quantity, _data);
    }

    function mint(address to, uint256 quantity) public onlyRole(MINTER_ROLE) {
        _mint(to, quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        _baseTokenURI = _newBaseURI;
    }

    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

   function setContractURI(string memory _newUri) public onlyOwner {
        _contractUri = _newUri;
    }

    function contractURI() public view returns (string memory) {
        return _contractUri;
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function burn(uint256 tokenId, bool approvalCheck) public {
        _burn(tokenId, approvalCheck);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}