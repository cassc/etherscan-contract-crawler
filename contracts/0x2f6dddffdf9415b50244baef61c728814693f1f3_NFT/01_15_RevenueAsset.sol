// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// OpenZeppelin's ERC721 implementation (it's a standard, so let it be)
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// IMXMethods.sol is an abstracted implementation of IMX-required interfaces (IMintable as well as Ownable)
import "./IMXMethods.sol";

// Make sure the contract is ERC721 compatible!
contract NFT is ERC721, IMXMethods {
    // Optional - used for L1-level late reveals, a static string can be used instead (check below)
    string public baseTokenURI;
    // blueprints storage, if you're not storing on-chain metadata comment this line
    mapping(uint256 => bytes) public metadata;

    // constructor which gets called on contract's deployment
    constructor(
        // name of your Token (eg. "BoredApeYachtClub")
        string memory _name,
        // symbol of your Token (reg. "BAYC")
        string memory _symbol,
        // IMX's Smart Contract address that gets passed to IMXMethods.sol for whitelisting purposes
        address _imx
    ) ERC721(_name, _symbol) IMXMethods(_imx) {}


    // this function receives the (already parsed) version of the blueprint from IMX.sol
    function _mintFor(
        // address of the receiving wallet (has to be IMX registered!)
        address user,
        // id of the Token that has to be mint
        uint256 id,
        // PARSED! blueprint without the {tokenId} prefix
        bytes memory blueprint
    ) internal override {
        // ERC721 defined mint function - required in order for the token to be created
        _safeMint(user, id);
        // you may store the blueprint (on-chain metadata) here or implement some logic that relies on the blueprint data passed
        // below is a bare-minimum implementation of a simple mapping, comment it out if you are not storing on-chain metadata
        metadata[id] = blueprint;
    }

    // overwrite OpenZeppelin's _baseURI to define the base for tokenURI
    // can be a static value, use a variable if you want the ability to change this (L1 late-reveal)
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    // optional - change the baseTokenURI for late-reveal purposes
    function setBaseTokenURI(string memory uri) public onlyOwner {
        baseTokenURI = uri;
    }
}