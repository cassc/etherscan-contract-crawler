// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721ABase.sol";

contract ERC721ABaseWithSupply is ERC721ABase {
    uint32 public immutable maxSupply; // 0 means no max supply

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        uint32 _maxSupply
    ) ERC721ABase(_name, _symbol, _royaltyRecipient, _royaltyBps) {
        maxSupply = _maxSupply;
        _setupRole(MINTER_ROLE, msg.sender);
    }

    function checkMaxSupply(uint256 _quantity) internal view {
        if (maxSupply > 0) {
            uint256 supply = totalSupply();
            require(
                supply + _quantity <= maxSupply,
                "Mint would exceed max supply"
            );
        }
    }

    function reserve(
        uint256 _quantity
    ) public virtual onlyRole(MINTER_ROLE) checkBot {
        checkMaxSupply(_quantity);
        _mint(msg.sender, _quantity);
    }
}