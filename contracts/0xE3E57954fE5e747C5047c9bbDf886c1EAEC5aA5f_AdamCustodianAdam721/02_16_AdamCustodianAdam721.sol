// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./AccessControlInitializer.sol";
import "./ERC721Receiver.sol";
import "./IAdam721.sol";
import "./ReturnIncorrectERC20.sol";
import "./ReturnIncorrectERC721.sol";


contract AdamCustodianAdam721 is AccessControl, AccessControlInitializer, ERC721Receiver, ReturnIncorrectERC20, ReturnIncorrectERC721 {

    bytes32 public constant BURN_CALLER_ROLE = keccak256("BURN_CALLER_ROLE");
    bytes32 public constant TRANSFER_CALLER_ROLE = keccak256("TRANSFER_CALLER_ROLE");

    event CallSetTokenURI(address indexed operator, address indexed contract_, uint256 indexed tokenId, string newValue);
    event CallTransfer(address indexed operator, address indexed contract_, uint256 indexed tokenId, address from, address to);

    constructor (bytes32[] memory roles, address[] memory addresses) {
        _setupRoleBatch(roles, addresses);
    }

    function callAdam721Burn(IAdam721 adam721, uint256 tokenId) external virtual onlyRole(BURN_CALLER_ROLE) {
        address owner = adam721.ownerOf(tokenId);
        adam721.burn(tokenId);
        emit CallTransfer(_msgSender(), address(adam721), tokenId, owner, address(0));
    }

    function callAdam721SafeMintOrTransferFrom(
        IAdam721 adam721, address to, uint256 tokenId, string memory tokenURI, bytes memory data
    ) public virtual onlyRole(TRANSFER_CALLER_ROLE) {
        address owner = adam721.gracefulOwnerOf(tokenId);
        if (owner == address(0)) {
            adam721.safeMint(to, tokenId, data);
            emit CallTransfer(_msgSender(), address(adam721), tokenId, address(0), to);
            if (bytes(tokenURI).length > 0) {
                adam721.setTokenURI(tokenId, tokenURI);
                emit CallSetTokenURI(_msgSender(), address(adam721), tokenId, tokenURI);
            }
        }
        else {
            require(owner == address(this), "AdamCustodianAdam721: transfer of token that is not own");
            if (bytes(tokenURI).length > 0) {
                if (keccak256(bytes(tokenURI)) != keccak256(bytes(adam721.tokenURI(tokenId)))) {
                    adam721.setTokenURI(tokenId, tokenURI);
                    emit CallSetTokenURI(_msgSender(), address(adam721), tokenId, tokenURI);
                }
            }
            adam721.safeTransferFrom(address(this), to, tokenId, data);
            emit CallTransfer(_msgSender(), address(adam721), tokenId, address(this), to);
        }
    }
}