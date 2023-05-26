// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FuturisticPortalPasses is Context, AccessControl, ERC721, ERC721Burnable, Ownable {

    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    Counters.Counter private _tokenIds;

    string private _baseTokenURI;
    uint256 public immutable maxSupply;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        uint256 maxSupply_
    ) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
        maxSupply = maxSupply_;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function mint(address to) public onlyRole(MINTER_ROLE) {
        require(_tokenIds.current() < maxSupply, "BaseNFT: Can not mint more than max supply");
        _mint(to, _tokenIds.current());
        _tokenIds.increment();
    }

    // Getters
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function baseURI() public view virtual returns (string memory) {
        return _baseTokenURI;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    // Setters
    function setBaseURI(string calldata newBaseTokenUrI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseTokenURI = newBaseTokenUrI;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}