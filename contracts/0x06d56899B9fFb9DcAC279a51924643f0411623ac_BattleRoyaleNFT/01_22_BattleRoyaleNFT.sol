pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./libraries/Property.sol";
import "./IBattleRoyaleNFT.sol";
import "./IBattleRoyaleNFTRenderer.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "./operator-filter/DefaultOperatorFilterer.sol";

//import "hardhat/console.sol";

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

contract BattleRoyaleNFT is IBattleRoyaleNFT, ERC721Enumerable, Ownable, ReentrancyGuard, EIP712, DefaultOperatorFilterer {
    uint public constant MINT_PRICE = 0.0099 ether;
    uint public constant MINT_SUPPLY = 13999;
    uint public constant MAX_PER_WALLET = 15;
    uint public constant WL_MINT_AMOUNT = 2;

    // 0: cannot mint
    // 1: public mint by people
    // 2: mint by game logic contract
    uint8 public mintStatus = 0;

    uint public nextTokenId;

    mapping(address => uint) public mintedCountByAddress;

    address[] private _games;
    mapping(address => uint) private _game2index;

    // nft property
    mapping(uint => uint) private _properties;

    IBattleRoyaleNFTRenderer public renderer;

    // custom cross chain logic
    bytes32 private constant _CROSS_CHAIN_TYPEHASH =
        keccak256("ClaimByCrossChain(address to,uint256[] data,uint256 nonce)");
    
    bytes32 private constant _MINT_WL_TYPEHASH =
        keccak256("MintWL(address to)");

    event CrossChainStart(uint indexed nonce, address indexed from, address indexed to, uint[] data);
    event CrossChainFinish(uint indexed nonce);

    address public validator;
    uint public crossChainNonce = 0;
    mapping(uint => bool) public claimedNonce;

    constructor(uint startTokenId) ERC721("Battle Royale NFT", "BattleRoyaleNFT") EIP712("Battle Royale NFT", "1") {
        nextTokenId = startTokenId;
    }

    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner nor approved"
        );
        _burn(tokenId);
    }

    // Ethereum <=> Arbitrum Nova
    function crossChain(address to, uint[] calldata tokenIds) external {
        uint count = tokenIds.length;
        require(count > 0, "No Tokens");
        uint[] memory data = new uint[](count * 2);
        for (uint i = 0; i < count; i++) {
            uint tokenId = tokenIds[i];
            data[i * 2] = tokenId;
            data[i * 2 + 1] = _properties[tokenId];

            burn(tokenId);
            delete _properties[tokenId];
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

        for(uint i = 0; i < data.length; i += 2) {
            _safeMint(to, data[i]);
            _properties[data[i]] = data[i+1];
        }
        emit CrossChainFinish(nonce);
    }

    function mint(uint amount) external payable {
        require(mintedCountByAddress[msg.sender] + amount <= MAX_PER_WALLET, "mint too many");
        mintedCountByAddress[msg.sender] += amount;
        require(msg.value >= MINT_PRICE * amount, "not enough money");
        _mintByAmount(amount);
    }

    // free wl mint
    function mintWL(uint8 v, bytes32 r, bytes32 s) external {
        require(mintedCountByAddress[msg.sender] == 0, "minted");
        mintedCountByAddress[msg.sender] = WL_MINT_AMOUNT;
        bytes32 structHash = keccak256(abi.encode(_MINT_WL_TYPEHASH, msg.sender));
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == validator, "mintWL: invalid signature");
        _mintByAmount(WL_MINT_AMOUNT);
    }

    function _mintByAmount(uint amount) private {
        require(mintStatus == 1, "no public mint ");
        require(nextTokenId + amount <= MINT_SUPPLY, "sold out");
        require(msg.sender == tx.origin, "no bot");

        /**
         * Character: 25%
         * Gun: 25%
         * Bomb: 10%
         * Armor: 10%
         * Ring: 10%
         * Food: 10%
         * Boots: 10%
         */
        for (uint i = 0; i < amount; i++) {
            _mintAny(msg.sender, 0x77665544332222211111);
        }
    }

    function _mintAny(address to, uint probability) internal returns (uint) {
        uint seed = uint(
            keccak256(abi.encodePacked(block.timestamp, msg.sender, nextTokenId))
        );
        return _mintToken(to, Property.newProperty(seed, probability));
    }

    function _mintToken(address to, uint property) internal returns (uint) {
        uint tokenId = nextTokenId;
        _properties[tokenId] = property;
        nextTokenId = tokenId + 1;
        _safeMint(to, tokenId);
        return tokenId;
    }

    // to support receiving ETH by default
    receive() external payable {}

    // operator filter
    function setApprovalForAll(address operator, bool approved) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public      
        override(ERC721, IERC721)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        _requireMinted(tokenId);
        return renderer.tokenURI(tokenId, tokenProperty(tokenId));
    }

    // nft property getter

    function tokenType(uint tokenId) public view returns (uint) {
        return Property.decodeType(_properties[tokenId]);
    }

    function tokenProperty(uint tokenId) public view returns (uint) {
        return _properties[tokenId];
    }

    function games() external view returns (address[] memory) {
        return _games;
    }

    modifier onlyGame() {
        require(_game2index[msg.sender] > 0, "not game");
        _;
    }

    // function getName(uint tokenId) view public returns (string memory name) {
    //     uint property = _properties[tokenId];
    // }

    // only for game
    function setProperty(uint tokenId, uint newProperty) external onlyGame {
        uint oldProperty = _properties[tokenId];
        require(
            Property.decodeType(oldProperty) == Property.decodeType(newProperty) &&
            Property.propertyCount(oldProperty) == Property.propertyCount(newProperty),
            "not same type"
        );
        _properties[tokenId] = newProperty;
    }

    function mintByGame(address to, uint property)
        external
        nonReentrant
        onlyGame
        returns (uint)
    {
        require(mintStatus == 2, "cannot mint by game");
        return _mintToken(to, property);
    }

    // only for owner
    function withdraw() external onlyOwner {
        (bool success,)= owner().call{value: address(this).balance}("");
        require(success);
    }

    function setMintStatus(uint8 status) external onlyOwner {
        require(status > mintStatus, "invalid status");
        mintStatus = status;
    }

    function addGame(address game) external onlyOwner {
        require(_game2index[game] == 0, "added");
        _games.push(game);
        _game2index[game] = _games.length;
    }

    function removeGame(address game) external onlyOwner {
        uint index = _game2index[game];
        require(index > 0, "not game");
        uint totalGameCount = _games.length;
        if (index != totalGameCount) {
            address lastGame = _games[totalGameCount - 1];
            _games[index-1] = lastGame;
            _game2index[lastGame] = index;
        }
        _games.pop();
        delete _game2index[game];
    }

    function setRenderer(IBattleRoyaleNFTRenderer newRenderer) external onlyOwner {
        renderer = newRenderer;
    }

    function setValidator(address newValidator) external onlyOwner {
        validator = newValidator;
    }
}