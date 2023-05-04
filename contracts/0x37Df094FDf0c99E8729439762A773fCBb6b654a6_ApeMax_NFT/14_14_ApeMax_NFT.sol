// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import 'base64-sol/base64.sol';

/*
    NFT version of ApeMax Token for credit card purchase
*/

interface ApeMax_Interface {
    function mint_apemax(
        address recipient,
        uint128 amount_payable,
        uint128 quantity,
        uint32 timestamp,
        uint8 currency_index,
        uint8 v, bytes32 r, bytes32 s
    ) external payable;

    function transfer(
        address recipient,
        uint256 amount
    ) external;
}

// contract ApeMax_NFT is ERC721Upgradeable, OwnableUpgradeable {
contract ApeMax_NFT is ERC721, Ownable {

    // ------- Global Vars -------
    ApeMax_Interface public apemax_token;
    uint32 public token_count;
    string public nft_image;

    mapping(uint32 => uint128) public token_id_to_balance;

    // ------- Init -------
    // function initialize(address apemax_contract_address, string memory image_url) public initializer {
    
        // __ERC721_init("ApeMax", "APEMAX");
        // __Ownable_init();

    constructor(address apemax_contract_address, string memory image_url) ERC721("ApeMax", "APEMAX") {
        apemax_token = ApeMax_Interface(apemax_contract_address);
        nft_image = image_url;
    }

    // ------- Presale -------
    function mint_apemax(
        address recipient,
        uint128 amount_payable,
        uint128 quantity,
        uint32 timestamp,
        uint8 currency_index,
        uint8 v, bytes32 r, bytes32 s
        )
        public payable
    {
        apemax_token.mint_apemax{value: msg.value}(address(this), amount_payable, quantity, timestamp, currency_index, v, r, s);
        _mint(recipient, token_count);
        token_id_to_balance[token_count] = quantity;
        token_count++;
    }

    // ------- Transfers -------
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public virtual override {
        require(ownerOf(tokenId) == msg.sender, "Only the owner of this NFT can transfer it");
        transfer(to, uint32(tokenId));
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        require(ownerOf(tokenId) == msg.sender, "Only the owner of this NFT can transfer it");
        transfer(to, uint32(tokenId));
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        require(ownerOf(tokenId) == msg.sender, "Only the owner of this NFT can transfer it");
        transfer(to, uint32(tokenId));
    }

    function transfer(address to, uint32 token_id) public {
        uint128 apemax_balance = token_id_to_balance[token_id];
        apemax_token.transfer(to, apemax_balance);
        _burn(uint256(token_id));
        delete token_id_to_balance[token_id];
    }

    // ------- Token URI -------
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory json = string(abi.encodePacked(
            '{"name":"',
            short_format_number(token_id_to_balance[uint32(tokenId)]),
            " $APEMAX",
            '", "description":"This NFT represents ApeMax tokens and has been designed to facilitate purchases using a credit card. To convert this NFT into actual ApeMax tokens, please transfer or export it to a custodial Ethereum wallet. Upon completing this process, the NFT will automatically convert into ApeMax tokens.", "image":"',
            nft_image,
            '"}'
        ));

        string memory base_64 = Base64.encode(bytes(json));

        return string(abi.encodePacked("data:application/json;base64,", base_64));
    }


    function update_image(string memory image_url) public onlyOwner {
        nft_image = image_url;
    }

    function to_fixed(uint256 value, uint256 precision) internal pure returns (string memory) {
        uint256 exponent = 10 ** precision;
        uint whole = value / exponent;
        uint decimals = value % exponent;

        if (decimals == 0) {
            return Strings.toString(whole);
        } else {
            return string(abi.encodePacked(
                Strings.toString(whole),
                ".",
                decimals < 10 ** (precision - 1) ? "0" : "",
                Strings.toString(decimals)
            ));
        }
    }

    function short_format_number(uint128 number) public pure returns (string memory) {
        if (number == 0) {
            return "0";
        }

        uint256 exponent = 0;
        uint256 base = 1000 * (10**18);

        while (number >= base) {
            number = number / 1000;
            exponent += 1;
        }

        string memory suffix;
        if (exponent == 1) {
            suffix = "K";
        } else if (exponent == 2) {
            suffix = "M";
        } else if (exponent == 3) {
            suffix = "B";
        } else if (exponent == 4) {
            suffix = "T";
        } else {
            return to_fixed(number / (10**16), 2);
        }

        return string(abi.encodePacked(to_fixed(number / (10**16), 2), suffix));
    }


}