// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./ERC721Enumerable.sol";

contract PunksThreeSE is ERC721Enumerable {

    address immutable authorizedMinter;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint256 _maxSupply,
        address _authorizedMinter
    ) PVERC721(_name, _symbol, _uri, _maxSupply) {
        authorizedMinter = _authorizedMinter;
    }

    function mint(address to) external {
        require(msg.sender == authorizedMinter, "NOT APPROVED TO MINT");

        _internalMint(to);
    }

    function ownerMint(address[] calldata _to, uint256[] calldata _amount) external onlyOwner {
        require(_to.length == _amount.length, "same length required");

        for (uint256 i; i < _to.length; ) {
            for (uint256 j; j < _amount.length; ) {
                _internalMint(_to[i]);

                unchecked {
                    j++;
                }
            }

            unchecked {
                i++;
            }
        }
    }
}