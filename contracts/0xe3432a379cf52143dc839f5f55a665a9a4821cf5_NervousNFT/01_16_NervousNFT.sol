// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721S.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract NervousNFT is
    ERC721Sequential,
    ReentrancyGuard,
    PaymentSplitter,
    Ownable
{
    using Strings for uint256;
    using ECDSA for bytes32;
    mapping(bytes => uint256) private usedTickets;

    uint256 public immutable maxSupply;

    uint256 public constant MINT_PRICE = 0.03 ether;
    uint256 public constant MAX_MINTS = 10;

    string public baseURI;

    bool public mintingEnabled = true;

    address public crossmint;

    string public constant R =
        "We are Nervous. Are you? Let us help you with your next NFT Project -> [email protected]";

    constructor(
        string memory name,
        string memory symbol,
        string memory _initBaseURI,
        uint256 _maxSupply,
        address[] memory payees,
        uint256[] memory shares
    ) ERC721Sequential(name, symbol) PaymentSplitter(payees, shares) {
        baseURI = _initBaseURI;
        maxSupply = _maxSupply;
    }

    /* Minting */

    function toggleMinting() public onlyOwner {
        mintingEnabled = !mintingEnabled;
    }

    function mint(uint256 numTokens)
        public
        payable
        nonReentrant
        requireValidMint(numTokens, msg.sender)
    {
        for (uint256 i = 0; i < numTokens; i++) {
            _safeMint(msg.sender);
        }
    }

    function mintTo(uint256 numTokens, address to)
        external
        payable
        nonReentrant
        requireCrossmint
        requireValidMint(numTokens, to)
    {
        _mintTo(numTokens, to);
    }

    function _mintTo(uint256 numTokens, address to) internal {
        for (uint256 i = 0; i < numTokens; i++) {
            _safeMint(to);
        }
    }

    // /* Magic */
    function magicMint(uint256 numTokens) external onlyOwner {
        require(
            totalMinted() + numTokens <= maxSupply,
            "Exceeds maximum token supply."
        );

        require(
            numTokens > 0 && numTokens <= 100,
            "Machine can dispense a minimum of 1, maximum of 100 tokens"
        );

        for (uint256 i = 0; i < numTokens; i++) {
            _safeMint(msg.sender);
        }
    }

    function magicGift(address[] calldata receivers) external onlyOwner {
        uint256 numTokens = receivers.length;
        require(
            totalMinted() + numTokens <= maxSupply,
            "Exceeds maximum token supply."
        );

        for (uint256 i = 0; i < numTokens; i++) {
            _safeMint(receivers[i]);
        }
    }

    function magicBatchGift(
        address[] calldata receivers,
        uint256[] calldata mintCounts
    ) external onlyOwner {
        require(receivers.length == mintCounts.length, "Length mismatch");

        for (uint256 i = 0; i < receivers.length; i++) {
            address to = receivers[i];
            uint256 numTokens = mintCounts[i];
            require(
                totalMinted() + numTokens <= maxSupply,
                "Exceeds maximum token supply."
            );
            _mintTo(numTokens, to);
        }
    }

    /* Utility */

    /* URL Utility */

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseURI = _baseTokenURI;
    }

    /* eth handlers */

    function withdraw(address payable account) public virtual {
        release(account);
    }

    function withdrawERC20(IERC20 token, address to) external onlyOwner {
        token.transfer(to, token.balanceOf(address(this)));
    }

    /* Crossmint */

    function setCrossmint(address _crossmint) public onlyOwner {
        crossmint = _crossmint;
    }

    /* Modifiers */

    modifier requireValidMint(uint256 numTokens, address to) {
        require(mintingEnabled, "Minting isn't enabled");
        require(totalMinted() + numTokens <= maxSupply, "Sold Out");
        require(
            numTokens > 0 && numTokens <= MAX_MINTS,
            "Machine can dispense a minimum of 1, maximum of 10 tokens"
        );
        require(
            msg.value >= numTokens * MINT_PRICE,
            "Insufficient Payment: Amount of Ether sent is not correct."
        );
        _;
    }

    modifier requireCrossmint() {
        require(msg.sender == crossmint, "Crossmint only");
        _;
    }
}