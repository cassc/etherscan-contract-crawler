// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {ERC721Enumerable, ERC721} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title Basic Enumerable ERC721 Contract
 * @author Ben Yu
 * @notice An ERC721Enumerable contract with basic functionality
 */
contract EnumerableERC721 is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private supplyCounter;

    uint256 public constant PRICE = 0.01 ether;
    uint256 public constant MAX_SUPPLY = 1000;

    string public baseTokenURI =
        "ipfs://bafybeih5lgrstt7kredzhpcvmft2qefue5pl3ykrdktadw5w62zd7cbkja/";
    bool public publicSaleActive;

    /**
     * @notice Initialize the contract
     */
    constructor() ERC721("Test Contract", "TEST") {
        // Start token IDs at 1
        supplyCounter.increment();
    }

    /**
     * @notice Override the default base URI function to provide a real base URI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * @notice Update the base token URI
     * @param _newBaseURI New base URI
     */
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseTokenURI = _newBaseURI;
    }

    /**
     * @notice Allows for public minting of tokens
     * @param _mintNumber Number of tokens to mint
     */
    function publicMint(uint256 _mintNumber) external payable virtual {
        require(msg.value == PRICE * _mintNumber, "INVALID_PRICE");
        require((totalSupply() + _mintNumber) <= MAX_SUPPLY, "MINT_TOO_LARGE");

        for (uint256 i = 0; i < _mintNumber; i++) {
            _safeMint(msg.sender, supplyCounter.current());
            supplyCounter.increment();
        }
    }

    /**
     * @notice Allow owner to send `mintNumber` tokens without cost to multiple addresses
     * @param _receivers Array of addresses to send tokens to
     * @param _mintNumber Number of tokens to send to each address
     */
    function gift(
        address[] calldata _receivers,
        uint256 _mintNumber
    ) external onlyOwner {
        require(
            (totalSupply() + (_receivers.length * _mintNumber)) <= MAX_SUPPLY,
            "MINT_TOO_LARGE"
        );

        for (uint256 i = 0; i < _receivers.length; i++) {
            for (uint256 j = 0; j < _mintNumber; j++) {
                _safeMint(_receivers[i], supplyCounter.current());
                supplyCounter.increment();
            }
        }
    }

    /**
     * @notice Allow contract owner to withdraw funds
     */
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}