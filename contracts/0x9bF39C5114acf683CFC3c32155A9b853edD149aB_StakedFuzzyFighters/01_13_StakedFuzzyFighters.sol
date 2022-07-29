// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import  "./IStakedFuzzyFighters.sol";

contract StakedFuzzyFighters is ERC1155, Ownable, ERC1155Burnable, IStakedFuzzyFighters {
    using Strings for uint256;
    string private baseURI;


    mapping(address => bool) private whitelist;
    constructor() ERC1155("") {}
    

    function setBaseURI(string memory newUri) external onlyOwner {
        baseURI = newUri;
    }

    function uri(uint256 id) public view virtual override returns (string memory) {
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, id.toString())) : "";
    }

    function setWhitelist(address[] calldata minters) external onlyOwner {
        for (uint256 i; i < minters.length; i++) {
            whitelist[minters[i]] = true;
        }
    }

    function whitelistMint(address account, uint256 id, uint256 amount) external {
        require(whitelist[msg.sender], 'sender must be whitelisted');
        _mint(account, id, amount, '');
    }

    function whitelistBurn(
        address account,
        uint256 id,
        uint256 value
    ) external {
        require(whitelist[msg.sender], 'sender must be whitelisted');

       _burn(account, id, value);
    }

    function checkWhitelist(address account) public view returns (bool) {
      return whitelist[account];
    }

    /// @notice Disable share transfers
    function _safeTransferFrom(
        address, /* from,*/
        address, /* to,*/
        uint256, /* id,*/
        uint256, /* amount,*/
        bytes memory /* data,*/
    ) internal pure  override{
        revert("non-transferable");
    }

     /// @notice Disable share transfers
    function _safeBatchTransferFrom(
        address,/*  from,*/
        address,/* to,*/
        uint256[] memory,/* ids,*/
        uint256[] memory,/* amounts,*/
        bytes memory/* data*/
    ) internal pure override {
        revert("non-transferable");
    }
}