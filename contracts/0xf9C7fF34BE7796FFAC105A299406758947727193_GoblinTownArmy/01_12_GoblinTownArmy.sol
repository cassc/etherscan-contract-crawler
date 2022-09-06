//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@##@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@*  %@@@  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@  @@@@    *@@@@@@@@@@@@@@  @@@@@@@@@@@@@  @@@@@@@@@@@@@@@@@@@@@@@@@@@@   [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@# %@@@@@@@@@   @@ /@@@@@@@@@@  @@@@@@@@@@@@  @@@@@@@@@@@@@ /@  /@@  @@@@@ @@@@@   @@@@@@@@ @@@@@@@@@@@@@@@@@@@@./@*         [email protected]@@@@@@@@@@@@@
//@@@@@@@@@@* @@@@@@@@@@@@  @@ @@@@@@@@@@@@ (@%   &@@@@@@  @@@,@@@@@@@ #@@@@%   @@@@@@ #@@@@         @@  @@@@@@@@@@@@@@@@. @/ @@@@@@@@@@@@  @@@@@@@@@@@@
//@@@@@@@@@@ /@@@@@@@@@@@@@      @  @@@    # @@@@@@@@@. @@ (@@@ @@@@@  @@@@@@@  @@@@@@  @@ &@@@@@@@@@  @ @@@@@@@  @@@@@@@/ @  @@@@@@@@@@@@@  @@@@@@@@@@@
//@@@@@@@@@@  @@@@@@@@@@@@    @@@@@@@@@@@@@   @@@@@@@@@@ @/ @@@& @@@/ @@@@@@@@  @@@@@@@   [email protected]@@@@@@@@@@@ & @@@@@@  (@@@@@@  @  &@@@@@@@@@@@@@( @@@@@@@@@@
//@@@@@@@@@@@  [email protected]@@@@.  ,@@@   @@@@@@@@@@@@   @@@@@@@@@  @@ [email protected]@@  @@@ @@@@@@@@  @@@@@@@@ # @@@@@@@@@@@@@   @@@@@   @@@@@  @@@  @@@@@@@@@@@@@@  @@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@%  @@@@@@@@@@@@@  %    ,@@  @@@  @@@@ @@@@ &@@@@@  (@@@@@@@@/   @@@@@@@@@@@* @  @@@* @ @@@@. @@@@# @@@@@@@@@@@@@@@  @@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@  @@@@@@@@@@@  @ ,@@@@@@@@@@@@ *@@@@@ @@@@@@@@@@@@@@@@@@@@@@  @ %@@@@@@@  @@@@, @@ @@  @@  @@@@@@ @@@@@@@@@@@@@@@  @@@@@@@@
//@@@@@@@@@@ %@@@@@@@@@@@@@@ *@  @@@@@@@  &@@( @@@@@@@@@@@@ %@@@@@@@@@@@@@@@@@@@@@@@@@@@@* @@@@   @@@@@@@@@@@@@@@@# @  @@@@@@@ @@@@@@@@@@@@@@@  @@@@@@@@
//@@@@@@@@@@@@      [email protected]@@@@@  @@@@       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  @@@@@@@@@@@@@@@@@@@@@@@@   @@@@@@@@@@@@@@@@@@@@@@@@  @@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@*   %@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//army
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721Optimized.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract GoblinTownArmy is ERC721Optimized, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public constant MAX_GTA = 10000;
    uint256 public maxGTAPurchase = 10;
    uint256 public GTAPrice = 0.0069 ether;
    string public _baseGTAURI;

    event GTAMinted(address indexed mintAddress, uint256 indexed tokenId);
    event PermanentURI(string _value, uint256 indexed _id);

    constructor(string memory baseURI)
        ERC721Optimized("GoblinTownArmy", "GTA")
    {
        _baseGTAURI = baseURI;
    }

    function giveAway(address to, uint256 numberOfTokens) public onlyOwner {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            createCollectible(to);
        }
    }

    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "Insufficient balance");
        Address.sendValue(payable(msg.sender), address(this).balance);
    }

    function withdrawTo(uint256 amount, address payable to) public onlyOwner {
        require(address(this).balance > 0, "Insufficient balance");
        Address.sendValue(to, amount);
    }

    function setBaseURI(string memory newuri) public onlyOwner {
        _baseGTAURI = newuri;
    }

    function setMintPrice(uint256 newPrice) public onlyOwner {
        require(newPrice >= 0, "GTA price must be greater than zero");
        GTAPrice = newPrice;
    }

    function mintGTA(uint256 numberOfTokens) public payable nonReentrant {
        require(
            (GTAPrice * numberOfTokens) <= msg.value,
            "Ether value sent is not correct"
        );
        require(
            numberOfTokens <= maxGTAPurchase,
            "You can mint max 10 GTA s per transaction"
        );
        require(
            (totalSupply() + numberOfTokens) <= MAX_GTA,
            "Purchase would exceed max supply of GTAs"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            createCollectible(_msgSender());
        }
    }

    function createCollectible(address mintAddress) private {
        uint256 mintIndex = totalSupply();
        if (mintIndex < MAX_GTA) {
            _safeMint(mintAddress, mintIndex);
            emit GTAMinted(mintAddress, mintIndex);
        }
    }

    function freezeMetadata(uint256 tokenId, string memory ipfsHash) public {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        require(
            _msgSender() == ERC721Optimized.ownerOf(tokenId),
            "Caller is not a token owner"
        );
        emit PermanentURI(ipfsHash, tokenId);
    }

    function _baseURI() internal view virtual returns (string memory) {
        return _baseGTAURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
                : "";
    }
}