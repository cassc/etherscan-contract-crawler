//
//
//
/////////////////////////////////////////////////////////////////
//                                                             //
//       ██████  ███████ ███    ██ ███    ██ ██ ███████        //
//       ██   ██ ██      ████   ██ ████   ██ ██ ██             //
//       ██   ██ █████   ██ ██  ██ ██ ██  ██ ██ ███████        //
//       ██   ██ ██      ██  ██ ██ ██  ██ ██ ██      ██        //
//       ██████  ███████ ██   ████ ██   ████ ██ ███████        //
//                                                             //
// ███████  ██████ ██   ██ ███    ███ ███████ ██      ███████  //
// ██      ██      ██   ██ ████  ████ ██      ██         ███   //
// ███████ ██      ███████ ██ ████ ██ █████   ██        ███    //
//      ██ ██      ██   ██ ██  ██  ██ ██      ██       ███     //
// ███████  ██████ ██   ██ ██      ██ ███████ ███████ ███████  //
//                                                             //
/////////////////////////////////////////////////////////////////
//
//
//

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract AufReisenHolderCollection is ERC1155PresetMinterPauser, Ownable, DefaultOperatorFilterer, ERC2981 {
    string public name = "AufReisenHolderCollection";
    string public symbol = "ARHC";

    address receiver = 0x24948484D253A099E3Ee25cDa180B0dBcFBdB9cE;
    uint96 feeNumerator = 1000;

    string public contractUri = "https://metadata.dennisschmelz.de/holdercollection/contract";

    constructor() ERC1155PresetMinterPauser("https://metadata.dennisschmelz.de/holdercollection/{id}") {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) public onlyOwner {
      _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function setUri(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function setContractURI(string memory newuri) public onlyOwner {
        contractUri = newuri;
    }

    function contractURI() public view returns (string memory) {
        return contractUri;
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155PresetMinterPauser, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}