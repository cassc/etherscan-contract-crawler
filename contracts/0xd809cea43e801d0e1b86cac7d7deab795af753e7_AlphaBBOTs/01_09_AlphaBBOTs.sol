// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {ERC721} from "@rari-capital/solmate/src/tokens/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {CantBeEvil, LicenseVersion} from "@a16z/contracts/licenses/CantBeEvil.sol";

//_/\\\\\\\\\\\\\__________________/\\\\\\\\\\\\\_________/\\\\\_______/\\\\\\\\\\\\\\\_____/\\\\\\\\\\\___
//_\/\\\/////////\\\_______________\/\\\/////////\\\_____/\\\///\\\____\///////\\\/////____/\\\/////////\\\_
// _\/\\\_______\/\\\_______________\/\\\_______\/\\\___/\\\/__\///\\\________\/\\\________\//\\\______\///__
//  _\/\\\\\\\\\\\\\\___/\\\\\\\\\\\_\/\\\\\\\\\\\\\\___/\\\______\//\\\_______\/\\\_________\////\\\_________
//   _\/\\\/////////\\\_\///////////__\/\\\/////////\\\_\/\\\_______\/\\\_______\/\\\____________\////\\\______
//    _\/\\\_______\/\\\_______________\/\\\_______\/\\\_\//\\\______/\\\________\/\\\_______________\////\\\___
//     _\/\\\_______\/\\\_______________\/\\\_______\/\\\__\///\\\__/\\\__________\/\\\________/\\\______\//\\\__
//      _\/\\\\\\\\\\\\\/________________\/\\\\\\\\\\\\\/_____\///\\\\\/___________\/\\\_______\///\\\\\\\\\\\/___
//       _\/////////////__________________\/////////////_________\/////_____________\///__________\///////////_____

contract AlphaBBOTs is ERC721, Ownable, CantBeEvil {
    using Strings for uint256;

    string public metadataPrefix;
    uint256 public nextId;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _metadataPrefix
    ) ERC721(_name, _symbol) CantBeEvil(LicenseVersion.CBE_PR_HS) {
        metadataPrefix = _metadataPrefix;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return string.concat(metadataPrefix, id.toString());
    }

    function mintBatch(uint256 amt, address to) external onlyOwner {
        for (uint256 i; i < amt; i++) {
            // Assume receiver can receive to save gas
            _mint(to, nextId);
            nextId++;
        }
    }

    function updateMetadata(string memory _metadataPrefix) external onlyOwner {
        metadataPrefix = _metadataPrefix;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(CantBeEvil, ERC721)
        returns (bool)
    {
        return
            CantBeEvil.supportsInterface(interfaceId) ||
            ERC721.supportsInterface(interfaceId);
    }
}