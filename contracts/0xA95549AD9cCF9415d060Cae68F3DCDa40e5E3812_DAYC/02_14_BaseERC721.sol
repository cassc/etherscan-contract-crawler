// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BaseERC721 is Ownable, ERC721A {
    uint256 public immutable FREE_MINT_MAX_QTY;
    uint256 public immutable TOTAL_MINT_MAX_QTY;
    uint256 public immutable GIFT_MAX_QTY;
    string private _tokenBaseURI;
    uint256 public maxFreeQtyPerWallet = 0;
    uint256 public mintedQty = 0;
    uint256 public giftedQty = 0;
    mapping(address => uint256) public minterToTokenQty;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 FREE_MINT_MAX_QTY_,
        uint256 GIFT_MAX_QTY_
    ) ERC721A(name_, symbol_) {
        FREE_MINT_MAX_QTY = FREE_MINT_MAX_QTY_;
        TOTAL_MINT_MAX_QTY = FREE_MINT_MAX_QTY_;
        GIFT_MAX_QTY = GIFT_MAX_QTY_;
    }

    function TOTAL_MAX_QTY() public view returns (uint256) {
        return FREE_MINT_MAX_QTY + GIFT_MAX_QTY;
    }

    function mint(uint256 _mintQty) external {
        require(mintedQty + _mintQty <= FREE_MINT_MAX_QTY, "MAXL");
        require(
            minterToTokenQty[msg.sender] + _mintQty <= maxFreeQtyPerWallet,
            "MAXF"
        );

        mintedQty += _mintQty;
        minterToTokenQty[msg.sender] += _mintQty;
        _safeMint(msg.sender, _mintQty);
    }

    function gift(address[] calldata receivers) external onlyOwner {
        require(giftedQty + receivers.length <= GIFT_MAX_QTY, "MAXG");

        giftedQty += receivers.length;
        for (uint256 i = 0; i < receivers.length; i++) {
            _safeMint(receivers[i], 1);
        }
    }

    function withdrawAll() external onlyOwner {
        require(address(this).balance > 0, "ZERO");
        payable(msg.sender).transfer(address(this).balance);
    }

    function setMaxFreeQtyPerWallet(uint256 _maxQtyPerWallet) external onlyOwner {
        maxFreeQtyPerWallet = _maxQtyPerWallet;
    }

    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    function _startTokenId() internal pure override(ERC721A) returns (uint256) {
        return 1;
    }

    function _baseURI()
        internal
        view
        override(ERC721A)
        returns (string memory)
    {
        return _tokenBaseURI;
    }
}