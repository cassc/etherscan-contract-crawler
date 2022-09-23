// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


import "./ERC1155Base.sol";

contract ERC1155CustomMint is ERC1155Base {
    bool private CUSTOM_MINT_ENABLED = false;

    constructor(address whitelistContract, string memory name_, string memory symbol_, uint256 price, uint256 maxSupply) public ERC1155Base(whitelistContract, name_, symbol_, price, maxSupply) {}

    function setCustomMintEnabled(bool enabled) public onlyOwner {
        CUSTOM_MINT_ENABLED = enabled;
    }

    function getCustomMintEnabled() public view returns (bool) {
        return CUSTOM_MINT_ENABLED;
    }

    function mintTo(address recipient, string memory _tokenURI, uint256 amount, bytes memory data) public override whenNotPaused payable {
        require(CUSTOM_MINT_ENABLED == true, "Custom mint is disabled");
        super.mintTo(recipient, _tokenURI, amount, data);
    }
}