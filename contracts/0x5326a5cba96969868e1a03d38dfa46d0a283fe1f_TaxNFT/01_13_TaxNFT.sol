// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//    __    __  ________  ________        ________                          ______             __        __
//   /  \  /  |/        |/        |      /        |                        /      \           /  |      /  |
//   $$  \ $$ |$$$$$$$$/ $$$$$$$$/       $$$$$$$$/______   __    __       /$$$$$$  | __    __ $$/   ____$$ |  ______
//   $$$  \$$ |$$ |__       $$ |            $$ | /      \ /  \  /  |      $$ | _$$/ /  |  /  |/  | /    $$ | /      \
//   $$$$  $$ |$$    |      $$ |            $$ | $$$$$$  |$$  \/$$/       $$ |/    |$$ |  $$ |$$ |/$$$$$$$ |/$$$$$$  |
//   $$ $$ $$ |$$$$$/       $$ |            $$ | /    $$ | $$  $$<        $$ |$$$$ |$$ |  $$ |$$ |$$ |  $$ |$$    $$ |
//   $$ |$$$$ |$$ |         $$ |            $$ |/$$$$$$$ | /$$$$  \       $$ \__$$ |$$ \__$$ |$$ |$$ \__$$ |$$$$$$$$/
//   $$ | $$$ |$$ |         $$ |            $$ |$$    $$ |/$$/ $$  |      $$    $$/ $$    $$/ $$ |$$    $$ |$$       |
//   $$/   $$/ $$/          $$/             $$/  $$$$$$$/ $$/   $$/        $$$$$$/   $$$$$$/  $$/  $$$$$$$/  $$$$$$$/

// Credits
// Created by: Jacob T. Martin, Esq. aka @TheNFTAttorney
// Produced by: @0xKilroy
// Smart contract and full-stack work: @backseats_eth
// Web design and overall marketing strategy: @FutureProofxyz & @plaidshaman
// Guide Contributors: Alex Roytenburg, CPA, Charles Kolstadt, Esq., Andrew Gordon, Esq.
// Software partner: ZenLedger

contract TaxNFT is ERC721Enumerable, Ownable {

    // Public Properties

    // A boolean for if minting is paused
    bool public mintingPaused = true;

    // Our withdraw address
    address public withdrawAddress;

    // Constants and Pricing
    uint256 constant PRICE = 0.08 ether;
    uint256 constant MAX_MINT = 21;

    // A mapping of the NFT ID to the address who claimed their ZenLedger code.
    // Used to verify that codes aren't reused.
    mapping(uint => address) public claimedCodes;

    // The base token URI for OpenSea to read JSON data from
    string _baseTokenURI;

    // Private Properties

    // An AllowList for the devs to mint for giveaways, promos, or other purposes.
    mapping(address => bool) private teamAllowList;

    // Events

    event Minted(address indexed _who, uint8 indexed _amount);
    event PromoMinted(address indexed _promoWho, uint8 indexed _amount);
    event CodeClaimed(address indexed _who, uint256 indexed _tokenId);
    event FundsWithdrawn(uint256 indexed _amount);
    event FallbackHit(address indexed _who, uint256 indexed _amount);

    // Modifier

    modifier onlyAllowListAndValidCount(uint256 _tokenQuantity) {
        require(teamAllowList[msg.sender] == true, "Not allowed");
        require(_tokenQuantity > 0 && _tokenQuantity < 256, "Mint 1-255");
        _;
    }

    // Constructor

    constructor(string memory baseURI) ERC721("NFT Tax Guide", "NFTAX") {
        setBaseURI(baseURI);
    }

    // Public Functions

    // Allows you to mint 1-20 NFT Tax Guides per transaction
    function mint(uint256 _tokenQuantity) external payable {
        require(!mintingPaused, "Minting paused");
        require(_tokenQuantity > 0 && _tokenQuantity < MAX_MINT, "Mint 1-20");
        require(PRICE * _tokenQuantity <= msg.value, "Insufficient ETH");

        for(uint256 i = 0; i < _tokenQuantity; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }
        emit Minted(msg.sender, uint8(_tokenQuantity));
    }

    // Allows the owner of the NFT to claim a ZenLedger coupon code for their software for the 2021 tax guide. Once an NFT ID redeems, a different holder trying to redeem will revert.
    function claimCode(uint _tokenId) external {
        require(ownerOf(_tokenId) == msg.sender, "Not your token");
        require(claimedCodes[_tokenId] == address(0), "tokenId already claimed");
        claimedCodes[_tokenId] = msg.sender;
        emit CodeClaimed(msg.sender, _tokenId);
    }

    // Returns all the IDs for this contract the wallet owns.
    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 count = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](count);
        for(uint256 i; i < count; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    // Internal Function

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // AllowList Functions

    // Allows the team to mint up to 255 at at time for giveaways, promos, or other purposes. 255 limit because that's the upperbound of the uint8 used in the event and we probably don't need to mint more than that at a time anyway.
    function devMint(uint256 _tokenQuantity) external onlyAllowListAndValidCount(_tokenQuantity) {
        for(uint256 i = 0; i < _tokenQuantity; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }
        emit Minted(msg.sender, uint8(_tokenQuantity));
    }

    function promoMint(uint256 _tokenQuantity, address _to) external onlyAllowListAndValidCount(_tokenQuantity) {
        for(uint256 i = 0; i < _tokenQuantity; i++) {
            _safeMint(_to, totalSupply() + 1);
        }
        emit PromoMinted(_to, uint8(_tokenQuantity));
    }

    // Ownable Functions

    function updateAllowList(address[] memory _addresses) external onlyOwner {
        for (uint i=0; i < _addresses.length; i++) {
            teamAllowList[_addresses[i]] = true;
        }
    }

    // Updates the withdraw address, for safety.
    function setWithdrawAddress(address _address) external onlyOwner {
        withdrawAddress = _address;
    }

    // Pauses and unpauses minting
    function setMintingPaused(bool _mintingPaused) external onlyOwner {
        mintingPaused = _mintingPaused;
    }

    // Updates the owner, for safety.
    function updateOwner(address _address) external onlyOwner {
        super.transferOwnership(_address);
    }

    // Sets the base token URI
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    // Withdraw

    // Withdraws the balance of the contract to the team's wallet
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(payable(withdrawAddress).send(balance));
        emit FundsWithdrawn(balance);
    }

    // A fallback function in case someone sends ETH to the contract
    receive() external payable {
        emit FallbackHit(msg.sender, msg.value);
    }

}