// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// dev is @elbrupt on telegram

contract CYBERUNNERS is ERC721, Ownable {
    using Strings for uint256;

    // test withdraw wallets
    address public verifiedSigner = 0xfA9500C2F2d397e95de8E67a0D78EeaC98340921;
    address private memberOne = 0xDcfe06271A89d454fF3302bAB78d564ad6952607; // art
    address private memberTwo = 0x983C5BC4C3Cfb1e615fc2C686BF996c0cc0532D3; // manage
    address private memberThree = 0x59AC63f2ce680CaDF37193CFed3D41C47F3d8c5E; // code
    address private memberFour = 0x713eeD92d42dF88AB85934E7156aCDC47b9968C4; // web

    uint256 public NFT_MAX = 2222;
    uint256 public NFT_PRICE = 0.07 ether;
    uint256 public constant NFTS_PER_MINT = 8;
    string private _contractURI;
    string private _tokenBaseURI;
    string public _mysteryURI;

    mapping(uint256 => bool) private usedNonce;

    bool public revealed;
    bool public saleLive = true;
    bool public giftLive = true;
    bool public burnLive;

    uint256 public totalSupply;
    uint256 public totalBurnedSupply;

    constructor() ERC721("CYBERUNNERS", "CYBER") {}

    function mintGiftAsOwner(uint256 tokenQuantity, address wallet)
        external
        onlyOwner
    {
        require(giftLive, "GIFTING_CLOSED");
        require(totalSupply < NFT_MAX, "OUT_OF_STOCK");
        require(totalSupply + tokenQuantity <= NFT_MAX, "EXCEED_STOCK");

        for (uint256 i = 0; i < tokenQuantity; i++) {
            _safeMint(wallet, totalSupply + i + 1);
        }

        totalSupply += tokenQuantity;
    }

    function mintGift(
        uint256 tokenQuantity,
        uint256 nonce,
        address wallet,
        bytes memory signature
    ) external {
        require(giftLive, "GIFTING_CLOSED");
        require(totalSupply < NFT_MAX, "OUT_OF_STOCK");
        require(totalSupply + tokenQuantity <= NFT_MAX, "EXCEED_PUBLIC");
        require(usedNonce[nonce] == false, "NONCE_ALREADY_USED");
        require(
            matchSigner(
                hashTransaction(nonce, wallet, tokenQuantity),
                signature
            ),
            "NOT_ALLOWED_TO_MINT"
        );
        usedNonce[nonce] = true;

        // gifts wallet input
        for (uint256 i = 0; i < tokenQuantity; i++) {
            _safeMint(wallet, totalSupply + i + 1);
        }

        totalSupply += tokenQuantity;
    }

    function mint(
        uint256 tokenQuantity,
        uint256 nonce,
        address wallet,
        bytes memory signature
    ) external payable {
        require(saleLive, "SALE_CLOSED");
        require(totalSupply < NFT_MAX, "OUT_OF_STOCK");
        require(totalSupply + tokenQuantity <= NFT_MAX, "EXCEED_STOCK");
        require(NFT_PRICE * tokenQuantity <= msg.value, "INSUFFICIENT_ETH");
        require(!usedNonce[nonce], "NONCE_ALREADY_USED");
        require(tokenQuantity <= NFTS_PER_MINT, "EXCEED_NFTS_PER_MINT");
        require(
            matchSigner(
                hashTransaction(nonce, wallet, tokenQuantity),
                signature
            ),
            "NOT_ALLOWED_TO_MINT"
        );
        usedNonce[nonce] = true;

        for (uint256 i = 0; i < tokenQuantity; i++) {
            _safeMint(msg.sender, totalSupply + i + 1);
        }

        totalSupply += tokenQuantity;
    }

    function hashTransaction(
        uint256 nonce,
        address wallet,
        uint256 tokenQuantity
    ) internal pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(nonce, wallet, tokenQuantity))
            )
        );
        return hash;
    }

    function matchSigner(bytes32 hash, bytes memory signature)
        internal
        view
        returns (bool)
    {
        return verifiedSigner == ECDSA.recover(hash, signature);
    }

    function withdraw() external {
        uint256 currentBalance = address(this).balance;
        payable(memberOne).transfer((currentBalance * 50) / 100);
        payable(memberTwo).transfer((currentBalance * 30) / 100);
        payable(memberThree).transfer((currentBalance * 10) / 100);
        payable(memberFour).transfer((currentBalance * 10) / 100);
    }

    function burnMint(uint256 _tokenId) public {
        require(burnLive == true, "BURN_IS_NOT_LIVE");
        require(ownerOf(_tokenId) == msg.sender, "TOKEN_TO_BURN_NOT_BY_OWNER");
        _burn(_tokenId);
        totalBurnedSupply = totalBurnedSupply + 1;
    }

    function burnMintAsOwner(uint256 _tokenId) public onlyOwner {
        require(burnLive == true, "BURN_IS_NOT_LIVE");
        _burn(_tokenId);
        totalBurnedSupply = totalBurnedSupply + 1;
    }

    function toggleBurnStatus() external onlyOwner {
        burnLive = !burnLive;
    }

    function toggleSaleStatus() external onlyOwner {
        saleLive = !saleLive;
    }

    function toggleSaleGiftStatus() external onlyOwner {
        giftLive = !giftLive;
    }

    function toggleMysteryURI() public onlyOwner {
        revealed = !revealed;
    }

    function setVerifiedSigner(address wallet) public onlyOwner {
        verifiedSigner = wallet;
    }

    function setMysteryURI(string calldata URI) public onlyOwner {
        _mysteryURI = URI;
    }

    function setPriceOfNFT(uint256 price) external onlyOwner {
        // 70000000000000000 = .07 eth
        NFT_PRICE = price;
    }

    function setNFTMax(uint256 max) external onlyOwner {
        NFT_MAX = max;
    }

    function setContractURI(string calldata URI) external onlyOwner {
        _contractURI = URI;
    }

    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "Cannot query non-existent token");

        if (revealed == false) {
            return _mysteryURI;
        }

        return
            string(
                abi.encodePacked(_tokenBaseURI, tokenId.toString(), ".json")
            );
    }
}