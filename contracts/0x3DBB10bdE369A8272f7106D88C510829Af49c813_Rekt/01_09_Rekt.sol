// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract Rekt is ERC1155 {
    bool public isSaleActive;

    uint256 public immutable limit;
    uint256 public minted;
    address public owner;
    uint256 public limitPerWallet;

    constructor(string memory _uri) ERC1155(_uri) {
        owner = msg.sender;
        limit = type(uint256).max;
        minted = 0;
        limitPerWallet = 1;
        isSaleActive = false;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }

    function setUri(string memory uri) external onlyOwner {
        _setURI(uri);
    }

    function setLimitPerWallet(uint256 _limitPerWallet) external onlyOwner {
        limitPerWallet = _limitPerWallet;
    }

    function setSaleActive(bool _isSaleActive) external onlyOwner {
        isSaleActive = _isSaleActive;
    }

    function mint() external {
        if (!isSaleActive) revert SaleNotActive();
        if (minted >= limit) revert SoldOut();
        if (balanceOf(msg.sender, 0) >= limitPerWallet)
            revert LimitPerWalletReached();
        minted += 1;
        _mint(msg.sender, 0, 1, "");
    }

    error SoldOut();
    error SaleNotActive();
    error OnlyOwner();
    error LimitPerWalletReached();
}