// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

/// @title Evooles mint contract.
/// @author 67ac2b3e1a1f71cdf69d11eb2baf93ad284264f20087ffc2866cfce01204fe91
/// @notice Evooles are malevolent ERC721 tokens from a distant, mysterious world.
contract Evooles is ERC721, ERC721Enumerable, Ownable, Pausable {
    using SafeMath for uint256;

    /// @notice The maximum number of Evooles available for minting.
    uint256 public constant MAX = 20000;

    /// @notice The maximum number of Evooles that can be purchased per transaction.
    uint256 public constant MAX_PER_PURCHASE = 10;

    /// @notice The cost of one Evoole.
    uint256 private price = 35000000000000000; // 0.035 Ether

    constructor() ERC721("Evooles", "EVOOLES") {}

    /// @notice Enter your wallet address to see which Evooles you own.
    /// @param _owner The wallet address of an Evooles token owner.
    /// @return An array of tokenIds of the Evooles owned by the address.
    function tokensByOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    /// @notice Mint an Evoole.
    /// @param _count How many Evooles you would like to mint.
    function mint(uint256 _count) public payable {
        uint256 totalSupply = totalSupply();
        require(_count > 0 && _count < MAX_PER_PURCHASE + 1, "Max 100 per transaction");
        require(totalSupply + _count < MAX + 1, "None left");
        require(msg.value >= price.mul(_count), "Not enough ETH");

        for(uint256 i = 0; i < _count; i++){
            _safeMint(msg.sender, totalSupply + i);
        }
    }

    /// @notice The Evooles contract owner can pause minting.
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice The Evooles contract owner can resume minting.
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @notice The Evooles contract owner can withdraw the ETH from the contract.
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    /// @notice The Evooles contract owner can change the price of an Evoole.
    /// @param _newPrice The new price to be set for an Evoole.
    function setPrice(uint256 _newPrice) public onlyOwner() {
        price = _newPrice;
    }

    /// @notice Get the price of an Evoole.
    /// @return The price of an Evoole expressed in Wei.
    function getPrice() public view returns (uint256) {
        return price;
    }

    /// @dev Required override for ERC721Enumerable.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @dev Required override for ERC721Enumerable.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /// @notice The IPFS request path where the Evooles images are found.
    /// @return An IPFS request path to which the Evooles tokenId can be affixed.
    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://bafybeihwcugv3i6kat4zaia4p6jmucen3zcwp6xx6uoxway7t42f76pxti/";
    }

}