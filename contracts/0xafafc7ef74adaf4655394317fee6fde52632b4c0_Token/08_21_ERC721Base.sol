// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";

abstract contract ERC721Base is ERC721, Ownable {
    string public baseURI;
    string public contractURI;
    uint256 private _totalSupply;
    uint256 public totalMaxSupply;

    constructor(
        uint256 _totalMaxSupply,
        string memory _name,
        string memory _symbol,
        string memory baseURI_,
        string memory _contractURI
    ) ERC721(_name, _symbol) {
        baseURI = baseURI_;
        contractURI = _contractURI;
        totalMaxSupply = _totalMaxSupply;
    }

    /**
     * @dev Transfers available payment tokens from contract address to the contact owner address
     * @param paymentTokenAddress Payment token address
     */
    function withdrawContractTokens(address paymentTokenAddress) external onlyOwner {
        require(
            IERC20(paymentTokenAddress).transfer(owner(), IERC20(paymentTokenAddress).balanceOf(address(this))),
            "Failed to withdraw"
        );
    }

    /**
     * @dev Transfers contract available ether balance to the contact owner address
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            (bool sent, ) = payable(owner()).call{value: balance}("");
            require(sent, "Failed to send Ether");
        }
    }

    /**
     * @dev Updates token base URI
     * @param baseURI_ New URI to be set
     */
    function setURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    /**
     * @dev Updates contract URI
     * @param _contractURI New contract URI to be set
     */
    function setContractURI(string memory _contractURI) external onlyOwner {
        contractURI = _contractURI;
    }

    /**
     * @dev Returns token metadata base URI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Total amount of tokens.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _totalSupply += 1;
        }

        if (to == address(0)) {
            uint256 supply = _totalSupply;
            require(supply > 0, "ERC721: burn amount exceeds totalSupply");
            unchecked {
                _totalSupply -= 1;
            }
        }
    }
}