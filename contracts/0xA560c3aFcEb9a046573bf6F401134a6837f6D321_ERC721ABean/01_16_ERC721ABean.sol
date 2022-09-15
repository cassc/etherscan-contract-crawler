// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creators: Chiru Labs

pragma solidity ^0.8.4;

import 'erc721a-upgradeable/contracts/ERC721AUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';




contract ERC721ABean is ERC721AUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    function initialize(string memory name_, string memory symbol_,address[] calldata addresses_, uint256[] calldata amt_) initializerERC721A initializer public {
        __ERC721A_init(name_, symbol_);
        __Ownable_init();
        __adminMintAllInit(addresses_,amt_);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function totalBurned() public view returns (uint256) {
        return _totalBurned();
    }

    function nextTokenId() public view returns (uint256) {
        return _nextTokenId();
    }

    function getAux(address owner) public view returns (uint64) {
        return _getAux(owner);
    }

    function setAux(address owner, uint64 aux) public {
        _setAux(owner, aux);
    }

    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return 'https://bafybeicravkhfjedcsasqrffrgaxyumwx7yjjpeznp3sfchoasxk5e5mzq.ipfs.nftstorage.link/';
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory __baseURI = _baseURI();
        return bytes(__baseURI).length != 0 ? string(abi.encodePacked(__baseURI, _toString(tokenId),".json")) : '';
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function __adminMintAllInit(address[] calldata addresses, uint256[] calldata amt) internal onlyInitializingERC721A{
        // mints every NFT to elibable addresses: 
        // uses _mintERC2309 to save on gas costs (emits 1 trasfer event per batch mint rather than for each):
        // check that length of addresses == length of amt 
        require(addresses.length == amt.length);

        for(uint256 i;i< addresses.length; ++i){
            _mintERC2309(addresses[i],amt[i]);
        }
    }
    //no need to mint at all
    // function safeMint(address to, uint256 quantity) public {
    //     _safeMint(to, quantity);
    // }

    // function safeMint(
    //     address to,
    //     uint256 quantity,
    //     bytes memory _data
    // ) public {
    //     _safeMint(to, quantity, _data);
    // }

    // function mint(address to, uint256 quantity) public {
    //     _mint(to, quantity);
    // }

    function burn(uint256 tokenId) public {
        _burn(tokenId);
    }

    function burn(uint256 tokenId, bool approvalCheck) public {
        _burn(tokenId, approvalCheck);
    }

    function toString(uint256 x) public pure returns (string memory) {
        return _toString(x);
    }

    function getOwnershipAt(uint256 index) public view returns (TokenOwnership memory) {
        return _ownershipAt(index);
    }

    function getOwnershipOf(uint256 index) public view returns (TokenOwnership memory) {
        return _ownershipOf(index);
    }

    function initializeOwnershipAt(uint256 index) public {
        _initializeOwnershipAt(index);
    }
}