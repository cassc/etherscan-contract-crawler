// SPDX-License-Identifier: MIT

/*
    __  __   ______   _  __    ______   ____
   / / / /  / ____/  | |/ /   / ____/  / __ \
  / /_/ /  / __/     |   /   / / __   / / / /
 / __  /  / /___    /   |   / /_/ /  / /_/ /
/_/ /_/  /_____/   /_/|_|   \____/   \____/

*/

pragma solidity ^0.8.4;
import "./ERC721A/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title HEXGONETWORK
 */
contract HEXGONETWORK is ERC721A, Ownable, Pausable, ReentrancyGuard {
    /** ===================== PUBLIC INFO / VARIABLES ===================== */

    string baseTokenURI;
    // string public placeholderTokenURI;
    bool public checkPublicSaleMint;
    uint256 public maxSupply;
    uint256 public mintLimit;
    uint256 public mintPrice;
    mapping(address => uint256) mintCount;

    /** ===================== CONTRACT INITIALIZATION ===================== */

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI_,
        uint256 maxSupply_,
        uint256 mintLimit_,
        uint256 mintPrice_
    ) ERC721A(name, symbol) {
        baseTokenURI = baseTokenURI_;
        maxSupply = maxSupply_;
        mintLimit = mintLimit_;
        mintPrice = mintPrice_;
    }

    /** ===================== OPERATIONAL FUNCTIONS ===================== */

    /// @notice Mints new NFTs
    /// @param many how many NFTs to mint
    function mint(uint256 many) public payable whenNotPaused nonReentrant {
        uint256 supply = totalSupply();
        address sender = _msgSender();

        require(checkPublicSaleMint, "Public sale is currently inactive");

        bool supplyNotReached = maxSupply == 0 || supply + many <= maxSupply;
        require(supplyNotReached, "Max supply reached");

        uint256 totalPrice = many * mintPrice;
        require(msg.value >= totalPrice, "Not enough funds transferred");

        uint256 count = mintCount[sender];
        require(count + many <= mintLimit, "Personal limit reached");

        mintCount[sender] = count + many;

        _mint(sender, many);

        uint256 rest = msg.value - totalPrice;
        if (rest > 0) {
            (bool success, ) = sender.call{value: rest}("");
            require(success);
        }
    }

    /// @notice Airdrop NFTS, calc amount to airdrop and adjust maxSupply if recepients is greater than max supply
    /// @param addresses address of who would be airdropped
     function airdrop(address[] memory addresses)
        external
        onlyOwner
        whenNotPaused
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            address recipient = addresses[i];
            _mint(recipient, 1);
        }
    }

    /** ===================== ADMINISTRATIVE FUNCTIONS ===================== */

    /// @notice Withdraws all ether from the contract
    /// @param to where withdraw the amount. Can be another contract address.
    function withdrawAll(address to) external onlyOwner {
        withdraw(to, address(this).balance);
    }

    /// @notice Withdraw the amount of ether from the contract
    /// @param to where withdraw the amount. Can be another contract address.
    /// @param amount to withdraw.
    function withdraw(address to, uint256 amount) public onlyOwner {
        uint256 balance = address(this).balance;
        require(amount <= balance);
        (bool success, ) = to.call{value: amount}("");
        require(success);
    }

    /// @notice Toggles public sale flag
    function togglePublicSaleState() external onlyOwner {
        checkPublicSaleMint = !checkPublicSaleMint;
    }

    /// @notice Sets max supply
    /// @param maxSupply_ that can be minted.
    function setMaxSupply(uint256 maxSupply_) external onlyOwner {
        maxSupply = maxSupply_;
    }

    /// @notice Sets public mint cost
    /// @param mintPrice_ for each minted item
    function setMintPrice(uint256 mintPrice_) external onlyOwner {
        mintPrice = mintPrice_;
    }

    /// @notice Sets public mint limit for each address
    /// @param mintLimit_ of mints for each address
    function setMintLimit(uint256 mintLimit_) external onlyOwner {
        mintLimit = mintLimit_;
    }

    /// @notice Sets base URI
    /// @param uri of the new base
    function setBaseURI(string memory uri) external onlyOwner {
        baseTokenURI = uri;
    }

    /// @notice Pauses the contract
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract
    function unpause() external onlyOwner {
        _unpause();
    }

    /** ===================== PRIVATE HELPER FUNCTIONS ===================== */

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    /// @dev Not allow transfer or selling of token. It can only be burned
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override whenNotPaused {
        if (owner() == msg.sender) {
            super._beforeTokenTransfers(from, to, startTokenId, quantity);
        } else {
            require(
                from == address(0) || to == address(0),
                "Token transfer/selling is BLOCKED"
            );
        }
    }
}