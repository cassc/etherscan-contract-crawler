// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

contract ERC721S {
    string private _name;
    string private _symbol;

    // Mapping from token ID to L2 owner address
    mapping(uint256 => address) private _owners;

    // Mapping from token ID to L1 owner address
    mapping(uint256 => address) private _rootOwners;

    constructor(string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
    } 

    function setShadow(address _rootOwner, address _shadowOwner, uint256 _tokenId) public virtual
    {
        // Set the child owner to the Shadow Owner address.
        _owners[_tokenId] = _shadowOwner;

        // Set the root owner .
        _rootOwners[_tokenId] = _rootOwner;
    }

    // ERC 721 Methods
    // Returns owner of Shadow.
    function ownerOf(uint256 _tokenId) public view virtual returns (address) {
        address owner = _owners[_tokenId];
        // require(owner != address(0), "ERC721S: owner query for nonexistent token");
        return owner;
    }

    function ownerOfRoot(uint256 _tokenId) public view virtual returns (address) {
        address owner = _rootOwners[_tokenId];
        // require(owner != address(0), "ERC721S: owner query for nonexistent token");
        return owner;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }
}