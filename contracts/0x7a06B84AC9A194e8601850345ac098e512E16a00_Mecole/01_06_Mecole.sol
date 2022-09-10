// SPDX-License-Identifier: MIT

/// @title Mecole
/// @author The NFT Project

pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Mecole is ERC721A, Ownable, ReentrancyGuard {

    mapping(uint256 => uint256) public _idToEdition;
    mapping(uint256 => string) public _editionToTokenUri;
    mapping(uint256 => uint256) public _editionToMaxSupply;
    mapping(uint256 => uint256) public _editionToPrice;
    mapping(uint256 => bool) public _editionToActive;
    mapping(uint256 => uint256) public _editionToCount;

    modifier canMintEdition(uint256 requestedEdition) {
        require(requestedEdition > 0, "Can't be zero");
        require(_editionToActive[requestedEdition], "Sale not active");
        require(_editionToCount[requestedEdition] + 1 <= _editionToMaxSupply[requestedEdition], "Not enough supply");
        require(msg.value >= _editionToPrice[requestedEdition], "Incorrect price");
        _;
    }

    constructor() ERC721A("Mecole Hardman", "MC") {
        _editionToTokenUri[1] = "ipfs://bafybeihpmdl4t6e7bsmm7brae22ysqxe3ewh5c3fw5s6gunijfn46nfkhe/SeasonEdition.json";
        _editionToTokenUri[2] = "ipfs://bafybeiacze5b3eau7lqmnfoayyqglskoncg7bb2up35ri56whcys4qq57q/PlayoffsEdition.json";
        _editionToTokenUri[3] = "ipfs://bafybeih3o6fs3lzfrltussaqvjkhphab4izdro2a2xl2rmoxfidgokg4ba/ConferenceEdition.json";
        _editionToTokenUri[4] = "ipfs://bafybeiecj4w2mlq3h4galeykfrgstyazmbjgkbxpixm3vmdi6nwoprkdku/SuperBowlEdition.json";

        _editionToMaxSupply[1] = 250;
        _editionToMaxSupply[2] = 250;
        _editionToMaxSupply[3] = 10;
        _editionToMaxSupply[4] = 3;

        // 0.04 ~$79
        _editionToPrice[1] = 40000000000000000;
        // 0.07 ~129
        _editionToPrice[2] = 70000000000000000;
        // 0.30 ~499
        _editionToPrice[3] = 300000000000000000;
        // 6 ~10,000
        _editionToPrice[4] = 6000000000000000000;

        _editionToActive[1] = true;
        _editionToActive[2] = true;
        _editionToActive[3] = true;
        _editionToActive[4] = true;
    }

    function mintEdition(uint256 edition) external payable canMintEdition(edition) nonReentrant {
        _editionToCount[edition]++;
        _idToEdition[_nextTokenId()] = edition;
        _mint(_msgSender(), 1);
    }

    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(_exists(tokenId), "Nonexistent token");

        return string(abi.encodePacked(_editionToTokenUri[_idToEdition[tokenId]]));
    }

    // ------- Owner functions --------
    function setBaseURI(uint256 edition, string memory baseURI) external onlyOwner {
        _editionToTokenUri[edition] = baseURI;
    }

    function setEditionActive(uint256 edition, bool active) external onlyOwner {
        _editionToActive[edition] = active;
    }

    function setEditionPrice(uint256 edition, uint256 price) external onlyOwner {
        _editionToPrice[edition] = price;
    }

    function setEditionMaxSupply(uint256 edition, uint256 newSupply) external onlyOwner {
        require(newSupply > _editionToMaxSupply[edition], "Cannot destroy");
        _editionToMaxSupply[edition] = newSupply;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
    }

    function ownerMint(uint256 edition, address to) external onlyOwner {
        _editionToCount[edition]++;
        _idToEdition[_nextTokenId()] = edition;
        _mint(to, 1);
    }

    // ------- Overrides --------
    function _startTokenId() internal view override returns (uint256) {
        return 1;
    }
}