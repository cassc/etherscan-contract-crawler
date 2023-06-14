// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1
// Chiru Labs ERC721 v3.2.0

/****************************************************************************
    9999 Delinquent Giraffes

    By ExoticMugshotsNFT
****************************************************************************/

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

error OwnerIndexOutOfBounds();

contract DelinquentGiraffes is ERC721A, Ownable, ReentrancyGuard {
    // Metadata Control
    bool private revealed;
    string private baseURI;
    string private notRevealedURI;
    string private ext = ".json";
    // Mint Control
    bool public whitelistEnabled;
    bool public mintEnabled;
    uint256 public maxMintsWhitelist = 3;
    // Price
    uint256 public whitelistPrice = 0.07 ether;
    uint256 public price = 0.09 ether;
    // Collection Size
    // Set to 9999 on ln. 45
    uint256 public immutable collectionSize;
    // Supply for presale
    uint256 public remainingDevSupply = 450;
    uint256 public immutable devSupply;
    // Map of wallets => slot counts
    mapping(address => uint256) public whitelist;

    // Constructor
    constructor() ERC721A("delinquentgiraffes", "delinquentgiraffes") {
        // Set collection size
        collectionSize = 9999;
        // Make dev supply public & immutable
        devSupply = remainingDevSupply;
    }

    // Ensure caller is a wallet
    modifier isWallet() {
        require(tx.origin == msg.sender, "Cant be a contract");
        _;
    }

    // Ensure there's enough supply to mint the quantity
    modifier enoughSupply(uint256 quantity) {
        require(
            totalSupply() + quantity <= collectionSize,
            "Reached max supply"
        );
        _;
    }

    // Mint function for whitelist sale
    function whitelistMint(uint256 quantity)
        external
        payable
        isWallet
        enoughSupply(quantity)
    {
        require(whitelistEnabled, "Minting not enabled");
        require(quantity <= whitelist[msg.sender], "No whitelist spots");
        require(quantity * whitelistPrice <= msg.value, "Not enough ETH");
        whitelist[msg.sender] = whitelist[msg.sender] - quantity;
        _safeMint(msg.sender, quantity);
        refundIfOver(quantity * whitelistPrice);
    }

    // Mint function for public sale
    function publicMint(uint256 quantity)
        external
        payable
        isWallet
        enoughSupply(quantity)
    {
        require(mintEnabled, "Minting not enabled");
        require(quantity * price <= msg.value, "Not enough ETH");
        _safeMint(msg.sender, quantity);
        refundIfOver(quantity * price);
    }

    // Mint function for developers (owner)
    // Used to fill presale airdrops
    function devMint(address recipient, uint256 quantity)
        external
        onlyOwner
        enoughSupply(quantity)
    {
        require(quantity <= remainingDevSupply, "Not enough dev supply");
        remainingDevSupply = remainingDevSupply - quantity;
        _safeMint(recipient, quantity);
    }

    // Returns the correct URI for the given tokenId based on contract state
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Nonexistent token");
        if (!revealed || compareStrings(baseURI, "") == true) {
            return notRevealedURI;
        }
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(baseURI, Strings.toString(tokenId), ext)
                )
                : "";
    }

    // Set price for public mint
    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    // Set price for public mint
    function setWhitelistPrice(uint256 _price) external onlyOwner {
        whitelistPrice = _price;
    }

    // Change base metadata URI
    function setBaseURI(string calldata _uri) external onlyOwner {
        baseURI = _uri;
    }

    // Change pre-reveal metadata URI
    function setNotRevealedURI(string calldata _uri) external onlyOwner {
        notRevealedURI = _uri;
    }

    // Change baseURI extension
    function setExt(string calldata _ext) external onlyOwner {
        ext = _ext;
    }

    // Set the mint state
    // 1 - Enable whitelist
    // 2 - Enable public mint
    // 0 - Disable whitelist & public mint
    function setMintState(uint256 _state) external onlyOwner {
        if (_state == 1) {
            whitelistEnabled = true;
        } else if (_state == 2) {
            mintEnabled = true;
        } else {
            whitelistEnabled = false;
            mintEnabled = false;
        }
    }

    // Reveal art
    function reveal(bool _revealed) external onlyOwner {
        revealed = _revealed;
    }

    // Seed whitelist
    function setWhitelist(address[] calldata addrs) external onlyOwner {
        for (uint256 i; i < addrs.length; i++) {
            whitelist[addrs[i]] = maxMintsWhitelist;
        }
    }

    // Returns the amount the address has minted
    function numberMinted(address addr) external view returns (uint256) {
        return _numberMinted(addr);
    }

    // Returns the ownership data for the given tokenId
    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return _ownershipOf(tokenId);
    }

    // Withdraw entire contract value to owners wallet
    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }

    // Refunds extra ETH if minter sends too much
    function refundIfOver(uint256 _price) private {
        if (msg.value > _price) {
            payable(msg.sender).transfer(msg.value - _price);
        }
    }

    // While invaluable when called from a read-only context, this function's
    // implementation is by nature NOT gas efficient [O(totalSupply)],
    // and degrades with collection size.
    //
    // Therefore, you typically shouldn't call tokenOfOwnerByIndex() from
    // another contract. Test for your use case.
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256)
    {
        if (index >= balanceOf(owner)) revert OwnerIndexOutOfBounds();
        uint256 numMintedSoFar = _currentIndex;
        uint256 tokenIdsIdx;
        address currOwnershipAddr;

        unchecked {
            for (uint256 i; i < numMintedSoFar; i++) {
                TokenOwnership memory ownership = _ownerships[i];
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    if (tokenIdsIdx == index) {
                        return i;
                    }
                    tokenIdsIdx++;
                }
            }
        }

        // Cant get to this line, because maths
        revert();
    }

    // Internal helper function that compares 2 strings
    function compareStrings(string memory a, string memory b)
        private
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }
}