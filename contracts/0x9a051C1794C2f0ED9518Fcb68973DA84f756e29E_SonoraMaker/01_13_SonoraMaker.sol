// SPDX-License-Identifier: VPL
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "erc721a/contracts/ERC721A.sol";

/**
 * @title Sonora Maker contract
 * @dev Simple implementation for a free mint based on ERC721A
 * */
contract SonoraMaker is ERC721A, Ownable {
    address public constant MILADY_MAKER = 0x5Af0D9827E0c53E4799BB226655A1de152A425a5;
    uint public constant MAX_SONORA = 444;
    string private _baseTokenURI;
    bool public saleIsActive = false;

    constructor(string memory baseURI) ERC721A("SonoraMaker", "SNRM") {
        _baseTokenURI = baseURI;
    }

    modifier callerIsUser() {
        require(
            tx.origin == msg.sender,
            "Are you who you say you are?"
        );
        _;
    }

    modifier supplyRemaining() {
        require(
            _totalMinted() < MAX_SONORA,
            "All Sonora's minted."
        );
        _;
    }

    modifier networkSpirit() {
        require(
            ERC721(MILADY_MAKER).balanceOf(msg.sender) >= 1,
            "You need more network spirit to mint a Sonora."
        );
        _;
    }

    modifier onlyOne() {
        require(
            balanceOf(msg.sender) < 1,
            "Save some Sonora for your fellow miladys."
        );
        _;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function mint() external
        callerIsUser
        supplyRemaining
        networkSpirit
        onlyOne
    {
        require(saleIsActive, "Sale must be active to mint Sonoras");
        _safeMint(msg.sender, 1);
    }

    function reserveMint(uint256 quantity) external
        onlyOwner
        callerIsUser
        supplyRemaining
    {
        require(
            quantity + _totalMinted() <= MAX_SONORA,
            "Sorry, but there can only be 444 Sonoras"
        );
        _safeMint(msg.sender, quantity);
    }

    function setBaseURI(string calldata baseURI) external
        onlyOwner
    {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
}