// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";

interface IUnikuraPhygitalCollection is IERC721AUpgradeable {
    /**
     * @dev Emit an event the Unikura Mothership Contract address is set
     */
    event UnikuraMothershipContract(address unikuraMothershipContract);

    /**
     * @dev Emit an event when sales address is set
     */
    event SalesAddress(address salesAddress);

    /**
     * @dev Emit an event when mint price is set
     */
    event MintPrice(uint256 mintPrice);

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    function initialize(
        string memory name_,
        string memory symbol_,
        address unikuraMothership_,
        address payable salesAddress_,
        uint8 maxTokens_,
        uint256 mintPrice_
    ) external;

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    function setBaseURI(string calldata baseURI_) external;

    // =============================================================
    //                   TOKEN COUNTING OPERATIONS
    // =============================================================

    function totalSupply() external view returns (uint256);

    function totalMinted() external view returns (uint256);

    // =============================================================
    //                        MINT OPERATIONS
    // =============================================================

    function mint(address to, uint256 quantity) external payable;

    function calculateFee(uint256 totalPrice) external view returns (uint256);

    function velvettFeeRecipient() external view returns (address payable);

    // =============================================================
    //                        UNIKURA OPERATIONS
    // =============================================================

    function unikuraMothership() external view returns (address);

    function setUnikuraMothershipContract(address unikuraMothership_) external;

    function salesAddress() external view returns (address);

    function setSalesAddress(address payable salesAddress_) external;

    function mintPrice() external view returns (uint256);

    function setMintPrice(uint256 mintPrice_) external;

    function maxTokens() external view returns (uint256);

    function totalMintedTokens() external view returns (uint256);
}