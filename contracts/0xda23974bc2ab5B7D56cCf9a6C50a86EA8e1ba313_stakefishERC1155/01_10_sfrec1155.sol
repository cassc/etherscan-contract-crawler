// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;


import "./ERC1155.sol";
import "./utils/Ownable.sol";

contract stakefishERC1155 is Ownable, ERC1155("") {
    string public name = "Stakefish NFT collection";
    mapping(uint256 => string) _uris;
    function batchMint(
        uint256 id,
        address[] calldata tos,
        uint256[] calldata amounts,
        bytes[] calldata data
    ) external onlyOwner {
        uint256 len = tos.length;
        require(len == amounts.length && len == data.length, "Array length not match");
        for (uint256 i = 0; i < len; i++) {
            _mint(tos[i], id, amounts[i], data[i]);
        }
    }
    function batchMint(
        uint256 id,
        address[] calldata tos,
        uint256[] calldata amounts
    ) external onlyOwner {
        uint256 len = tos.length;
        require(len == amounts.length, "Array length not match");
        for (uint256 i = 0; i < len; i++) {
            _mint(tos[i], id, amounts[i], "");
        }
    }
    function setURI(uint256 id, string calldata uri) external onlyOwner {
        _uris[id] = uri;
    }
    function uri(uint256 id) public view override returns (string memory) {
        return _uris[id];
    }
}