// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TAPERAJUNGLE is ERC721Pausable, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private tokenId;

    uint256 public mintFee;
    string private baseUriExtended;
    uint256 public immutable MAX_SUPPLY = 8000;

    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
    {}

    /*
     * mint nft to the address passed by user in 'to' parameter
     * at the call time total supply + desired amount of nfts should be less than the limit
     * Requirements:
     * contract should not be paused
     * msg.value must be equal to the minting fee
     */

    function mint(address to, uint256 nftAmount)
        external
        payable
        whenNotPaused
    {
        require(
            tokenId.current() + nftAmount <= MAX_SUPPLY,
            "Max limit reached"
        );
        require(msg.value == mintFee * nftAmount, "Invalid mint fee");
        for (uint256 i = 0; i < nftAmount; i++) {
            tokenId.increment();
            _mint(to, tokenId.current());
        }
    }

    /*
     * only owner can set the Mint Fee
     * Requirements:
     * ownable function
     * 'fee' length should be greater than 0
     */

    function setMintFee(uint256 fee) external onlyOwner {
        mintFee = fee;
    }

    /*
     * only owner can set the Uri
     * Requirements:
     * ownable function
     * '_baseUri' length should be greater than 0
     */

    function setBaseURI(string memory baseURI) external onlyOwner {
        require(bytes(baseURI).length > 0, "Cannot be null");
        baseUriExtended = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUriExtended;
    }

    function pause() external whenNotPaused onlyOwner {
        _pause();
    }

    function unpause() external whenPaused onlyOwner {
        _unpause();
    }

    /*
     * returns the amount of minted nfts
     */

    function totalSupply() external view returns (uint256) {
        return tokenId.current();
    }

    /*
     * owner can withdraw eth from contract
     * Requirements:
     * ownable function
     * entered amount should be less than the contract balance
     */

    function withdrawEth(address to) external onlyOwner {
        require(to != address(0), "zero address");
        payable(to).transfer(address(this).balance);
    }
}