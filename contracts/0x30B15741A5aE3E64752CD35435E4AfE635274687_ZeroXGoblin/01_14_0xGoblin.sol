//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./CommonNft.sol";

contract ZeroXGoblin is CommonNft {
    uint256 public maxFreeMintAmountPerTx;
    uint256 public maxMintAmountPerTx;

    constructor()
        CommonNft(
            "0xGoblin",
            "XGBN",
            CommonNft.Config(5000, 0, 4000, 0.0045 ether, 10, "")
        )
    {
        maxFreeMintAmountPerTx = 3;
        maxMintAmountPerTx = 10;
    }

    function setBundleProps(
        uint256 maxFreeMintAmountPerTx_,
        uint256 maxMintAmountPerTx_
    ) external onlyOwner {
        maxFreeMintAmountPerTx = maxFreeMintAmountPerTx_;
        maxMintAmountPerTx = maxMintAmountPerTx_;
    }

    function mint(uint256 quantity) external payable override nonReentrant {
        require(isMintStarted, "Not started");
        require(tx.origin == msg.sender, "Contracts not allowed");
        uint256 pubMintSupply = config.maxSupply - config.reserved;
        require(
            totalSupply() + quantity <= pubMintSupply,
            "Exceed sales max limit"
        );
        require(
            numberMinted(msg.sender) + quantity <= config.maxTokenPerAddress,
            "can not mint this many"
        );
        if (totalSupply() >= config.firstFreeMint) {
            require(
                quantity <= maxMintAmountPerTx,
                "Mint quantity need smaller"
            );
            uint256 cost;
            unchecked {
                cost = quantity * config.mintPrice;
            }
            require(msg.value == cost, "wrong payment");
        } else {
            require(
                quantity <= maxFreeMintAmountPerTx,
                "Free mint quantity need smaller"
            );
        }
        _safeMint(msg.sender, quantity);
    }
}