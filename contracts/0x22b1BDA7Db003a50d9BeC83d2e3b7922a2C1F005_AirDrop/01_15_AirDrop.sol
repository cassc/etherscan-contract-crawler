// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract AirDrop is Ownable {
    using SafeERC20 for IERC20;

    address public constant NFTCONTRACT =
        0x9261B6239a85348E066867C366d3942648e24511;

    address public constant TOKENCONTRACT =
        0x1850b846fDB4d2EF026f54D520aa0322873f0Cbd;

    bool private airdropActive = true;
    uint256 private constant amount = 25000 ether;

    struct Claim {
        mapping(uint256 => bool) token_ids;
    }

    mapping(address => Claim) private claims;
    
    IERC20 token = IERC20(TOKENCONTRACT);

    constructor() {}

    function toogleSale() public onlyOwner {
        airdropActive = !airdropActive;
    }

    function emergencyClaim() public onlyOwner {
        token.safeTransfer(msg.sender, token.balanceOf(address(this)));
    }

    function getAmountToClaim(address owner) public view returns (uint256) {
        uint256 pay = 0;
        address account = owner;
        uint256 token_qty = ERC721(NFTCONTRACT).balanceOf(account);

        if (token_qty > 0) {
            for (uint256 i = 0; i < token_qty; i++) {
                uint256 token_id = ERC721Enumerable(NFTCONTRACT).tokenOfOwnerByIndex(account, i);

                if (!claims[owner].token_ids[token_id]) {
                    pay = pay + amount;
                }

            }
        }
        return pay;
    }

    function checkToken(address owner, uint256 tokenId) public view returns (bool) {
        return claims[owner].token_ids[tokenId];
    }

    function claim() external {
        require(airdropActive, "Claim are currently close");

        uint256 pay = 0;
        address account = msg.sender;

        uint256 token_qty = ERC721(NFTCONTRACT).balanceOf(account);
        require(token_qty > 0, "Error: You does not have Monkeys.");
        for (uint256 i = 0; i < token_qty; i++) {
            uint256 token_id = ERC721Enumerable(NFTCONTRACT).tokenOfOwnerByIndex(account, i);
            
            if (!claims[account].token_ids[token_id]) {
                pay = pay + amount;
                claims[account].token_ids[token_id] = true;
            }
        }

        require(pay > 0, "Error: no balance to withdraw.");
        token.safeTransfer(account, pay);
    }
}