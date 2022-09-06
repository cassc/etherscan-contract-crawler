// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./PublicSalesActivation.sol";
import "./Whitelist.sol";
import "./ERC721Opensea.sol";
import "./Withdrawable.sol";
import "./PrivateSalesActivation.sol";

contract StageOne is
    Ownable,
    EIP712,
    PublicSalesActivation,
    Whitelist,
    ERC721Opensea,
    Withdrawable,
    PrivateSalesActivation
{
    uint256 public TOTAL_SUPPLY = 100;
    uint256 public PUBLIC_MAX_QTY_PER_MINTER = 1;
    uint256 public PRICE = 0.064 ether;

    mapping(address => uint256) public privateSalesMinterToTokenQty;
    mapping(address => uint256) public publicSalesMinterToTokenQty;

    constructor() ERC721("Stage 1-1", "Stage1-1") Whitelist("Stage 1-1", "1") {}

    function publicSalesMint() external payable isPublicSalesActive {
        require(totalSupply() < TOTAL_SUPPLY, "Exceed sales max limit");
        require(
            publicSalesMinterToTokenQty[msg.sender] + 1 <=
                PUBLIC_MAX_QTY_PER_MINTER,
            "Exceed max mint per minter"
        );
        require(msg.value == PRICE, "Insufficient ETH");
        publicSalesMinterToTokenQty[msg.sender] += 1;
        uint256 newTokenId = totalSupply() + 1;
        _safeMint(msg.sender, newTokenId);
    }

    function privateSalesMint(
        uint256 _signedQty,
        uint256 _nonce,
        bytes memory _signature
    )
        external
        payable
        isPrivateSalesActive
        isSenderWhitelisted(_signedQty, _nonce, _signature)
    {
        require(totalSupply() < TOTAL_SUPPLY, "Exceed sales max limit");
        require(
            privateSalesMinterToTokenQty[msg.sender] + 1 <= _signedQty,
            "Exceed signed quantity"
        );
        require(msg.value == PRICE, "Insufficient ETH");
        privateSalesMinterToTokenQty[msg.sender] += 1;
        uint256 newTokenId = totalSupply() + 1;
        _safeMint(msg.sender, newTokenId);
    }

    function gift(address[] calldata receivers) external onlyOwner {
        require(totalSupply() + receivers.length < TOTAL_SUPPLY, "Exceed sales max limit");
        
        for (uint256 i = 0; i < receivers.length; i++) {
            _safeMint(receivers[i], totalSupply() + 1);
        }
    }
}