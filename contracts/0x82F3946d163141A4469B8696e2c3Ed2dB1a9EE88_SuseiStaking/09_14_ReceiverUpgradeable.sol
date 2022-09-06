// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

contract ReceiverUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    IERC721Upgradeable public nft;

    function __Receiver_init(IERC721Upgradeable nft_) internal onlyInitializing {
        nft = nft_;
    }

    function _receive(uint256 id_, address from_) internal {
        nft.safeTransferFrom(from_, address(this), id_);
    }

    function _return(uint256 id_, address to_) internal {
        nft.safeTransferFrom(address(this), to_, id_);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata 
    ) external pure override(IERC721ReceiverUpgradeable) returns (bytes4) {
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }
}