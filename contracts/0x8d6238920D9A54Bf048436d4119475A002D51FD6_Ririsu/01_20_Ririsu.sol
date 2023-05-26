// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "../Interfaces/IProxyRegistry.sol";
import "./PaymentSplitterMod.sol";
import "./ERC721R.sol";
import "./Signed.sol";

contract Ririsu is Signed, PaymentSplitterMod, ERC721R {
    using Strings for uint256;

    uint256 private MAX_SUPPLY = 5_555;
    uint256 private price = 0.088 ether; // 0.08Ξ
    uint256 private maxOrder = 5;

    bool private isActive = false;

    // IPFS content hash of contract-level metadata
    string private _contractURIHash = "QmdndNAWt4yQ2AU1EbEMW1u89LKPiCtx8s1pY9jNpvnBED";
    string private _baseTokenURI = "";
    string private _tokenURISuffix = "";

    address[] private addressList = [
        0x87EAAEc2a77D3F2A3102d5Fb8B8f767fC2A8D8e3,
        0x7a991F4D736BD12bbE6bFddcac545910D69c9A80
    ];
    uint256[] private shareList = [50, 50];

    uint256 private limitPerAddress = 2;

    mapping(address => uint256) private uwu;

    // OpenSea"s Proxy Registry
    IProxyRegistry public immutable proxyRegistry;

    constructor(IProxyRegistry _proxyRegistry) ERC721R("Ririsu", "RIRI") PaymentSplitterMod(addressList, shareList) {
        proxyRegistry = _proxyRegistry;
    }

    function toggleSale() external onlyDelegates {
        isActive = !isActive;
    }

    function setLimitPerAddress(uint256 limit) external onlyDelegates {
        limitPerAddress = limit;
    }

    /**
     * @notice The IPFS URI of contract-level metadata.
     */
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked("ipfs://", _contractURIHash));
    }

    /**
     * @notice Set the _contractURIHash.
     * @dev Only callable by the owner.
     */
    function setContractURIHash(string memory newContractURIHash) external onlyOwner {
        _contractURIHash = newContractURIHash;
    }

    function _baseURI() internal view returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @notice Set the baseURI.
     * @dev Only callable by the owner.
     */
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    /**
     * @notice Override isApprovedForAll to whitelist user"s OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator) public view override(ERC721R) returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        if (proxyRegistry.proxies(owner) == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    function tokenURI(uint256 tokenId) external view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_baseTokenURI, tokenId.toString(), _tokenURISuffix));
    }

    //external
    fallback() external payable {}

    function mint(uint256 quantity, bytes calldata signature) external payable {
        require(msg.value >= price * quantity, "Not enough Ether sent.");

        uint256 supply = totalSupply();
        require(supply + quantity <= MAX_SUPPLY, "Mint/order exceeds supply");

        if (!isActive) {
            if (signature.length > 0) {
                verifySignature(quantity.toString(), signature);
            } else {
                revert("sale is not open and sig n/a");
            }
        }

        require(uwu[msg.sender] + quantity <= limitPerAddress, "Can't mint anymore");
        uwu[msg.sender] += quantity;
        _safeMint(msg.sender, quantity, "");
    }

    function adminMint(uint256 quantity) external onlyDelegates {
        uint256 supply = totalSupply();
        require(supply + quantity <= MAX_SUPPLY, "Mint/order exceeds supply");
        _safeMint(msg.sender, quantity, "");
    }
}