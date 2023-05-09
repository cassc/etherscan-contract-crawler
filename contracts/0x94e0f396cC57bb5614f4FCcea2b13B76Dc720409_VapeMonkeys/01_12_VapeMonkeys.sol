// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VapeMonkeys is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant MAX_BATCH_SIZE = 8;

    uint256 public constant PRICE = .05 ether;
    uint256 public constant WL_PRICE = .03 ether;

    string public baseTokenUri;

    uint256 public constant MAX_GIVEAWAY_SUPPLY = 500;
    uint256 public giveawaySupply;

    uint256 public constant MAX_WHITELIST_SUPPLY = 100;
    uint256 public whitelistSupply;

    bool public publicSale;
    bool public whitelistSale;
    bool public pause;

    constructor() ERC721A("Vape Monkey", "VM") {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Cannot be called by a contract");
        _;
    }

    function mint(uint256 _quantity) external payable callerIsUser {
        require(pause == false, "Minting paused");
        require(publicSale, "Public sale not yet started.");

        require(
            (totalSupply() + _quantity) <= MAX_SUPPLY,
            "Max supply exceeded"
        );
        require(msg.value >= (PRICE * _quantity), "Insuficient value");

        require(_quantity <= MAX_BATCH_SIZE, "Max 8 tokens per mint");

        _safeMint(msg.sender, _quantity);
    }

    function whitelistMint(uint256 _quantity) external payable callerIsUser {
        require(pause == false, "Minting paused");
        require(whitelistSale, "Whitelist sale not yet started.");

        require(
            (totalSupply() + _quantity) <= MAX_SUPPLY,
            "Max supply exceeded"
        );
        require(
            (whitelistSupply + _quantity) < MAX_WHITELIST_SUPPLY,
            "Max whitelist supply exceeded"
        );

        require(msg.value >= (WL_PRICE * _quantity), "Insuficient value");

        require(_quantity <= MAX_BATCH_SIZE, "Max 8 tokens per mint");

        whitelistSupply = whitelistSupply + _quantity;

        _safeMint(msg.sender, _quantity);
    }

    function giveawayMint(uint256 _quantity) external onlyOwner {
        require(
            (totalSupply() + _quantity) <= MAX_SUPPLY,
            "Max supply exceeded"
        );
        require(
            (giveawaySupply + _quantity) < MAX_GIVEAWAY_SUPPLY,
            "Attempting to mint more NFTs than supply for giveaways"
        );

        giveawaySupply = giveawaySupply + _quantity;

        _safeMint(msg.sender, _quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    //return uri for certain token
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        //string memory baseURI = _baseURI();
        return
            bytes(baseTokenUri).length > 0
                ? string(
                    abi.encodePacked(baseTokenUri, tokenId.toString(), ".json")
                )
                : "";
    }

    /// @dev walletOf() function shouldn't be called on-chain due to gas consumption
    function walletOf() external view returns (uint256[] memory) {
        address _owner = msg.sender;
        uint256 numberOfOwnedNFT = balanceOf(_owner);
        uint256[] memory ownerIds = new uint256[](numberOfOwnedNFT);

        for (uint256 index = 0; index < numberOfOwnedNFT; index++) {
            ownerIds[index] = tokenOfOwnerByIndex(_owner, index);
        }

        return ownerIds;
    }

    function setTokenUri(string memory _baseTokenUri) external onlyOwner {
        baseTokenUri = _baseTokenUri;
    }

    function togglePause() external onlyOwner {
        pause = !pause;
    }

    function togglePublicSale() external onlyOwner {
        publicSale = !publicSale;
    }

    function toggleWhitelistSale() external onlyOwner {
        whitelistSale = !whitelistSale;
    }

    function withdraw() external onlyOwner {
        uint256 withdrawAmount_A = (address(this).balance * 80) / 100;
        uint256 withdrawAmount_B = address(this).balance - withdrawAmount_A;

        payable(0x8c8c1fCb8560601a0B6D4728BcF816f3118295d9).transfer(
            withdrawAmount_A
        );
        payable(0x309Eb6e036855b005a93daE7c6Ef24b37d188A29).transfer(
            withdrawAmount_B
        );
    }

    function getMintPrice() external pure returns (uint256) {
        return PRICE;
    }
}