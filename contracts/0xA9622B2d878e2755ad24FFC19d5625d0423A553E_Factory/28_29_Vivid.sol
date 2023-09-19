// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "solady/src/utils/LibString.sol";

contract Vivid is Initializable, ERC721Upgradeable, OwnableUpgradeable {

    string public baseUri;
    address private _lastVersion;
    bool private _phantomMintingDisabled;

    constructor() {
        _disableInitializers();
    }
    
    function initialize(address lastVersion) public initializer {
        __ERC721_init("VIVID", "VIVID");
        __Ownable_init();

        _lastVersion = lastVersion;
    }

    function phantomMint(
        address[] calldata owners, uint256 startAt
    ) public onlyOwner {
        require(!_phantomMintingDisabled);
        for (uint256 i = startAt; i < owners.length; i++)
            emit Transfer(address(0), owners[i], i);
    }

    function ownerOf(uint256 tokenId) public override view returns (address) {
        address owner = _ownerOf(tokenId);
        if (owner == address(0))
            return IERC721(_lastVersion).ownerOf(tokenId);
        else return owner;
    }

    function setBaseURI(string memory _newBaseUri) external onlyOwner {
        baseUri = _newBaseUri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return bytes(baseUri).length != 0
            ? string(abi.encodePacked(baseUri, LibString.toString(tokenId)))
            : "";
    }

    function disablePhantomMintingForever() public onlyOwner {
        _phantomMintingDisabled = true;        
    }

}