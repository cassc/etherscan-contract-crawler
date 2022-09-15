// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./CreatorTracking.sol";

contract NiftyIslandCommunityForge1155 is
    OwnableUpgradeable,
    ERC1155SupplyUpgradeable,
    CreatorTracking
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIdCounter;

    function initialize(string memory baseuri) public initializer {
        __ERC1155_init("Nifty Island Community Forge");
        __Ownable_init();
        __ERC1155Supply_init();
        _setURI(baseuri);
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
        emit BaseUriChanged(newuri);
    }

    function mint(uint256 amount) public {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _mint(msg.sender, tokenId, amount, "");
        setCreator(tokenId, msg.sender);
    }

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal override {
        require(totalSupply(id) == 0, "attempt to mint existing token");
        super._mint(to, id, amount, data);
    }

    function currentTokenId() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    event BaseUriChanged(string uri);
}