// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "./KrystalCharacterStorage.sol";
import "./IKrystalCharacter.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract KrystalCharacterImpl is KrystalCharacterStorage, IKrystalCharacter {
    using Strings for uint256;

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        address _admin
    ) public initializer {
        super.initialize(_name, _symbol, _uri);
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);

        tokenUriPrefix = _uri;
    }

    // ERC-721 Compatible
    function tokenUri(uint256 tokenId) external view returns (string memory) {
        return string(abi.encodePacked(tokenUriPrefix, tokenId.toString()));
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "unauthorized: admin required");
        _;
    }

    function setMinter(address _minter) external onlyAdmin {
        _setupRole(MINTER_ROLE, _minter);
        emit SetMinter(_minter);
    }

    function setURI(string memory newuri) external onlyAdmin {
        super._setBaseURI(newuri);
        tokenUriPrefix = newuri;
    }
}