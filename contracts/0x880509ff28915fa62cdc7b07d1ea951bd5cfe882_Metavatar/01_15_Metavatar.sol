//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

/*

███    ███ ███████ ████████  █████  ██    ██  █████  ████████  █████  ██████  
████  ████ ██         ██    ██   ██ ██    ██ ██   ██    ██     ██   ██  ██   ██ 
██ ████ ██ █████      ██    ███████ ██    ██ ███████    ██    ███████ ██████  
██  ██  ██ ██         ██    ██   ██  ██  ██  ██   ██    ██    ██   ██  ██    ██ 
██      ██ ███████    ██    ██   ██   ████   ██   ██    ██    ██   ██  ██    ██ 

*/

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./interfaces/IMetavatarGenerator.sol";

// import "hardhat/console.sol";

contract Metavatar is ERC721, ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public price = 0.04 ether;
    uint256 public whitelistPrice = 0.02 ether;
    uint256 public constant MAX_PER_TX = 8;
    uint256 public constant MAX_PER_ADDRESS = 10;
    uint256 public constant MAX_PER_ADDRESS_WHITELIST = 5;
    uint256 public constant MAX_PER_FOUNDER_ADDRESS = 30;
    bool public publicSaleActive = false;
    bool public whitelistSaleActive = true;
    bytes32 public whitelistMerkleRoot;
    IMetavatarGenerator public generator;

    mapping(uint256 => uint256) private seed;
    mapping(address => bool) public founderList;
    mapping(address => uint256) private _mintedPerAddress;
    mapping(address => uint256) private _whitelistMintedPerAddress;

    event MetavatarsMinted(
        address sender,
        uint256 minted_count,
        uint256 lastMintedTokenID
    );

    modifier isFounder() {
        require(founderList[msg.sender], "Not in founders list");
        _;
    }

    constructor(IMetavatarGenerator _generator) ERC721("Metavatar", "MVTR") {
        generator = _generator;
        _tokenIds.increment(); // start from 1
    }

    function setGenerator(IMetavatarGenerator _generator) external onlyOwner {
        generator = _generator;
    }

    function _bulkMint(uint256 numTokens, address destination) private {
        require(tokensMinted() <= MAX_SUPPLY, "All metavatars minted");
        require(
            tokensMinted() + numTokens <= MAX_SUPPLY,
            "Minting exceeds max supply"
        );
        for (uint256 i = 0; i < numTokens; i++) {
            uint256 newItemId = _tokenIds.current();
            _safeMint(destination, newItemId);
            _tokenIds.increment();
            seed[newItemId] = uint256(
                keccak256(
                    abi.encodePacked(
                        newItemId,
                        destination,
                        block.difficulty,
                        block.timestamp
                    )
                )
            );
        }
        _mintedPerAddress[destination] += numTokens;
        emit MetavatarsMinted(destination, numTokens, _tokenIds.current() - 1);
    }

    function claim(uint256 numTokens) public payable virtual nonReentrant {
        require(publicSaleActive, "Public sale not open");
        require(numTokens > 0, "numTokens cannot be 0");
        require(price * numTokens <= msg.value, "incorrect ETH amount");
        require(
            _mintedPerAddress[msg.sender] + numTokens <= MAX_PER_ADDRESS,
            "Exceeds wallet limit"
        );
        require(numTokens <= MAX_PER_TX, "Mint upto 8 metavatars at a time");
        _bulkMint(numTokens, msg.sender);
    }

    function whitelistClaim(uint256 numTokens, bytes32[] calldata merkleProof)
        external
        payable
        virtual
        nonReentrant
    {
        require(whitelistSaleActive, "Whitelist sale not open");
        require(numTokens > 0, "numTokens cannot be 0");
        require(
            _whitelistMintedPerAddress[msg.sender] <= MAX_PER_ADDRESS_WHITELIST,
            "Max allowed metavatars claimed by this wallet"
        );
        require(
            MerkleProof.verify(
                merkleProof,
                whitelistMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in whitelist"
        );
        require(
            whitelistPrice * numTokens <= msg.value,
            "Need more funds to mint metavatar(s)"
        );
        _bulkMint(numTokens, msg.sender);
    }

    function airdrop(address[] memory to) public onlyOwner {
        require(
            tokensMinted() + to.length <= MAX_SUPPLY,
            "Minting exceeds max supply"
        );
        for (uint256 i = 0; i < to.length; i++) {
            uint256 newItemId = _tokenIds.current();
            _safeMint(to[i], newItemId);
            _tokenIds.increment();
            seed[newItemId] = uint256(
                keccak256(
                    abi.encodePacked(
                        newItemId,
                        to[i],
                        block.difficulty,
                        block.timestamp
                    )
                )
            );
        }
    }

    function claimForFriend(uint256 numTokens, address walletAddress)
        public
        payable
        virtual
    {
        require(publicSaleActive, "Public sale not open");
        require(
            price * numTokens <= msg.value,
            "Need more funds to mint metavatar nft"
        );
        require(
            _mintedPerAddress[msg.sender] + numTokens <= MAX_PER_ADDRESS,
            "Exceeds wallet limit"
        );
        require(numTokens <= MAX_PER_TX, "Mint upto 8 metavatars at a time");
        _bulkMint(numTokens, walletAddress);
    }

    function ownerClaim(uint256 numTokens) public onlyOwner {
        _bulkMint(numTokens, msg.sender);
    }

    function founderClaim(uint256 numTokens) public isFounder {
        require(numTokens > 0, "numTokens cannot be 0");
        require(
            _mintedPerAddress[msg.sender] + numTokens <=
                MAX_PER_FOUNDER_ADDRESS,
            "Exceeds founder wallet limit"
        );
        _bulkMint(numTokens, msg.sender);
    }

    function dataURI(uint256 tokenId) public view returns (string memory) {
        require(tokenId > 0 && tokenId <= tokensMinted(), "Invalid token ID");
        return generator.dataURI(tokenId, Strings.toString(seed[tokenId]));
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(tokenId > 0 && tokenId <= tokensMinted(), "Invalid token ID");
        return generator.tokenURI(tokenId, Strings.toString(seed[tokenId]));
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function tokensMinted() public view returns (uint256) {
        return _tokenIds.current() - 1;
    }

    function isSaleActive() external view returns (bool) {
        return publicSaleActive;
    }

    function isWhitelistSaleActive() external view returns (bool) {
        return whitelistSaleActive;
    }

    function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        whitelistMerkleRoot = merkleRoot;
    }

    function setSaleActive(bool status) public onlyOwner {
        publicSaleActive = status;
    }

    function setWhitelistSaleActive(bool status) public onlyOwner {
        whitelistSaleActive = status;
    }

    function setFounderList(address[] calldata founderAddr) external onlyOwner {
        for (uint256 i = 0; i < founderAddr.length; i++) {
            founderList[founderAddr[i]] = true;
        }
    }
}