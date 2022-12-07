// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";


contract SwapTool is Initializable, UUPSUpgradeable, IERC721ReceiverUpgradeable, OwnableUpgradeable {

    // collection address -> is allowed
    mapping(address => bool) public allowedCollections;
    // collection address -> account -> balance
    mapping(address => mapping(address => uint)) public balance;

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();

        setAllowedCollection(0x02BeeD1404c69e62b76Af6DbdaE41Bd98bcA2Eab, true);
    }

    function transferTokens(address collection, uint[] calldata tokenIds, address from, address to) internal {
        for (uint i = 0; i < tokenIds.length; i++) {
            IERC721Upgradeable(collection).safeTransferFrom(
                from,
                to,
                tokenIds[i]
            );
        }
    }

    function poolSwap(address collection, uint[] calldata inTokensIds, uint[] calldata outTokensIds) external onlyProxy {
        require(allowedCollections[collection], "Collection is not allowed for pool swap");

        transferTokens(collection, inTokensIds, msg.sender, address(this));
        balance[collection][msg.sender] += inTokensIds.length;

        require(balance[collection][msg.sender] >= outTokensIds.length, "Insufficient balance");
        transferTokens(collection, outTokensIds, address(this), msg.sender);
        balance[collection][msg.sender] -= outTokensIds.length;
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }


    function setAllowedCollection(address collection, bool value) public onlyOwner {
        allowedCollections[collection] = value;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {

    }

}