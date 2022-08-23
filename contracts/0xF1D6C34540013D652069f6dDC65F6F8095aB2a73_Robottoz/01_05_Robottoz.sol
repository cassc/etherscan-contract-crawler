// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 ____  _____  ____  _____  ____  ____  _____  ____ 
(  _ \(  _  )(  _ \(  _  )(_  _)(_  _)(  _  )(_   )
 )   / )(_)(  ) _ < )(_)(   )(    )(   )(_)(  / /_ 
(_)\_)(_____)(____/(_____) (__)  (__) (_____)(____)
*/

/// @title Smart Contract for the Robottoz project by MetaBlub
/// @author https://github.com/dr-noid
contract Robottoz is ERC721A, Ownable {
    uint256 public constant price = 0.02 ether;
    uint256 public constant walletMax = 5;
    uint256 public constant maxRobots = 4444;
    string public baseUri;
    bool public open = false;
    bool public freeSale = true;
    uint256 public freeMax = 500;

    constructor() ERC721A("Robottoz", "RBTZ") {}

    modifier mintCompliance() {
        require(open, "Minting has not started yet");
        require(_totalMinted() + 2 <= maxRobots, "Max robots reached");
        if (_totalMinted() >= freeMax) {
            freeSale = false;
        }
        _;
    }

    /// @notice Mint a new Robottoz, depending on the sale phase of the project,
    /// @notice you will either be able to mint a free token or get one extra token.
    function mintRobottoz() external payable mintCompliance {
        uint256 userMinted = _numberMinted(msg.sender);

        // Free mint
        if (freeSale && userMinted == 0) {
            _safeMint(msg.sender, 1);
            return;
        }

        require(userMinted + 2 <= walletMax, "You have already minted max");
        require(msg.value >= price, "Free sale has ended");
        _safeMint(msg.sender, 2);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    /// @notice Change the baseURI of the tokens
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseUri = _newBaseURI;
    }

    /// @notice Open or close minting
    function setOpen(bool _value) external onlyOwner {
        open = _value;
    }

    /// @notice devMint for collabs, community, treasury, etc
    function devMint(uint256 _quantity) external onlyOwner {
        require(_totalMinted() + _quantity <= maxRobots, "Max robots reached");
        _safeMint(msg.sender, _quantity);
        if (_totalMinted() >= freeMax) {
            freeSale = false;
        }
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    /// @notice ERC721A starts tokenIds from 0 by default, Robottoz starts with 1
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /// @notice adds ".json" to the tokenURI string
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json"))
                : "";
    }
}