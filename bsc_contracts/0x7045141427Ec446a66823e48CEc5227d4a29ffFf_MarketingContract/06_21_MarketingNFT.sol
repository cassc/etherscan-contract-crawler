// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract MarketingNFT is ERC721Enumerable, Ownable, Pausable, ReentrancyGuard {
    using Math for uint256;

    uint256 private nonce = 1; //for random function

    uint256 public constant MINT_PER_TRANSACTION = 5;       // max amount to mint in tx
    uint256 public constant MINT_PER_ADDRESS = 20;          // max amount each address can mint
    uint256 public constant CAPPED_SUPPLY = 10000;          // max amount for minting
    uint256 public constant SALE_ROUND_SUPPLY = 1000;       // 1000 nft in sale round
    uint256 public constant INCREMENT_PRICE_PERCENT = 100;  // 10 %
    uint256 public constant PERCENT_MULTIPLIER = 10;
    uint256[4] CHANCE = [230, 66, 4];
    enum Rarity { COMMON, UNCOMMON, RARE, LEGENDARY }

    string public baseTokenURI;                             // IPFS base link

    uint256 public pricePerTokenERC20;                      // start 49 ERC20 tokens

    address public paymentToken;                            // payment ERC20 token

    uint256 public currentlyMinted;                         // minted amount
    uint256 public saleRoundMinted;
    mapping(address => uint256) public mintedPerAddress;

    //Mapping represents rarity of nft: tokenId => (0 - common, 1 - uncommon, 2 - rare, 3 - legendary)
    mapping(uint256 => uint256) nftRarity;


    event BaseTokenURIUpdate(string oldURI, string newURI);
    event Mint(address minter, address indexed to, uint256 tokenId);
    event SetPricePerTokenERC20(uint256 newPrice);

    constructor(
        string memory _baseTokenURI,
        address _paymentToken,
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) {
        pricePerTokenERC20 = 49 ether;
        baseTokenURI = _baseTokenURI;
        paymentToken = _paymentToken;

        _pause();
    }

    function getMintPrice(uint256 amount) external view returns (uint256) {
        return _getMintPrice(amount, pricePerTokenERC20);
    }


    function _getMintPrice(uint256 amount, uint256 price) internal view returns (uint256) {
        uint256 limitedAmount = _getMaxMintAvailable(amount, _msgSender());
        return price * limitedAmount;
    }

    function _getMaxMintAvailable(uint256 amount, address user)
        internal
        view
        returns (uint256) {

        uint256 mintForSender = amount.min(MINT_PER_TRANSACTION);
        mintForSender =  mintForSender.min(MINT_PER_ADDRESS - mintedPerAddress[user]);
        return mintForSender.min(SALE_ROUND_SUPPLY - saleRoundMinted);
    }

    function mint(uint256 amount) public whenNotPaused {
        require(mintedPerAddress[msg.sender] < MINT_PER_ADDRESS, "MINT LIMIT REACHED");
        address tokenAddress = paymentToken;
        _mintForERC20(msg.sender, amount, tokenAddress);
    }

    function _mintForERC20(
        address to,
        uint256 amount,
        address tokenAddress
    ) internal {
        uint256 howManyToMint = _getMaxMintAvailable(amount, to);
        uint256 mintPrice = pricePerTokenERC20 * howManyToMint;
        IERC20(tokenAddress).transferFrom(_msgSender(), owner(), mintPrice);
        _mint(howManyToMint, to);
    }

    function _mint(uint256 howManyToMint, address to) internal {
        uint256 minted = currentlyMinted;
        uint256 roundMinted = saleRoundMinted;

        for (uint256 i = 0; i < howManyToMint; i++) {
            _safeMint(to, ++minted);
            ++roundMinted;
            uint256 rarity = generateNftRarity();
            nftRarity[minted] = rarity;
            emit Mint(msg.sender, to, minted);
        }

        currentlyMinted = minted;
        saleRoundMinted = roundMinted;
        mintedPerAddress[to] += howManyToMint;
        if (saleRoundMinted == SALE_ROUND_SUPPLY) {
            switchSaleRound();
        }
    }

    function switchSaleRound() private {
        _pause();
        pricePerTokenERC20 += (pricePerTokenERC20 * INCREMENT_PRICE_PERCENT) / (100 * PERCENT_MULTIPLIER);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function startSale() external onlyOwner whenPaused {
        _unpause();
    }

    function stopSale() external onlyOwner whenNotPaused {
        _pause();
    }

    function setBaseTokenURI(string calldata URI) external onlyOwner {
        string memory oldURI = baseTokenURI;
        baseTokenURI = URI;
        emit BaseTokenURIUpdate(oldURI, URI);
    }


    function setPricePerTokenERC20(uint256 newPrice) external onlyOwner {
        pricePerTokenERC20 = newPrice;
        emit SetPricePerTokenERC20(newPrice);
    }

    function getNftRarity(uint256 tokenId) external view returns(uint256) {
        return nftRarity[tokenId];
    }

    function generateNftRarity() internal returns(uint256) {
        uint256 randNum = getRandomNumber(0, 1000);
        if (randNum < CHANCE[2]) return uint(Rarity.LEGENDARY);
        if (randNum < CHANCE[1]) return uint(Rarity.RARE);
        if (randNum < CHANCE[0]) return uint(Rarity.UNCOMMON);
        return uint(Rarity.COMMON);
    }

    function getRandomNumber(uint minNumber, uint maxNumber) internal returns (uint) {
        nonce++;
        uint randomNumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % (maxNumber - minNumber);
        randomNumber = randomNumber + minNumber;
        return randomNumber;
    }
}