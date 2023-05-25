// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.10;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/RAYC.sol";
import "./interfaces/Serum.sol";

import "hardhat/console.sol";

// @kntrvlr

contract ZAYC is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string public baseURI;
    uint256 private constant ZAYC_TOTAL = 10_000;
    uint256 private constant MZAYC_TOTAL = 10;

    address public raycAddress;
    address public serumAddress;

    uint256 public spawnStart = 1667779200;
    uint256 public coffinRevealStart = 1670198400;
    mapping(uint256 => bool) public spawned;
    mapping(uint => uint256) private ownerships;
    mapping(uint256 => bool) public coffinRevealed;

    uint256 private Z1_SERUM = 0;

    IRAYC private rayc;

    constructor(
        address _raycAddress,
        address _serumAddress
    ) ERC721("Zombie Apepes", "ZAYC")
    {
        raycAddress = _raycAddress;
        serumAddress = _serumAddress;
        rayc = IRAYC(_raycAddress);
    }

    function spawn(uint256[] calldata ids) public returns (uint256[] calldata) {
        require(block.timestamp > spawnStart, "Patience");
        require(ids.length <= 20, "20 or fewer per txn.");
        require(
            ids.length <= checkSerumBalance(msg.sender),
            "Not enough serums"
        );
        ISerum serum = ISerum(serumAddress);
        require(
            serum.isApprovedForAll(msg.sender, address(this)),
            "Must approve ZAYC contract to handle Serum."
        );

        serum.burn(msg.sender, ids.length);

        for (uint i = 0; i < ids.length; i++) {
            ownerships[i] = ids[i];
            require(
                rayc.ownerOf(ownerships[i]) == msg.sender,
                "Can't spawn it if you don't own it"
            );
            require(spawned[ids[i]] != true, "Already spawned");
            spawned[ids[i]] = true;
            _safeMint(msg.sender, ids[i]);
        }
        return ids;
    }

    function sendCoffin(address _address, uint256 tokenId) public onlyOwner {
        require(tokenId >= 10000 && tokenId <= 10009, "tokenId out of range");
        require(spawned[tokenId] != true, "Already sent");
        spawned[tokenId] = true;
        _safeMint(_address, tokenId);
    }

    function revealCoffin(uint256 tokenId) public {
        require(block.timestamp > coffinRevealStart, "The prophecy's time has not yet come.");
        require(msg.sender == ownerOf(tokenId), "Only owners of coffins may reveal them.");
        require(coffinRevealed[tokenId] != true, "What is done, is done.");
        coffinRevealed[tokenId] = true;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Does not exist");
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function checkSerumBalance(address _address)
        private
        view
        returns (uint256)
    {
        ISerum serum = ISerum(serumAddress);
        return serum.balanceOf(_address, Z1_SERUM);
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function setSpawnStart(uint256 _newStart) public onlyOwner {
        spawnStart = _newStart;
    }

    function setCoffinRevealStart(uint256 _newStart) public onlyOwner {
        coffinRevealStart = _newStart;
    }

    function withdraw() public payable onlyOwner {
        // =============================================================================
        (bool os, ) = payable(msg.sender).call{value: address(this).balance}(
            ""
        );
        require(os);
        // =============================================================================
    }
}