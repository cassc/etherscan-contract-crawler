// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract SudoWolves is ERC721A, Ownable {
    bool minted;
    string baseURI;

    constructor() ERC721A("SudoWolves", "SUDOWOLVES") {
        baseURI = "ipfs://Qma2D6D2tWwvc9nMKdxASeTGYyXAWMYLXCjj4WXDKQrRVE/";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newURI) external onlyOwner() {
        baseURI = newURI;
    }

    function mint() external payable onlyOwner() {
        require(!minted, "Mint already completed");
        _mint(msg.sender, 2000);
        minted = true;
    }

    function setMinted(bool _minted) external onlyOwner(){
        minted = _minted;
    }
}
