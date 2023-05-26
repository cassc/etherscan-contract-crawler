// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MuskyPunks is ERC721, Ownable {
    string public baseURI;

    uint256 public constant MAX_SUPPLY = 10000;

    uint256 public constant MAX_MINT_PER_TX = 42;

    uint256 public constant MAX_PRE_MINT_SUPPLY = 100;

    uint256 public constant PRICE = 0.04 ether;

    uint256 public totalSupply = 0;

    uint256 public preMintSupply = 0;

    uint256 public mintableSupply = MAX_SUPPLY;

    uint256[MAX_SUPPLY] private indices;

    bool public mintable = false;

    event Mintable(bool mintable);

    event BaseURI(string baseURI);

    constructor() ERC721("MuskyPunks", "MUSKY") {}

    modifier isMintable() {
        require(mintable, "MuskyPunks: NFT cannot be minted yet.");
        _;
    }

    modifier isNotExceedMaxMintPerTx(uint256 amount) {
        require(
            amount <= MAX_MINT_PER_TX,
            "MuskyPunks: Mint amount exceeds max limit per tx."
        );
        _;
    }

    modifier isNotExceedMaxSupply(uint256 amount) {
        require(
            totalSupply + amount <= MAX_SUPPLY - MAX_PRE_MINT_SUPPLY,
            "MuskyPunks: There are no more remaining NFT's to mint."
        );
        _;
    }

    modifier isPaymentSufficient(uint256 amount) {
        require(
            msg.value == amount * PRICE,
            "MuskyPunks: There was not enough/extra ETH transferred to mint an NFT."
        );
        _;
    }

    modifier isNotExceedMaxPreMintSupply(uint256 amount) {
        require(
            preMintSupply + amount <= MAX_PRE_MINT_SUPPLY,
            "MuskyPunks: There are not enough NFT's to premint."
        );
        _;
    }

    function preMint(uint256 amount)
        public
        onlyOwner
        isNotExceedMaxPreMintSupply(amount)
    {
        for (uint256 index = 0; index < amount; index++) {
            preMintSupply++;

            _safeMint(msg.sender, getAvailableRandomTokenId());
        }
    }

    function mint(uint256 amount)
        public
        payable
        isMintable
        isNotExceedMaxMintPerTx(amount)
        isNotExceedMaxSupply(amount)
        isPaymentSufficient(amount)
    {
        for (uint256 index = 0; index < amount; index++) {
            _safeMint(msg.sender, getAvailableRandomTokenId());
        }
    }

    function getAvailableRandomTokenId() internal returns (uint256) {
        uint256 index = uint256(
            keccak256(
                abi.encodePacked(
                    msg.sender,
                    mintableSupply,
                    block.number,
                    block.difficulty,
                    block.timestamp,
                    blockhash(block.number - 1)
                )
            )
        ) % mintableSupply;

        uint256 tokenId = indices[index] != 0 ? indices[index] : index;

        mintableSupply--;

        totalSupply++;

        indices[index] = indices[mintableSupply] == 0
            ? mintableSupply
            : indices[mintableSupply];

        return tokenId + 1;
    }

    function setBaseURI(string memory _URI) public onlyOwner {
        baseURI = _URI;

        emit BaseURI(baseURI);
    }

    function setMintable(bool _mintable) public onlyOwner {
        mintable = _mintable;

        emit Mintable(mintable);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}