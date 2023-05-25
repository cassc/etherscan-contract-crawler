// SPDX-License-Identifier: MIT

/*

 _   _______ _      _       ___  ______ _____  ___  ______  _____ 
| | / /_   _| |    | |     / _ \ | ___ \  ___|/ _ \ | ___ \/  ___|
| |/ /  | | | |    | |    / /_\ \| |_/ / |__ / /_\ \| |_/ /\ `--. 
|    \  | | | |    | |    |  _  || ___ \  __||  _  ||    /  `--. \
| |\  \_| |_| |____| |____| | | || |_/ / |___| | | || |\ \ /\__/ /
\_| \_/\___/\_____/\_____/\_| |_/\____/\____/\_| |_/\_| \_|\____/ 

*/

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

contract KillaBears is ERC721Enumerable, EIP712, Ownable {
    uint256 public maxTokens = 3333;
    uint256 public cap = 3333;
    uint256 public tokenPrice = 80000000000000000;
    string _baseTokenURI;

    MintMode public mintMode = MintMode.Closed;
    address public voucherSigner;

    uint256 public devTokensMinted = 0;
    mapping(uint256 => uint256) public voucherBalance;

    address[] public teamWallets = [
        0x07b5c013fEbEFA0d810474612A826411EcA18931, // Kickrrr
        0xA1E5d623DE25F026d11e312933d3c6d882282568, // Memo
        0x5Bd2010585E45172c25A1C9210776221Ada101AB, // KB
        0x6d53C339D2F0Ef9698E77ff5Bc55961BD53e2C5b // BeNFT
    ];

    uint256[] public teamShares = [
        25, // Kickrrr
        25, // Memo
        25, // KB
        10 // BeNFT
    ]; // Rest goes to owner

    constructor(
        string memory baseURI,
        string memory tokenName,
        string memory tokenSymbol
    ) ERC721(tokenName, tokenSymbol) EIP712(tokenName, "1") {
        _baseTokenURI = baseURI;
    }

    // Mint Tokens
    function mint(uint256 n) public payable {
        require(mintMode == MintMode.Open, "Public mint is closed");
        require(n <= 20, "Too many tokens");
        require(msg.value >= tokenPrice * n, "Didn't send enough ETH");
        require(
            totalSupply() + n <= maxTokens,
            "Can't fulfill requested tokens"
        );
        require(totalSupply() + n <= cap, "Can't fulfill requested tokens");

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
        require(totalSupply() + n <= cap, "Can't fulfill requested tokens");
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
    function airdrop(address[] memory addr) external onlyOwner {
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

    // Set the cap
    function setCap(uint256 _cap) external onlyOwner {
        cap = _cap;
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

    // Distribute
    function distribute() public {
        // Distribute if called by the owner
        if (msg.sender == owner()) {
            _distribute();
            return;
        }

        // Distribute if called by one of the team members
        for (uint256 i = 0; i < teamWallets.length; i++) {
            if (teamWallets[i] == msg.sender) {
                _distribute();
                return;
            }
        }
    }

    // Handles the actual distribution
    function _distribute() private {
        // Distribute funds to team
        uint256 totalBalance = address(this).balance;
        for (uint256 i = 0; i < teamWallets.length; i++) {
            payable(teamWallets[i]).transfer(
                (totalBalance * teamShares[i]) / 100
            );
        }

        // Send leftovers to owner
        if (address(this).balance > 0) {
            payable(owner()).transfer(address(this).balance);
        }
    }

    // Withdraw all
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    // Withdraw portion
    function withdrawPortion(uint256 portion) external onlyOwner {
        payable(msg.sender).transfer(portion);
    }

    // Set mintmode
    function setMintMode(MintMode _mode) external onlyOwner {
        mintMode = _mode;
    }

    // Set voucher signer
    function setVoucherSigner(address _signer) external onlyOwner {
        voucherSigner = _signer;
    }

    // Start presale
    function startPresale(
        uint256 _price,
        address _signer,
        uint256 _cap
    ) external onlyOwner {
        tokenPrice = _price;
        voucherSigner = _signer;
        cap = _cap;
        mintMode = MintMode.VoucherOnly;
    }

    // End presale
    function endPresale() external onlyOwner {
        voucherSigner = address(0x0);
        mintMode = MintMode.Closed;
    }

    // Start public sale
    function startPublicSale(uint256 _price, uint256 _cap) external onlyOwner {
        tokenPrice = _price;
        cap = _cap;
        mintMode = MintMode.Open;
    }

    // Used for voucher verification
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

    // Verify voucher and extract signer address
    function verifyVoucher(Voucher calldata voucher)
        public
        view
        returns (address)
    {
        bytes32 digest = hashVoucher(voucher);
        return ECDSA.recover(digest, voucher.signature);
    }
}