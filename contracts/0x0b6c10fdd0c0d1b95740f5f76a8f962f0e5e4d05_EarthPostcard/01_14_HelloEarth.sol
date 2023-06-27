// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// @custom:security-contact [email protected]
contract EarthPostcard is ERC721, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter public tokenIdCounter;
    
    struct MintInfo {
        bool didMint;
        uint tokenId;
    }

    bool public isTesting;
    string public baseURI = "ipfs://QmUDkzstkLHNxTL7dxmoGaRZaW4MW2XBJQth8b3mMt8N7n";
    string public _contractURI = "ipfs://QmW5CdEp1qvwo7iojsjPQKPj8qY1JPoGnHbwHkvbWLNoAK";
    bytes32 public merkleroot;
    uint256 constant public TOTALCOUNT = 500; 
    mapping(address => MintInfo) public tokenPerWallet;



    constructor(bytes32 root, bool _isTesting) ERC721(".earth postcard", "EARTH-POSTCARD") {
        merkleroot = root;
        isTesting = _isTesting;
    }

    function isWhitelisted(address to) public view returns (bool) {
        if(isTesting) return true;
        if(
            IERC721(0xc92cedDfb8dd984A89fb494c376f9A48b999aAFc).balanceOf(to) > 0 || //creature world
            IERC721(0x8a90CAb2b38dba80c64b7734e58Ee1dB38B8992e).balanceOf(to) > 0 || // doodles
            IERC721(0xC2C747E0F7004F9E8817Db2ca4997657a7746928).balanceOf(to) > 0 || // hashmasks
            IERC721(0x7AB2352b1D2e185560494D5e577F9D3c238b78C5).balanceOf(to) > 0 || // adam bomb squad
            IERC721(0x60E4d786628Fea6478F785A6d7e704777c86a7c6).balanceOf(to) > 0 || // MAYC
            IERC721(0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D).balanceOf(to) > 0 || // BAYC
            IERC721(0x8584e7A1817C795f74Ce985a1d13b962758FE3CA).balanceOf(to) > 0 || // BLAZED Cats
            IERC721(0x7EA3Cca10668B8346aeC0bf1844A49e995527c8B).balanceOf(to) > 0 || // Cyberkongz VX
            IERC721(0x57a204AA1042f6E66DD7730813f4024114d74f37).balanceOf(to) > 0 || // Cyberkongz
            IERC721(0xED5AF388653567Af2F388E6224dC7C4b3241C544).balanceOf(to) > 0 || // AZUKI
            IERC721(0x1A92f7381B9F03921564a437210bB9396471050C).balanceOf(to) > 0 || // Cool Cats
            IERC721(0xe785E82358879F061BC3dcAC6f0444462D4b5330).balanceOf(to) > 0 || // World of women
            IERC721(0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB).balanceOf(to) > 0  // CryptoPunks
        ) {
            return true;
        }
        return false;
    }

    function isValidProof(bytes32[] calldata _proof, address to) view public returns(bool) {
        bytes32 leaf = computeLeaf(to);
        return MerkleProof.verify(_proof, merkleroot, leaf);
    }

    function computeLeaf(address to) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(to));
    }

    function mint(address to, bytes32[] calldata _proof) public {
        require((isWhitelisted(to) || isValidProof(_proof, to)), "You are not whitelisted");
        require(tokenPerWallet[to].didMint == false || isTesting, "Token for that address already minted");
        uint256 tokenId = tokenIdCounter.current();
        require(tokenId < TOTALCOUNT, "Fully minted");
        tokenIdCounter.increment();
        tokenPerWallet[to].didMint = true;
        tokenPerWallet[to].tokenId = tokenId;
        _mint(to, tokenId);
    }

    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _baseURI();
    }

    function setContractURI(string memory _newURI) public onlyOwner {
        _contractURI = _newURI;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
}