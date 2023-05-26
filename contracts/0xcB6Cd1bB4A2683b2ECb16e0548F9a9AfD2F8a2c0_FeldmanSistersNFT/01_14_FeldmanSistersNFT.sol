// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract FeldmanSistersNFT is Ownable, ERC721Enumerable {
    using Math for uint256;

    uint256 public maxTotalSupply;
    bool public saleStarted;

    uint256 public priceInEther;
    uint256 public whitelistPerWallet;

    string public uri;

    mapping(address => bool) public whitelist;
    mapping(address => uint256) public whitelistMinted;

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        maxTotalSupply = 4096;
        priceInEther = 0.02 ether;
        whitelistPerWallet = 1;
    }

    function mint(uint256 mintCount_) external payable {
        require(saleStarted, "FSNFT: sale has not started");
        require(mintCount_ > 0, "FSNFT: zero mint");
        require(mintCount_ <= getMintLeft(), "FSNFT: cap reached");

        (uint256 whitelistMint_, uint256 normalMint_) = getMintCount(mintCount_);

        require(msg.value == normalMint_ * priceInEther, "FSNFT: wrong ether amount provided");

        whitelistMinted[msg.sender] += whitelistMint_;

        for (uint256 i = 0; i < mintCount_; i++) {
            _mint(msg.sender, totalSupply() + 1);
        }
    }

    function getMintLeft() public view returns (uint256) {
        return maxTotalSupply - totalSupply();
    }

    function getMintCount(uint256 mintCount_)
        public
        view
        returns (uint256 whitelistMint_, uint256 normalMint_)
    {
        if (whitelist[msg.sender]) {
            whitelistMint_ = mintCount_.min(
                whitelistPerWallet - whitelistMinted[msg.sender].min(whitelistPerWallet)
            );
        }

        normalMint_ = mintCount_ - whitelistMint_;
    }

    function triggerSale(bool start_) external onlyOwner {
        saleStarted = start_;
    }

    function setPrice(uint256 price_) external onlyOwner {
        priceInEther = price_;
    }

    function editWhitelist(address[] calldata users_, bool add_) external onlyOwner {
        for (uint256 i = 0; i < users_.length; i++) {
            whitelist[users_[i]] = add_;
        }
    }

    function setWhitelistPerWallet(uint256 amount_) external onlyOwner {
        whitelistPerWallet = amount_;
    }

    function setBaseURI(string calldata uri_) external onlyOwner {
        uri = uri_;
    }

    function withdrawEther(address recipient_) external onlyOwner {
        (bool status, ) = recipient_.call{value: address(this).balance}("");
        require(status, "FSNFT: failed transfer ether");
    }

    function _baseURI() internal view override returns (string memory) {
        return uri;
    }
}