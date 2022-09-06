// SPDX-License-Identifier: MIT

/*

██╗  ██╗██╗██╗     ██╗      █████╗ ██████╗  █████╗ ███████╗███████╗███████╗███████╗
██║ ██╔╝██║██║     ██║     ██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔════╝██╔════╝██╔════╝
█████╔╝ ██║██║     ██║     ███████║██████╔╝███████║███████╗███████╗█████╗  ███████╗
██╔═██╗ ██║██║     ██║     ██╔══██║██╔═══╝ ██╔══██║╚════██║╚════██║██╔══╝  ╚════██║
██║  ██╗██║███████╗███████╗██║  ██║██║     ██║  ██║███████║███████║███████╗███████║
╚═╝  ╚═╝╚═╝╚══════╝╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝╚══════╝

*/

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/* --------
    Structs
   -------- */

struct TokenConfig {
    bool open;
    uint256 price;
    uint256 max;
    uint256 allowance;
    address burner;
    string uri;
    bool supplyFinalized;
}

/* --------
    Errors
   -------- */

error MintClosed();
error SupplyOverflow();
error DidntSendEnoughEth();
error AllowanceOverflow();
error ArrayLengthMismatch();
error NotAllowed();
error SupplyFinalized();
error WithdrawalFailed();

/* ------
    Main
   ------ */

contract KILLAPASSES is ERC1155, Ownable {
    mapping(uint256 => TokenConfig) public configurations;
    mapping(uint256 => uint256) public minted;
    mapping(uint256 => mapping(address => uint256)) public mintedPerWallet;

    constructor() ERC1155("") {}

    /* ---------
        Minting
       --------- */

    /// @notice Mint tokens
    function mint(uint256 typeId, uint256 n) external payable {
        TokenConfig memory config = configurations[typeId];

        if (config.supplyFinalized) revert SupplyFinalized();
        if (!config.open) revert MintClosed();
        if (msg.value < config.price * n) revert DidntSendEnoughEth();
        if (minted[typeId] + n > config.max) revert SupplyOverflow();
        if (mintedPerWallet[typeId][msg.sender] + n > config.allowance)
            revert AllowanceOverflow();

        mintedPerWallet[typeId][msg.sender] += n;
        minted[typeId] += n;
        _mint(msg.sender, typeId, n, "");
    }

    /// @notice Airdrop tokens
    function airdrop(
        uint256 typeId,
        address[] calldata addresses,
        uint256[] calldata amounts
    ) external onlyOwner {
        if (addresses.length != amounts.length) revert ArrayLengthMismatch();

        TokenConfig memory config = configurations[typeId];

        if (config.supplyFinalized) revert SupplyFinalized();

        uint256 total = 0;
        for (uint256 i = 0; i < amounts.length; i++) total += amounts[i];
        if (minted[typeId] + total > config.max) revert SupplyOverflow();

        for (uint256 i = 0; i < amounts.length; i++) {
            uint256 n = amounts[i];
            _mint(addresses[i], typeId, n, "");
        }

        minted[typeId] += total;
    }

    /* ---------
        Burning
       --------- */

    /// @dev Burns tokens so they can be used
    function burn(
        uint256 typeId,
        address owner,
        uint256 n
    ) external {
        if (msg.sender != configurations[typeId].burner) revert NotAllowed();
        _burn(owner, typeId, n);
    }

    /* ---------------
        Configuration
       --------------- */

    /// @notice Configure a token type
    function configureTokenType(uint256 typeId, TokenConfig calldata config)
        external
        onlyOwner
    {
        if (configurations[typeId].supplyFinalized) revert SupplyFinalized();
        configurations[typeId] = config;
    }

    /// @notice Toggle mint on/off for a given token type
    function toggleMint(uint256 typeId, bool open) external onlyOwner {
        configurations[typeId].open = open;
    }

    /// @notice Set the price for a given token type
    function setPrice(uint256 typeId, uint256 price) external onlyOwner {
        configurations[typeId].price = price;
    }

    /// @notice Set max supply for a given token type
    function setMax(uint256 typeId, uint256 max) external onlyOwner {
        if (configurations[typeId].supplyFinalized) revert SupplyFinalized();
        configurations[typeId].max = max;
    }

    /// @notice Set the max amount a person can mint for a given token type
    function setAllowance(uint256 typeId, uint256 a) external onlyOwner {
        configurations[typeId].allowance = a;
    }

    /// @notice Set the burner address for a given token type
    function setBurner(uint256 typeId, address burner) external onlyOwner {
        configurations[typeId].burner = burner;
    }

    /// @notice Set the uri for a given token type
    function setURI(uint256 typeId, string calldata _uri) external onlyOwner {
        configurations[typeId].uri = _uri;
    }

    /// @notice Set the burner address for a given token type
    function finalizeSupply(uint256 typeId) external onlyOwner {
        configurations[typeId].supplyFinalized = true;
    }

    /* -------
        Other
       ------- */

    /// @dev Returns the URI for a given token type
    function uri(uint256 typeId) public view override returns (string memory) {
        return configurations[typeId].uri;
    }

    /// @notice Withdraw all funds
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}