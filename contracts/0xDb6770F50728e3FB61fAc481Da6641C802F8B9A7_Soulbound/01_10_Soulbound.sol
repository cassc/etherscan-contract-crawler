//SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./ISoulbound.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Soulbound is ISoulbound, Initializable, OwnableUpgradeable {
    uint256 private _tokenId;

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _ids;

    function initialize() public initializer {
        super.__Ownable_init();
        _tokenId = 1;
    }

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(ISoulbound).interfaceId;
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _owners[tokenId];
    }

    function id(address owner) public view override returns (uint256) {
        return _ids[owner];
    }

    function mint() external {
        require(!_exists(_msgSender()), "Already minted");
        _owners[_tokenId] = _msgSender();
        _ids[_msgSender()] = _tokenId;
        _tokenId += 1;
        emit SoulboundMinted(_msgSender());
    }

    function _exists(address owner) internal view virtual returns (bool) {
        return _ids[owner] != 0;
    }

}