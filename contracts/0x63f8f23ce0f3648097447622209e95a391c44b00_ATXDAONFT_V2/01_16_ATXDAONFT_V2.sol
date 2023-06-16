/*
  /$$$$$$  /$$$$$$$$ /$$   /$$ /$$$$$$$   /$$$$$$   /$$$$$$
 /$$__  $$|__  $$__/| $$  / $$| $$__  $$ /$$__  $$ /$$__  $$
| $$  \ $$   | $$   |  $$/ $$/| $$  \ $$| $$  \ $$| $$  \ $$
| $$$$$$$$   | $$    \  $$$$/ | $$  | $$| $$$$$$$$| $$  | $$
| $$__  $$   | $$     >$$  $$ | $$  | $$| $$__  $$| $$  | $$
| $$  | $$   | $$    /$$/\  $$| $$  | $$| $$  | $$| $$  | $$
| $$  | $$   | $$   | $$  \ $$| $$$$$$$/| $$  | $$|  $$$$$$/
|__/  |__/   |__/   |__/  |__/|_______/ |__/  |__/ \______/
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {Strings} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract ATXDAONFT_V2 is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    using MerkleProof for bytes32[];
    using Strings for uint256;

    bool public isMintable = false;
    uint256 public _mintPrice = 630000000000000000; // 0.63 ether

    Counters.Counter private _mintCount;
    Counters.Counter private _tokenIds;

    bytes32 merkleRoot;
    string private baseURI;
    string public baseExtension = ".json";

    mapping(address => bool) public hasMinted;

    constructor() ERC721("ATX DAO", "ATX") {}

    function setMerkleRoot(bytes32 root) public onlyOwner {
        merkleRoot = root;
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    // Normal mint
    function mint(bytes32[] memory proof) external payable {
        require(
            proof.verify(merkleRoot, keccak256(abi.encodePacked(msg.sender))),
            "Not on the list!"
        );
        require(
            isMintable == true,
            "ATX DAO NFT is not mintable at the moment!"
        );
        require(
            !hasMinted[msg.sender],
            "Minting is only available for non-holders"
        );
        require(msg.value >= _mintPrice, "Not enough ether sent to mint!");
        require(!isContract(msg.sender), "No contracts!");

        // Mint
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        hasMinted[msg.sender] = true;
        _safeMint(msg.sender, newTokenId);
        _setTokenURI(
            newTokenId,
            string(
                abi.encodePacked(baseURI, newTokenId.toString(), baseExtension)
            )
        );

        _mintCount.increment();
    }

    function resetHasMinted(address[] memory recipients) external onlyOwner {
        for (uint64 i = 0; i < recipients.length; i++) {
            hasMinted[recipients[i]] = false;
        }
    }

    // Dev mint
    function mintSpecial(
        address[] memory recipients,
        string memory tokenURI,
        bool _dynamic
    ) external onlyOwner {
        for (uint64 i = 0; i < recipients.length; i++) {
            _tokenIds.increment();
            uint256 newTokenId = _tokenIds.current();
            hasMinted[recipients[i]] = true;

            _safeMint(recipients[i], newTokenId);
            _dynamic
                ? _setTokenURI(
                    newTokenId,
                    string(
                        abi.encodePacked(
                            tokenURI,
                            newTokenId.toString(),
                            baseExtension
                        )
                    )
                )
                : _setTokenURI(newTokenId, tokenURI);
        }
    }

    function startMint(
        uint256 mintPrice,
        string memory tokenURI,
        bytes32 _root
    ) public onlyOwner {
        isMintable = true;
        _mintPrice = mintPrice;
        baseURI = tokenURI;
        setMerkleRoot(_root);
        _mintCount.reset();
    }

    function endMint() public onlyOwner {
        isMintable = false;
    }

    function sweepEth() public onlyOwner {
        uint256 _balance = address(this).balance;
        payable(owner()).transfer(_balance);
    }
}