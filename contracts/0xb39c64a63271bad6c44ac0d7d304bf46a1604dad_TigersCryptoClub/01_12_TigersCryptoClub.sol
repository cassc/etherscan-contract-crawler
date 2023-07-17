// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract TigersCryptoClub is ERC721, Pausable, Ownable {
    using Address for address payable;
    using Strings for uint256;

    enum SalePhase {
        paused,
        open
    }

    // 0.19 ETH for the whitelist
    uint256 public constant WHITELIST_PRICE = 190000000000000000;
    // Max supply of 5555 tokens
    uint256 public constant MAX_SUPPLY = 5555;

    address private constant DEV_TEAM =
        0xB2952D78f6bE9170Ca9116AC1994F18016603c29;
    address private constant S_ADDRESS =
        0xfb6af20D25C173fF8Bf5117b8b0e377320c69884;
    address private constant FUNDS_RECIPIENT =
        0x78732fCC62D3A6dA09F00b28A8073Dc81613c5cF;

    // How many tokens have been minted
    uint256 public totalSupply;
    // 0.19 ETH but can be altered
    uint256 public regularPrice = 190000000000000000;

    // The baseURI where the metadata files are located
    string public baseURI;

    // Default to 0, so to paused
    SalePhase public currentPhase;

    // Address => how many NFTs this address has minted
    // Unlike the balance this quantity will not change after
    // a token transfer which is the desired behavior
    mapping(address => uint256) private mintCount;

    constructor() ERC721("Tigers Crypto Club", "TCC") {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Mint tokens for a given address
     * @param to Address that will receive the tokens
     * @param count number of tokens to mint
     */
    function mintTo(address to, uint256 count) external payable {
        // Check that the mint is open
        require(currentPhase == SalePhase.open, "Mint not open");
        // An address can mint only up to 3 NFTs during public sale
        require(mintCount[to] + count <= 3, "Only up to 3 NFTs per address");
        // Check that there's still supply left
        require(totalSupply + count <= MAX_SUPPLY, "Not enough supply left");
        // Check that the ETH provided is enough
        require(msg.value == regularPrice * count, "Invalid value");
        // Proceed to mint the tokens
        _mintTo(to, count);
    }

    function airdrop(address[] memory addrs, uint256[] memory counts)
        external
        onlyOwner
    {
        require(addrs.length == counts.length, "Arrays mismatch");
        for (uint256 i = 0; i < addrs.length; i++) {
            _mintTo(addrs[i], counts[i]);
        }
    }

    function _mintTo(address to, uint256 count) private {
        // Mint all the tokens requested
        for (uint256 i = 1; i <= count; i++) {
            _safeMint(to, totalSupply + i);
        }
        // Update the total supply accordingly
        totalSupply += count;
        // We update the mint count for that address
        mintCount[to] += count;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Set the current phase of the sale
     * @param _phase The phase to switch to.
     * Either 0 (= paused), 1 (= presale) or 2 (= open)
     */
    function setPhase(SalePhase _phase) external onlyOwner {
        currentPhase = _phase;
    }

    /**
     * @dev Set the baseURI used to store the metadata
     * @param _uri The new URI for the baseURI
     */
    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    /**
     * @dev Set the price for the regular mint
     * @param _price Price at which the mint should be set
     */
    function setPrice(uint256 _price) external onlyOwner {
        regularPrice = _price;
    }

    /**
     * @dev Withdraw the funds held by this contract to the address specified
     */
    function withdrawFunds() external onlyOwner {
        // Takes some fees for the people who worked on this smart contract
        uint256 fees = (address(this).balance * 4) / 100;
        // 2 thirds of the fees
        payable(DEV_TEAM).sendValue((fees * 2) / 3);
        // 1 third of the fees
        payable(S_ADDRESS).sendValue(fees / 3);
        // Sends the rest of the balance to the address specified
        payable(FUNDS_RECIPIENT).sendValue(address(this).balance);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        // Concatenate the baseURI and the tokenId as the tokenId should
        // just be appended at the end to access the token metadata
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }
}