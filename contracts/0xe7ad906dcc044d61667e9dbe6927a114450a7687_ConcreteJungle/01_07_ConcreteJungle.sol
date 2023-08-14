// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract ConcreteJungle is Ownable, Pausable {
    IERC721 public immutable defiApes;

    IERC20 public immutable apeFi;

    uint256 public constant SELL_PRICE = 100000e18;

    uint256 public constant BUY_PRICE = 200000e18;

    event Buy(address indexed buyer, uint256[] tokenIds);
    event Sell(address indexed seller, uint256[] tokenIds);

    constructor(address defiApes_, address apeFi_) {
        defiApes = IERC721(defiApes_);
        apeFi = IERC20(apeFi_);
    }

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "EOA only");
        _;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function sellDefiApes(uint256[] memory tokenIds) public whenNotPaused onlyEOA {
        for (uint256 i = 0; i < tokenIds.length;) {
            uint256 tokenId = tokenIds[i];
            require(defiApes.ownerOf(tokenId) == msg.sender, "not owner");

            defiApes.transferFrom(msg.sender, address(this), tokenId);

            unchecked {
                i++;
            }
        }

        uint256 amount = tokenIds.length * SELL_PRICE;
        require(apeFi.balanceOf(address(this)) >= amount, "insufficient balance");

        apeFi.transfer(msg.sender, amount);

        emit Sell(msg.sender, tokenIds);
    }

    function buyDefiApes(uint256[] memory tokenIds) public whenNotPaused onlyEOA {
        for (uint256 i = 0; i < tokenIds.length;) {
            uint256 tokenId = tokenIds[i];
            require(defiApes.ownerOf(tokenId) == address(this), "not owner");

            defiApes.transferFrom(address(this), msg.sender, tokenId);

            unchecked {
                i++;
            }
        }

        uint256 amount = tokenIds.length * BUY_PRICE;
        require(apeFi.balanceOf(msg.sender) >= amount, "insufficient balance");

        apeFi.transferFrom(msg.sender, address(this), amount);

        emit Buy(msg.sender, tokenIds);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function withdrawDefiApes(uint256[] memory tokenIds) external onlyOwner {
        for (uint256 i = 0; i < tokenIds.length;) {
            uint256 tokenId = tokenIds[i];
            require(defiApes.ownerOf(tokenId) == address(this), "not owner");

            defiApes.transferFrom(address(this), owner(), tokenId);

            unchecked {
                i++;
            }
        }
    }

    function withdrawApeFi(uint256 amount) external onlyOwner {
        require(apeFi.balanceOf(address(this)) >= amount, "insufficient balance");

        apeFi.transfer(owner(), amount);
    }
}