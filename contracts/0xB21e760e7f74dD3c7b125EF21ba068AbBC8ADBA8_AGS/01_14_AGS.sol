// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721A.sol";
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒░░░░░░▒▒▓▓▓▓▓▓▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▓▓█████▓▒░▓█████████████▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓█████████████████████████████▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓▓████████████████████████████████▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓████████████████▓████████████████████▓▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓██████████████████▓███████████████████████▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░▒▓█████████████████████████████████████████████▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░▓█████████████████████▓█████████████████████████▓░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░▒▓█████████████████▓▓▓▓▒▓▓▓▒▒▒▒▒▓█████████████████▓▒░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░▓███████████████▒▒█▒░▒░░░░░░░░░░██▒▓████████████████▒░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░▒▓███████████████▒░▓▓░░░░░░░░░░▒▓█▓▒▒██████████████████░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░▒▓▓██████████████████▓░░▓▒░░░░░░░░▓▓█▓░░███████████████████▒░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░▓█▓▓███████████████████░░▒▓░░░░░░░░░░░▓█▒▓██████████████████░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░▒█▓▓██████████████████▓▓░░░░░░░░░░░░░░░▓▓░░▒▓███████████████▓░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░██▓█████████████████▓▓▓▒▒▒▒░░░░░░░░▒▒▒▒▒▒▒▒▓███████████████▒░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░▒███████████████████▓▓▓▓▓▓▓▒▒░░░░░░░▒▒▓▓▓▓▓▓████████████████▓░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░███████████████████████████▓▒░▒░▒▓█████████████████████████▒░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░▓████████████████████████████▓▓▓███████████████████████████▓▒░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░▓███████████████████████████▒░░▒▓█████████████████████████████░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░▓███████████████▓▓██████████▒░░░▒▒█████████████████████████████▒░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░▓███████████████▒▒▒▒▓█████▓▓▒░░░░░░░▓███████▓▒▓█████████████████░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░▒████▓██████████▒▒░░▒░░░▒▒▒░░░░░░░░░░░░░▒▒▒▒░░▒░▒▓▒▓█████████████▒░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░▒████▓▒██████████▓░░▒░▒░░░░░░░░░░░░░░░░░░░░░░░░░▒▒░▒████████████▓░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░█████▒████████████▒▒▒░▓▒░░░░░░░░▒▒▒▒▒▒░░░░░░░▒▓░▒▒░▓███████████▓░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░█████▓███████████████▓██▒░░░░░▒▒▓▓▓▓▓▓▒░░░░░▒▓█▓███████████████▓░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░▒████▓██████████████████▒▒▒░░░░░▒▒▒▒▒▒░░░░░▒░▒██████████████████▓▒░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░▒▓███▓█████████████████▒░▒░░░░░░░░░░░░░░▒▒░░▓███████████▓████████▒░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░▓██▓▓████████████████▒░░░░▒▒░░░░░░░░▒▒░░░░▓███████████▓█████████░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░▓███▓████████████████░░░░░░░░▒░░░░▒░░░░░░░▒█████████████▓███████▒░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░▓████▓████▓███████████▓░░░░░░░░░░░░░░░░░░░░░▒█████████████▓▓██████▒░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░▒████▓▓▓███▓▓███████████▒░░░░░░░░░░░░░░░░░░░░░░▓████████████▓██████▒░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░████▒▓████▓████████████▓░░░░░░░░░░░░░░░░░░░░░░░▒███████████▓██████▓░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░▓███▓█████████████████▓░░░░░░░░░░░░░░░░░░░░░░░░░▒█████████▓█▓▓██████▓▒░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░▒███████▓▓█████████▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓███████▓▒█▓▓███████▓▒░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░▓███████▒▓██████▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓▓█████▒▓█▓█████████▒░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░▒▓█████████▒█▓▓▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▓▓▓█████████▒░░░░░░░░░░░░
// ░░░░░░░░░░░▒█████▓▓▓▓▓▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▓▓▓░░░░░░░░░░░░
// ░░░░░░░░░░░▓▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒░░░░░░░░░
// ░░░░░░░░▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒░░░░░░░
// ░░░░░░▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒░░░░░░
// ░░░░░░▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒░░░░░
// ░░░░░▒░░░░░░░░░░░▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒░░░░░
// ░░░░░▒░░░░░░░░░░░░░▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒░░░░░
// ░░░░░▒▒▒░▒░░░░░░░░░░▒░░░░░░░░░░░░░░░░░▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒░░░░░░░░░░▒░░░░░
// ░▒▒▒░░░▒▒▒░░░░░░░░░░▒▒░░░░░▒░░░░░░░░░░░░▒▒░░░░░▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒░░░░░░░░░░░░░░░
// ▒░░░░░░░░░░░░░░░░░░░░▒░░░▒▒░░░░░░░░░░░░░░▒░▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒░▒▒▒░░░░░░░░░░░░▒
// ▒░░░░░░░░░▒▒▒░░░░░░░░░░▒▒▒░░░░░░░░░░░░░▒▒░▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒░░░▒░░░░░░░░░░░░░░▒
// ▒▒░░░░░░░░▒▒▒▒░░░░░░░░░▒░░░░░░░░░░░░░░░░▒▒░░░░░░░░░░░░░░░░░░░░▒▒░░░░░░░░░░░▒▒▒░░▒░░▒░░░░░░░░░░░░░░▒▒
// ░▒▒░░░░░░░░▒▒▒▒▒░░░░░░▒▒░░░░░░░░░░░░░░░░░▒▒░░░░░░░░░░░░░░░░░▒▒▒▒░░░░░░░░░░▒▒░░░░░░░▒░░░░░░░░░░░░░▒▒░

contract AGS is ERC721A, Ownable {
    using Strings for uint256;
    uint256 public supply = 8888;
    string public baseUri = "https://gateway.pinata.cloud/ipfs/QmWanHwbtoLn9PzWFx5Q16i3fToLkE2oMDmeFhrkLp11AF/";
    string public extension = ".json";  

    bytes32 public tier1Whitelist;
    bytes32 public tier2Whitelist;

    bool public tier1MintLive;
    bool public tier2MintLive;
    bool public publicLive;

    uint8 public TIER1_MINT_CAP = 3;
    uint8 public TIER2_MINT_CAP = 3;
    uint8 public PUBLIC_MINT_CAP = 8;
    uint256 public TIER1_PRICE = 0.05 ether;
    uint256 public NON_TIER1_PRICE = 0.08 ether;

    address public withdrawAddress = 0xe3Cb43481F105108F5E0Fce0A3bC33A21e864C03;

    constructor() ERC721A("Astro Girls Society", "AGS", supply) {}

    function setMintCaps(uint8 _tier1, uint8 _tier2, uint8 _public) public onlyOwner {
        TIER1_MINT_CAP = _tier1;
        TIER2_MINT_CAP = _tier2;
        PUBLIC_MINT_CAP = _public;
    }

    function setWithdrawAddress(address _addr) public onlyOwner {
        withdrawAddress = _addr;
    }

    function setSupply(uint256 _supply) public onlyOwner {
        supply = _supply;
    }

    function setPrices(uint256 _tier1, uint256 _tier2) public onlyOwner {
        TIER1_PRICE = _tier1;
        NON_TIER1_PRICE = _tier2;
    }

    function setBaseUri(string calldata _baseUri) public onlyOwner {
        baseUri = _baseUri;
    }

    function setMerkleTier1(bytes32 _whitelist) external onlyOwner {
        tier1Whitelist = _whitelist;
    }

    function setMerkleTier2(bytes32 _whitelist) external onlyOwner {
        tier2Whitelist = _whitelist;
    }

    function setMintStages(bool _tier1, bool _tier2, bool _public) public onlyOwner {
        tier1MintLive = _tier1;
        tier2MintLive = _tier2;
        publicLive = _public;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        string memory currentBaseURI = baseUri;
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        extension
                    )
                )
                : "";
    }

    function tier1Mint(uint8 numToMint, bytes32[] calldata proof) public payable {
        require(tier1MintLive, "Not live");
        require(msg.value >= TIER1_PRICE * numToMint, "invalid price");
        require(MerkleProof.verify(proof, tier1Whitelist, keccak256(abi.encodePacked(msg.sender))), "Leaf node could not be verified, check proof.");
        require(_numberMinted(msg.sender) + numToMint < TIER1_MINT_CAP + 1, "minted too many");
        _safeMint(msg.sender, numToMint);
    }

    function tier2Mint(uint8 numToMint, bytes32[] calldata proof) public payable isMintValid(numToMint) {
        require(tier2MintLive, "Not live");
        require(msg.value >= NON_TIER1_PRICE * numToMint, "invalid price");
        require(MerkleProof.verify(proof, tier2Whitelist, keccak256(abi.encodePacked(msg.sender))), "Leaf node could not be verified, check proof.");
        require(_numberMinted(msg.sender) + numToMint < TIER2_MINT_CAP + 1, "minted too many");
        _safeMint(msg.sender, numToMint);
    }

    function publicMint(uint8 numToMint) public payable isMintValid(numToMint){
        require(publicLive, "Not live");
        require(msg.value >= NON_TIER1_PRICE * numToMint, "invalid price");
        require(_numberMinted(msg.sender) + numToMint < PUBLIC_MINT_CAP + 1, "minted too many");
        _safeMint(msg.sender, numToMint);
    }

    function devMint(uint256 count, address to) public onlyOwner isMintValid(count) {
        _safeMint(to, count);
    }

    function checkTier1Whitelist(bytes32[] memory proof) external view returns (bool) {
        return MerkleProof.verify(proof, tier1Whitelist, keccak256(abi.encodePacked(msg.sender)));
    }

    function checkTier2Whitelist(bytes32[] memory proof) external view returns (bool) {
        return MerkleProof.verify(proof, tier2Whitelist, keccak256(abi.encodePacked(msg.sender)));
    }

    function checkNumMinted(address user) public view returns (uint256) {
        return _numberMinted(user);
    } 


    function withdraw() public onlyOwner {
        payable(withdrawAddress).transfer(payable(address(this)).balance);
    }

    modifier isMintValid(uint256 numToMint) {
        require(totalSupply() + numToMint < supply + 1, "Not enough remaining for mint amount requested");
        require(numToMint > 0, "Quantity needs to be more than 0");
        _;
    }
}