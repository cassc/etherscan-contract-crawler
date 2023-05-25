// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// imports

import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// for all the
// golfers
// out there

contract Bettinardi is ERC721, Ownable {
    using Strings for uint256;

    bool public revealed = false;
    uint256 public constant per_mint_max_nft = 5;
    uint256 public max_nft = 777;

    uint256 public price_nft = 0.2 ether;
    mapping(uint256 => bool) private usedNonce;
    address public bypass = 0xE3ab0D7eec24FA0D08a8b0E6c5C61BE5aaD00D1C;
    mapping(address => bool) public presalerList;
    uint256 public totalSupply;

    string private _tokenBaseURI;
    string private _contractURI;
    string public _mysteryURI;
    bool public gift_gate = false;
    bool public sale_gate = false;
    bool public presale_gate = false;
    mapping(address => uint256) public presalerListPurchases;

    constructor() ERC721("BETTINARDI", "BETT") {}

    function gift(uint256 amount, address wallet) external onlyOwner {
        require(gift_gate, "Gift Not Open");

        for (uint256 j = 0; j < amount; j++) {
            _safeMint(wallet, totalSupply + j + 1);
        }
        totalSupply += amount;
    }

    function regularMint(
        uint256 amount,
        uint256 nonce,
        address wallet,
        bytes memory signature
    ) external payable {
        require(sale_gate, "Closed");
        require(totalSupply + amount <= max_nft, "Max Supply");
        require(price_nft * amount <= msg.value, "Eth Amount Invalid");
        require(amount <= per_mint_max_nft, "Max NFTs To Buy Exceeded");
        require(!usedNonce[nonce], "Nonce Ran");
        require(
            matchSigner(hashTransaction(nonce, wallet, amount), signature),
            "Bypass Didnt Work"
        );
        usedNonce[nonce] = true;
        for (uint256 j = 0; j < amount; j++) {
            _safeMint(msg.sender, totalSupply + j + 1);
        }

        totalSupply += amount;
    }

    function presaleMint(uint256 amount, uint256 nonce) external payable {
        require(presale_gate, "closed");
        require(totalSupply + amount <= max_nft, "Supply Overflow");
        require(price_nft * amount <= msg.value, "Eth Error");
        require(presalerList[msg.sender], "Not On Presale List");
        usedNonce[nonce] = true;
        for (uint256 j = 0; j < amount; j++) {
            _safeMint(msg.sender, totalSupply + j + 1);
        }

        totalSupply += amount;
    }

    function addPresale(address[] calldata entries) external onlyOwner {
        for (uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "Require Address");
            require(!presalerList[entry], "Not On List");

            presalerList[entry] = true;
        }
    }

    function hashTransaction(
        uint256 nonce,
        address wallet,
        uint256 amount
    ) internal pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(nonce, wallet, amount))
            )
        );

        return hash;
    }

    function matchSigner(bytes32 hash, bytes memory signature)
        internal
        view
        returns (bool)
    {
        return bypass == ECDSA.recover(hash, signature);
    }

    function editGift() external onlyOwner {
        gift_gate = !gift_gate;
    }

    function editMystery() public onlyOwner {
        revealed = !revealed;
    }

    function editMysteryUri(string calldata URI) public onlyOwner {
        _mysteryURI = URI;
    }

    function editPriceNft(uint256 price) external onlyOwner {
        price_nft = price;
    }

    function setMaxSupply(uint256 max) external onlyOwner {
        max_nft = max;
    }

    function previewContract() public view returns (string memory) {
        return _contractURI;
    }

    function modifyContractUri(string calldata URI) external onlyOwner {
        _contractURI = URI;
    }

    function editSaleGate() external onlyOwner {
        sale_gate = !sale_gate;
    }

    function editToken(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    function withdrawTheMoney() external {
        uint256 currentBalance = address(this).balance;
        payable(0x84e8158D31A1051f823Df0da76167a976fBAaAE5).transfer(
            (currentBalance * 8500) / 10000
        );
        payable(0x435e0191177Bd65B4c2204Fc25816D63646CCdB7).transfer(
            (currentBalance * 825) / 10000
        );
        payable(0x01e7ac0f16009b0d968e63Cda02eB5cC5a8303Cc).transfer(
            (currentBalance * 675) / 10000
        );
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