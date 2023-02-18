//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./BaseMintModuleCloneable.sol";
import "../../interfaces/modules/minting/IMintingModule.sol";

contract PricedMint is BaseMintModuleCloneable, IMintingModule {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializer function for contract creation
    /// @param _admin The address of the admin
    /// @param _minter The address of the wallet or contract that can call canMint (passport or LL)
    /// @param data encoded unint256 maxClaim - maximum amount of tokens per claim & mintPrice - price per token in wei
    function initialize(
        address _admin,
        address _minter,
        bytes calldata data
    ) external override initializer {
        (uint256 _maxClaim, uint256 _mintPrice) = abi.decode(data, (uint256, uint256));
        __BaseMintModule_init(_admin, _minter, _maxClaim, _mintPrice);
    }

    /// @notice Mint Passport token(s) to caller
    /// @dev Must first set isActive to true
    /// @param value uint256 amount eth sent to minting transaction, in wei
    /// @param mintAmounts uint256[] the first element in mintAmounts specifies the amount to mint
    function canMint(
        address, /*minter*/
        uint256 value,
        uint256[] calldata, /*tokenIds*/
        uint256[] calldata mintAmounts,
        bytes32[] calldata, /*proof*/
        bytes calldata /*data*/
    ) external view returns (uint256) {
        require(isActive, "T6");
        require(value == mintPrice * mintAmounts[0], "T8");
        require(mintAmounts[0] <= maxClaim, "T10");

        return mintAmounts[0];
    }
}