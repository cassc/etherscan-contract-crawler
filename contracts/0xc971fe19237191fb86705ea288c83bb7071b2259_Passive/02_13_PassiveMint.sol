//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721BaseTokenURI.sol";

contract PassiveMint is ERC721BaseTokenURI {
    enum State {
        Paused,
        Minting
    }

    mapping(uint256 => string) private _roninAddressForTokenId;
    uint256 private _maxPerWalletAndMint;
    uint256 private _maxSupply;
    State public state = State.Paused;
    uint256 public tokenCount = 0;
    uint256 private _tokenPrice;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        uint256 maxPerWalletAndMint,
        uint256 maxSupply,
        uint256 tokenPrice
    ) ERC721BaseTokenURI(name, symbol, baseTokenURI) {
        _maxPerWalletAndMint = maxPerWalletAndMint;
        _maxSupply = maxSupply;
        _tokenPrice = tokenPrice;
    }

    function roninAddressForTokenId(uint256 tokenId)
        external
        view
        returns (string memory)
    {
        require(_exists(tokenId), "Token doesn't exist.");
        return _roninAddressForTokenId[tokenId];
    }

    function setState(State _state) external onlyOwner {
        state = _state;
    }

    function mint(uint256 numberOfTokens, string calldata roninAddress)
        external
        payable
    {
        require(state == State.Minting, "The sale is paused.");
        require(
            numberOfTokens > 0 && numberOfTokens <= _maxPerWalletAndMint,
            "Invalid number of tokens."
        );
        require(
            tokenCount + numberOfTokens <= _maxSupply,
            "Not enough tokens left."
        );
        require(
            balanceOf(_msgSender()) + numberOfTokens <= _maxPerWalletAndMint,
            "Max per wallet exceeded!"
        );
        require(
            msg.value >= numberOfTokens * _tokenPrice,
            "Not enough ETH sent."
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            tokenCount++;
            uint256 tokenId = tokenCount;
            _roninAddressForTokenId[tokenId] = roninAddress;
            _mint(_msgSender(), tokenId);
        }
    }

    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = owner().call{value: balance}("");
        require(success, "Withdraw failed.");
    }

    function burn(uint256 tokenId) public virtual {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721Burnable: caller is not owner nor approved"
        );
        _burn(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from != address(0)) {
            require(
                to == address(0),
                "Tokens can only be transferred to the burn address."
            );
        }
    }
}