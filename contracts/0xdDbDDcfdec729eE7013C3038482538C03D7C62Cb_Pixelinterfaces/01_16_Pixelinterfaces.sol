// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import {ERC721A} from "ERC721A.sol";
import {Ownable} from "Ownable.sol";
import {Strings} from "Strings.sol";
import {PaymentSplitter} from "PaymentSplitter.sol";
import {MerkleProof} from "MerkleProof.sol";


contract Pixelinterfaces is ERC721A, PaymentSplitter, Ownable {
    using Strings for uint256;

    uint256 public immutable maxSupply = 4004;
    uint256 public immutable earlyReserve = 500;
    uint256 public immutable maxTokensPerTx = 5;
    uint256 public immutable price = 0.022 ether;

    uint256 public claimed;

    uint32 public saleStartTime = 1650092400;

    bool public revealed;

    bytes32 public merkleRoot;

    string private _baseTokenURI;
    string private notRevealedUri;

    mapping(address => bool) private earlyReserveClaimed;

    event Minted(address _from, uint256 _remaining);

    constructor(
        string memory name_,
        string memory symbol_,
        string memory _initNotRevealedUri,
        uint256 maxBatchSize_,
        address[] memory payees_,
        uint256[] memory shares_
    ) ERC721A(name_, symbol_, maxBatchSize_) PaymentSplitter(payees_, shares_) {
        _safeMint(msg.sender, 1);
        setNotRevealedURI(_initNotRevealedUri);
    }

    function mint(uint256 quantity, bytes32[] memory proof)
        external
        payable
    {
        require(quantity != 0, "zero quantiy");
        require(block.timestamp >= saleStartTime,
            "sale has not started yet"
        );
        require(quantity <= maxTokensPerTx, "sale transaction limit exceeded");
        if (
            MerkleProof.verify(
                proof,
                merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            )
        ) {
            if (!earlyReserveClaimed[msg.sender]) {
                mintWhitelist(quantity);
            } else {
                mintStandard(quantity);
            }
        } else {
            mintStandard(quantity);
        }
    }

    function mintStandard(uint256 quantity) internal {
        require(totalSupply() + quantity <= currentMaxSupply(), "reached max supply");
        _safeMint(msg.sender, quantity);
        emit Minted(msg.sender, remainingSupply());
    }

    function mintWhitelist(uint256 quantity) internal {
        require(totalSupply() + quantity <= currentMaxSupply() + 1, "reached max supply");
        _safeMint(msg.sender, quantity);
        earlyReserveClaimed[msg.sender] = true;
        claimed++;
        emit Minted(msg.sender, remainingSupply());
    }

    function isClaimed(address user) public view returns(bool) {
        return earlyReserveClaimed[user];
    }

    function currentMaxSupply() public view returns(uint256) {
        return (maxSupply - earlyReserve + claimed);
    }

    function remainingSupply() public view returns(uint256) {
        uint256 remaining = ((maxSupply - earlyReserve) - (totalSupply() - claimed));
        return remaining;
    }

    function setPublicSaleStartTime(uint32 _timestamp) external onlyOwner {
        saleStartTime = _timestamp;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setOwnersExplicit(uint256 quantity)
        external
        onlyOwner
    {
        _setOwnersExplicit(quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnerOfToken(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (revealed == false) {
            return notRevealedUri;
        }
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }
}