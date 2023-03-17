// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// from openzeppelin
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

// local
import "./SalesActivation.sol";
import "./Whitelist.sol";

// Base721A
contract Base721A is
    Ownable,
    ERC721A,
    SalesActivation,
    Whitelist
{

    // ------------------------------------------- const
    // total sales
    uint256 public constant TOTAL_MAX_QTY = 1000;

    // ------------------------------------------- variable
    mapping(address => uint256) public accountToTokenQtyWhitelist;
    mapping(address => uint256) public accountToTokenQtyPublic;

    // nft sales price
    uint256 public whitelistPrice = 0.01 ether;
    uint256 public publicPrice = 0.01 ether;

    // max number of NFTs every wallet can buy
    uint256 public maxQtyPerMinterInPublicSales = 5;

    // max number of NFTs every wallet can buy in whitelistsales
    uint256 public maxQtyPerMinterInWhitelist = 5;

    // whitelist sales quantity
    uint256 public whitelistSalesMintedQty = 0;

    // public sales quantity
    uint256 public publicSalesMintedQty = 0;

    // URI for NFT meta data
    string private _baseTokenURI;

    // init for the contract
    constructor() ERC721A("Base721A", "Base721A")   {}

    // whitelist mint
    function whitelistMint(uint256 _mintQty)
        external
        isPreSalesActive
        callerIsUser
        payable
    {
        require(
            isInWhitelist(msg.sender),
            "Not in whitelist yet!"
        );
        require(
            publicSalesMintedQty + whitelistSalesMintedQty + _mintQty <= TOTAL_MAX_QTY,
            "Exceed sales max limit!"
        );
        require(
            accountToTokenQtyWhitelist[msg.sender] + _mintQty <= maxQtyPerMinterInWhitelist,
            "Exceed max mint per minter!"
        );
        require(
            msg.value >= _mintQty * whitelistPrice,
            "Insufficient ETH!"
        );

        // update the quantity of the sales
        accountToTokenQtyWhitelist[msg.sender] += _mintQty;
        whitelistSalesMintedQty += _mintQty;

        // safe mint for every NFT
        _mint(msg.sender, _mintQty);

    }

    // public mint
    function mint(uint256 _mintQty)
        external
        isPublicSalesActive
        callerIsUser
        payable
    {
        require(
            publicSalesMintedQty + whitelistSalesMintedQty + _mintQty <= TOTAL_MAX_QTY,
            "Exceed sales max limit!"
        );
        require(
            accountToTokenQtyPublic[msg.sender] + _mintQty <= maxQtyPerMinterInPublicSales,
            "Exceed max mint per minter!"
        );
        require(
            msg.value >= _mintQty * publicPrice,
            "Insufficient ETH"
        );

        // update the quantity of the sales
        accountToTokenQtyPublic[msg.sender] += _mintQty;
        publicSalesMintedQty += _mintQty;

        _mint(msg.sender, _mintQty);

    }

    // set the quantity per minter can mint in public sales
    function setQtyPerMinterPublicSales(uint256 _qty) external onlyOwner {
        maxQtyPerMinterInPublicSales = _qty;
    }

    // set the quantity per minter can mint in whitelist sales
    function setQtyPerMinterWhitelist(uint256 _qty) external onlyOwner {
        maxQtyPerMinterInWhitelist = _qty;
    }
    
    // set the whitelist price
    function setWhitelistPrice(uint256 _price) external onlyOwner {
        whitelistPrice = _price;
    }

    // set the public price
    function setPublicPrice(uint256 _price) external onlyOwner {
        publicPrice = _price;
    }

    // ------------------------------------------- withdraw
    // withdraw all (if need)
    function withdrawAll() external onlyOwner  {
        require(address(this).balance > 0, "Withdraw: No amount");
        payable(msg.sender).transfer(address(this).balance);
    }

    // metadata URI
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        _baseTokenURI = _newBaseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // not other contract
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "not user!");
        _;
    }

}