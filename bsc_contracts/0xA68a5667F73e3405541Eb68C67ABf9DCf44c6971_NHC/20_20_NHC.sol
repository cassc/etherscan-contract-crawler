// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/ISouvenir.sol";

contract NHC is
    ERC721Enumerable,
    ERC721Burnable,
    Ownable,
    Pausable,
    ReentrancyGuard
{
    ISouvenir nftca;

    event Mint(address indexed buyer, uint256 amount, uint256 indexed tokenID);
    event Burn(address indexed burner, uint256 indexed tokenId);
    uint8 public constant CONST_EXCHANGE_RATE_DECIMAL = 18;
    address constant highUsdPriceFeed =
        address(0xdF4Dd957a84F798acFADd448badd2D8b9bC99047);
    IERC20 constant high =
        IERC20(address(0x5f4Bde007Dc06b867f86EBFE4802e34A1fFEEd63));
    address constant highWallet =
        address(0x0ff81A8D361668b4cB38fb64FCA5eE0Eb51E6798); // BSC Chain high wallet
    address constant nftooWallet =
        address(0x16bfB96C512DAb1E3F7E5a3b41089E9E9a3232ac); // BSC Chain nftoo wallet
    address constant souvenirNFT =
        address(0x7297aF4E7B2b8be5a48784A7beFA8b3B8e09eefb); // BSC Chain souvenir nft
    uint256 public constant souvenirTokenId = 1;
    uint256 public constant highFeeRate = 8;
    uint256 private constant baseUSDPrice = 2 * (10 ** 18);

    string private baseURI = "";
    uint private maxSupply = 300;
    uint private mintedSupply = 0;
    uint private basePrice = 0;

    constructor() ERC721("Highstreet x NFTOO Champagne)", "NHC") {
        pause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function withdraw(address addr) external onlyOwner {
        payable(addr).transfer(address(this).balance);
    }

    function withdrawERC20(
        address tokenAddr,
        address to,
        uint256 amount
    ) public onlyOwner {
        IERC20 token = IERC20(tokenAddr);
        require(token.transfer(to, amount), "transfer failed");
    }

    function mint(uint256 amount) public payable nonReentrant whenNotPaused {
        require(tx.origin == msg.sender, "Contract are not allowed to call");
        require(amount <= 3, "One TX Max supply 3");

        require(mintedSupply < maxSupply, "Max supply reached");
        require(
            mintedSupply + uint256(amount) <= maxSupply,
            "Exceeds max supply"
        );

        /** 
        1. get the HIGH - USD price feed from chainlink contract 
        2. convert the product price from USD to HIGH 
        3. Check whether user have enough HIGH
        4. Transfer the platform fee to Highstreet address
        5. Transfer the remain value to Nftoo address or contract itself
        6. Mint the NFT to user 
         */

        uint256 highPrice = uint256(
            getTokenPrice(highUsdPriceFeed, CONST_EXCHANGE_RATE_DECIMAL)
        );

        uint256 totalHighAmount = ((baseUSDPrice * 100) * amount) /
            (highPrice * 100);

        uint256 toHighAmount = (totalHighAmount * highFeeRate) / 100;
        uint256 toNftooAmount = totalHighAmount - toHighAmount;

        SafeERC20.safeTransferFrom(high, msg.sender, highWallet, toHighAmount);
        SafeERC20.safeTransferFrom(
            high,
            msg.sender,
            nftooWallet,
            toNftooAmount
        );

        emit Mint(msg.sender, totalHighAmount, mintedSupply);

        mintInner(uint256(amount));
    }

    function mintInner(uint amount) internal {
        uint mintedSupplyCopy = mintedSupply;
        for (uint i = 0; i < amount; ++i) {
            _safeMint(msg.sender, mintedSupplyCopy);
            ++mintedSupplyCopy;
        }
        mintedSupply = mintedSupplyCopy;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function getStatus() public view returns (uint[] memory) {
        uint[] memory arr = new uint[](8);
        arr[0] = paused() ? 0 : 1;
        arr[1] = basePrice;
        arr[2] = maxSupply;
        arr[3] = mintedSupply;
        arr[4] = baseUSDPrice;
        return arr;
    }

    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, Strings.toString(_tokenId)))
                : "";
    }

    function getTokenPrice(
        address _base,
        uint8 _decimals
    ) public view returns (int256) {
        require(
            _decimals > uint8(0) && _decimals <= uint8(18),
            "Invalid _decimals"
        );
        (, int256 tokenBasePrice, , , ) = AggregatorV3Interface(_base)
            .latestRoundData();
        uint8 baseDecimals = AggregatorV3Interface(_base).decimals();
        tokenBasePrice = scalePrice(tokenBasePrice, baseDecimals, _decimals);

        return tokenBasePrice;
    }

    function scalePrice(
        int256 _price,
        uint8 _priceDecimals,
        uint8 _decimals
    ) internal pure returns (int256) {
        if (_priceDecimals < _decimals) {
            return _price * int256(10 ** uint256(_decimals - _priceDecimals));
        } else if (_priceDecimals > _decimals) {
            return _price / int256(10 ** uint256(_priceDecimals - _decimals));
        }
        return _price;
    }

    function redeem(uint256 tokenId) public {
        burn(tokenId);
        nftca = ISouvenir(souvenirNFT);
        nftca.mint(msg.sender, souvenirTokenId, 1);
        emit Burn(msg.sender, tokenId);
    }
}