//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "../AdventurersStorage.sol";

/**
 * @notice Presale (Crystal exchange) stage of Adventurers Token workflow
 */
abstract contract PreSale is AdventurersStorage {
    using ERC165Checker for address;

    string constant internal invalidPayment = "presale: invalid payment amount";
    string constant internal invalidCount = "presale: invalid count";
    string constant internal invalid1155 = "presale: 0 or valid IERC1155";

    
    /// @notice PreSaleConfig struct.
    /// @param price The PreSale price.
    /// @param tokensPerCrystal The amount of tokens per crystal.
    struct PresaleConfig {
        uint128 price;
        uint32 tokensPerCrystal;
    }

    /// @notice Address to the crystal smart contract. 
    address public crystal;

    /// @notice Returns the preSaleConfig.
    PresaleConfig public presaleConfig = PresaleConfig({
        price: 0.095 ether,
        tokensPerCrystal: 4 // 3 + extra 1 for <
    });

    modifier cost(uint _count) {
        PresaleConfig memory _cfg = presaleConfig;
        if (msg.value != _cfg.price * _count) revert ErrorMessage(invalidPayment);
        _;
    }

    /// @dev Emittet if the presale is disabled.
    error PresaleDisabled();

    event PreSaleConfigSet(
        uint128 indexed price,
        uint32 indexed tokensPerCrystal
    );

    event CrystalSet(address indexed value);

    /// @notice Used by the crystal holders to mint from the presale.
    /// @dev Transfers the crytstal nft from the msg.sender to this contract.
    /// @param _count The amount of tokens to mint. 
    /// @param _id The tokenId of the crystal held by the msg.sender.
    function mintCrystalHolders(uint _count, uint _id) 
        external 
        payable 
        cost(_count)
    {
        if(crystal == address(0)) revert PresaleDisabled();
        PresaleConfig memory _cfg = presaleConfig;
        if (_count <= 0 && _count > _cfg.tokensPerCrystal) revert ErrorMessage(invalidCount);

        IERC1155(crystal).safeTransferFrom(msg.sender, address(this), _id, 1, "");
        
        _mint(msg.sender, _count);
    } 
    
    /// @notice Used to adjust the presale config values.
    /// @dev Restricted with onlyOwner modifier. 
    /// @param _price The presale mint price.
    /// @param _tokensPerCrystal The tokens required per crystal.
    function setPresaleConfig(uint128 _price, uint32 _tokensPerCrystal) external onlyOwner {
        presaleConfig = PresaleConfig({
            price: _price,
            tokensPerCrystal: _tokensPerCrystal + 1
        });
        emit PreSaleConfigSet(_price, _tokensPerCrystal +1);
    }

    /// @notice Used to set the Crystal contract address.
    /// @dev Restricted to onlyOwner modifier.
    /// @param _value The Crystal contract address
    function setCrystal(address _value) external onlyOwner {
        require(_value == address(0) 
            || _value.supportsInterface(type(IERC1155).interfaceId),
            invalid1155);

        crystal = _value;
        
        if (_value != address(0)) {
            IERC1155(_value).setApprovalForAll(owner(), true); // we want to regift crystals
        }
        emit CrystalSet(_value);
    }
}