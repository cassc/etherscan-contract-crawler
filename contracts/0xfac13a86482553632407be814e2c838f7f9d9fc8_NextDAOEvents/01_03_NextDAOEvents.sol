// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "solmate/tokens/ERC1155.sol";
import "solmate/auth/Owned.sol";

contract NextDAOEvents is ERC1155, Owned {
    string public constant name = "NextDAO Events";
    string public tokenURI;

    constructor(address _owner, string memory _uri) Owned(_owner) {
        tokenURI = "ipfs://xxx/{id}";
    }

    function create(
        address recipient,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external onlyOwner {
        _batchMint(recipient, ids, amounts, "");
    }

    function burn(
        address from,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external onlyOwner {
        _batchBurn(from, ids, amounts);
    }

    function uri(uint256 id) public view override returns (string memory) {
        return tokenURI;
    }

    function updateURI(string calldata _uri) external onlyOwner {
        tokenURI = _uri;
    }
}