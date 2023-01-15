pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "./libraries/Property.sol";
import "./IBattleRoyaleNFTRenderer.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

//import "hardhat/console.sol";

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

contract BattleRoyaleNFTOnEthereum is ERC721AQueryable, Ownable, EIP712 {
    uint public constant TOTAL_SUPPLY = 10000;

    uint public constant MAX_PER_WALLET = 20;

    address private constant OPENSEA_OPERATOR = 0x1E0049783F008A0085193E00003D00cd54003c71;

    bool public freeMintOne = false;
    uint64 public mintPrice = 0.0045 ether;

    // 0: cannot mint
    // 1: public mint by people
    // 2: mint by game logic contract
    uint8 public mintStatus = 1;
    IBattleRoyaleNFTRenderer public renderer = IBattleRoyaleNFTRenderer(0x533B2E3B00ef3e191A205Bdf86c256Ca95FDec0F);

    // nft property
    mapping(uint => uint) private _properties;

    // custom cross chain logic
    bytes32 private constant _CROSS_CHAIN_TYPEHASH =
        keccak256("ClaimByCrossChain(address to,uint256[] data,uint256 nonce)");
    
    bytes32 private constant _MINT_WL_TYPEHASH =
        keccak256("MintWL(address to)");

    event CrossChainStart(uint indexed nonce, address indexed from, address indexed to, uint[] data);
    event CrossChainFinish(uint indexed nonce);

    address public validator = 0xcb652b6b6b77d510446993BCe16E576F8713916f;
    uint96 public crossChainNonce = 0;
    mapping(uint => bool) public claimedNonce;

    constructor() ERC721A("Battle Royale NFT", "BattleRoyaleNFT") EIP712("Battle Royale NFT", "1") {
    }

    function burn(uint256 tokenId) public {
        _burn(tokenId, true);
    }

    // Ethereum <=> Arbitrum Nova
    function crossChain(address to, uint[] calldata tokenIds) external {
        uint count = tokenIds.length;
        require(count > 0, "No Tokens");
        uint[] memory data = new uint[](count * 2);
        for (uint i = 0; i < count; i++) {
            uint tokenId = tokenIds[i];
            data[i * 2] = tokenId;
            data[i * 2 + 1] = tokenProperty(tokenId);
            burn(tokenId);
        }
        emit CrossChainStart(crossChainNonce, msg.sender, to, data);
        crossChainNonce += 1;
    }

    function claimByCrossChain(
        address to,
        uint[] calldata data,
        uint nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(!claimedNonce[nonce], "Claimed");
        claimedNonce[nonce] = true;
        bytes32 structHash = keccak256(abi.encode(_CROSS_CHAIN_TYPEHASH, to, keccak256(abi.encodePacked(data)), nonce));
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == validator, "claimByCrossChain: invalid signature");

        uint amount = data.length / 2;
        uint[] memory properties = new uint[](amount);
        for(uint i = 0; i < amount; i++) {
            properties[i] = data[i * 2 + 1];
        }
        _addNewProperties(_nextTokenId(), properties);
        _safeMint(to, amount);
        emit CrossChainFinish(nonce);
    }

    function mint(uint amount) external payable {
        uint mintedCount = _numberMinted(msg.sender);
        require(mintedCount + amount <= MAX_PER_WALLET, "mint too many");
        require(msg.value >= (amount - ((freeMintOne && mintedCount == 0) ? 1 : 0)) * uint(mintPrice), "not enough money");
        uint nextTokenId = _nextTokenId();
        require(mintStatus == 1, "no public mint ");
        require(nextTokenId + amount <= TOTAL_SUPPLY, "sold out");
        // require(msg.sender == tx.origin, "no bot");

        /**
         * Character: 25%
         * Gun: 25%
         * Bomb: 10%
         * Armor: 10%
         * Ring: 10%
         * Food: 10%
         * Boots: 10%
         */
        uint[] memory properties = new uint[](amount);
        for (uint i = 0; i < amount; i++) {
            uint seed = uint(
                keccak256(abi.encodePacked(block.timestamp, msg.sender, nextTokenId + i))
            );
            properties[i] = Property.newProperty(seed, 0x77665544332222211111);
        }
        _addNewProperties(nextTokenId, properties);
        _safeMint(msg.sender, amount);
    }

    function _addNewProperties(uint nextTokenId, uint[] memory properties) private {
        uint lastChunckIndex = nextTokenId / Property.COUNT_IN_CHUNCK;
        uint packedProperty = _properties[lastChunckIndex];
        uint amount = properties.length;
        for (uint i = 0; i < amount; i++) {
            uint chunckIndex = nextTokenId / Property.COUNT_IN_CHUNCK;
            if (lastChunckIndex != chunckIndex) {
                _properties[lastChunckIndex] = packedProperty;
                lastChunckIndex = chunckIndex;
                packedProperty = 0;
            }
            packedProperty |= properties[i] << (36 * (nextTokenId % Property.COUNT_IN_CHUNCK));
            nextTokenId++;
        }
        _properties[lastChunckIndex] = packedProperty;
    }

    // to support receiving ETH by default
    receive() external payable {}

    // Optimized for opensea.io. Don't need to set approved for all when you are listing on opensea.io
    function isApprovedForAll(address owner, address operator) public view virtual override(ERC721A, IERC721A) returns (bool) {
        return operator == OPENSEA_OPERATOR || super.isApprovedForAll(owner, operator);
    }

    // nft property getter

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721A, IERC721A)
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        uint property = tokenProperty(tokenId);
        uint property2 = (property & 0xf) << 248;
        for (uint i = 0; i < 10; i++) {
            uint p = (property >> (4 + i * 8)) & 0xff;
            if (p == 0) {
                property2 |= i;
                break;
            }
            property2 |= p << (i * 16 + 16);
        }
        return renderer.tokenURI(tokenId, property2);
    }

    function tokenType(uint tokenId) public view returns (uint) {
        return tokenProperty(tokenId) & 0xf;
    }

    function tokenProperty(uint tokenId) public view returns (uint) {
        return (_properties[tokenId / Property.COUNT_IN_CHUNCK] >> (36 * (tokenId % Property.COUNT_IN_CHUNCK))) & Property.MASK;
    }

    function getNextTokenId() external view returns (uint) {
        return _nextTokenId();
    }

    function numberMinted(address addr) external view returns (uint) {
        return _numberMinted(addr);
    }

    // only for owner
    function withdraw() external onlyOwner {
        (bool success,)= owner().call{value: address(this).balance}("");
        require(success);
    }

    function setMintStatus(uint8 status) external onlyOwner {
        mintStatus = status;
    }

    function setMintPrice(uint64 price, bool canFreeMintOne) external onlyOwner {
        mintPrice = price;
        freeMintOne = canFreeMintOne;
    }

    function setRenderer(IBattleRoyaleNFTRenderer newRenderer) external onlyOwner {
        renderer = newRenderer;
    }

    function setValidator(address newValidator) external onlyOwner {
        validator = newValidator;
    }
}