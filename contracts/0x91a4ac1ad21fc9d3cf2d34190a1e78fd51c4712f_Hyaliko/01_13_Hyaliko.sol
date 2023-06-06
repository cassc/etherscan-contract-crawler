// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721A.sol";
import {IHyalikoDescriptor} from "./interfaces/IHyalikoDescriptor.sol";

/*********************************
 * ░░░░░░░░░░███████████░░░░░░░░░░ *
 * ░░░░░░████░░░░░░░░░░░████░░░░░░ *
 * ░░░░██░░░░░░░░░░░░░░░░░░░██░░░░ *
 * ░░██░░░░░░░░░░░░░░░░░░░░░░░██░░ *
 * ░░██░░░░░████░░░░░████░░░░░██░░ *
 * ██░░░░░░██░░██░░░██░░██░░░░░░██ *
 * ██░░░░░░██░░██░░░██░░██░░░░░░██ *
 * ██░░░░░░░░░░░░░░░░░░░░░░░░░░░██ *
 * ░░██░░░░░░░░░░░░░░░░░░░░░░░██░░ *
 * ░░██░░░░░░░░░░░░░░░░░░░░░░░██░░ *
 * ░░░░██░░░░░░░░░░░░░░░░░░░██░░░░ *
 * ░░░░░░████░░░░░░░░░░░████░░░░░░ *
 * ░░░░░░░░░░███████████░░░░░░░░░░ *
 *********************************/

contract Hyaliko is ERC721A, Ownable {
    bool public publishedForAirdrop;
    bool public publishedForWhitelist;
    bool public published;

    struct HyalikoData {
        uint256 dna;
    }

    // Mapping from token ID to random seed.
    // Some of these struct values are empty.
    // We use a technique similar to the one ERC721A uses for ownership to minimize random seed writes.
    mapping(uint256 => HyalikoData) hyaliko;

    uint256 public constant TOKEN_LIMIT = 2000;
    bytes32 public immutable whitelistMerkleRoot;
    bytes32 public immutable airdropMerkleRoot;
    string public baseURI;

    uint256 public constant MAX_WHITELIST_MINT = 1;
    uint256 public constant MAX_MINT = 100;

    IHyalikoDescriptor public descriptor;

    constructor(
        bytes32 _airdropMerkleRoot,
        bytes32 _whitelistMerkleRoot,
        string memory baseURI_
    ) ERC721A("Hyaliko", "HLKO") {
        publishedForAirdrop = false;
        publishedForWhitelist = false;
        published = false;

        airdropMerkleRoot = _airdropMerkleRoot;
        whitelistMerkleRoot = _whitelistMerkleRoot;
        baseURI = baseURI_;
    }

    function publishForAirdrop() public onlyOwner {
        publishedForAirdrop = true;
    }

    function publishForWhitelist() public onlyOwner {
        publishedForWhitelist = true;
    }

    function publish() public onlyOwner {
        published = true;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function mintHyalikoZero() public onlyOwner {
        require(totalSupply() == 0);
        _mint(msg.sender, 1, "", false);
        HyalikoData memory hyalikoData;
        hyalikoData.dna = 1;
        hyaliko[0] = hyalikoData;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function setDescriptor(address _descriptor) public onlyOwner {
        descriptor = IHyalikoDescriptor(_descriptor);
    }

    // CAUTION: Never introduce any kind of batch processing for mint() or mintFromSale() since then people can
    // execute the same bug that appeared on sushi's bitDAO auction
    // There are some issues with merkle trees such as pre-image attacks or possibly duplicated leaves on
    // unbalanced trees, but here we protect against them by checking against msg.sender and only allowing each account to claim once
    // See https://github.com/miguelmota/merkletreejs#notes for more info
    mapping(address => bool) public claimedAirdrop;

    function mintFromAirdrop(uint16 quantity, bytes32[] calldata _merkleProof)
        public
    {
        require(publishedForAirdrop == true, "b:01");
        require(
            MerkleProof.verify(
                _merkleProof,
                airdropMerkleRoot,
                keccak256(
                    abi.encodePacked(
                        keccak256(abi.encodePacked(msg.sender)),
                        keccak256(abi.encodePacked(quantity))
                    )
                )
            ) == true,
            "b:09"
        );

        uint256 startingIndex = totalSupply();

        // reentrancy guard
        require(claimedAirdrop[msg.sender] == false, "b:08");
        claimedAirdrop[msg.sender] = true;
        _mint(msg.sender, quantity, "", false);

        // Store the DNA for just the initial token
        // The DNA for the rest of the tokens minted in this batch can be derived from this one random number
        HyalikoData memory hyalikoData;
        hyalikoData.dna = uint256(
            keccak256(
                abi.encodePacked(
                    startingIndex,
                    msg.sender,
                    block.difficulty,
                    block.timestamp
                )
            )
        );
        hyaliko[startingIndex] = hyalikoData;
    }

    // CAUTION: Never introduce any kind of batch processing for mint() or mintFromSale() since then people can
    // execute the same bug that appeared on sushi's bitDAO auction
    // There are some issues with merkle trees such as pre-image attacks or possibly duplicated leaves on
    // unbalanced trees, but here we protect against them by checking against msg.sender and only allowing each account to claim once
    // See https://github.com/miguelmota/merkletreejs#notes for more info
    mapping(address => bool) public claimedWhitelist;

    function mintFromWhitelist(bytes32[] calldata _merkleProof) public {
        require(publishedForWhitelist == true, "b:02");
        require(
            MerkleProof.verify(
                _merkleProof,
                whitelistMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ) == true,
            "b:09"
        );

        uint256 startingIndex = totalSupply();

        // reentrancy guard
        require(claimedWhitelist[msg.sender] == false, "b:08");
        claimedWhitelist[msg.sender] = true;
        _mint(msg.sender, MAX_WHITELIST_MINT, "", false);
        uint256 finalSupply = totalSupply();
        require(finalSupply <= TOKEN_LIMIT, "b:07");

        // Store the DNA for just the initial token
        // The DNA for the rest of the tokens minted in this batch can be derived from this one random number
        HyalikoData memory hyalikoData;
        hyalikoData.dna = uint256(
            keccak256(
                abi.encodePacked(
                    startingIndex,
                    msg.sender,
                    block.difficulty,
                    block.timestamp
                )
            )
        );
        hyaliko[startingIndex] = hyalikoData;
    }

    // CAUTION: Never introduce any kind of batch processing for mint() or mintFromSale() since then people can
    // execute the same bug that appeared on sushi's bitDAO auction
    // There are some issues with merkle trees such as pre-image attacks or possibly duplicated leaves on
    // unbalanced trees, but here we protect against them by checking against msg.sender and only allowing each account to claim once
    // See https://github.com/miguelmota/merkletreejs#notes for more info

    function mintFromSale(uint256 quantity) public payable {
        require(published == true, "b:03");
        require(quantity <= MAX_MINT, "b:06");
        uint256 cost;
        unchecked {
            cost = quantity * 0.02 ether;
        }
        require(msg.value == cost, "b:05");
        uint256 startingIndex = totalSupply();

        _mint(msg.sender, quantity, "", false);
        uint256 finalSupply = totalSupply();
        require(finalSupply <= TOKEN_LIMIT, "b:07");

        // Store the DNA for just the initial token
        // The DNA for the rest of the tokens minted in this batch can be derived from this one pseudorandom number
        HyalikoData memory hyalikoData;
        hyalikoData.dna = uint256(
            keccak256(
                abi.encodePacked(
                    startingIndex,
                    msg.sender,
                    block.difficulty,
                    block.timestamp
                )
            )
        );
        hyaliko[startingIndex] = hyalikoData;
    }

    function getDna(uint256 _tokenId) public view returns (uint256) {
        uint256 curr = _tokenId;

        unchecked {
            if (_startTokenId() <= curr && curr < _currentIndex) {
                HyalikoData memory hyalikoData = hyaliko[curr];
                // If the DNA for this token ID is set, return it.
                if (hyalikoData.dna != 0) {
                    return hyalikoData.dna;
                }
                // Invariant:
                // There will always be an ownership that has an address and is not burned
                // before an ownership that does not have an address and is not burned.
                // Hence, curr will not underflow.
                while (true) {
                    curr--;
                    hyalikoData = hyaliko[curr];
                    if (hyalikoData.dna != 0) {
                        // Once we arrive at the last DNA, hash it with n where n = _tokenId - curr
                        return
                            uint256(
                                keccak256(
                                    abi.encodePacked(
                                        hyalikoData.dna,
                                        _tokenId - curr
                                    )
                                )
                            );
                    }
                }
            }
        }
        revert OwnerQueryForNonexistentToken();
    }

    function tokenGltfDataOf(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        return descriptor.tokenGltfDataForDna(getDna(tokenId));
    }

    function getTraitsOf(uint256 tokenId)
        public
        view
        returns (bytes[6] memory)
    {
        return descriptor.getTraits(getDna(tokenId));
    }
}

/*               
errors:         
01: This can only be done after the project has been published for airdrop.
02: This can only be done after the project has been published for whitelist.
03: This can only be done after the project has been published.
04: Ineligible to mint.
05: Hyaliko cost 0.02 ETH each.
06: Mint quantity exceeds maximum allowed.
07: Sold out.
08: Already claimed.
09: Wrong merkle proof. Unlisted address or wrong quantity.
*/