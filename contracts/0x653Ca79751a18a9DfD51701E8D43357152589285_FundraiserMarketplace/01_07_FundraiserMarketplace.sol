// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ERC20Interface.sol";
import "./ERC1155Interface.sol";
import {Verification} from "./Verification.sol";

// This line is added for temporary use
contract FundraiserMarketplace is Ownable, Verification {
    uint256 private PRICE = 150000000000000000000;
    address public usdtAddress;
    constructor(address usdt) {
        usdtAddress = usdt;
    }
    using SafeMath for uint256;
    mapping(address => mapping(uint256 => bool)) seenNonces;

    struct transferNFTData {
        uint256 tokenId;
        address to;
        address nft;
        uint256 amount;
        bytes signature;
        address from;
        string encodeKey;
        uint256 nonce;
    }

    event NftTransferred(uint256 tokenId, uint256 price, address from, address to);

    function transfer1155(transferNFTData memory _transferData) public {
        require(!seenNonces[msg.sender][_transferData.nonce], "Invalid request");
        seenNonces[msg.sender][_transferData.nonce] = true;
        require(verify(msg.sender, msg.sender, _transferData.amount, _transferData.encodeKey, _transferData.nonce, _transferData.signature), "invalid signature");
        
        require(_transferData.amount > 0 && _transferData.amount < 11, "Please select valid amount");
        uint256 totalValue = PRICE * _transferData.amount;
        transferERC20ToOwner(msg.sender, address(this), totalValue, usdtAddress);
        IERC1155Token nftToken = IERC1155Token(_transferData.nft);
        nftToken.safeTransferFrom(_transferData.from, msg.sender, _transferData.tokenId, _transferData.amount, "");
    }
    fallback () payable external {}
    receive () payable external {}
    function transferERC20ToOwner(address from, address to, uint256 amount, address tokenAddress) private {
        IERC20Token token = IERC20Token(tokenAddress);
        uint256 balance = token.balanceOf(from);
        require(balance >= amount, "insufficient balance" );
        token.transferFrom(from, to, amount);
    }
    function withdrawUSDT() public onlyOwner {
        IERC20Token annexToken = IERC20Token(usdtAddress);
        uint256 balance = annexToken.balanceOf(address(this));
        require(balance >= 0, "insufficient balance" );
        annexToken.transfer(owner(), balance);
    }
    function updatePrice(uint256 _price) public onlyOwner {
        PRICE = _price;
    }
}