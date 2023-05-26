// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC1155.sol";

contract Traits is ERC1155 {
    constructor() ERC1155() {}

    string private _uriBase;
    string private _extension;

    function name() public pure returns (string memory) {
        return "TestTraits";
    }

    function symbol() public pure returns (string memory) {
        return "TRAIT";
    }

    function setURI(string memory uriBase) public onlyOwner {
        _uriBase = uriBase;
    }

    function setURIExtension(string memory extension) public onlyOwner {
        _extension = extension;
    }

    function uri(uint256 tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(_uriBase, Strings.toString(tokenId), _extension));
    }

    function mint(address to, uint256 id, uint256 amount) external {
        require(_hasAccess(Access.Mint, _msgSender()), "Not allowed to mint");
        _safeMint(to, id, amount, "");
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts) external {
        require(_hasAccess(Access.Mint, _msgSender()), "Not allowed to mint");
        _safeMintBatch(to, ids, amounts, "");
    }
}