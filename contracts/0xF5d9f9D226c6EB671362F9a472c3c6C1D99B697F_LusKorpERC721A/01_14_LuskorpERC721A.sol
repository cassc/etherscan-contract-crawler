// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A.sol";

contract LusKorpERC721A is
    Ownable,
    Pausable,
    ReentrancyGuard,
    PaymentSplitter,
    ERC721A
{
    using Strings for uint256;

    enum Step {
        Before,
        WhitelistSale,
        PublicSale,
        SoldOut,
        Reveal
    }

    Step public sellingStep;

    uint256 private constant MAX_SUPPLY = 8499;

    uint256 private constant MAX_PER_ACCOUNT_DURING_WHITELIST_SALE = 3;
    uint256 private constant MAX_PER_ACCOUNT_DURING_PUBLIC_SALE = 2;
    mapping(address => uint256) public amountNFTperAccountWhitelistSale;
    mapping(address => uint256) public amountNFTperAccountPublicSale;

    uint256 public price = 0.0094 ether;
    uint256 public saleStartTime = 1662993000;

    bytes32 public merkleRoot;
    string private baseURI;

    address[] private _team = [0xEE18CA9206faA77FBC65424612B428e9972ed6DC];
    uint256[] private _teamShares = [1000];

    constructor(bytes32 _merkleRoot, string memory _baseURI)
        ERC721A("LusKorp", "LK")
        PaymentSplitter(_team, _teamShares)
    {
        merkleRoot = _merkleRoot;
        baseURI = _baseURI;
    }

    /**
     * @notice Pause the contract if unpaused
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the contract if paused
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @notice Change the merkle root
     *
     * @param _merkleRoot The new merkle root
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
     * @notice Hash an address
     *
     * @param _account The address to be hashed
     *
     * @return bytes32 The hashed address
     */
    function leaf(address _account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account));
    }

    /**
     * @notice Returns true if a leaf can be proved to be a part of a merkle tree defined by root
     *
     * @param _leaf The leaf
     * @param _proof The Merkle Proof
     *
     * @return bool Return true if a leaf can be proved to be a part of a merkle tree defined by root, false othewise
     */
    function _verify(bytes32 _leaf, bytes32[] memory _proof)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(_proof, merkleRoot, _leaf);
    }

    /**
     * @notice Check if an address is whitelisted or not
     *
     * @param _account The account checked
     * @param _proof The Merkle Proof
     *
     * @return bool Return true if an address is whitelisted, false otherwise
     */
    function isWhitelisted(address _account, bytes32[] calldata _proof)
        internal
        view
        returns (bool)
    {
        return _verify(leaf(_account), _proof);
    }

    /**
     * @notice Release the gains on every accounts
     */
    function releaseAll() external onlyOwner {
        for (uint256 i = 0; i < _team.length; i++) {
            release(payable(payee(i)));
        }
    }

    /**
     * @notice Allows to set the public sale price
     *
     * @param _price The new price of one NFT during the public sale
     */
    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    /**
     * @notice Change the starting time (timestamp) of the whitelist sale
     *
     * @param _saleStartTime The new starting timestamp of the whitelist sale
     */
    function setSaleStartTime(uint256 _saleStartTime) external onlyOwner {
        saleStartTime = _saleStartTime;
    }

    /**
     * @notice Change the step of the sale
     *
     * @param _step The new step of the sale
     */
    function setStep(uint256 _step) external onlyOwner {
        sellingStep = Step(_step);
    }

    /**
     * @notice Change the base URI of the NFTs
     *
     * @param _baseURI The new base URI of the NFTs
     */
    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /** @notice Get the token URI of an NFT by his ID
     *
     * @param _tokenId The ID of the NFT you want to have the URI of the metadatas
     *
     * @return string Token URI of an NFT by his ID
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "URI query for nonexistent token");

        return
            string(
                abi.encodePacked(
                    baseURI,
                    sellingStep == Step.Reveal ? _tokenId.toString() : "hidden",
                    ".json"
                )
            );
    }

    /**
     * @notice Mint function for the whitelist sale
     *
     * @param _account Account which will receive the NFT
     * @param _quantity Amount of NFTs ther user wants to mint
     * @param _proof The Merkle Proof
     */
    function whitelistMint(
        address _account,
        uint256 _quantity,
        bytes32[] calldata _proof
    ) external payable whenNotPaused nonReentrant {
        require(
            sellingStep == Step.WhitelistSale,
            "Whitelist sale is not activated"
        );
        require(
            block.timestamp >= saleStartTime &&
                block.timestamp < saleStartTime + 40 minutes,
            "Sale is not running"
        );
        require(isWhitelisted(msg.sender, _proof), "Not whitelisted");
        require(
            amountNFTperAccountWhitelistSale[msg.sender] + _quantity <=
                MAX_PER_ACCOUNT_DURING_WHITELIST_SALE,
            "You can only get 3 NFT during the whitelist sale"
        );
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Max supply exceeded");
        amountNFTperAccountWhitelistSale[msg.sender] == 0
            ? require(
                msg.value >= (price * _quantity) - price,
                "Not enough funds"
            )
            : require(msg.value == price * _quantity, "Not enough funds");
        amountNFTperAccountWhitelistSale[msg.sender] += _quantity;
        _safeMint(_account, _quantity);
    }

    /**
     * @notice Mint function for the public sale
     *
     * @param _account Account which will receive the NFTs
     *
     * @param _quantity Amount of NFTs the user wants to mint
     */
    function mint(address _account, uint256 _quantity)
        external
        payable
        whenNotPaused
        nonReentrant
    {
        require(sellingStep == Step.PublicSale, "Public sale is not activated");
        require(
            block.timestamp >= saleStartTime + 40 minutes,
            "Sale is not running"
        );
        require(
            amountNFTperAccountPublicSale[msg.sender] + _quantity <=
                MAX_PER_ACCOUNT_DURING_PUBLIC_SALE,
            "You can only get 2 NFT during the public sale"
        );
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Max supply exceeded");
        require(msg.value >= price * _quantity, "Not enough funds");
        amountNFTperAccountWhitelistSale[msg.sender] += _quantity;
        _safeMint(_account, _quantity);
        if (totalSupply() == MAX_SUPPLY) {
            sellingStep = Step.SoldOut;
        }
    }

    function ownerMint(address _account, uint _quantity)
        external
        payable
        nonReentrant
        onlyOwner
    {
        _safeMint(_account, _quantity);
    }
}