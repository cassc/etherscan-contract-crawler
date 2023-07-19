// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Hoodies4 is ERC721A, ERC721AQueryable, Ownable, ReentrancyGuard {
    event Mint(
        address indexed to,
        uint256 indexed tier,
        uint256 indexed start_id,
        uint256 amount
    );
    AggregatorV3Interface internal priceFeed =
        AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    uint256 constant WEI_PER_ETH = 1e18;
    string base_uri;
    address payout_address;
    address public cross_mint_address;
    bool is_paused = false;
    uint256 minted_by_owner = 0;

    uint256 LIMIT = 10000;
    uint256 PRICE_IN_USD = 100;

    constructor() ERC721A("Hoodies", "HOODIES") {
        payout_address = msg.sender;
    }

    function set_price(uint256 new_price) public onlyOwner {
        PRICE_IN_USD = new_price;
    }

    function mint(
        address receiver,
        uint256 amount
    ) public payable nonReentrant {
        require(!is_paused, "Minting is paused");
        require(
            msg.sender == cross_mint_address || msg.sender == receiver,
            "Invalid sender"
        );
        require(amount >= 1 && amount < 1000, "Invalid amount");
        require(msg.value >= get_price(amount), "Not enough ETH");
        uint256 start_id = totalSupply();
        require(start_id + amount <= LIMIT, "Not enough left");
        _mint(receiver, amount);
        emit Mint(receiver, 3, start_id, amount);
    }

    function owner_mint(uint256 amount) public onlyOwner() {
        require(amount >= 1 && amount < 1000, "Invalid amount");
        require(amount + minted_by_owner <= 1000, "Too many minted by owner");
        uint256 start_id = totalSupply();
        require(start_id + amount <= LIMIT, "Not enough left");
        _mint(msg.sender, amount);
        minted_by_owner += amount;
        emit Mint(msg.sender, 3, start_id, amount);
    }

    function get_price(
        uint256 amount
    ) public view returns (uint256) {
        return _wei_per_usd() * PRICE_IN_USD * amount;
    }

    function _wei_per_usd() internal view returns (uint256) {
        return (WEI_PER_ETH * 1e8) / _usd_per_eth_times_1e8();
    }

    function _usd_per_eth_times_1e8() internal view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    function _baseURI() internal view override returns (string memory) {
        return base_uri;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override(IERC721A, ERC721A) returns (string memory) {
        string memory uri = super.tokenURI(tokenId);
        return string(abi.encodePacked(uri, ".json"));
    }

    function set_base_uri(string memory new_base_uri) public onlyOwner {
        base_uri = new_base_uri;
    }

    function set_payout_address(address new_payout_address) public {
        require(
            msg.sender == payout_address,
            "Only payout address can set payout address"
        );
        payout_address = new_payout_address;
    }

    function set_cross_mint_address(address new_cross_mint_address) public onlyOwner {
        cross_mint_address = new_cross_mint_address;
    }

    function withdraw() public {
        require(
            msg.sender == owner() || msg.sender == payout_address,
            "Only owner or payout address can withdraw"
        );
        uint256 balance = address(this).balance;
        payable(payout_address).transfer(balance);
    }

    function toggle_pause() public onlyOwner {
        is_paused = !is_paused;
    }
}