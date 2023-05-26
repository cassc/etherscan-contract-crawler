// SPDX-License-Identifier: Unlicense
// Creator: 0xBasedPixel; Based Pixel Labs/Yeety Labs; 1 yeet = 1 yeet
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ERC721.sol";
import "./PixelURIParser.sol";


/*
     ___              ___   ____   ___
     |  \     /\     /      |      |  \
     |__/    /  \    \__    |___   |   \
     |  \   /____\      \   |      |   /
     |__/  /      \  ___/   |___   |__/
*/
// Pixel is based. No scarcity mentality nonsense - infinite mint!
// Get 10 pixel grids at a time for 0.003 ETH per pack. A CC0 Collection.


contract BasedPixels is ERC721, Ownable {
    uint256 public mintPrice;

    address public immutable currency;
    address immutable wrappedNativeCoinAddress;

    address public immutable hexCharsAddress;
    address public immutable pixelURIParserAddress;

    address private signerAddress;
    bool public paused;

    // Mapping from batch numbers to random roots ("r" array/map)
    mapping(uint256 => uint256) public _randomRoots;

    // Mapping from batch numbers to image "slices" ("s" array/map)
    mapping(uint256 => uint256) public _slices;

    // Track whether randomness has been seeded
    bool public isSeeded = false;

    // Contains the external_link attribute for contract metadata
    string private externalLink = "https://twitter.com/0xBasedPixel";

    // Contract royalties address
    string public royaltyAddr = "0xDd2654FAB462cbD1DB945739b81359662e2D333e";

    string private collecImg = "<svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' width='100%25' height='100%25' viewBox='0 0 16 16'><path d='M0,0L16,0,16,16,0,16' fill='black'/><path d='M3,3L3,8,6,8,6,3M4,4L7,4,7,5,4,5M4,6L7,6L7,7L4,7M9,8L9,13,10,13,10,11,12,11,12,8M10,9L13,9,13,10,10,10' fill='white'/></svg>";

    string public CC0LicenseHTML = "<p xmlns:dct='http://purl.org/dc/terms/' xmlns:vcard='http://www.w3.org/2001/vcard-rdf/3.0#'><a rel='license' href='http://creativecommons.org/publicdomain/zero/1.0/'><img src='http://i.creativecommons.org/p/zero/1.0/88x31.png' style='border-style: none;' alt='CC0' /></a><br />To the extent possible under law,<a rel='dct:publisher' href='https://twitter.com/0xBasedPixel'><span property='dct:title'>Tomislav Zabcic-Matic, a.k.a. Yeeticasso, a.k.a. 0xBasedPixel</span></a>has waived all copyright and related or neighboring rights to<span property='dct:title'>Based Pixels</span>. This work is published from:<span property='vcard:Country' datatype='dct:ISO3166' content='US' about='https://twitter.com/0xBasedPixel'>United States</span>.</p>";

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _mintPrice,
        uint256 _maxAllowedMints,
        address _currency,
        address _wrappedNativeCoinAddress,
        address _hexCharsAddress,
        address _pixelURIParserAddress
    ) ERC721(_name, _symbol, _maxAllowedMints*10) {
        mintPrice = _mintPrice;
        currency = _currency;
        wrappedNativeCoinAddress = _wrappedNativeCoinAddress;
        hexCharsAddress = _hexCharsAddress;
        pixelURIParserAddress = _pixelURIParserAddress;
    }

    function randomNumber(uint256 _lookback, uint256 _nonce) private view returns (uint256) {
        uint256 lbHash = uint256(keccak256(abi.encodePacked(blockhash(block.number - _lookback), block.timestamp, block.gaslimit, _nonce)));
        return uint256(keccak256(abi.encodePacked(blockhash(block.number - (lbHash%256 + 1)), block.timestamp, block.gaslimit, (lbHash<<8)>>17)));
    }

    function seedRandomness() public onlyOwner {
        require(!isSeeded, "randomness already seeded");
        for (uint256 i = 0; i < 16; i++) {
            _randomRoots[i] = randomNumber(i+1, i);
        }
        for (uint256 i = 0; i < 17; i++) {
            _slices[i] = randomNumber(i+1, i*10);
        }
        isSeeded = true;
    }

    function flipPaused() external onlyOwner {
        paused = !paused;
    }

    function setExternalLink(string memory _link) public onlyOwner {
        externalLink = _link;
    }

    function setRoyaltyAddr(string memory _addr) public onlyOwner {
        royaltyAddr = _addr;
    }

    function mint(uint amount) public payable {
        require(!paused, "mint is paused");
        require(isSeeded, "randomness not yet seeded");

        if (currency == wrappedNativeCoinAddress) {
            if (address(msg.sender) != owner()) {
                require(amount*mintPrice <= msg.value, "a");
            }
        } else {
            IERC20 _currency = IERC20(currency);
            _currency.transferFrom(msg.sender, address(this), amount * mintPrice);
        }

        for (uint i = 0; i < amount; i++) {
            _randomRoots[(currentIndex/10)+16+i] = randomNumber((_randomRoots[(currentIndex/15)+13])%256, (currentIndex/10)+i);
            _slices[(currentIndex/10)+17+i] = randomNumber((_randomRoots[(currentIndex/10)+16])%256, (currentIndex/10)+i);
        }
        _safeMint(address(0), msg.sender, amount*10);
    }

    function giftMint(uint amount, address receiver) public payable {
        require(!paused, "mint is paused");
        require(isSeeded, "randomness not yet seeded");

        if (currency == wrappedNativeCoinAddress) {
            if (address(msg.sender) != owner()) {
                require(amount*mintPrice <= msg.value, "a");
            }
        } else {
            IERC20 _currency = IERC20(currency);
            _currency.transferFrom(msg.sender, address(this), amount * mintPrice);
        }

        for (uint i = 0; i < amount; i++) {
            _randomRoots[(currentIndex/10)+16+i] = randomNumber((_randomRoots[(currentIndex/15)+13])%256, (currentIndex/10)+i);
            _slices[(currentIndex/10)+17+i] = randomNumber((_randomRoots[(currentIndex/10)+16])%256, (currentIndex/10)+i);
        }
        _safeMint(msg.sender, receiver, amount*10);
    }

    function getSlices(uint256 tokenId) public view returns (uint256[12] memory) {
        require(_exists(tokenId), "z");

        uint256 mintBatchRootID = (tokenId - (tokenId%10))/10;

        uint256[] memory slices = new uint256[](48);

        for (uint i = 0; i < 12; i++) {
            for (uint j = 0; j < 4; j++) {
                slices[i+(j*12)] = (_randomRoots[mintBatchRootID+(tokenId%10)+j]^_slices[mintBatchRootID+i+j])^(_randomRoots[mintBatchRootID+10+j]^_slices[mintBatchRootID+12+j]);
            }

            if ((_slices[mintBatchRootID+16]>>((tokenId%10)*25))%3 == 0) {
                slices[i] = slices[i]^slices[i+12];
            }
            else if ((_slices[mintBatchRootID+16]>>((tokenId%10)*25))%3 == 1) {
                slices[i] = slices[i]&slices[i+12];
            }
            else {
                slices[i] = slices[i]|slices[i+12];
            }

            if ((_randomRoots[mintBatchRootID+14]>>((tokenId%10)*25))%3 == 0) {
                slices[i] = slices[i]^slices[i+24];
            }
            else if ((_randomRoots[mintBatchRootID+14]>>((tokenId%10)*25))%3 == 1) {
                slices[i] = slices[i]&slices[i+24];
            }
            else {
                slices[i] = slices[i]|slices[i+24];
            }

            if ((_randomRoots[mintBatchRootID+15]>>((tokenId%10)*25))%3 == 0) {
                slices[i] = slices[i]^slices[i+36];
            }
            else if ((_randomRoots[mintBatchRootID+15]>>((tokenId%10)*25))%3 == 1) {
                slices[i] = slices[i]&slices[i+36];
            }
            else {
                slices[i] = slices[i]|slices[i+36];
            }
        }

        return [slices[0], slices[1], slices[2], slices[3], slices[4], slices[5], slices[6], slices[7], slices[8], slices[9], slices[10], slices[11]];
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "z");

        uint256[12] memory slices = getSlices(tokenId);

        return (PixelURIParser.getPixelURI(slices, tokenId));
    }

    function contractURI() public view returns (string memory) {
        return string(
            abi.encodePacked(
                "data:application/json;utf8,{\"name\":\"Based Pixels\",",
                "\"description\":\"A collection of randomly generated 16x16 pixel ",
                "grids, created with fully on-chain pseudorandomness. Infinite mint. ",
                "Pixels mint in packs of 10 per mint. Each pack costs 0.003 ETH.",
                "Find your favorite pixel design. Happy hunting! This is a CC0 project.\",",
                "\"image\":\"data:image/svg+xml;utf8,", collecImg, "\",",
                "\"external_link\":\"", externalLink, "\",",
                "\"seller_fee_basis_points\":100,\"fee_recipient\":\"", royaltyAddr, "\"}"
            )
        );
    }

    receive() external payable {
        mint(msg.value / mintPrice);
    }

    function withdraw() external onlyOwner() {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawTokens(address tokenAddress) external onlyOwner() {
        IERC20(tokenAddress).transfer(msg.sender, IERC20(tokenAddress).balanceOf(address(this)));
    }
}