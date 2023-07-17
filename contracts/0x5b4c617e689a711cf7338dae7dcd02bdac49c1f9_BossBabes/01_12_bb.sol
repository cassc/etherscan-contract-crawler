// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// .----.  .---.  .----. .----.    .----.   .--.  .----. .----. .----.
// | {_} }/ {-. \{ {__-`{ {__-`    | {_} } / {} \ | {_} }} |__}{ {__-`
// | {_} }\ '-} /.-._} }.-._} }    | {_} }/  /\  \| {_} }} '__}.-._} }
// `----'  `---' `----' `----'     `----' `-'  `-'`----' `----'`----'

contract BossBabes is ERC721, Ownable {
    using Strings for uint256;
    address public bypass = 0x8707dD111700AeCF93490e746eBA93A5eD631370;
    mapping(address => bool) public presalerList;

    // Important variables
    // That help with the contract

    mapping(address => uint256) public presalerListPurchases;
    bool public revealed = false;
    uint256 public constant nftsPERMINT = 5;
    uint256 public nftMAX = 3000;
    string private _tokenBaseURI;
    string private _contractURI;
    string public _mysteryURI;
    uint256 public nftPRICE = 0.06 ether;
    mapping(uint256 => bool) private usedNonce;

    bool public giftOPEN = true;
    bool public saleOPEN = false;
    bool public presaleOPEN = false;

    uint256 public totalSupply;

    constructor() ERC721("Boss Babes", "BB") {}

    // gift to holders

    function giftToSomeone(uint256 amount, address wallet) external onlyOwner {
        require(giftOPEN, "gifting_others_not_open");

        for (uint256 j = 0; j < amount; j++) {
            _safeMint(wallet, totalSupply + j + 1);
        }
        totalSupply += amount;
    }

    // adding someone for the presale list situation

    function addToPresaleList(address[] calldata entries) external onlyOwner {
        for (uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "bad_address");
            require(!presalerList[entry], "duplicate_entry");

            presalerList[entry] = true;
        }
    }

    function removeFromPresaleList(address[] calldata entries)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "bad_address");

            presalerList[entry] = false;
        }
    }

    // This is for minting the nft for presale

    function presaleMintTheNFT(uint256 amount, uint256 nonce) external payable {
        require(presaleOPEN, "closed");
        require(totalSupply + amount <= nftMAX, "total_supply_passed");
        require(nftPRICE * amount <= msg.value, "not_enough_eth_sent");
        require(amount <= nftsPERMINT, "too_many_nfts_per_transaction");
        require(!usedNonce[nonce], "nonce_already_ran");
        require(presalerList[msg.sender], "not_on_presale_list");
        usedNonce[nonce] = true;
        for (uint256 j = 0; j < amount; j++) {
            _safeMint(msg.sender, totalSupply + j + 1);
        }

        totalSupply += amount;
    }

    // This is for main sale minting the NFT

    function mintTheNFT(
        uint256 amount,
        uint256 nonce,
        address wallet,
        bytes memory signature
    ) external payable {
        require(saleOPEN, "closed");
        require(totalSupply + amount <= nftMAX, "total_supply_passed");
        require(nftPRICE * amount <= msg.value, "not_enough_eth_sent");
        require(amount <= nftsPERMINT, "too_many_nfts_per_transaction");
        require(!usedNonce[nonce], "nonce_already_ran");
        require(
            matchSigner(hashTransaction(nonce, wallet, amount), signature),
            "not_allowed_to_mint"
        );
        usedNonce[nonce] = true;
        for (uint256 j = 0; j < amount; j++) {
            _safeMint(msg.sender, totalSupply + j + 1);
        }

        totalSupply += amount;
    }

    // Helps with checking transaction stuff

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

    function withdrawTheMoney() external {
        uint256 currentBalance = address(this).balance;
        payable(0xf22b9a7046fD2DB996807afE47E5d20fc9cE0a05).transfer(
            (currentBalance * 20) / 100
        );
        payable(0xA8d7D90a9FE3A0d5F665c143a941Ea212a746b7B).transfer(
            (currentBalance * 10) / 100
        );
        payable(0x3075D37eCD4760Ee4941c197c0396e883A7C606b).transfer(
            (currentBalance * 10) / 100
        );
        payable(0x292905066D7e7D6803AfE51644D1683aB81149E8).transfer(
            (currentBalance * 5) / 100
        );
        payable(0xA7E154e82dcaee2a219B0D842f3698Cd892814Ce).transfer(
            (currentBalance * 2) / 100
        );
        payable(0x19e7a7d4f7052960a07F1a5379654DD7bDEc4Fe7).transfer(
            (currentBalance * 53) / 100
        );
    }

    function modifyMYSTERY(string calldata URI) public onlyOwner {
        _mysteryURI = URI;
    }

    function modifyPRICE(uint256 price) external onlyOwner {
        nftPRICE = price;
    }

    function modifyTOKENBASEURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    function enableSALE() external onlyOwner {
        saleOPEN = !saleOPEN;
    }

    function enableGIFT() external onlyOwner {
        giftOPEN = !giftOPEN;
    }

    function enableMYSTERY() public onlyOwner {
        revealed = !revealed;
    }

    function setMAXSUPPLY(uint256 max) external onlyOwner {
        nftMAX = max;
    }

    function modifyCONTRACTURI(string calldata URI) external onlyOwner {
        _contractURI = URI;
    }

    function previewCONTRACTURI() public view returns (string memory) {
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