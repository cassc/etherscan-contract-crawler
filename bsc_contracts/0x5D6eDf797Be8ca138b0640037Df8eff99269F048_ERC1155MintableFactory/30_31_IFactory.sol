// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../libraries/structs.sol";

interface IERC1155Factory {
    function createERC1155(
        address owner,
        string calldata name,
        string calldata symbol,
        ERC1155Config calldata configuration,
        PriceRule[] calldata rules
    ) external;
}

interface IERC721Factory {
    function createERC721(
        address owner,
        string calldata name,
        string calldata symbol
    ) external;
}

interface IERC721AMintableFactory {
    function createERC721AMintable(
        address _stars,
        address _owner,
        bool _ethAllowed,
        bool _starsAllowed,
        uint256[] memory ethPrices,
        uint256[] memory starsPrices
    ) external;
}

interface IInitializableERC1155 {
    function init(
        address _owner,
        string memory _name,
        string memory _symbol,
        uint256[] calldata globalSupplyConfigs
    ) external;

    function setInitialPricingConfig(
        PriceStrategy _strategy,
        address[] calldata _acceptedTokens,
        uint256[] calldata _acceptedPrices,
        PriceRule[] calldata _pricingRules
    ) external;
}

interface IInitializableERC721 {
    function init(
        address _owner,
        string memory _name,
        string memory _symbol
    ) external;
}

interface IInitializableERC721AMintable {
    function init(
        address _stars,
        address _owner,
        bool _ethAllowed,
        bool _starsAllowed,
        uint256[] memory ethPrices,
        uint256[] memory starsPrices
    ) external;
}