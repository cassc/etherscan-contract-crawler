// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./PreSalesActivation.sol";
import "./PublicSalesActivation.sol";
import "./Whitelist.sol";
import "./ERC721Opensea.sol";
import "./Withdrawable.sol";

contract Monaverse is
    Ownable,
    EIP712,
    PreSalesActivation,
    PublicSalesActivation,
    Whitelist,
    ERC721Opensea,
    Withdrawable
{
    // Specification
    uint256 public constant TOTAL_MAX_QTY = 1234;
    uint256 public constant GIFT_MAX_QTY = 34;
    uint256 public constant SALES_MAX_QTY = TOTAL_MAX_QTY - GIFT_MAX_QTY;
    uint256 public constant MAX_QTY_PER_MINTER = 2;
    uint256 public constant PRICE = 0.08 ether;

    // Minter to token
    mapping(address => uint256) public preSalesMinterToTokenQty;
    mapping(address => uint256) public publicSalesMinterToTokenQty;

    // Quantity minted
    uint256 public preSalesMintedQty = 0;
    uint256 public publicSalesMintedQty = 0;
    uint256 public giftedQty = 0;

    constructor() ERC721("Monaverse", "MONA") Whitelist("Monaverse", "1") {}

    function preSalesMint(
        uint256 _signedQty,
        uint256 _nonce,
        bytes memory _signature
    )
        external
        payable
        isPreSalesActive
        isSenderWhitelisted(_signedQty, _nonce, _signature)
    {
        require(
            preSalesMintedQty + publicSalesMintedQty < SALES_MAX_QTY,
            "Exceed sales max limit"
        );
        require(
            preSalesMinterToTokenQty[msg.sender] +
                publicSalesMinterToTokenQty[msg.sender] <
                MAX_QTY_PER_MINTER,
            "Exceed max mint per minter"
        );
        require(
            preSalesMinterToTokenQty[msg.sender] < _signedQty,
            "Exceed signed quantity"
        );
        require(msg.value >= PRICE, "Insufficient ETH");
        require(tx.origin == msg.sender, "Contracts not allowed");

        preSalesMinterToTokenQty[msg.sender] += 1;
        preSalesMintedQty += 1;

        _safeMint(msg.sender, totalSupply() + 1);
    }

    function publicSalesMint() external payable isPublicSalesActive {
        require(
            preSalesMintedQty + publicSalesMintedQty < SALES_MAX_QTY,
            "Exceed sales max limit"
        );
        require(
            preSalesMinterToTokenQty[msg.sender] +
                publicSalesMinterToTokenQty[msg.sender] <
                MAX_QTY_PER_MINTER,
            "Exceed max mint per minter"
        );
        require(msg.value >= PRICE, "Insufficient ETH");
        require(tx.origin == msg.sender, "Contracts not allowed");

        publicSalesMinterToTokenQty[msg.sender] += 1;
        publicSalesMintedQty += 1;

        _safeMint(msg.sender, totalSupply() + 1);
    }

    function gift(address[] calldata receivers) external onlyOwner {
        require(
            giftedQty + receivers.length <= GIFT_MAX_QTY,
            "Exceed gift max limit"
        );

        giftedQty += receivers.length;

        for (uint256 i = 0; i < receivers.length; i++) {
            _safeMint(receivers[i], totalSupply() + 1);
        }
    }
}