// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract SADBOYZ is ERC721, Ownable {
    using Strings for uint256;

    address public signer = 0x1A4F425a9CC14D804a914091896D3048659aC422;
    address private wallet1 = 0x667b439839d1c3185199Fddb786ec0e6e355f443;
    address private wallet2 = 0x8fA1674824e49C3486e0da0cF676592a06e51643;
    address private wallet3 = 0x713eeD92d42dF88AB85934E7156aCDC47b9968C4;
    address private wallet4 = 0xE9583749652dbCb039F2FeA69A4ac7f5E143E063;
    address private wallet5 = 0xc3d89B91C5a019c768c3C00BcBE62f7faE52870B;
    address private wallet6 = 0x7810509E4C33c397BC64CE025d0B25cD807836a9; // 2.5%
    uint256 public nftSupply = 7777;
    uint256 public nftPrice = 0.11 ether;
    uint256 public maxNftPerBuy = 10;
    bool public revealed;
    bool public saleLive = true;
    bool public giftLive = true;
    bool public burnLive;
    string private _contractURI;
    string private _tokenBaseURI;
    string private _mysteryURI =
        "https://gateway.pinata.cloud/ipfs/QmSXUb1PDpWfo5fQDsj21JJeRjR4rwmgVV99KZv9er4woy/1.json";
    uint256 public totalSupply;
    uint256 public totalBurnedSupply;
    mapping(uint256 => bool) private usedNonce;

    constructor() ERC721("Sadboyz", "SADBOYZ") {}

    function mintGiftOwner(uint256 tokenQuantity, address wallet)
        external
        onlyOwner
    {
        require(giftLive, "Gifting closed");
        require(totalSupply + tokenQuantity <= nftSupply, "Exceed NFT supply");
        for (uint256 i = 0; i < tokenQuantity; i++) {
            _safeMint(wallet, totalSupply + i + 1);
        }
        totalSupply += tokenQuantity;
    }

    function mintGiftUser(
        uint256 tokenQuantity,
        uint256 nonce,
        address wallet,
        bytes memory signature
    ) external {
        require(giftLive, "Gifting Closed");
        require(totalSupply + tokenQuantity <= nftSupply, "Exceed NFT supply");
        require(usedNonce[nonce] == false, "Nonce Used");
        require(
            matchSigner(
                hashTransaction(nonce, wallet, tokenQuantity),
                signature
            ),
            "Not allowed to mint"
        );
        usedNonce[nonce] = true;
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
        require(saleLive, "Sale is closed");
        require(nftPrice * tokenQuantity <= msg.value, "Wrong price");
        require(totalSupply + tokenQuantity <= nftSupply, "Exceed NFT supply");
        require(tokenQuantity <= maxNftPerBuy, "Exceed max to mint");
        require(!usedNonce[nonce], "Nonce used");
        require(
            matchSigner(
                hashTransaction(nonce, wallet, tokenQuantity),
                signature
            ),
            "Not allowed to mint"
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
        return signer == ECDSA.recover(hash, signature);
    }

    function withdraw() external {
        uint256 currentBalance = address(this).balance;
        payable(wallet1).transfer((currentBalance * 195) / 1000);
        payable(wallet2).transfer((currentBalance * 195) / 1000);
        payable(wallet3).transfer((currentBalance * 195) / 1000);
        payable(wallet4).transfer((currentBalance * 195) / 1000);
        payable(wallet5).transfer((currentBalance * 195) / 1000);
        payable(wallet6).transfer((currentBalance * 25) / 1000);
    }

    function burnMintUser(uint256 _tokenId) public {
        require(burnLive == true, "Burn is not live");
        require(ownerOf(_tokenId) == msg.sender, "Owner is not burning");
        _burn(_tokenId);
        totalBurnedSupply = totalBurnedSupply + 1;
    }

    function burnMintOwner(uint256 _tokenId) public onlyOwner {
        require(burnLive == true, "Burn is not live");
        _burn(_tokenId);
        totalBurnedSupply = totalBurnedSupply + 1;
    }

    function toggleBurnStatus() external onlyOwner {
        burnLive = !burnLive;
    }

    function toggleSaleGiftStatus() external onlyOwner {
        giftLive = !giftLive;
    }

    function toggleMysteryUri() public onlyOwner {
        revealed = !revealed;
    }

    function toggleSaleStatus() external onlyOwner {
        saleLive = !saleLive;
    }

    function setSigner(address wallet) public onlyOwner {
        signer = wallet;
    }

    function setMaxNftPerBuy(uint256 maxPer) external onlyOwner {
        maxNftPerBuy = maxPer;
    }

    function setPriceOfNft(uint256 price) external onlyOwner {
        nftPrice = price;
    }

    function setMysteryUri(string calldata URI) public onlyOwner {
        _mysteryURI = URI;
    }

    function setTotalSupply(uint256 max) external onlyOwner {
        nftSupply = max;
    }

    function setBaseUri(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    function setContractUri(string calldata URI) external onlyOwner {
        _contractURI = URI;
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