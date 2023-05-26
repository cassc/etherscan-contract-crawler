// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./lib/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract OwnableDelegateProxy {}
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract OmegaKongsClub is ERC721A, Ownable {
    using Strings for uint256;

    address public openseaProxyRegistryAddress;
    string public baseURIString = "https://storage.googleapis.com/alphakongclub/omegas/metadata/";

    mapping(address => bool) public allowedMinter;

    modifier onlyMinter {
        require(allowedMinter[msg.sender] || msg.sender == owner(), "Sender not allowed to mint");
        _;
    }
 
    receive() external payable {}

    constructor(
        address _openseaProxyRegistryAddress
    ) ERC721A("Omega Kongs Club", "OKC") Ownable() {       
        openseaProxyRegistryAddress = _openseaProxyRegistryAddress;
        allowedMinter[owner()] = true;
    }

    /** === Minting === */

    function mint(address recipient, uint256 amount) external onlyMinter {
        _safeMint(recipient, amount);
    }

    /** === View === */

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(baseURIString, tokenId.toString(), ".json"));     
    }

    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Create an instance of the ProxyRegistry contract from Opensea
        ProxyRegistry proxyRegistry = ProxyRegistry(openseaProxyRegistryAddress);
        // whitelist the ProxyContract of the owner of the NFT
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        if (openseaProxyRegistryAddress == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /** === Admin only === */

    function setAllowedMinter(address minter, bool allowed) external onlyOwner {
        allowedMinter[minter] = allowed;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURIString = _newBaseURI;        
    }

    function withdrawStuckEther(address _to) external onlyOwner {
        require(_to != address(0), "CANNOT WITHDRAW TO ZERO ADDRESS");
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "NO ETHER TO WITHDRAW");
        payable(_to).transfer(contractBalance);
    }
}