// deployed to 0x74b219d1805460B705f4f01C839a954a530B184D

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract SplootsNFT is ERC721Enumerable, Ownable, Pausable {
    // 500 basis points = 5% set up for openSea seconday market
    uint256 public constant ROYALTY_PERCENTAGE = 500;

    // whitelist
    mapping(address => bool) public whitelist;
    // Tracks if a whitelisted address has claimed their NFT
    mapping(address => bool) public hasClaimed;

    // mint base price
    uint256 public mintPrice;
    // current number of mints
    uint256 public totalMinted;
    // maximum number of mints in collection
    uint256 public maxSupply;
    // amount of NFTs wallet can own. set to 1
    uint256 public maxPerWallet;
    // determined by owner when users can mint
    bool public PublicMintEnabled;
    // determines url for opensea to see where images are located
    string internal baseTokenUri;
    // withdrawal wallet
    address payable public withdrawWallet;
    // tracks mints to wallets and how many NFTs wallets have minted
    mapping(address => uint256) public walletMints;

    constructor() payable ERC721("SplootsNFT", "SPLT") {
        // free mint
        mintPrice = 0.00000 ether;
        totalMinted = 0;
        maxSupply = 50;
        maxPerWallet = 1;
        // set withdraw wallet address
        // set for sepolia network
        withdrawWallet = payable(0x9f274EbDCfA538eD275F6098213c61dF0B39c80c);

        // Set the baseTokenUri to the IPFS gateway URL or base URL where the metadata JSON files can be accessed
        baseTokenUri = "https://ipfs.io/ipfs/Qmdx3qc4t8GYMh5nAQNowoUUBeAnreN2hzgPVkGt6caAac/";
    }

    // Allows owner/ deployer to setPublicMintEnabled, allowing minting
    function setPublicMintEnabled(bool PublicMintEnabled_) external onlyOwner {
        PublicMintEnabled = PublicMintEnabled_;
    }

    // Sets url where basetoken images are located
    function setBaseTokenUri(string calldata baseTokenUri_) external onlyOwner {
        baseTokenUri = baseTokenUri_;
    }

    // Function that opensea calls to grab the images
    // takes base uri and appends the token id to the end
    // tokens have images stored in ipfs and pinned with individual CIDs in pinata
    function tokenURI(
        uint256 tokenID_
    ) public view override returns (string memory) {
        require(_exists(tokenID_), "Token does not exist");
        // Takes URL, grabs ID, places behind URL, and places it as a JSON for OpenSea
        return
            string(
                abi.encodePacked(
                    baseTokenUri,
                    Strings.toString(tokenID_),
                    ".json"
                )
            );
    }

    // Function creates a call to withdraw to wallet
    function withdraw() external onlyOwner {
        (bool success, ) = withdrawWallet.call{value: address(this).balance}(
            ""
        );
        require(success, "withdraw failed");
    }

    // sets withdrawal wallet
    function setWithdrawWallet(
        address payable _withdrawWallet
    ) external onlyOwner {
        withdrawWallet = _withdrawWallet;
    }

    //Function to allow public mint when not paused
    function mint() public payable whenNotPaused {
        // checks requires first
        uint256 quantity_ = 1; // Set quantity as 1
        require(PublicMintEnabled, "minting not enabled");
        require(msg.value == quantity_ * mintPrice, "wrong mint value");
        require(totalMinted + quantity_ <= maxSupply, "sold out");
        require(
            walletMints[msg.sender] + quantity_ <= maxPerWallet,
            "max mints reached"
        );

        // performs mint incrementing from 0 the tokenID
        for (uint256 i = 0; i < quantity_; i++) {
            uint256 newTokenID = totalMinted + 1;
            totalMinted++;
            walletMints[msg.sender] += 1;

            // Safe check function after all affects
            _safeMint(msg.sender, newTokenID);
        }
    }

    // returns number of minted NFTs
    function getNumMintedNFTs() public view returns (uint256) {
        return totalMinted;
    }

    function getMintPrice() public view returns (uint256) {
        return mintPrice;
    }

    // OpenSea's native royalties function
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (address receiver, uint256 royaltyAmount) {
        // recviver of royalties goes to contract owner
        receiver = owner();

        // calculate royalty amount of 5%
        royaltyAmount = (_salePrice * ROYALTY_PERCENTAGE) / 10000;
    }

    // pause and unpause the contract
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // whitelist functions
    function addToWhitelist(address[] memory addresses) external onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = true;
        }
    }

    function removeFromWhitelist(
        address[] memory addresses
    ) external onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = false;
        }
    }

    function claimMint() external {
        require(whitelist[msg.sender], "Address not whitelisted");
        require(!hasClaimed[msg.sender], "Already claimed");
        require(totalMinted < maxSupply, "Max supply reached");
        require(walletMints[msg.sender] < maxPerWallet, "max mints reached");

        // perform minting action
        _mint(msg.sender, totalMinted + 1);
        totalMinted += 1;
        walletMints[msg.sender] += 1;

        // Mark as claimed
        hasClaimed[msg.sender] = true;
    }

    // Function to check if a given address is whitelisted
    function isWhitelisted(address _address) public view returns (bool) {
        return whitelist[_address];
    }
}