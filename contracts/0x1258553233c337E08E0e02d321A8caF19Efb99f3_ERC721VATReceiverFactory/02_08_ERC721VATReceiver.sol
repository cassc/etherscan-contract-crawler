// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

struct TradeInfo {
    address seller;
    address buyer;
    uint256 tokenId;
    bool used;
}

interface IERC721VAT {
    function currentTradeInfo() external view returns (TradeInfo memory);

    function hasRole(bytes32 role, address account) external view returns (bool);

    function increaseTokenVAT(uint256 tokenId, uint256 vat) external;
}

contract ERC721VATReceiver is Ownable {
    using SafeERC20 for IERC20;

    bytes32 public constant MARKET_ROLE = keccak256("MARKET_ROLE");

    address payable public nftToken;

    constructor(address nft) {
        nftToken = payable(nft);
    }

    function setCollection(address nft) external onlyOwner {
        nftToken = payable(nft);
    }

    function receiveVAT() internal {
        IERC721VAT nftVAT = IERC721VAT(nftToken);
        if (!nftVAT.hasRole(MARKET_ROLE, msg.sender)) {
            return;
        }
        TradeInfo memory info = nftVAT.currentTradeInfo();
        if (info.used) {
            return;
        }
        nftVAT.increaseTokenVAT(info.tokenId, msg.value);
        nftToken.call{ value: msg.value }("");
    }

    receive() external payable {
        receiveVAT();
    }

    fallback() external payable {
        receiveVAT();
    }

    function withdraw(address payable to, uint256 amount) external onlyOwner {
        Address.sendValue(to, amount);
    }

    function withdrawERC20(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        IERC20(token).safeTransfer(to, amount);
    }
}