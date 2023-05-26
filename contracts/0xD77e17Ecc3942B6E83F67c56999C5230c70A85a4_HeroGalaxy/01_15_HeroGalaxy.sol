// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract HeroGalaxy is ERC721, Ownable,ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using ECDSA for bytes32;
    using Strings for uint256;

    uint256 public MAX_HERO_GALAXY_HEROES = 5555;
    uint256 public MAX_HERO_GALAXY_HEROES_PER_PURCHASE = 5;
    uint256 public MAX_HERO_GALAXY_HEROES_WHITELIST_CAP = 2;
    uint256 public constant HERO_GALAXY_PRICE = 0.069 ether;
    uint256 public RESERVED_HERO_GALAXY = 2222;

    string public tokenBaseURI;
    string public unrevealedURI;
    bool public presaleActive = false;
    bool public mintActive = false;
    bool public reservesMinted = false;

    mapping(address => uint256) private whitelistAddressMintCount;
    Counters.Counter public tokenSupply;

    constructor() ERC721("Hero Galaxy: Heroes", "HERO") {}

    // BEGIN REAL STUFF

    function setTokenBaseURI(string memory _baseURI) external onlyOwner {
        tokenBaseURI = _baseURI;
    }

    function setUnrevealedURI(string memory _unrevealedUri) external onlyOwner {
        unrevealedURI = _unrevealedUri;
    }

    function setWhitelistCap(uint256 _whitelist_cap) external onlyOwner {
        require(_whitelist_cap > RESERVED_HERO_GALAXY, "New reserved count must be higher than old");
        RESERVED_HERO_GALAXY = _whitelist_cap;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        bool revealed = bytes(tokenBaseURI).length > 0;

        if (!revealed) {
            return unrevealedURI;
        }

        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return string(abi.encodePacked(tokenBaseURI, _tokenId.toString()));
    }

    function setPresaleActive(bool _active) external onlyOwner {
        presaleActive = _active;
    }

    function setMintActive(bool _active) external onlyOwner {
        mintActive = _active;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function verifyOwnerSignature(bytes32 hash, bytes memory signature)
        private
        view
        returns (bool)
    {
        return hash.toEthSignedMessageHash().recover(signature) == owner();
    }

    // Mint

    function presaleMint(uint256 _quantity, bytes calldata _whitelistSignature)
        external
        payable
        nonReentrant
    {
        require(
            verifyOwnerSignature(
                keccak256(abi.encode(msg.sender)),
                _whitelistSignature
            ),
            "Invalid whitelist signature"
        );
        require(presaleActive, "Presale is not active");
        require(
            _quantity <= MAX_HERO_GALAXY_HEROES_WHITELIST_CAP,
            "You can only mint a maximum of 2 for presale"
        );
        require(
            whitelistAddressMintCount[msg.sender].add(_quantity) <=
                MAX_HERO_GALAXY_HEROES_WHITELIST_CAP,
            "This purchase would exceed the maximum Hero Galaxy Heroes you are allowed to mint in the presale"
        );

        whitelistAddressMintCount[msg.sender] += _quantity;
        _safeMintHeroes(_quantity);
    }

    function publicMint(uint256 _quantity) external payable {
        require(mintActive, "Sale is not active.");
        require(
            _quantity <= MAX_HERO_GALAXY_HEROES_PER_PURCHASE,
            "Quantity is more than allowed per transaction."
        );

        _safeMintHeroes(_quantity);
    }

    function _safeMintHeroes(uint256 _quantity) internal {
        require(_quantity > 0, "You must mint at least 1 hero");    
        require(
            tokenSupply.current().add(_quantity) <= MAX_HERO_GALAXY_HEROES,
            "This purchase would exceed max supply of Hero Galaxy Heroes"
        );
        require(
            msg.value >= HERO_GALAXY_PRICE.mul(_quantity),
            "The ether value sent is not correct"
        );

        for (uint256 i = 0; i < _quantity; i++) {
            uint256 mintIndex = tokenSupply.current();

            if (mintIndex < MAX_HERO_GALAXY_HEROES) {
                tokenSupply.increment();
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function mintReservedHeroes() external onlyOwner {
        require(!reservesMinted, "Reserves have already been minted.");
        require(
            tokenSupply.current().add(RESERVED_HERO_GALAXY) <= MAX_HERO_GALAXY_HEROES,
            "This mint would exceed max supply of Heroes"
        );

        for (uint256 i = 0; i < RESERVED_HERO_GALAXY; i++) {
            uint256 mintIndex = tokenSupply.current();

            if (mintIndex < MAX_HERO_GALAXY_HEROES) {
                tokenSupply.increment();
                _safeMint(msg.sender, mintIndex);
            }
        }

        reservesMinted = true;
    }
}