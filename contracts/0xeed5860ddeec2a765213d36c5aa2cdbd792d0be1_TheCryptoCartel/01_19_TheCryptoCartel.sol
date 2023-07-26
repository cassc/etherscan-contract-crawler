///////////////////////////////////////////////////////////////////////////////////////
//  _____ _            _____                  _          _____            _       _  //
// |_   _| |          /  __ \                | |        /  __ \          | |     | | //
//   | | | |__   ___  | /  \/_ __ _   _ _ __ | |_ ___   | /  \/ __ _ _ __| |_ ___| | //
//   | | | '_ \ / _ \ | |   | '__| | | | '_ \| __/ _ \  | |    / _` | '__| __/ _ \ | //
//   | | | | | |  __/ | \__/\ |  | |_| | |_) | || (_) | | \__/\ (_| | |  | ||  __/ | //
//   \_/ |_| |_|\___|  \____/_|   \__, | .__/ \__\___/   \____/\__,_|_|   \__\___|_| //
//                                 __/ | |                                           //
//                                |___/|_|                                           //
///////////////////////////////////////////////////////////////////////////////////////
// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./MerkleProof.sol";

contract TheCryptoCartel is ERC721Enumerable, ERC721URIStorage, ERC721Burnable, Pausable, AccessControl {
    using Counters for Counters.Counter;
    string public BASE_URI = "https://gateway.pinata.cloud/ipfs/QmcJYqxXyyB5obzkXbjTc7kZvfSTXJQCA8f2GgS6muutfQ/";
    string public BASE_URI_PRE_REVEAL = "https://gateway.pinata.cloud/ipfs/QmdxeCJAWouNFhXGow5d1T8VodgHCGcpDrdPcCCXs5yEgT";
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _whitelistCounter;
    bool private whitelistEnabled = true;
    bool private saleEnabled = false;
    bool private revealed = false;

    uint8 MINT_LIMIT = 6;
    uint8 WHITELIST_TRANSACTION_LIMIT = 3;

    uint16 SUPPLY_LIMIT = 7950;

    uint256 public constant PRICE_PER_TOKEN_PRE_SALE = 0.069 ether;
    uint256 public constant PRICE_PER_TOKEN = 0.08 ether;

    address t92 = 0xA665Af5AF9e485B6b496D43844e018fBE24DBe6d; // 92% withdrawal
    address t3 = 0x7Bf4209cF7C38Bad15C3531A9291A6345F1a7b3b; // 3% withdrawal
    address t5 = 0xC6521BAfD305FCa9205bC7c046634AA9f5B45303; // 5% withdrawal

    constructor() ERC721("The Crypto Cartel", "TCC") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setWhitelistSaleStatus(bool _isWhitelistActive) public onlyRole(DEFAULT_ADMIN_ROLE) {
        whitelistEnabled = _isWhitelistActive;
    }

    function setSaleStatus(bool _isSaleActive, bool _whitelistStatus) public onlyRole(DEFAULT_ADMIN_ROLE) {
        saleEnabled = _isSaleActive;
        whitelistEnabled = _whitelistStatus;
    }

    function setRevealStatus(bool _revealed) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revealed = _revealed;
    }

    // Implemented to change base URI in scenarios like revealing whitelisted tokens
    function setBaseUri(string memory _baseUri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        BASE_URI = _baseUri;
    }

    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function mint(uint256 numberOfTokens, bytes32[] calldata proof, bytes32 merkleRoot, string[] memory uris) public payable {
        uint256 ts = totalSupply();

        require(ts + numberOfTokens <= SUPPLY_LIMIT, "Reached max limit. No more minting possible!");
        require(numberOfTokens < MINT_LIMIT, "Cannot mint more than 5 cartels per transaction!");
        if(!saleEnabled && whitelistEnabled) {
            require(_verify(_leaf(msg.sender), proof, merkleRoot), "Not a whitelisted member!");
            require(PRICE_PER_TOKEN_PRE_SALE * numberOfTokens <= msg.value, "Ether amount sent is not correct");
        } else {
            require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether amount sent is not correct");
        }
        
        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenId);
            _setTokenURI(tokenId, uris[i]);
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function withdraw() public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 balance = address(this).balance;
        uint256 t_92 = balance * 87 /100;
        uint256 t_5 = balance * 10 /100;
        uint256 t_3 = balance * 3 /100;
        payable(t92).transfer(t_92);
        payable(t5).transfer(t_5);
        payable(t3).transfer(t_3);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        require(_exists(tokenId), "Token URI query for nonexistent token!");
        if(revealed == true) {
            // We can return BASE_URI + tokenId.json here but that would mean tokenId 1 should have
            // return super.tokenURI(tokenId);
            return super.tokenURI(tokenId); //string(abi.encodePacked(BASE_URI, "/", Strings.toString(tokenId), ".json"));
        } else {
            return BASE_URI_PRE_REVEAL;
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /** ---------------- Merkle tree whitelisting ---------------- */
    // Generate the leaf node (just the hash of tokenID concatenated with the account address)
    function _leaf(address account) internal pure returns (bytes32) {
            return keccak256(abi.encodePacked(account));
    }
    // Verify that a given leaf is in the tree.
    function _verify(bytes32 _leafNode, bytes32[] memory proof, bytes32 merkleRoot) internal view returns (bool) {
            return MerkleProof.verify(proof, merkleRoot, _leafNode);
    }
}