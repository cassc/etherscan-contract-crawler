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

contract ShibaTitans is ERC721Enumerable, EIP712, Ownable {
    uint256 public maxTokens;
    uint256 public batchCap;
    uint256 public tokenPrice;
    string _baseTokenURI;

    MintMode public mintMode = MintMode.Closed;
    address public voucherSigner;

    uint256 public devTokensMinted = 0;
    mapping(uint256 => uint256) public voucherBalance;

    constructor(
        string memory baseURI,
        string memory tokenName,
        string memory tokenSymbol,
        uint256 _price,
        uint256 _maxTokens
    ) ERC721(tokenName, tokenSymbol) EIP712(tokenName, "1") {
        _baseTokenURI = baseURI;
        tokenPrice = _price;
        maxTokens = _maxTokens;
        batchCap = _maxTokens;
    }

    // Mint Tokens
    function mint(uint256 n) public payable {
        require(mintMode == MintMode.Open, "Public mint is closed");
        require(n <= 7, "Too many tokens");
        require(msg.value >= tokenPrice * n, "Didn't send enough ETH");
        require(
            totalSupply() + n <= maxTokens,
            "Can't fulfill requested tokens"
        );
        require(
            totalSupply() + n <= batchCap,
            "Can't fulfill requested tokens"
        );

        for (uint256 i = 0; i < n; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    // Mint tokens using voucher
    function mintWithVoucher(uint256 n, Voucher calldata voucher)
        public
        payable
    {
        require(mintMode != MintMode.Closed, "Minting is closed");
        require(msg.value >= tokenPrice * n, "Didn't send enough ETH");
        require(
            totalSupply() + n <= maxTokens,
            "Can't fulfill requested tokens"
        );
        require(
            voucherBalance[voucher.id] + n <= voucher.allowance,
            "Voucher doesn't have enough allowance"
        );
        require(verifyVoucher(voucher) == voucherSigner, "Invalid voucher");
        require(voucher.wallet == msg.sender, "This is not your voucher");

        for (uint256 i = 0; i < n; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }

        voucherBalance[voucher.id] += n;
    }

    // Mint 1 token to each address in an array (owner only);
    function send(address[] memory addr) external onlyOwner {
        require(
            totalSupply() + addr.length <= maxTokens,
            "Can't fulfill requested tokens"
        );
        for (uint256 i = 0; i < addr.length; i++) {
            _safeMint(addr[i], totalSupply() + 1);
        }
        devTokensMinted += addr.length;
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
    function setVoucherSigner(address signer) external onlyOwner {
        voucherSigner = signer;
    }

    // Start presale
    function startPresale(uint256 price, address signer) external onlyOwner {
        tokenPrice = price;
        voucherSigner = signer;
        mintMode = MintMode.VoucherOnly;
    }

    // End presale
    function endPresale() external onlyOwner {
        voucherSigner = address(0x0);
        mintMode = MintMode.Closed;
    }

    // Start public sale
    function startPublicSale(uint256 price) external onlyOwner {
        tokenPrice = price;
        mintMode = MintMode.Open;
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
    function verifyVoucher(Voucher calldata voucher)
        internal
        view
        returns (address)
    {
        bytes32 digest = hashVoucher(voucher);
        return ECDSA.recover(digest, voucher.signature);
    }
}