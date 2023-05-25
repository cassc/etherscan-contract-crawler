// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract BoredBigfootBillionaires is ERC721, Ownable {
    using Strings for uint256;

    // Change these
    address public verifiedSigner = 0xF41D419b73AC92f0f2C2135e798879CE9AB24B63;
    address private memberOne = 0xceEC829845c7a4c042d835952799328D3515a3bF;
    address private memberTwo = 0xfb3b14ECd84B52d9376bD12C1D1fB73562bD85DF;
    address private memberThree = 0xc7F1B6FC1675621aE1d03B8237C07956e6Df2CF7;
    address private memberFour = 0xF41D419b73AC92f0f2C2135e798879CE9AB24B63;
    uint256 public constant NFT_MAX = 10000;
    uint256 public NFT_PRICE = 0.07 ether;
    uint256 public constant NFTS_PER_MINT = 10;
    string private _contractURI =
        "https://gateway.pinata.cloud/ipfs/QmchjF8VkYP62eneBr5y3fLoVK4ov9LpAKKcPLKZ3o3BnX/";
    string private _tokenBaseURI =
        "https://gateway.pinata.cloud/ipfs/QmchjF8VkYP62eneBr5y3fLoVK4ov9LpAKKcPLKZ3o3BnX/";
    string public _mysteryURI =
        "https://gateway.pinata.cloud/ipfs/QmXu4SkW5pxAf7LvMbtUodJJTwrCCUsuHs6DuWVqKZFa3U/1.json";
    // end of change

    mapping(uint256 => bool) private usedNonce;

    bool public revealed;
    bool public saleLive;
    bool public giftLive;

    uint256 public totalSupply;

    constructor() ERC721("Bored Bigfoot Billionaires", "BFOOTS") {}

    function mintGift(uint256 tokenQuantity, address wallet)
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
            matchSigner(hashTransaction(nonce, wallet), signature),
            "NOT_ALLOWED_TO_MINT"
        );
        usedNonce[nonce] = true;

        for (uint256 i = 0; i < tokenQuantity; i++) {
            _safeMint(msg.sender, totalSupply + i + 1);
        }

        totalSupply += tokenQuantity;
    }

    function hashTransaction(uint256 nonce, address wallet)
        internal
        pure
        returns (bytes32)
    {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(nonce, wallet))
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
        payable(memberOne).transfer((currentBalance * 445) / 1000);
        payable(memberTwo).transfer((currentBalance * 215) / 1000);
        payable(memberThree).transfer((currentBalance * 180) / 1000);
        payable(memberFour).transfer((currentBalance * 160) / 1000);
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

    function setMysteryURI(string calldata URI) public onlyOwner {
        _mysteryURI = URI;
    }

    function setPriceOfNFT(uint256 price) external onlyOwner {
        // 70000000000000000 = .07 eth
        NFT_PRICE = price;
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