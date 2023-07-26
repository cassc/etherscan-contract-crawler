// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFT4096 is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;
    Counters.Counter private _givedAmountTracker;

    string private _baseTokenURI;
    uint256 public saleStartTimestamp = 1634248800;
    uint256 public maxTokenAmount = 8192;
    uint256 public maxGiveableAmount = 512;

    bool public active = true;

    mapping(address => bool) private mintedFreeAddresses;
    mapping(address => bool) private mintedFreeBonusAddresses;

    // mapping(address => bool) private mintedFreeBlueAddresses;

    constructor() ERC721("4096", "4096") {
        setBaseURI("ipfs://QmNQk2FRspKm1DwWEUPGa4ytp9v61chPCHjD4kefNxj3Gm/");
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function contractURI() external pure returns (string memory) {
        return "https://www.4096nfts.io/api/contract_metadata";
    }

    function setActive(bool state) external onlyOwner {
        active = state;
    }

    function mint_free() external {
        _canMint(1);
        require(canMintFree(msg.sender), "Already Minted Free");
        mint(msg.sender);
        mintedFreeAddresses[msg.sender] = true;
    }

    function mint_bonus() external {
        _canMint(1);
        require(canMintFreeBonus(msg.sender), "Already Minted Free Bonus");
        mint(msg.sender);
        mintedFreeBonusAddresses[msg.sender] = true;
    }

    // function mint_free_bluechip() external {
    //     _canMint(1);
    //     require(
    //         mintedFreeBlueAddresses[msg.sender] == false,
    //         "Already Used Offer"
    //     );
    //     _mint(msg.sender);
    //     mintedFreeBlueAddresses[msg.sender] = true;
    // }

    function buy(uint256 amount) external payable {
        _canMint(amount);
        require(
            msg.value >= amount * 80000000000000000, //amount * 0.08 eth
            "Not Enough Ether Sent "
        );
        for (uint256 i = 0; i < amount; i++) {
            mint(msg.sender);
        }
        payable(owner()).transfer(msg.value);
    }

    function giveaway(address[] calldata receivers, uint256 amount)
        external
        onlyOwner
    {
        uint256 arrayLength = receivers.length;
        _canMint(amount * arrayLength);
        require(
            arrayLength * amount <=
                maxGiveableAmount - _givedAmountTracker.current(),
            "Not enough left to give"
        );
        for (uint256 i = 0; i < arrayLength; i++) {
            for (uint256 j = 0; j < amount; j++) {
                mint(receivers[i]);
                _givedAmountTracker.increment();
            }
        }
    }

    function _canMint(uint256 amount) internal view {
        require(active, "Contract is inactive");
        require(
            block.timestamp >= saleStartTimestamp,
            "Sale has not started yet"
        );
        require(
            amount <= maxTokenAmount - _tokenIdTracker.current(),
            "Not enough left"
        );
    }

    function amountLeft() public view returns (uint256) {
        return maxTokenAmount - _tokenIdTracker.current();
    }

    function canMintFree(address account) public view returns (bool) {
        return mintedFreeAddresses[account] == false;
    }

    function canMintFreeBonus(address account) public view returns (bool) {
        return mintedFreeBonusAddresses[account] == false;
    }

    function mint(address to) internal {
        _tokenIdTracker.increment();
        _mint(to, _tokenIdTracker.current());
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
}