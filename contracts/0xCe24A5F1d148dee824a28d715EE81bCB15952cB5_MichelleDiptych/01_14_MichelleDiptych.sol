// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

/// @title Michelle Diptych mint contract.
/// @author https://michellediptych.com
/// @notice The only morality in a cruel world is chance. - Harvey Dent
contract MichelleDiptych is ERC721, ERC721Enumerable, Ownable {

    /// @notice The maximum number of Michelle Diptychs available for minting.
    uint256 public constant MAX = 10000;

    /// @notice The maximum number of Michelle Diptychs that can be purchased per transaction.
    uint256 public constant MAX_PER_PURCHASE = 10;

    constructor() ERC721("MichelleDiptych", "MDIP") {}

    /// @notice Enter your wallet address to see which Michelle Diptych you own.
    /// @param _owner The wallet address of a Michelle Diptych token owner.
    /// @return An array of tokenIds of each Michelle Diptych owned by the address.
    function tokensOfOwner(address _owner) external view returns(uint256[] memory) {
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

    /// @notice Mint a Michelle Diptych.
    /// @param _count How many Michelle Diptychs you would like to mint.
    function mint(uint256 _count) public payable {
        uint256 totalSupply = totalSupply();
        require(_count > 0 && _count < MAX_PER_PURCHASE + 1, "Max 10 per transaction");
        require(totalSupply + _count < MAX + 1, "None left");

        // Determine the price based on the current total supply
        uint256 effectivePrice = totalSupply < 1000 ? 0 : 25000000000000000; // 0.025 Ether
        require(msg.value >= effectivePrice * _count, "Not enough ETH");

        for (uint256 i = 0; i < _count; i++) {
            _safeMint(msg.sender, totalSupply + i);
        }
    }

    /// @notice The Michelle Diptych contract owner can withdraw the ETH from the contract.
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    /// @notice Get the price of an Michelle Diptych.
    /// @return The price of a Michelle Diptych expressed in Wei.
    function getPrice() public view returns (uint256) {
        uint256 totalSupply = totalSupply();
        return totalSupply < 1000 ? 0 : 25000000000000000; // 0.025 Ether
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
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    /// @notice The IPFS request path where the Michelle Diptych images are found.
    /// @return An IPFS request path to which the Michelle Diptych tokenId can be affixed.
    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmNhpUae2qH2p2s4r2dfWXSXTdArye5CNU5EpsrLwYXyuQ/";
    }

}