//   ____   _____  _____   _
//  | __ ) | ____||_   _| / \
//  |  _ \ |  _|    | |  / _ \
//  | |_) || |___   | | / ___ \
//  |____/ |_____|  |_|/_/   \_\  _
//  | |/ / _ __  ___   __ _ | |_ (_)__   __
//  | ' / | '__|/ _ \ / _` || __|| |\ \ / /
//  | . \ | |  |  __/| (_| || |_ | | \ V /
//  |_|\_\|_|   \___| \__,_| \__||_|  \_/
//
//  SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BetaKreativVip is ERC721A, Ownable {
    string public baseURI = "";

    constructor() ERC721A("Beta Kreativ Vip", "BKVIP") {
        _safeMint(msg.sender, 1);
    }
    
    function airdrop(address[] memory _addresses, uint256 _quantity)
        external
        onlyOwner
    {
        for (uint256 i; i < _addresses.length; i++) {
            _safeMint(_addresses[i], _quantity);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }
}