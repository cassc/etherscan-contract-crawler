// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";

pragma solidity ^0.8.0;

contract Mushy is ERC721A, Ownable, ReentrancyGuard {
    // declares the maximum amount of tokens that can be minted
    uint256 public constant MAX_TOTAL_TOKENS = 5555;

    // max number of mints per transaction
    uint256 public allowlist_mint_max_per_tx = 3;
    uint256 public pub_mint_max_per_tx = 3;

    // price of mints depending on state of sale
    uint256 public item_price_al = 0.08 ether;
    uint256 public item_price_public = 0.08 ether;

    // merkle root for allowlist
    bytes32 public root;

    // metadata
    string private baseURI = "";
    string private unrevealedURI = "ipfs://QmbTe5jr8jJoTHtMVLH6dYmaHD7iGm2HdUNV3dRT5Fjeo8";

    // status
    bool public is_allowlist_active;
    bool public is_public_mint_active;
    bool public is_revealed;

    // reserved mints for the team
    mapping (address => uint256) reserved_mints;
    uint256 public total_reserved = 675;

    using Strings for uint256;

    constructor (bytes32 _root) ERC721A("Mushy NFT", "Mushy") {
        root = _root;

        // don't forget to update total_reserved
        reserved_mints[0x4Ac2bD3b9Af192456A416de78E9E124d4FA6c399] = 120;
        reserved_mints[0x10b5B489E9b4d220Ab6e4a0E7276c54D5bf837cD] = 555;
    }

    function internalMint(uint256 _amt) external nonReentrant {
        uint256 amt_reserved = reserved_mints[msg.sender];

        require(totalSupply() + _amt <= MAX_TOTAL_TOKENS, "Not enough NFTs left to mint");
        require(amt_reserved >= _amt, "Invalid reservation amount");
        require(amt_reserved <= total_reserved, "Amount exceeds total reserved");

        reserved_mints[msg.sender] -= _amt;
        total_reserved -= _amt;

        _safeMint(msg.sender, _amt);
    }

    function allowlistMint(bytes32[] calldata _proof, uint256 _amt) external payable nonReentrant {
        require(totalSupply() + _amt <= MAX_TOTAL_TOKENS - total_reserved, "Not enough NFTs left to mint");
        require(msg.sender == tx.origin, "Minting from contract not allowed");
        require(item_price_al * _amt == msg.value,  "Not sufficient ETH to mint this number of NFTs");
        require(is_allowlist_active, "Allowlist mint not active");

        uint64 new_claim_total = _getAux(msg.sender) + uint64(_amt);
        require(new_claim_total <= allowlist_mint_max_per_tx, "Requested mint amount invalid");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_proof, root, leaf), "Invalid proof");

        _setAux(msg.sender, new_claim_total);
        _safeMint(msg.sender, _amt);
    }

    function publicMint(uint256 _amt) external payable nonReentrant {
        require(totalSupply() + _amt <= MAX_TOTAL_TOKENS - total_reserved, "Not enough NFTs left to mint");
        require(msg.sender == tx.origin, "Minting from contract not allowed");
        require(item_price_public * _amt == msg.value, "Not sufficient ETH to mint this number of NFTs");
        require(is_public_mint_active, "Public mint not active");
        require(_amt <= pub_mint_max_per_tx, "Too many NFTs in single transaction");

        _safeMint(msg.sender, _amt);
    }

    function setAllowlistMintActive(bool _val) external onlyOwner {
        is_allowlist_active = _val;
    }

    function setPublicMintActive(bool _val) external onlyOwner {
        is_public_mint_active = _val;
    }

    function setIsRevealed(bool _val) external onlyOwner {
        is_revealed = _val;
    }

    function setNewRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    function setAllowlistMintAmount(uint256 _amt) external onlyOwner {
        allowlist_mint_max_per_tx = _amt;
    }

    function setItemPricePublic(uint256 _price) external onlyOwner {
        item_price_public = _price;
    }

    function setItemPriceAL(uint256 _price) external onlyOwner {
        item_price_al = _price;
    }

    function setMaxMintPerTx(uint256 _amt) external onlyOwner {
        pub_mint_max_per_tx = _amt;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function setUnrevealedURI(string memory _uri) external onlyOwner {
        unrevealedURI = _uri;
    }

    function isOnAllowList(bytes32[] calldata _proof, address _user) public view returns (uint256) {
        bytes32 leaf = keccak256(abi.encodePacked(_user));
        return MerkleProof.verify(_proof, root, leaf) ? 1 : 0;
    }

    function getSaleStatus() public view returns (string memory) {
        if(is_public_mint_active) {
            return "public";
        }
        else if(is_allowlist_active) {
            return "allowlist";
        }
        else {
            return "closed";
        }
    }

    function tokenURI(uint256 _tokenID) public view virtual override returns (string memory) {
        require(_exists(_tokenID), "ERC721Metadata: URI query for nonexistent token");

        if(is_revealed) {
            return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenID.toString(), ".json")) : "";
        }
        else {
            return unrevealedURI;
        }
    }

    function withdrawEth() public onlyOwner nonReentrant {
        uint256 total = address(this).balance;

        require(payable(0x452A89F1316798fDdC9D03f9af38b0586F8142e5).send((total * 5) / 100));
        require(payable(0x10b5B489E9b4d220Ab6e4a0E7276c54D5bf837cD).send((total * 15) / 100));
        require(payable(0x41e1c9116667Fcc9dd640287796fB5eBDB1DB70E).send((total * 20) / 100));
        require(payable(0x5C2ce2d9eFAA4361aB129f77Bdad019A9a1b1cbe).send((total * 20) / 100));
        require(payable(0x6D9d741BC5Bca227070C43a23977E2FDE6B971e9).send((total * 20) / 100));
        require(payable(0x94Eb23cC87c4826DF76158151e0C3e94c18f02bB).send((total * 20) / 100));
    }

    receive() payable external {
        revert("Contract does not allow receipt of ETH or ERC-20 tokens");
    }

    fallback() payable external {
        revert("An incorrect function was called");
    }
}