// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

//  =============================================
//   _   _  _  _  _  ___  ___  ___  ___ _    ___
//  | \_/ || || \| ||_ _|| __|| __|| o ) |  | __|
//  | \_/ || || \\ | | | | _| | _| | o \ |_ | _|
//  |_| |_||_||_|\_| |_| |___||___||___/___||___|
//
//  Website: https://minteeble.com
//  Email: [email protected]
//
//  =============================================

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract MinteeblePartialERC721 is Ownable {
    uint256 public maxSupply;
    uint256 public mintPrice;

    string public baseUri = "";
    string public uriSuffix = ".json";
    string public preRevealUri = "";
    bool public revealed = false;
    bool public paused = true;

    uint256 public maxMintAmountPerTrx = 5;
    uint256 public maxMintAmountPerAddress = 20;
    mapping(address => uint256) public totalMintedByAddress;

    /**
     *  @dev Checks if caller provided enough funds for minting
     */
    modifier enoughFunds(uint256 _mintAmount) {
        require(msg.value >= _mintAmount * mintPrice, "Insufficient funds!");
        _;
    }

    modifier active() {
        require(!paused, "Contract is paused.");
        _;
    }

    /**
     *  @notice Sets new base URI
     *  @param _baseUri New base URI to be set
     */
    function setBaseUri(string memory _baseUri) public onlyOwner {
        baseUri = _baseUri;
    }

    /**
     *  @notice Sets new URI suffix
     *  @param _uriSuffix New URI suffix to be set
     */
    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    /**
     *  @notice Reveals (or unreveals) the collection
     *  @param _revealed New revealed value to be set. True if revealed, false otherwise
     */
    function setRevealed(bool _revealed) public onlyOwner {
        revealed = _revealed;
    }

    /**
     * @notice Change paused state
     * @param _paused Paused state
     */
    function setPaused(bool _paused) public onlyOwner {
        paused = _paused;
    }

    /**
     *  @notice Sets new pre-reveal URI
     *  @param _preRevealUri New pre-reveal URI to be used
     */
    function setPreRevealUri(string memory _preRevealUri) public onlyOwner {
        preRevealUri = _preRevealUri;
    }

    /**
     *  @notice Allows owner to set a new mint price
     *  @param _mintPrice New mint price to be set
     */
    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    /**
     *  @notice Allows owner to set the max number of mintable items in a single transaction
     *  @param _maxAmount Max amount
     */
    function setMaxMintAmountPerTrx(uint256 _maxAmount) public onlyOwner {
        maxMintAmountPerTrx = _maxAmount;
    }

    /**
     *  @notice Allows owner to set the max number of items mintable per wallet
     *  @param _maxAmount Max amount
     */
    function setMaxMintAmountPerAddress(uint256 _maxAmount) public onlyOwner {
        maxMintAmountPerAddress = _maxAmount;
    }

    /**
     *  @notice Withdraws contract balance to onwer account
     */
    function withdrawBalance() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success);
    }
}