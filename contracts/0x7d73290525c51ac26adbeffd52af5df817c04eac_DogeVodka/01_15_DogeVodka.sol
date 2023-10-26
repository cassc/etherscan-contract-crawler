// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract DogeVodka is ERC721A, Ownable, AccessControl {
    using MerkleProof for bytes32[];
    using Strings for uint256;

    string private baseURI;
    string private redeemedBaseURI;
    bytes32 private preWhitelistCode;

    mapping(uint256 => bool) public redeemedToken;

    bytes32 public constant REDEEMER_ROLE = keccak256("REEDEMER_ROLE");

    constructor() ERC721A("SpiritPunks Rocket Pass", "ROCKETPASS") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    bool public saleStarted = false;
    bool public preWhitelist = true;
    bool public publicSaleStarted = false;
    bool public redeemStarted = false;
    uint256 public constant vodkaPrice = 0.1 ether;
    uint256 public constant maxVodkas = 2013;
    uint8 public constant maxVodkasPurchase = 5;

    bytes32 public merkleRoot;

    event Redeemed(uint256[] _tokenIds);

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setRedeemedBaseURI(string memory _redeemedBaseURI) public onlyOwner {
        redeemedBaseURI = _redeemedBaseURI;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function mint(
        bytes32[] memory proof,
        bytes32 leaf,
        uint16 numberOfTokens
    ) public payable {
        require(saleStarted == true, "The sale is paused");
        if (publicSaleStarted == false && preWhitelist == false) {
            require(keccak256(abi.encodePacked(msg.sender)) == leaf, "This leaf does not belong to the sender");
            require(proof.verify(merkleRoot, leaf), "You are not in the list");
        } else if (preWhitelist == true) {
            require(leaf == preWhitelistCode, "The pre-whitelist code is not correct");
        }

        require(numberOfTokens <= maxVodkasPurchase, "Can only mint 5 tokens at a time");
        require(totalSupply() + numberOfTokens <= maxVodkas, "Purchase would exceed max supply of Doge Vodkas");
        require(vodkaPrice * numberOfTokens == msg.value, "Ether value sent is not correct");

        _safeMint(msg.sender, numberOfTokens);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        if (redeemedToken[tokenId] == true) return string(abi.encodePacked(redeemedBaseURI, tokenId.toString()));
        else return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    function redeem(uint256[] memory tokenIds) public onlyRole(REDEEMER_ROLE) {
        require(redeemStarted == true, "The redeem is paused");

        for (uint256 i = 0; i < tokenIds.length; i++) redeemedToken[tokenIds[i]] = true;

        emit Redeemed(tokenIds);
    }

    function startSale() public onlyOwner {
        saleStarted = true;
    }

    function pauseSale() public onlyOwner {
        saleStarted = false;
    }

    function togglePublicSale() public onlyOwner {
        publicSaleStarted = !publicSaleStarted;
    }

    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance), "Error withdrawing funds");
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721A) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function setPreWhitelistCode(bytes32 _preWhitelistCode) public onlyOwner {
        preWhitelistCode = _preWhitelistCode;
    }

    function startWhitelist() public onlyOwner {
        preWhitelist = false;
    }

    function startRedeem() public onlyOwner {
        redeemStarted = true;
    }

    function pauseRedeem() public onlyOwner {
        redeemStarted = false;
    }
}