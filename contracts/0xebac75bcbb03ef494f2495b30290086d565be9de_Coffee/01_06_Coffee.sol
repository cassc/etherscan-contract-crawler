// SPDX-License-Identifier: MIT
//
//
//  ▄████████  ▄██████▄     ▄████████    ▄████████    ▄████████    ▄████████
// ███    ███ ███    ███   ███    ███   ███    ███   ███    ███   ███    ███
// ███    █▀  ███    ███   ███    █▀    ███    █▀    ███    █▀    ███    █▀
// ███        ███    ███  ▄███▄▄▄      ▄███▄▄▄      ▄███▄▄▄      ▄███▄▄▄
// ███        ███    ███ ▀▀███▀▀▀     ▀▀███▀▀▀     ▀▀███▀▀▀     ▀▀███▀▀▀
// ███    █▄  ███    ███   ███          ███          ███    █▄    ███    █▄
// ███    ███ ███    ███   ███          ███          ███    ███   ███    ███
// ████████▀   ▀██████▀    ███          ███          ██████████   ██████████
//
//
//

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IManagersTBA {
    function balanceOf(address owner) external view returns (uint256);

    function showTBA(uint256 id) external view returns (address);
}

contract Coffee is ERC20, Ownable {
    bool public limited;
    uint256 public maxHoldingAmount;
    uint256 public minHoldingAmount;
    address public uniswapV2Pair;

    bool public mintLive = true;
    mapping(address => bool) private mintedStatus;
    IManagersTBA public ManagersTBA;

    // Supply params
    uint256 public constant MAX_SUPPLY = 100e6 ether;
    uint256 mintAmount = 25e3 ether;
    uint256 burnAmount = 1 ether;
    uint256 public roundNumber = 0;

    constructor(uint256 _initialSupply, address _tba) ERC20("Coffee", "MUG") {
        ManagersTBA = IManagersTBA(_tba);
        // Used for Uniswap LP
        _mint(msg.sender, _initialSupply); // 100000000000000000000000000 / 2
        // Used for TBA Airdrop
        _mint(address(this), _initialSupply);
    }

    // Setters
    function mintTokens(uint256 tokenId) public {
        // Find TBA for this TokenId
        // We dont check if the sender  is the TBA owner, we just check if the TBA has minted this token
        // If someone wants to mint for someone else, they can do that :)

        address TBA = ManagersTBA.showTBA(tokenId);

        require(roundNumber < 2500, "Mint is finished");
        require(mintLive, "Mint is finished");
        require(mintedStatus[TBA] == false, "Already airdroped ERC20 to this TBA");
        require(ManagersTBA.balanceOf(msg.sender) != 0, "You dont own any Managers NFT");

        // Transfer from SC to TBA
        mintedStatus[TBA] = true;
        require(balanceOf(address(this)) >= mintAmount, "Not enough tokens in the contract");
        _transfer(address(this), TBA, mintAmount);
        _burn(address(this), burnAmount);
        // Decrease mintAmount so reward the most early minters, burn more with each new claim
        mintAmount -= 5 ether;
        burnAmount += 1 ether;
        roundNumber++;
    }

    // Batch mint for users with multiple TBAs
    function mintBatch(uint256[] memory tokenIds, uint256 _mintAmount) public {
        uint256 minted = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            // Check if this one is already minted
            address TBA = ManagersTBA.showTBA(tokenIds[i]);
            if (mintedStatus[TBA] == false && minted < _mintAmount) {
                mintTokens(tokenIds[i]);
                minted++;
            }
        }
    }

    function setRule(
        bool _limited,
        address _uniswapV2Pair,
        uint256 _maxHoldingAmount,
        uint256 _minHoldingAmount
    ) external onlyOwner {
        limited = _limited;
        uniswapV2Pair = _uniswapV2Pair;
        maxHoldingAmount = _maxHoldingAmount;
        minHoldingAmount = _minHoldingAmount;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        // We check if traiding is started but also permit owner to transfer tokens to uniswap pool
        if (uniswapV2Pair == address(0)) {
            require(from == owner() || to == owner() || to == address(this), "Trading not started");
            return;
        }

        // Check the limits once trading is limited, after that just ignore
        if (limited && from == uniswapV2Pair) {
            require(
                super.balanceOf(to) + amount <= maxHoldingAmount && super.balanceOf(to) + amount >= minHoldingAmount,
                "Forbid"
            );
        }
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }

    // Burn unclaimed supply
    function burnSupply() external onlyOwner {
        _burn(address(this), balanceOf(address(this)));
    }

    function setMintStatus(bool status) external onlyOwner {
        mintLive = status;
    }

    // Getters

    function checkMintedStatus(uint256 tokenId) external view returns (bool) {
        return mintedStatus[ManagersTBA.showTBA(tokenId)];
    }

    function showUnclaimedSupply() external view returns (uint256) {
        return balanceOf(address(this));
    }
}