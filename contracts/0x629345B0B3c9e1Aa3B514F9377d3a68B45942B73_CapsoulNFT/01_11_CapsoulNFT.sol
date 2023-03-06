// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CapsoulNFT is ERC721, Ownable {
    using Strings for uint256;

    uint256 public totalSupply;

    uint256 public maxSupply = 100;

    uint256 public price = 0.08 ether;

    uint256 public startDate = 1678024800; // Sunday, March 5, 2023 2:00:00 PM

    uint256 public privateSaleLength = 48 hours;

    string public baseURI = "https://nftstorage.link/ipfs/QmaMb7aePCSjm2H5j6DBtuGEYEmQsWMoy9JsdRqH1DiTPx/";

    // whitelist
    mapping(address => bool) public whitelist;
    // mints
    mapping(address => bool) public mints;

    constructor() ERC721("POPrism", "POPrism") {}

    /**
     * @notice Reveal metadata
     */
    function setBaseURI(string calldata __baseURI) external onlyOwner
    {
        baseURI = __baseURI;
    }

    /**
     * @notice Add to whitelist
     */
    function addToWhitelist(address[] calldata addresses) external onlyOwner
    {
        for (uint i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = true;
        }
    }

    /**
     * @notice Remove from whitelist
     */
    function removeFromWhitelist(address[] calldata addresses) external onlyOwner
    {
        for (uint i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = false;
        }
    }

    function mint() external payable {
        // check the sale has started
        require(block.timestamp >= startDate, "Sale has not started");
        // check the sale not sold out
        require(totalSupply < maxSupply, "Sold out");
        // check the amount sent to the contract
        require(msg.value == price, "Wrong payment amount");
        // check if it still the private phase
        if (block.timestamp < startDate + privateSaleLength) {
            require(whitelist[msg.sender], "User is not whitelisted");
            require(!mints[msg.sender], "Can only mint one NFT");
        }

        mints[msg.sender] = true;

        unchecked {
            ++totalSupply;
        }
        _mint(msg.sender, totalSupply);
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}