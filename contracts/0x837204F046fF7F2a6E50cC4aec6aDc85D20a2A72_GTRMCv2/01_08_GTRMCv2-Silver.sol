// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface IERC20 {
    function allowance(address owner, address spender) external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256 balance);
    function decimals() external view returns (uint8);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract GTRMCv2 is ERC721AQueryable, Ownable, Pausable {

    bool public _mintEnabled;
    uint256 public _mintPrice;
    address public _mintPriceAddress;
    uint256 public _mintPriceTax1;
    uint256 public _mintPriceTax1Divisor;
    address public _mintPriceTax1Address;
    uint256 public _mintPriceTax2;
    uint256 public _mintPriceTax2Divisor;
    address public _mintPriceTax2Address;

    mapping(IERC20 => bool) public _paymentTokens;
    uint256 public _maxSupply;
    string public _baseUri;

    event NftMinted(uint256 tokenId, address purchaser, address beneficiary, IERC20 paymentToken, uint8 decimals, uint256 mintPrice, uint256 adjustedMintPrice, string ref);
    
    constructor() ERC721A("GTRMC Silver", "GTRMC") {
        //validate stablecoins for deposit
        _paymentTokens[IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7)] = true; //usdt mainnet
        _paymentTokens[IERC20(0x4Fabb145d64652a948d72533023f6E7A623C7C53)] = true; //busd mainnet
        _paymentTokens[IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48)] = true; //usdc mainnet

        //set initial properties
        _maxSupply = 1800;
        _mintEnabled = false;
        _mintPrice = 1359;
        _mintPriceAddress = 0x1825F9fd57A2426b338eCd1392257B1B4243c899;
        _mintPriceTax1 = 500;
        _mintPriceTax1Divisor = 10000;
        _mintPriceTax1Address = 0x1825F9fd57A2426b338eCd1392257B1B4243c899;
        _mintPriceTax2 = 500;
        _mintPriceTax2Divisor = 10000;
        _mintPriceTax2Address = 0x1825F9fd57A2426b338eCd1392257B1B4243c899;
    }

    //
    // PUBLIC FUNCTIONS
    //

    function getMintPriceForAsset(IERC20 paymentToken) external view returns (uint8 tokenDecimals, uint256 adjustedMintPrice) {
        require(_paymentTokens[paymentToken] == true, "INVALID_TOKEN");
        uint8 decimals = paymentToken.decimals();
        uint256 mintPrice = _mintPrice * (10**decimals);
        return (decimals, mintPrice);
    }

    function mint(IERC20 paymentToken, address beneficiary, string calldata ref) external payable whenNotPaused {
        require(_mintEnabled == true, "DISABLED");
        require(_totalMinted() + 1 <= _maxSupply, "MAX_SUPPLY_REACHED");
        require(_paymentTokens[paymentToken] == true, "INVALID_TOKEN");
        uint8 decimals = paymentToken.decimals();
        uint256 mintPrice = _mintPrice * (10**decimals);
        uint256 adjustedMintPrice = mintPrice;
        require(paymentToken.allowance(msg.sender, address(this)) >= adjustedMintPrice, "INVALID_ALLOWANCE");

        //process tax1
        if (_mintPriceTax1 > 0 && _mintPriceTax1Divisor > 0 && _mintPriceTax1Address != address(0)) {
            uint256 taxAmount = adjustedMintPrice * _mintPriceTax1 / _mintPriceTax1Divisor;
            require(paymentToken.transferFrom(msg.sender, _mintPriceTax1Address, taxAmount), "FAILED_TRANSFER_TAX1");
            adjustedMintPrice -= taxAmount;
        }

        //process tax2
        if (_mintPriceTax2 > 0 && _mintPriceTax2Divisor > 0 && _mintPriceTax2Address != address(0)) {
            uint256 taxAmount = adjustedMintPrice * _mintPriceTax2 / _mintPriceTax2Divisor;
            require(paymentToken.transferFrom(msg.sender, _mintPriceTax2Address, taxAmount), "FAILED_TRANSFER_TAX2");
            adjustedMintPrice -= taxAmount;
        }

        //process payment and mint
        require(paymentToken.transferFrom(msg.sender, _mintPriceAddress, adjustedMintPrice), "FAILED_TRANSFER");
        _mint(beneficiary, 1);
        emit NftMinted(_totalMinted()-1, msg.sender, beneficiary, paymentToken, decimals, mintPrice, adjustedMintPrice, ref);
    }

    //
    // MIXED FUNCTIONS
    //

    //allow self burning or admin burning
    function burn(uint256 tokenId) external {
        require(tokenId < totalSupply(), "INVALID_TOKEN");
        require(ownerOf(tokenId) == msg.sender || owner() == msg.sender, "NOT_PERMITTED");

        //burn and do not require built in approvalCheck
        _burn(tokenId, false);
    }

    //
    // INTERNAL FUNCTIONS
    //
    function _baseURI() internal view virtual override returns (string memory uri) { return _baseUri; }
    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal virtual override {
        //stop transfers unless not paused, minting or person is owner
        require(paused() == false || from == address(0) || msg.sender == owner(), "NOT_PERMITTED");

        //call base function
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    //
    // ADMIN FUNCTIONS
    //

    function pause() external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }

    function setTokenBaseUri(string memory url) external onlyOwner { _baseUri = url; }
    function setMintStatus(bool mintEnabled) external onlyOwner { _mintEnabled = mintEnabled; }

    function setMintPrice(uint256 price, address dest) external onlyOwner {
        _mintPrice = price;
        _mintPriceAddress = dest;
    }

    function setMintTax(uint8 taxType, uint256 amount, uint256 divisor, address dest) external onlyOwner {
        require(taxType <= 2, "INVALID_TYPE");

        if (taxType == 1) { _mintPriceTax1 = amount; _mintPriceTax1Divisor = divisor; _mintPriceTax1Address = dest; }
        else if (taxType == 2) { _mintPriceTax2 = amount; _mintPriceTax2Divisor = divisor; _mintPriceTax2Address = dest; }
    }

    function mintAirdrop(address[] calldata addresses) external onlyOwner {
        require(_totalMinted() + addresses.length <= _maxSupply, "MAX_SUPPLY_REACHED");

        for (uint256 i = 0; i < addresses.length; i++) {
            _mint(addresses[i], 1);
        }
    }

    function withdrawToken(IERC20 token, uint256 amount, address to) external onlyOwner {
        if (address(token) == address(0)) {
            (bool success, ) = to.call{value: (amount == 0 ? address(this).balance : amount)}(new bytes(0)); 
            require(success, "NATIVE_TRANSFER_FAILED");
        } else {
            (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(IERC20.transfer.selector, to, (amount == 0 ? token.balanceOf(address(this)) : amount))); 
            require(success && (data.length == 0 || abi.decode(data, (bool))), "ERC20_TRANSFER_FAILED");
        }
    }

    receive() external payable {}
}