// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title Alltherest
 */
contract Alltherest is ERC721, Ownable {
    using Counters for Counters.Counter;
    bool public whitelist_active = false;
    bool public mint_active = false;
    Counters.Counter private _tokenIdCounter;
    uint256 public HARD_CAP = 1000;
    bytes32 public MERKLE_ROOT;
    bool public is_collection_locked = false;
    string public contract_base_uri;
    mapping(uint256 => string) public selfie;
    mapping(address => uint256) public minted;

    constructor(
        string memory _name,
        string memory _ticker
    ) ERC721(_name, _ticker) {}

    function _baseURI() internal view override returns (string memory) {
        return contract_base_uri;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        string memory _tknId = Strings.toString(_tokenId);
        return string(abi.encodePacked(contract_base_uri, _tknId, ".json"));
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory ownerTokens)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalTkns = totalSupply();
            uint256 resultIndex = 0;
            uint256 tnkId;

            for (tnkId = 1; tnkId <= totalTkns; tnkId++) {
                if (ownerOf(tnkId) == _owner) {
                    result[resultIndex] = tnkId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    function fixBaseURI(string memory _newURI) public onlyOwner {
        require(!is_collection_locked, "Collection locked");
        contract_base_uri = _newURI;
    }

    /*
        This method will allow owner lock the collection
    */
    function lockCollection() public onlyOwner {
        is_collection_locked = true;
    }

    /*
        This method will allow owner to change states
    */
    function fixStates(uint8 what, bool newState) external onlyOwner {
        if (what == 1) {
            mint_active = newState;
        } else if (what == 2) {
            whitelist_active = newState;
        }
    }

    /*
        This method will allow owner to set the merkle root
    */
    function fixMerkleRoot(bytes32 root) external onlyOwner {
        MERKLE_ROOT = root;
    }

    /*
        This method will return the whitelisting state for a proof
    */
    function isWhitelisted(bytes32[] calldata _merkleProof, address _address)
        public
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        bool whitelisted = MerkleProof.verify(_merkleProof, MERKLE_ROOT, leaf);
        return whitelisted;
    }

    /*
        This method will allow users to mint the nft
    */
    function mintNFT(bytes32[] calldata _merkleProof, string memory _selfie)
        public
    {
        bool canMint = mint_active;
        if (mint_active && whitelist_active) {
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            canMint = MerkleProof.verify(_merkleProof, MERKLE_ROOT, leaf);
        }
        require(
            totalSupply() < HARD_CAP &&
                minted[msg.sender] == 0 &&
                canMint,
            "Can't mint"
        );
        _tokenIdCounter.increment();
        uint256 nextId = _tokenIdCounter.current();
        _mint(msg.sender, nextId);
        selfie[nextId] = _selfie;
        minted[msg.sender] = nextId;
    }
}