// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import "solmate/tokens/ERC721.sol";
import "solmate/tokens/ERC20.sol";
import "solmate/auth/Owned.sol";

/**
 * @title Pebbles
 * @notice NFT wrapper for PebbleDAO's 72M entry requirement.
 * @author kvk0x
 */
contract PebbleNFT is ERC721, Owned {
    // Events

    event SetURI(string uri);
    event Withdraw(uint256 amount);

    // Config

    uint256 public immutable cost;
    ERC20 public immutable pebble;
    string public uri;

    // State

    uint256 public currentTokenId;

    // Constructor

    constructor(address _owner, ERC20 _pebble, uint256 _cost) ERC721("Pebbles", "PEBBLE") Owned(_owner) {
        pebble = _pebble;
        cost = _cost;
    }

    // Supply

    function mint(address to) external returns (uint256) {
        require(to != address(0), "mint to zero address");

        uint256 newItemId = ++currentTokenId;
        _safeMint(to, newItemId);

        pebble.transferFrom(msg.sender, address(this), cost);

        return newItemId;
    }

    // Metadata

    function tokenURI(uint256) public view virtual override returns (string memory) {
        return uri;
    }

    function setTokenURI(string memory _uri) external onlyOwner {
        uri = _uri;

        emit SetURI(uri);
    }

    // Admin

    function withdraw() external onlyOwner {
        uint256 balance = pebble.balanceOf(address(this));
        pebble.transfer(msg.sender, balance);

        emit Withdraw(balance);
    }
}