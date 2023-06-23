//SPDX-License-Identifier: Unlicense

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFT is ERC721Burnable, Ownable {

    using Strings for uint256;
    
    address bridgeManager;
    string public stacksAddress;
    string public baseURI;

    modifier onlyBridgeManager() {
        require(msg.sender == bridgeManager);
        _;
    }

    constructor(string memory name_, string memory symbol_, string memory baseURI_, string memory stacksAddress_) ERC721(name_, symbol_) {
        baseURI = baseURI_;
        stacksAddress = stacksAddress_;
        bridgeManager = msg.sender;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    function mint(address to, uint256 tokenId) external onlyBridgeManager {
        _mint(to, tokenId);
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function bridge2Stacks(address sender, uint256 tokenId) external onlyBridgeManager {
        require(_isApprovedOrOwner(sender, tokenId), "ERC721Metadata: caller is not owner nor approved");
        _transfer(sender, bridgeManager, tokenId);
    }

}

interface AggregatorInterface{
    function latestAnswer() external view returns (uint256);
}