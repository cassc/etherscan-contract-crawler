// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "prb-math/contracts/PRBMathUD60x18.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./access/DeveloperAccess.sol";
import "./MerkleProof.sol";
import "./ERC721GAC.sol";

contract GamingApeClub is
    ERC721GAC,
    MerkleProof,
    Ownable,
    DeveloperAccess,
    ReentrancyGuard
{
    using PRBMathUD60x18 for uint256;

    uint256 private constant ONE_PERCENT = 10000000000000000; // 1% (18 decimals)
    uint8 private constant AUCTION_QUANTITY = 1; // 1 for auction

    bytes32 private _merkleRoot;
    uint256 public mintPrice;
    uint256 public whitelistStart;
    uint256 public whitelistReset;
    uint256 public whitelistEnd;
    uint256 public publicStart;
    string private _baseUri;
    uint16 public maxWhitelistSupply;
    uint16 public maximumSupply;
    uint16 public maxPerWallet;

    constructor(
        address devAddress,
        uint16 maxSupply,
        uint16 walletMax,
        uint16 whitelistMax,
        uint256 price,
        uint256 presaleMintStart,
        uint256 presaleResetTime,
        uint256 presaleMintEnd,
        uint256 publicMintStart,
        string memory baseUri
    ) ERC721GAC("Gaming Ape Club", "GAC") DeveloperAccess(devAddress) {
        require(maxSupply >= AUCTION_QUANTITY, "Bad supply");
        require(whitelistMax <= maxSupply, "Bad wl max");

        // GLOBALS
        maximumSupply = maxSupply;
        maxPerWallet = walletMax;
        mintPrice = price;
        maxWhitelistSupply = whitelistMax;

        // CONFIGURE PRESALE Mint
        whitelistStart = presaleMintStart;
        whitelistReset = presaleResetTime;
        whitelistEnd = presaleMintEnd;

        // CONFIGURE PUBLIC MINT
        publicStart = publicMintStart;

        // SET BASEURI
        _baseUri = baseUri;

        // MINT AUCTION NFTS
        ownerMint(AUCTION_QUANTITY, msg.sender);
    }

    // -------------------------------------------- OWNER/DEV ONLY ----------------------------------------

    /**
     * @dev Throws if called by any account other than the developer/owner.
     */
    modifier onlyOwnerOrDeveloper() {
        require(
            developer() == _msgSender() || owner() == _msgSender(),
            "Ownable: caller is not the owner or developer"
        );
        _;
    }

    /**
     * Allows for the owner to mint for free.
     * @param quantity - the quantity to mint.
     * @param to - the address to recieve that minted quantity.
     */
    function ownerMint(uint64 quantity, address to) public onlyOwner {
        uint256 remaining = maximumSupply - _currentIndex;

        require(remaining > 0, "Mint over");
        require(quantity <= remaining, "Not enough");

        _mint(address(this), to, quantity, "", true, 0); // private
    }

    /**
     * Sets the wallet max for both sales
     *
     * @param newMax - the new wallet max for the two sales
     */
    function setMaxPerWallet(uint16 newMax) public onlyOwnerOrDeveloper {
        maxPerWallet = newMax;
    }

    /**
     * Sets the base URI for all tokens
     *
     * @dev be sure to terminate with a slash
     * @param uri - the target base uri (ex: 'https://google.com/')
     */
    function setBaseURI(string calldata uri) public onlyOwnerOrDeveloper {
        _baseUri = uri;
    }

    /**
     * Updates the mint price
     * @param price - the price in WEI
     */
    function setMintPrice(uint256 price) public onlyOwnerOrDeveloper {
        mintPrice = price;
    }

    /**
     * Updates the merkle root
     * @param root - the new merkle root
     */
    function setMerkleRoot(bytes32 root) public onlyOwnerOrDeveloper {
        _merkleRoot = root;
    }

    /**
     * Updates the supply cap on whitelist.
     * If a given transaction will cause the supply to increase
     * beyond this number, it will fail.
     */
    function setWhitelistMaxSupply(uint16 max) public onlyOwnerOrDeveloper {
        require(max <= maximumSupply, "Bad wl max");
        maxWhitelistSupply = max;
    }

    /**
     * Updates the mint dates.
     *
     * @param wlStartDate - the start date for whitelist in UNIX seconds.
     * @param wlResetDate - the reset date for whitelist in UNIX seconds.
     * @param wlEndDate - the end date for whitelist in UNIX seconds.
     * @param pubStartDate - the start date for public in UNIX seconds.
     */
    function setMintDates(
        uint256 wlStartDate,
        uint256 wlResetDate,
        uint256 wlEndDate,
        uint256 pubStartDate
    ) public onlyOwnerOrDeveloper {
        whitelistStart = wlStartDate;
        whitelistReset = wlResetDate;
        whitelistEnd = wlEndDate;
        publicStart = pubStartDate;
    }

    /**
     * Withdraws balance from the contract to the dividend recipients within.
     */
    function withdraw() external onlyOwnerOrDeveloper {
        uint256 amount = address(this).balance;

        (bool s1, ) = payable(0x4C21f55d3Ef836aDeFc5b0A9c9C6908C4F8bD545).call{
            value: amount.mul(ONE_PERCENT * 85)
        }("");
        (bool s2, ) = payable(0x7436F0949BCa6b6C6fD766b6b9AA57417B0314A9).call{
            value: amount.mul(ONE_PERCENT * 4)
        }("");
        (bool s3, ) = payable(0x13c4d22a8dbB2559B516E10FE0DE47ba4b4A03EB).call{
            value: amount.mul(ONE_PERCENT * 3)
        }("");
        (bool s4, ) = payable(0xB3D665d27A1AE8F2f3C32cB1178c9E749ce00714).call{
            value: amount.mul(ONE_PERCENT * 3)
        }("");
        (bool s5, ) = payable(0x470049b45A5f05c84e9285Cb467642733450acE5).call{
            value: amount.mul(ONE_PERCENT * 3)
        }("");
        (bool s6, ) = payable(0xcbFF601C8745a86e39d9dcB4725B7e6019f5e4FE).call{
            value: amount.mul(ONE_PERCENT * 2)
        }("");

        if (s1 && s2 && s3 && s4 && s5 && s6) return;

        // fallback to paying owner
        (bool s7, ) = payable(owner()).call{value: amount}("");

        require(s7, "Payment failed");
    }

    // ------------------------------------------------ MINT ------------------------------------------------

    /**
     * A handy getter to retrieve the number of private mints conducted by a user.
     * @param user - the user to query for.
     * @param postReset - retrieves the number of mints after the whitelist reset.
     */
    function getPresaleMints(address user, bool postReset) external view returns (uint256) {
        if (postReset) return _numberMintedAux(user);
        return _numberMintedPrivate(user);
    }

    /**
     * A handy getter to retrieve the number of public mints conducted by a user.
     * @param user - the user to query for.
     */
    function getPublicMints(address user) external view returns (uint256) {
        return _numberMintedPublic(user);
    }

    /**
     * Mints in the premint stage by using a signed transaction from a merkle tree whitelist.
     *
     * @param amount - the amount of tokens to mint. Will fail if exceeds allowable amount.
     * @param proof - the merkle proof from the root to the whitelisted address.
     */
    function premint(uint16 amount, bytes32[] memory proof) public payable nonReentrant {
        uint256 remaining = maxWhitelistSupply - _currentIndex;

        require(remaining > 0, "Mint over");
        require(remaining >= amount, "Insuf. amount");

        require(
            verify(_merkleRoot, keccak256(abi.encodePacked(msg.sender)), proof),
            "Invalid proof"
        );
        require(mintPrice * amount == msg.value, "Bad value");
        bool isReset = block.timestamp >= whitelistReset;
        
        if (isReset) {
            require(
                _numberMintedAux(msg.sender) + amount <= maxPerWallet,
                "Limit exceeded"
            );
        } else {
            require(
                _numberMintedPrivate(msg.sender) + amount <= maxPerWallet,
                "Limit exceeded"
            );
        }
        

        require(
            whitelistStart <= block.timestamp &&
                whitelistEnd >= block.timestamp,
            "Inactive"
        );

        // DISTRIBUTE THE TOKENS
        _safeMint(msg.sender, amount, isReset ? 1 : 0);
    }

    /**
     * Mints one token provided it is possible to.
     *
     * @notice This function allows minting in the public sale.
     */
    function mint(uint16 amount) public payable nonReentrant {
        uint256 remaining = maximumSupply - _currentIndex;

        require(remaining > 0, "Mint over");
        require(remaining >= amount, "Insuf. amount");
        require(
            _numberMintedPublic(msg.sender) + amount <= maxPerWallet,
            "Limit exceeded"
        );
        require(mintPrice * amount == msg.value, "Bad value");
        require(block.timestamp >= publicStart, "Inactive");

        // DISTRIBUTE THE TOKENS
        _safeMint(msg.sender, amount, 2); // public
    }

    /**
     * Burns the provided token id if you own it.
     * Reduces the supply by 1.
     *
     * @param tokenId - the ID of the token to be burned.
     */
    function burn(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "Not owner");

        _burn(tokenId);
    }

    // ------------------------------------------- INTERNAL -------------------------------------------

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseUri;
    }

    // --------------------------------------- FALLBACKS ---------------------------------------

    /**
     * The receive function, does nothing
     */
    receive() external payable {
        // DO NOTHING
    }
}