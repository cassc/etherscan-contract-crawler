// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "solmate/tokens/ERC721.sol";
import "openzeppelin-contracts/utils/Strings.sol";
import "openzeppelin-contracts/access/Ownable.sol";

interface IVault {
    function balanceOf(address) external view returns (uint256);
}

contract NFT is ERC721, Ownable{
    using Strings for uint256;
    string public baseURI;
    uint256 public currentTokenId;
    uint256 public constant MAX_SUPPLY = 10_000;
    address public vault;
    uint256 public shopxRequired = 10_000 ether; // 10000 shopx in wei

    event UpdateShopxRequired(uint256 amount);
    event UpdateVault(address vault);

    error MaxSupply();
    error NonExistentTokenURI();
    error NotEnoughStakingBalance();

    constructor(string memory _name, string memory _symbol, address _vault)
        ERC721(_name, _symbol)
    {
        baseURI = "https://shopx-metadata.s3.us-east-2.amazonaws.com/";
        vault = _vault;
    }

    function mintTo(address recipient) public returns (uint256) {
        // check if balanceOf(contract squadX's msg.sender address) >= shopxRequired
        if (IVault(vault).balanceOf(msg.sender) < shopxRequired) revert NotEnoughStakingBalance();

        uint256 newTokenId = ++currentTokenId;
        if (newTokenId > MAX_SUPPLY) revert MaxSupply();
        _safeMint(recipient, newTokenId);
        return newTokenId;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (ownerOf(tokenId) == address(0)) revert NonExistentTokenURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    function updateShopxRequired(uint256 _amount) external onlyOwner returns (uint256) {
        require(_amount!=0, "Invalid input");
        shopxRequired = _amount;
        emit UpdateShopxRequired(shopxRequired);
        return shopxRequired;
    }

    function updateVault(address _addr) external onlyOwner returns (address) {
        require(_addr!=address(0), "Invalid input");
        vault = _addr;
        emit UpdateVault(vault);
        return vault;
    }

    function updateBaseUri(string memory _uri) external onlyOwner returns (string memory) {
        baseURI = _uri;
        return baseURI;
    }

}