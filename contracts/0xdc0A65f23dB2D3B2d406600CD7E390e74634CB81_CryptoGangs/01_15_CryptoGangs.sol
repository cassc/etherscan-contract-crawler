// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

struct Voucher {
    uint256 allowance;
    uint256 id;
    address wallet;
    bytes signature;
}
enum MintMode {
    Closed,
    VoucherOnly,
    Open
}

contract CryptoGangs is ERC721Enumerable, EIP712, Ownable {
    uint256 public maxItems;
    uint256 public batchCap;
    uint256 public tokenPrice;
    string _baseTokenURI;

    MintMode public mintMode = MintMode.Closed;
    address public voucherSigner;

    uint256 public devItemsMinted = 0;
    uint256 public totalMinted = 0;
    mapping(uint256 => uint256) public voucherBalance;

    uint256[] public specials;

    address[] public partnerWallets = [
        0x7Dc476c91aD1ADdC8dcf793D555CbCc1c52B5C57, // DrStned
        0x3330C63C919d995B277c2B51cCCC4ac2Ec9cb73d, // mingos
        0x25Ea84b38bd17946f063a72a46659875ad906B1f, // Eggy
        0x2C22a5f4fD64edd61fcb62059BeBA370af03BA32, // Archie
        0xFC85c6aC6dF5F8A3FBe27cB4c575Cef5F8F24BbD, // KryptoBean
        0xDdC06533a03bfa266F3da61Df338DA9BA3DAd74a, // Charity
        0x730498DBE66de4d58551F671A4fA42e8F7655E5d // Roadmap
    ];
    uint256[] public partnerShares = [
        2200000, // DrStned
        2200000, // mingos
        2075000, // Eggy
        800000, // Archie
        2075000, // KryptoBean
        450000, // Charity
        200000 // Roadmap
    ]; // Out of 10000000

    constructor(
        string memory baseURI,
        string memory tokenName,
        string memory tokenSymbol,
        uint256 _price,
        uint256 _maxItems
    ) ERC721(tokenName, tokenSymbol) EIP712(tokenName, "1") {
        _baseTokenURI = baseURI;
        tokenPrice = _price;
        maxItems = _maxItems;
        batchCap = _maxItems - 200;
    }

    // Mint items
    function mint(uint256 n) public payable {
        require(mintMode != MintMode.Closed, "Minting is closed");
        require(mintMode != MintMode.VoucherOnly, "You need a voucher to mint");
        require(n <= 30, "Too many items");
        require(msg.value >= tokenPrice * n, "Didn't send enough ETH");
        require(totalMinted + n <= maxItems, "Can't fulfill requested items");
        require(totalMinted + n <= batchCap, "Can't fulfill requested items");

        for (uint256 i = 0; i < n; i++) {
            totalMinted++;
            _safeMint(msg.sender, totalMinted);
        }
    }

    // Mint items using voucher
    function mintWithVoucher(uint256 n, Voucher calldata voucher)
        public
        payable
    {
        require(mintMode != MintMode.Closed, "Minting is closed");
        require(msg.value >= tokenPrice * n, "Didn't send enough ETH");
        require(totalMinted + n <= maxItems, "Can't fulfill requested items");
        require(
            voucherBalance[voucher.id] + n <= voucher.allowance,
            "Voucher doesn't have enough allowance"
        );
        require(verifyVoucher(voucher) == voucherSigner, "Invalid voucher");
        require(voucher.wallet == msg.sender, "This is not your voucher");

        for (uint256 i = 0; i < n; i++) {
            totalMinted++;
            _safeMint(msg.sender, totalMinted);
        }

        voucherBalance[voucher.id] += n;
    }

    // Mint n items to address (owner only);
    function devMint(address addr, uint256 n) external onlyOwner {
        require(totalMinted + n <= maxItems, "Can't fulfill requested items");
        for (uint256 i = 0; i < n; i++) {
            _safeMint(addr, totalMinted + 1);
            totalMinted++;
        }
        devItemsMinted += n;
    }

    // Mint 1 items to each address in an array (owner only);
    function devMintMultiple(address[] memory addr) external onlyOwner {
        require(
            totalMinted + addr.length <= maxItems,
            "Can't fulfill requested items"
        );
        for (uint256 i = 0; i < addr.length; i++) {
            _safeMint(addr[i], totalMinted + 1);
            totalMinted++;
        }
        devItemsMinted += addr.length;
    }

    // Mint an item and mark as special
    function devMintSpecial(address addr) external onlyOwner {
        require(totalMinted + 1 <= maxItems, "Can't fulfill requested items");
        _safeMint(addr, totalMinted + 1);
        specials.push(totalMinted + 1);
        totalMinted++;
        devItemsMinted += 1;
    }

    // Get the base URI (internal)
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // Set the token price
    function setTokenPrice(uint256 _price) external onlyOwner {
        tokenPrice = _price;
    }

    // Set the batch cap
    function setBatchCap(uint256 _cap) external onlyOwner {
        batchCap = _cap;
    }

    // Set the base URI
    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    // Get the base URI
    function getBaseURI() external view onlyOwner returns (string memory) {
        return _baseTokenURI;
    }

    // get all tokens owned by an address
    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    // withdraw balance
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    // Set mintmode
    function setMintMode(MintMode mode) external onlyOwner {
        mintMode = mode;
    }

    // Set voucher signer
    function setVoucherSigner(address addr) external onlyOwner {
        voucherSigner = addr;
    }

    // Get all special mints
    function getSpecials() external view returns (uint256[] memory) {
        return specials;
    }

    // distribute
    function distribute() public {
        // Distribute if called by the owner
        if (msg.sender == owner()) {
            _distribute();
            return;
        }

        // Distribute if called by one of the partners
        for (uint256 i = 0; i < partnerWallets.length; i++) {
            if (partnerWallets[i] == msg.sender) {
                _distribute();
                return;
            }
        }
    }

    // handles the actual distribution
    function _distribute() private {
        uint256 totalBalance = address(this).balance;
        for (uint256 i = 0; i < partnerWallets.length; i++) {
            payable(partnerWallets[i]).transfer(
                (totalBalance * partnerShares[i]) / 10000000
            );
        }
    }

    // get balance of partner
    function partnerBalance() external view returns (uint256) {
        for (uint256 i = 0; i < partnerWallets.length; i++) {
            if (partnerWallets[i] == msg.sender) {
                return (address(this).balance * partnerShares[i]) / 10000000;
            }
        }
        return 0;
    }

	// used for verification
    function hashVoucher(Voucher calldata voucher)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "Voucher(uint256 allowance,uint256 id,address wallet)"
                        ),
                        voucher.allowance,
                        voucher.id,
                        voucher.wallet
                    )
                )
            );
    }

	// verify voucher and extract signer address
    function verifyVoucher(Voucher calldata voucher) internal view returns (address) {
        bytes32 digest = hashVoucher(voucher);
        return ECDSA.recover(digest, voucher.signature);
    }
}