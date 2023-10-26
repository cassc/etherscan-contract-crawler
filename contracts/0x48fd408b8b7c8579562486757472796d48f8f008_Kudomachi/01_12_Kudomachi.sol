// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A.sol";

contract Kudomachi is ERC721A, Ownable, PaymentSplitter {
    using Strings for uint256;

    enum Step {
        Before,
        WhitelistSale,
        PublicSale,
        Finished
    }

    uint256 private constant MAX_SUPPLY = 3333;
    uint256 private constant MAX_WHITELIST = 3000;
    uint256 private constant MAX_PUBLIC = 333;

    uint256 private constant PRICE_WHITELIST = 0.0098 ether;
    uint256 private constant PRICE_PUBLIC = 0.014 ether;

    uint256 public saleStartTime = 1667842200;

    bytes32 public merkleRoot;

    string public baseURI;

    mapping(address => uint256) amountNFTsperWalletWhitelist;
    mapping(address => uint256) amountNFTsperWalletPublic;

    uint256 private constant MAX_PER_ADDRESS_DURING_WHITELIST = 2;
    uint256 private constant MAX_PER_ADDRESS_DURING_PUBLIC = 3;

    uint256 private teamLenght;

    address[] private _team = [0x474dbB40408bf0cE7271BF512185B278F4F01DA1];

    uint256[] private _teamShares = [100];

    constructor(bytes32 _merkleRoot, string memory _baseURI)
        ERC721A("Kudomachi", "Kudo")
        PaymentSplitter(_team, _teamShares)
    {
        merkleRoot = _merkleRoot;
        baseURI = _baseURI;
        teamLenght = _team.length;
    }

    function whitelistMint(
        address _account,
        uint256 _quantity,
        bytes32[] calldata _proof
    ) external payable {
        require(
            getStep() == Step.WhitelistSale,
            "Not the moment for the WL sale"
        );
        require(isWhitelisted(_account, _proof), "Not whitelisted");
        require(
            amountNFTsperWalletWhitelist[msg.sender] + _quantity <=
                MAX_PER_ADDRESS_DURING_WHITELIST,
            "You can only mint 2 NFTs during the whitelist sale"
        );
        require(
            totalSupply() + _quantity <= MAX_WHITELIST,
            "Max supply exceeded"
        );
        require(msg.value >= PRICE_WHITELIST * _quantity, "not enought funds");
        amountNFTsperWalletWhitelist[msg.sender] += _quantity;
        _safeMint(_account, _quantity);
    }

    function publicMint(address _account, uint256 _quantity) external payable {
        require(
            getStep() == Step.PublicSale,
            "Not the moment to mint during public"
        );
        require(
            amountNFTsperWalletPublic[msg.sender] + _quantity <=
                MAX_PER_ADDRESS_DURING_PUBLIC,
            "You can only mint 3 NFTs during the public sale"
        );
        require(
            totalSupply() + _quantity <= MAX_PUBLIC + MAX_WHITELIST,
            "Max supply exceeded"
        );
        require(msg.value >= PRICE_PUBLIC * _quantity, "Not enought funds");
        amountNFTsperWalletPublic[msg.sender] += _quantity;
        _safeMint(_account, _quantity);
    }

    function getStep() public view returns (Step actualStep) {
        if (block.timestamp < saleStartTime) {
            return Step.Before;
        }
        if (
            block.timestamp >= saleStartTime &&
            block.timestamp < saleStartTime + 1 hours
        ) {
            return Step.WhitelistSale;
        }
        if (
            block.timestamp >= saleStartTime + 1 hours &&
            block.timestamp < saleStartTime + 168 hours
        ) {
            return Step.PublicSale;
        }
        if (
            block.timestamp >= saleStartTime + 168 hours &&
            block.timestamp < saleStartTime + 169 hours
        ) {
            return Step.Finished;
        }
    }

    function isWhitelisted(address _account, bytes32[] calldata _proof)
        internal
        view
        returns (bool)
    {
        return
            MerkleProof.verify(
                _proof,
                merkleRoot,
                keccak256(abi.encodePacked((_account)))
            );
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override(ERC721A)
        returns (string memory)
    {
        require(_exists(_tokenId), "NFT NOT MINTED");

        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    function setSaleStartime(uint256 _saleStartTime) external onlyOwner {
        saleStartTime = _saleStartTime;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function withdraw() external onlyOwner {
        for (uint256 i = 0; i < teamLenght; i++) {
            release(payable(payee(i)));
        }
    }

    receive() external payable override {
        revert("only if you mint");
    }
}