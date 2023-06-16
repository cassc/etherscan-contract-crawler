// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract MECHADUCK is ERC721, EIP712, ERC721Enumerable, Pausable, AccessControl, ERC721Burnable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenCounter;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string private constant BASE_URI = "https://ipfs.madworld.io/mechaduck/";
    ERC721 public constant FIRST_GEN_TOKEN = ERC721(0x71E7AFA8B3AB8e83011ce7bBBDCD76Ccd7cb0660);
    uint256 public constant INIT_TOKEN_ID =  100001221205000001;
    uint256 public constant MINT_LIMIT = 1;

    bytes32 public RARE_PROOF_ROOT = 0x478c46387efe3c9745d79886703ec5e1d978dfe6d42556a0dd388424a917e62b;
    mapping(uint256 => uint256) _mappingMintCount;

    struct Duck{
        uint256 id;
        bool isLegendary;
        bytes32[] proof;
    }

    struct Purchase{
        uint256 price;
        Duck[] ducks;
    }

    constructor() ERC721("MECHADUCK", "MECHADUCK") EIP712("MECHADUCK", "1") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, address(0xd3A94F0630329Ab9096826cC96F203a6709e1744));
    }

    function _baseURI() internal pure override returns (string memory) {
        return BASE_URI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return string(abi.encodePacked(BASE_URI, Strings.toString(_tokenId)));
    }

    function getMintCount(uint256 _duckId)
        public
        view
        returns (uint256)
    {
        require(
            FIRST_GEN_TOKEN.ownerOf(_duckId) != address(0),
            "MECHADUCK: Token 404"
        );

        return _mappingMintCount[_duckId];
    }

    function contractURI() public pure returns (string memory) {
        return string(abi.encodePacked(BASE_URI, "metadata.json"));
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    // Set Root for the rare bduck
    function setRoot(uint256 _root) onlyRole(MINTER_ROLE) public {
        RARE_PROOF_ROOT = bytes32(_root);
    }

    function buy(Purchase calldata data, uint8 v, bytes32 r, bytes32 s) external whenNotPaused {
        require(data.ducks.length == 2, "MECHADUCK: At least two ducks are required");

        bytes32 payloadHash = keccak256(abi.encode(keccak256("mint(address receiver, uint256 price, uint256 duck1, uint256 duck2, uint chainId)"), msg.sender, data.price, data.ducks[0].id, data.ducks[1].id, block.chainid));
        bytes32 digest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", payloadHash));

        address addr = ecrecover(digest, v, r, s);
        require(hasRole(MINTER_ROLE, addr), "MECHADUCK: Invalid signer");


        for (uint256 index = 0; index < data.ducks.length; index++) {
            Duck memory duck = data.ducks[index];
            bytes32 leaf = keccak256(abi.encodePacked(duck.id));
            require(MerkleProof.verify(duck.proof, RARE_PROOF_ROOT, leaf), string(abi.encodePacked("BDUCKINGS: Not Rare ", duck.id.toString())) );
            require(FIRST_GEN_TOKEN.ownerOf(duck.id) == msg.sender, string(abi.encodePacked("MECHADUCK: Invalid Owner of NFT ", duck.id.toString())));
            require(_mappingMintCount[duck.id] < MINT_LIMIT,  string(abi.encodePacked("MECHADUCK: Reach Limit ", duck.id.toString())));
            _mappingMintCount[duck.id]++;
        }
        
        mintNew(msg.sender);
    }

    function safeMint(address to) public onlyRole(MINTER_ROLE) {
        mintNew(to);
    }


    function mintNew(address to) private {
        uint256 tokenId = INIT_TOKEN_ID + _tokenCounter.current();
        _tokenCounter.increment();
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}