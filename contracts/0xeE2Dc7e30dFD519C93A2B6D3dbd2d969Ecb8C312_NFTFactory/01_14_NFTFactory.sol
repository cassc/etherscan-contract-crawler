// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./BNFT.sol";

contract NFTFactory {
    event NFTCreated(address indexed nftAddress, string name, string symbol);

    address public immutable admin;

    constructor(address admin_) {
        admin = admin_;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Restricted to admin.");
        _;
    }

    function createNewNFT(
        address admin_,
        address owner,
        string memory baseURI,
        string memory name,
        string memory symbol
    ) external onlyAdmin returns (address) {
        BNFT nft = new BNFT(admin_, owner, baseURI, name, symbol);
        emit NFTCreated(address(nft), name, symbol);
        return address(nft);
    }
}