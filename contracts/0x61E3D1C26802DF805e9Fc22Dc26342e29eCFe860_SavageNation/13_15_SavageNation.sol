// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Contract by @AsteriaLabs
import "./Reg_ERC721Batch.sol";
import "./utils/Whitelist_Merkle.sol";
import "./utils/ERC173.sol";
import "./interfaces/DefaultOperatorFilterer.sol";

/// @title Savage Nation
/// @author Goku <@Suleman132446>
contract SavageNation is
    Reg_ERC721Batch,
    Whitelist_Merkle,
    ERC173,
    DefaultOperatorFilterer
{
    using MerkleProof for bytes32[];

    uint256 public whitelistPrice = 0.039 ether;
    uint256 public publicPrice = 0.059 ether;
    uint256 public maxPerWhitelist = 2;
    uint256 public maxPerPublic = 2;
    uint256 public maxSupply = 10000;

    /**
     @dev An enum representing the sale state
     */
    enum Sale {
        PAUSED,
        PRIVATE,
        PUBLIC
    }

    Sale public saleState = Sale.PAUSED;
    // Mapping of nft minted by a wallet in public
    mapping(address => uint256) public mintedPerWallet;

    // Modifier to allow only owner

    // Modifier to check the sale state
    modifier isSaleState(Sale sale_) {
        require(saleState == sale_, "Sale not active");
        _;
    }

    // Modifier to block the other contracts
    modifier blockContracts() {
        require(tx.origin == msg.sender, "No smart contracts are allowed");
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    ) {
        __init_ERC721Metadata(name_, symbol_, baseURI_);
        _setOwner(msg.sender);
    }

    /**
     * @dev tranfer the funds from contract
     *
     * @param to_ : the address of the wallet to transfer the funds
     */
    function withdraw(address to_, uint amount_) public onlyOwner {
        uint256 _balance_ = address(this).balance;
        require(_balance_ > 0, "No balance to withdraw");
        require(amount_ <= _balance_, "Amount is not valid");
        address _recipient_ = payable(to_);
        (bool _success_, ) = _recipient_.call{value: amount_}("");
        require(_success_, "Transaction failed");
    }

    /**
     * @dev set the whiltelist price
     *
     * @param price_ : the price of whitelist mint
     */
    function setWhitelistPrice(uint256 price_) external onlyOwner {
        whitelistPrice = price_;
    }

    /**
     * @dev set the public mint price
     *
     * @param price_ : the price of public mint
     */
    function setPublicPrice(uint256 price_) external onlyOwner {
        publicPrice = price_;
    }

    /**
     * @dev set the mints per wallet in whitelist
     *
     * @param mints_ : the amount of for whitelist mint
     */
    function setMintsPerWhitelist(uint256 mints_) external onlyOwner {
        maxPerWhitelist = mints_;
    }

    /**
     * @dev set the mints per wallet in public
     *
     * @param mints_ : the amount of for public mint
     */
    function setMintsPerPublic(uint256 mints_) external onlyOwner {
        maxPerPublic = mints_;
    }

    /**
     * @dev set the max supply for collection
     *
     * @param supply_ : the amount for  supply
     */
    function setMaxSupply(uint256 supply_) external onlyOwner {
        uint _currentSupply_ = totalSupply();
        require(
            supply_ > _currentSupply_,
            "Max supply should be greater than current supply"
        );
        require(
            supply_ < maxSupply,
            "Max supply should be greater than previous max supply"
        );
        maxSupply = supply_;
    }

    /**
     * @dev set the merkle root for whitelist
     *
     * @param root_ : the merkle for whitelist
     */
    function setWhitelistRoot(bytes32 root_) external onlyOwner {
        _setWhitelist(root_);
    }

    /**
     * @dev set the base uri for collection
     *
     * @param baseURI_ : the base uri for collection
     */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _setBaseURI(baseURI_);
    }

    /**
     * @dev set the sale state
     *
     * @param sale_ : the new sale state
     */
    function setSaleState(Sale sale_) external onlyOwner {
        saleState = sale_;
    }

    /**
     * @dev mint the token in whitelist sale
     *
     * @param proof_ : the proof for verificaton
     * @param qty_ : the quantity of mint
     */
    function mintWhitelist(bytes32[] memory proof_, uint256 qty_)
        external
        payable
        blockContracts
        isSaleState(Sale.PRIVATE)
        isWhitelisted(msg.sender, proof_, maxPerWhitelist, qty_)
    {
        uint _supply_ = totalSupply();
        require(_supply_ + qty_ <= maxSupply, "Exceeds supply");
        require(
            msg.value == qty_ * whitelistPrice,
            "Ether sent is not correct"
        );
        _mint(msg.sender, qty_);
        _consumeWhitelist(msg.sender, qty_);
    }

    /**
     * @dev mint the token for airdrop
     *
     * @param qty_ : the quantity of mint
     * @param to_: the address to send to
     */
    function airdrop( uint256 qty_ , address to_) onlyOwner
        external
        payable
        blockContracts
    {
        uint _supply_ = totalSupply();
        require(_supply_ + qty_ <= maxSupply, "Exceeds supply");
        _mint(to_, qty_);
    }

    /**
     * @dev mint the token in public sale
     *
     * @param qty_ : the quantity of mint
     */
    function mintPublic(uint256 qty_)
        external
        payable
        blockContracts
        isSaleState(Sale.PUBLIC)
    {
        uint _supply_ = totalSupply();
        require(
            mintedPerWallet[msg.sender] + qty_ <= maxPerPublic,
            "Exceeds mint per wallet"
        );
        require(_supply_ + qty_ <= maxSupply, "Exceeds supply");
        require(msg.value == qty_ * publicPrice, "Ether sent is not correct");
        _mint(msg.sender, qty_);
        mintedPerWallet[msg.sender] += qty_;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}