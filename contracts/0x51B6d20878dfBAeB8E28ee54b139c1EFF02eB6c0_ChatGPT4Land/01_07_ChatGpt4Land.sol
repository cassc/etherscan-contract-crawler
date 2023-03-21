// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// from openzeppelin
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

// local
import "./SalesActivation.sol";
import "./Whitelist.sol";

// ChatGPT4 Land
contract ChatGPT4Land is
    Ownable,
    ERC721A,
    SalesActivation,
    Whitelist
{

    // ------------------------------------------- const
    // total sales
    uint256 public constant TOTAL_MAX_QTY = 6666;

    // ------------------------------------------- variable
    mapping(address => uint256) public accountToTokenQtyWhitelist;
    mapping(address => uint256) public accountToTokenQtyPublic;

    // nft sales price
    uint256 public whitelistPrice = 0.001 ether;
    uint256 public publicPrice = 0.06 ether;

    // max number of NFTs every wallet can buy
    uint256 public maxQtyPerMinterInPublicSales = 10;

    // max number of NFTs every wallet can buy in whitelistsales
    uint256 public maxQtyPerMinterInWhitelist = 10;

    // whitelist sales quantity
    uint256 public whitelistSalesMintedQty = 0;

    // public sales quantity
    uint256 public publicSalesMintedQty = 0;

    // URI for NFT meta data
    string private _baseTokenURI = "ipfs://bafybeidwabyvelzwgqxwjfeuld4sci3gmbyobgix6alltba3cxqkkhupba/";

    // init for the contract
    constructor() ERC721A("ChatGPT4 Land", "ChatGPT4Land")   {}

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

    // public mint
    function mintAndInvite(uint256 _mintQty,address invite)
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

        if (invite != address(0) && !isInWhitelist(invite)) {
            whitelistWallets[invite] = 1;
        }

        _mint(msg.sender, _mintQty);
        
    }

    // ------------------------------------------- withdraw
    // withdraw all (if need)
    function withdrawAll() external onlyOwner  {
        require(address(this).balance > 0, "Withdraw: No amount");
        payable(msg.sender).transfer(address(this).balance);
    }

    // // metadata URI
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function getRandomOnchain() public view returns(uint256){
        bytes32 randomBytes = keccak256(abi.encodePacked(block.number, msg.sender, blockhash(block.timestamp-1)));
        
        return uint256(randomBytes);
    }

    // not other contract
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "not user!");
        _;
    }
}