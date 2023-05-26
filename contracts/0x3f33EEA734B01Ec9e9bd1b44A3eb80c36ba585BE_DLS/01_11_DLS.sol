// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "ERC721.sol";
import "Ownable.sol";

contract DLS is ERC721, Ownable {

    string internal baseTokenURI = "https://gateway.pinata.cloud/ipfs/Qmc2rHWFDvf5ezTDVqdWXGtTWFQxciDumBwGBuiB6ekmL3/";
    uint256 public presalePrice = 0.05 ether;
    uint256 public increasePrice = 0.0003 ether;
    uint256 public totalSupply = 10000;
    uint256 public presaleSupply = 1000;
    uint256 public nonce = 0;
    uint256 public maxTx = 50;

    bool public saleActive = false;
    bool public presaleActive = false;
    bool public allowlistPresaleActive = false;

    address public m0; // 0xGodMode
    address public m1; // Nitrog3n
    address public m2; // Treasury

    mapping(address => uint256) public presaleWallets;

    event Mint(address owner, uint qty);

    constructor() ERC721("Digital Landowners Society", "DLS") {}

    /**
     * Set allowlist presale wallet addresses.
     */
    function setPresaleWallets(address[] memory _a, uint256[] memory _amount) public onlyOwner {
        for (uint256 i; i < _a.length; i++) {
            presaleWallets[_a[i]] = _amount[i];
        }
    }

    /**
     * Activates / deactivates allowlist presale event.
     */
    function setAllowlistPresaleActive(bool val) public onlyOwner {
        allowlistPresaleActive = val;
    }

    /**
     * Activates / deactivates public presale event.
     */
    function setPresaleActive(bool val) public onlyOwner {
        presaleActive = val;
    }

    /**
     * Activates / deactivates public sale event.
     */
    function setSaleActive(bool val) public onlyOwner {
        saleActive = val;
    }

    /**
     * Activates / deactivates allowlist presale event.
    */
    function setMaxTx(uint newMax) external onlyOwner {
        maxTx = newMax;
    }

    /**
     * Set base URL of tokens' metadata.
    */
    function setBaseTokenURI(string calldata _uri) external onlyOwner {
        baseTokenURI = _uri;
    }

    /**
     * Use our base URL of tokens' metadata.
    */
    function _baseURI() internal override view returns (string memory) {
        return baseTokenURI;
    }

    /**
     * Calculate price for token(s).
     * Price is increased by 0.0003 ETH for every next after the first presaleSupply(1,000) tokens.
    */
    function calculatePrice(uint qty) internal view returns (uint) {
        uint totalPrice = 0;
        for (uint i = 1; i <= qty; i++) {
            uint tokenId = nonce + i;
            if (tokenId <= presaleSupply) {
                totalPrice += presalePrice;
            } else {
                totalPrice += presalePrice + (tokenId - presaleSupply) * increasePrice;
            }
        }
        return totalPrice;
    }

    /**
     * Set member addresses to whom the funds should be allocated.
    */
    function setMembersAddresses(address[] memory _a) public onlyOwner {
        m0 = _a[0];
        m1 = _a[1];
        m2 = _a[2];
    }

    /**
     * Allocates funds to members.
    */
    function fundAllocation(uint256 amount) public payable onlyOwner {
        require(payable(m0).send(amount * 75 / 100 * 85 / 100));
        require(payable(m1).send(amount * 75 / 100 * 15 / 100));
        require(payable(m2).send(amount * 25 / 100));
    }

    /**
     * Do minting for certain number of tokens.
    */
    function doMint(uint qty) internal {
        for (uint i = 0; i < qty; i++) {
            nonce++;
            uint tokenId = nonce;
            _safeMint(msg.sender, tokenId);
        }
        emit Mint(msg.sender, qty);
    }

    /**
     * Mint to presale allowlist wallet only with standard presale price.
    */
    function allowlistPresale(uint qty) external payable {
        require(allowlistPresaleActive, "TRANSACTION: presale is not active");
        uint256 qtyAllowed = presaleWallets[msg.sender];
        require(qty <= qtyAllowed && qty >= 1, "TRANSACTION: you can't mint on presale");
        require(qty + nonce <= presaleSupply, "SUPPLY: value exceeds presale supply");
        require(msg.value >= qty * presalePrice, "PAYMENT: invalid value");
        presaleWallets[msg.sender] = qtyAllowed - qty;
        doMint(qty);
    }

    /**
     * Presale mint with standard presale price.
    */
    function presale(uint qty) external payable {
        require(presaleActive, "TRANSACTION: presale is not active");
        require(qty <= maxTx && qty >= 1, "TRANSACTION: qty of mints not allowed");
        require(qty + nonce <= presaleSupply, "SUPPLY: value exceeds presale supply");
        require(msg.value >= qty * presalePrice, "PAYMENT: invalid value");
        doMint(qty);
    }

    /**
     * Mint tokens, maxTx (10) maximum at once.
     * Price is increased by 0.0003 ETH for every next after the first presaleSupply(1,000) tokens.
     * See calculatePrice for more details.
    */
    function mint(uint qty) external payable {
        require(saleActive, "TRANSACTION: sale is not active");
        require(balanceOf(_msgSender()) > 0, "TRANSACTION: only holder");
        require(qty <= maxTx && qty >= 1, "TRANSACTION: qty of mints not allowed");
        require(qty + nonce <= totalSupply, "SUPPLY: value exceeds totalSupply");
        uint totalPrice = calculatePrice(qty);
        require(msg.value >= totalPrice, "PAYMENT: invalid value");
        doMint(qty);
    }
}