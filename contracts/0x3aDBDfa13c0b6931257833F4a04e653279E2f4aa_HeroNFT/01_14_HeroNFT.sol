// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Ownable.sol";
import "EnumerableSet.sol";
import "Pausable.sol";
import "ERC721A.sol";

contract HeroNFT is ERC721A, Ownable, Pausable {

    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private minters;

    string public baseURI;

    event Minted(address minter, uint256 heroBoxId, uint256 boxCategory, uint256 tokenIdStart, uint256 quantity, bytes32 randomHash);
    event BaseURIChanged(string newBaseURI);

    constructor(
        string memory _initBaseURI,
        string memory _name,
        string memory _symbol,
        uint256 _maxBatchSize,
        uint256 _collectionSize
    ) ERC721A(_name, _symbol, _maxBatchSize, _collectionSize) {
        baseURI = _initBaseURI;
    }

    function addMinter(address _minter) external onlyOwner {
        minters.add(_minter);
    }

    function deletedMinter(address _minter) external onlyOwner {
        minters.remove(_minter);
    }

    function isMinter(address _minter) public view returns (bool){
        return minters.contains(_minter);
    }

    modifier onlyMinter() {
        require(isMinter(_msgSender()), "not minter");
        _;
    }


    function pause() public whenNotPaused onlyOwner {
        _pause();
    }

    function unpause() public whenPaused onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override(ERC721A) whenNotPaused {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }


    function mint(address to, uint256 heroBoxId, uint256 boxCategory, uint256 quantity, bytes32 randomHash) external onlyMinter {

        require(quantity >0 && quantity <= maxBatchSize, "quantity invalid");

        require(totalSupply() + quantity <= collectionSize, "max supply exceeded");


        uint tokenIdStart = totalSupply();

        _safeMint(to, quantity);

        emit Minted(to, heroBoxId, boxCategory, tokenIdStart, quantity, randomHash);
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
        emit BaseURIChanged(newBaseURI);
    }

    function setOwnersExplicit(uint256 quantity) external onlyOwner {
        _setOwnersExplicit(quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId) public view returns (TokenOwnership memory) {
        return ownershipOf(tokenId);
    }


}