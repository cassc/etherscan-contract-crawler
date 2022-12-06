// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// Uncomment this line to use console.log
import "hardhat/console.sol";

interface ERCBase {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function getApproved(uint256 tokenId) external view returns (address);
}

interface ERC721Partial is ERCBase {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface ERC1155Partial is ERCBase {
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata) external;
}


contract Test is Initializable, PausableUpgradeable, OwnableUpgradeable, IERC721ReceiverUpgradeable {

    bytes4 _ERC721;
    bytes4 _ERC1155;

    function initialize() public initializer {

      _ERC721 = 0x80ac58cd;
      _ERC1155 = 0xd9b67a26;

      // Call the init function of OwnableUpgradeable to set owner
      // Calls will fail without this
      __Ownable_init();

    }

    function pause() onlyOwner external {
       _pause();
    }

    function unpause() onlyOwner external {
       _unpause();
    }

    /**
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        console.log("Received 721NFT");

        return this.onERC721Received.selector;
    }

    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        console.log("Received 1155NFT");

        return this.onERC1155Received.selector;
    }

    receive () external payable { }

    fallback () external payable { }

}