// SPDX-License-Identifier: MIT
// RemWar Contracts v0.2

pragma solidity ^0.8.12;

import "@ERC721A/ERC721A.sol";
import "@ERC721A/IERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@solady/utils/Base64.sol";

// Minting Errors
error MaxSupplyExceeded();
error TooManyMinted();
error PublicMintClosed();

error NoQualifyingTokens();

contract Remilio64 is ERC721A, Ownable {
    // Contracts for free mints
    address remilio = 0xFC22BEA24f90df476E6c929dDc59a0D214b6Af32;
    IERC721A remilioContract = IERC721A(remilio);

    // Supply and Price info
    uint64 public immutable _maxSupply = 10000;
    uint256 public maxPerMint = 10;
    uint256 maxPerWallet = 30;

    string private imgURI =
        "ipfs://bafybeig7jmw2nbbmbjhthyhscleq66gab5ivliwdlu6kwnetrxiemktll4/";
    string private baseURI = "ipfs://bafybeieeji6q4ptcfeshy3umlvwwmktgbtxeuobmumyatqv23kiknieqhu/";

    function setImageURI(string calldata uri) public onlyOwner {
        imgURI = uri;
    }

    constructor() ERC721A("GriftcoinOrdinals", "GTC") {

    }

    /// -------------------------------------
    /// 🪙 MINTING
    /// -------------------------------------
    //    - 0.003Ξ~ avg mint
    //      - Dollady and Remilio are WL'd
    //
    // ℹ️ - Be aware that some minters could
    //     could get remilio64s at the prev
    //     tier price, if they are minting
    //     over the boundries. Consider
    //     this an intended gift should it
    //     occur.

    /// -------------------------------------
    /// 🪙 MINT MODIFIERS
    /// -------------------------------------

    // This is set to true for testing for convenience
    bool testMode = false;

    function setTestMode(bool tf) public onlyOwner {
        testMode = tf;
    }

    modifier quantityCheck(uint256 quantity) {
        if (!testMode) {
            require(balanceOf(msg.sender) < 30, "Wallet Max Reached");
        }
        if (quantity > maxPerMint) {
            revert TooManyMinted();
        }
        _;
    }

    modifier maxSupplyCheck(uint256 quantity) {
        if (totalSupply() + quantity > _maxSupply) {
            revert MaxSupplyExceeded();
        }
        _;
    }

    modifier publicMintCheck() {
        if (mintOpened != true) {
            revert PublicMintClosed();
        }
        _;
    }

    /// -------------------------------------
    /// 🪙 PUBLIC MINT
    /// -------------------------------------
    bool public mintOpened = true;

    function getMintOpened() public view returns (bool) {
        return mintOpened;
    }

    function setMintOpened(bool tf) public onlyOwner {
        mintOpened = tf;
    }

    uint256[] priceTiers = [0.001 ether, 0.002 ether];

    function mint(uint256 quantity)
        external
        payable
        quantityCheck(quantity)
        maxSupplyCheck(quantity)
        publicMintCheck
    {
        // Regular Public Mint
        if (totalSupply() <= 4999) {
            require(
                msg.value == priceTiers[0] * quantity,
                "The price is invalid"
            );
        } else if (totalSupply() > 4999) {
            require(
                msg.value == priceTiers[1] * quantity,
                "The price is invalid"
            );
        }

        mint_and_gen(quantity);
    }

    /// -------------------------------------
    /// 🪆 Friends Mint
    /// -------------------------------------

    uint256 freeTokens = 3000;

    function getFreeTokens() public view returns (uint256) {
        return freeTokens;
    }

    // Toggle for wl
    bool wlOn = false;

    function setWlStatus(bool tf) public onlyOwner {
        wlOn = tf;
    }

    bool public remilioOn = true;

    function setRemilioWl(bool tf) public onlyOwner {
        remilioOn = tf;
    }

    // Helper function to see if on WL
    function checkFriendCollections(address sender)
        public
        view
        returns (uint256)
    {
        uint256 total = 0;
        if (remilioOn) {
            total += remilioContract.balanceOf(sender);
        }
        return total;
    }

    // Mapping to keep track of wallet mints
    mapping(address => uint256) walletMints;
    uint256 maxWlWalletMints = 10;
    uint256 maxWlQuantity = 10;

    function setWlwalletLimit(uint256 x) public onlyOwner {
        maxWlWalletMints = x;
    }

    function setWlQuantity(uint256 x) public onlyOwner {
        maxWlQuantity = x;
    }

    function wl_mint(uint256 quantity) public maxSupplyCheck(quantity) {
        require(freeTokens > 0, "No Free Mints Left");

        if (!testMode) {
            require(
                walletMints[msg.sender] <= maxWlWalletMints,
                "Max Per Wallet Reached Already"
            );
            require(
                quantity <= maxWlQuantity,
                "Max Per Wallet Reached Already"
            );
            uint256 friendTokens = checkFriendCollections(address(msg.sender));
            if (friendTokens == 0) {
                revert NoQualifyingTokens();
            }
        }

        freeTokens -= quantity;
        walletMints[msg.sender] += quantity;
        mint_and_gen(quantity);
    }

    /// -------------------------------------
    /// 🪙 MINT AND GEN FACTION
    /// -------------------------------------

    function mint_and_gen(uint256 quantity) private {
        _mint(msg.sender, quantity);
    }

    /// -------------------------------------
    /// 🪙 OWNER MINT
    /// -------------------------------------

    function ownerMint(uint256 quantity)
        external
        onlyOwner
        maxSupplyCheck(quantity)
    {
        // Mint and Generate Faction
        mint_and_gen(quantity);
    }

    bool tokenDynamic = true;

    function setTokenDynamic(bool tf) public onlyOwner {
        tokenDynamic = tf;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
            return tokenDynamicURI(tokenId);
    }

    function tokenDynamicURI(uint256 tokenId)
        private
        view
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return
            string(
                abi.encodePacked(baseURI, _toString(tokenId), ".json")
            );
    }

    /// -------------------------------------
    /// 🏦 Withdraw
    /// -------------------------------------

    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "Nothing to release");
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "withdraw failed");
    }

    /// -------------------------------------
    /// 💰 Price
    ///
    /// Hopefully this stuff will not be
    /// needed, but may have to reduce price
    /// if players aren't minting.
    /// -------------------------------------

    function getPrice() public view returns (uint256[] memory) {
        return priceTiers;
    }

    function changePrice(uint256 index, uint256 _price) public onlyOwner {
        priceTiers[index] = _price;
    }

    /// -------------------------------------
    /// 🔗 BASE URI and TOKEN URI
    /// -------------------------------------

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _baseUri) public onlyOwner {
        baseURI = _baseUri;
    }
}