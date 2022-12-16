//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./BaseMintModuleCloneable.sol";
import "../../interfaces/modules/minting/IMintingModule.sol";

contract MintsPerAddress is BaseMintModuleCloneable, IMintingModule {
    mapping(address => bool) public hasAddressMinted;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializer function for contract creation
    /// @param _admin The address of the admin
    /// @param _minter The address of the wallet or contract that can call canMint (passport/LL)
    /// @param data encoded uint256 maxClaim - max amount of tokens per address & uint256 mintPrice - price per token in wei
    function initialize(
        address _admin,
        address _minter,
        bytes calldata data
    ) external override initializer {
        (uint256 _maxClaim, uint256 _mintPrice) = abi.decode(data, (uint256, uint256));
        __BaseMintModule_init(_admin, _minter, _maxClaim, _mintPrice);
    }

    /// @notice Mint Passport token(s) to caller
    /// @dev Must first enable claim & set fee/amount (if desired)
    /// @param minter address The address to mint to
    /// @param value uint256 amount eth sent to minting transaction, in wei
    /// @param mintAmounts uint256[] amount of tokens to mint per tokenId
    function canMint(
        address minter,
        uint256 value,
        uint256[] calldata, /*tokenIds*/
        uint256[] calldata mintAmounts,
        bytes32[] calldata, /*proof*/
        bytes calldata /*data*/
    ) external onlyMinter returns (uint256) {
        require(isActive, "T6");
        require(!hasAddressMinted[minter], "T12");
        require(mintAmounts[0] <= maxClaim, "T7");
        require(value == mintPrice * mintAmounts[0], "T8");

        hasAddressMinted[minter] = true;

        return mintAmounts[0];
    }
}