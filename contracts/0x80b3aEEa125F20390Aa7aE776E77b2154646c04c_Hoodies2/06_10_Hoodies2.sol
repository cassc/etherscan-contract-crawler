// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Hoodies2 is ERC721A, ERC721AQueryable, Ownable, ReentrancyGuard {
    event Mint(
        address indexed to,
        uint256 indexed tier,
        uint256 indexed start_id,
        uint256 amount
    );
    AggregatorV3Interface internal priceFeed =
        AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    uint256 constant WEI_PER_ETH = 1e18;
    bytes32 whitelist;
    string base_uri;
    address payout_address;
    mapping(bytes32 => uint256) minted;
    mapping(uint256 => uint256) minted_by_tier;
    address public cross_mint_address;

    uint256[] TIER_LIMITS = [0, 0, 0, 2000, 500, 100];
    uint256[] TIER_PRICES_IN_USD = [0, 0, 0, 150, 300, 500];

    constructor() ERC721A("Hoodies", "HOODIES") {
        payout_address = msg.sender;
    }

    function mint(
        address receiver,
        bytes32[] calldata proof,
        uint256 tier,
        uint256 amount,
        uint256 max_amount
    ) public payable nonReentrant {
        require(
            msg.sender == cross_mint_address || msg.sender == receiver,
            "Invalid sender"
        );
        require(tier >= 3 && tier <= 5, "Invalid tier");
        require(amount >= 1 && amount < 1000, "Invalid amount");
        _ensure_mint_limits(receiver, proof, tier, amount, max_amount);
        require(msg.value >= get_price(tier, amount), "Not enough ETH");
        _mint(receiver, amount);
        uint256 start_id = totalSupply();
        emit Mint(receiver, tier, start_id, amount);
    }

    function get_price(
        uint256 tier,
        uint256 amount
    ) public view returns (uint256) {
        uint256 price_in_usd = TIER_PRICES_IN_USD[tier];
        return _wei_per_usd() * price_in_usd * amount;
    }

    function _ensure_mint_limits(
        address receiver,
        bytes32[] calldata proof,
        uint256 tier,
        uint256 amount,
        uint256 max_amount
    ) internal {
        bytes32 minted_index = keccak256(abi.encode(receiver, tier));
        require(
            _is_on_whitelist(receiver, proof, tier, max_amount),
            "Not on whitelist"
        );
        uint256 minted_by_wallet_from_tier = minted[minted_index];
        require(
            minted_by_wallet_from_tier + amount <= max_amount,
            "Would surpass your mint limit"
        );
        require(
            minted_by_tier[tier] + amount <= TIER_LIMITS[tier],
            "Would surpass global mint limit"
        );
        minted[minted_index] += amount;
        minted_by_tier[tier] += amount;
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

    function set_whitelist(bytes32 new_whitelist) public onlyOwner {
        whitelist = new_whitelist;
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

    function _is_on_whitelist(
        address receiver,
        bytes32[] calldata proof,
        uint256 tier,
        uint256 max_amount
    ) internal view returns (bool) {
        if (whitelist == 0) {
            return true;
        }
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(receiver, tier, max_amount)))
        );
        return MerkleProof.verify(proof, whitelist, leaf);
    }
}