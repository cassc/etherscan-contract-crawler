// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

/// @title Index router interface
/// @notice Describes methods allowing to mint and redeem index tokens
interface IIndexRouter {
    struct MintParams {
        address index;
        uint256 amountInBase;
        address recipient;
    }

    struct MintSwapParams {
        address index;
        address inputToken;
        uint256 amountInInputToken;
        address recipient;
        MintQuoteParams[] quotes;
    }

    struct MintSwapValueParams {
        address index;
        address recipient;
        MintQuoteParams[] quotes;
    }

    struct BurnParams {
        address index;
        uint256 amount;
        address recipient;
    }

    struct BurnSwapParams {
        address index;
        uint256 amount;
        address outputAsset;
        address recipient;
        BurnQuoteParams[] quotes;
    }

    struct MintQuoteParams {
        address asset;
        address swapTarget;
        uint256 buyAssetMinAmount;
        bytes assetQuote;
    }

    struct BurnQuoteParams {
        address swapTarget;
        uint256 buyAssetMinAmount;
        bytes assetQuote;
    }

    /// @notice Initializes IndexRouter
    /// @param _WETH WETH address
    /// @param _registry IndexRegistry contract address
    function initialize(address _WETH, address _registry) external;

    /// @notice Mints index in exchange for appropriate index tokens withdrawn from the sender
    /// @param _params Mint params structure containing mint amounts, token references and other details
    /// @return _amount Amount of index to be minted for the given assets
    function mint(MintParams calldata _params) external returns (uint256 _amount);

    /// @notice Mints index in exchange for specified asset withdrawn from the sender
    /// @param _params Mint params structure containing mint recipient, amounts and other details
    /// @return _amount Amount of index to be minted for the given amount of the specified asset
    function mintSwap(MintSwapParams calldata _params) external returns (uint256 _amount);

    /// @notice Mints index in exchange for specified asset withdrawn from the sender
    /// @param _params Mint params structure containing mint recipient, amounts and other details
    /// @param _deadline Maximum unix timestamp at which the signature is still valid
    /// @param _v Last byte of the signed data
    /// @param _r The first 64 bytes of the signed data
    /// @param _s Bytes 64…128 of the signed data
    /// @return _amount Amount of index to be minted for the given amount of the specified asset
    function mintSwapWithPermit(MintSwapParams calldata _params, uint256 _deadline, uint8 _v, bytes32 _r, bytes32 _s)
        external
        returns (uint256 _amount);

    /// @notice Mints index in exchange for ETH withdrawn from the sender
    /// @param _params Mint params structure containing mint recipient, amounts and other details
    /// @return _amount Amount of index to be minted for the given value
    function mintSwapValue(MintSwapValueParams calldata _params) external payable returns (uint256 _amount);

    /// @notice Burns index and returns corresponding amount of index tokens to the sender
    /// @param _params Burn params structure containing burn recipient, amounts and other details
    function burn(BurnParams calldata _params) external;

    /// @notice Burns index and returns corresponding amount of index tokens to the sender
    /// @param _params Burn params structure containing burn recipient, amounts and other details
    /// @return _amounts Returns amount of tokens returned after burn
    function burnWithAmounts(BurnParams calldata _params) external returns (uint256[] memory _amounts);

    /// @notice Burns index and returns corresponding amount of index tokens to the sender
    /// @param _params Burn params structure containing burn recipient, amounts and other details
    /// @param _deadline Maximum unix timestamp at which the signature is still valid
    /// @param _v Last byte of the signed data
    /// @param _r The first 64 bytes of the signed data
    /// @param _s Bytes 64…128 of the signed data
    function burnWithPermit(BurnParams calldata _params, uint256 _deadline, uint8 _v, bytes32 _r, bytes32 _s)
        external;

    /// @notice Burns index and returns corresponding amount of specified asset to the sender
    /// @param _params Burn params structure containing burn recipient, amounts and other details
    function burnSwap(BurnSwapParams calldata _params) external returns (uint256 _amount);

    /// @notice Burns index and returns corresponding amount of specified asset to the sender
    /// @param _params Burn params structure containing burn recipient, amounts and other details
    /// @param _deadline Maximum unix timestamp at which the signature is still valid
    /// @param _v Last byte of the signed data
    /// @param _r The first 64 bytes of the signed data
    /// @param _s Bytes 64…128 of the signed data
    function burnSwapWithPermit(BurnSwapParams calldata _params, uint256 _deadline, uint8 _v, bytes32 _r, bytes32 _s)
        external
        returns (uint256 _amount);

    /// @notice Burns index and returns corresponding amount of ETH to the sender
    /// @param _params Burn params structure containing burn recipient, amounts and other details
    function burnSwapValue(BurnSwapParams calldata _params) external returns (uint256 _amount);

    /// @notice Burns index and returns corresponding amount of ETH to the sender
    /// @param _params Burn params structure containing burn recipient, amounts and other details
    /// @param _deadline Maximum unix timestamp at which the signature is still valid
    /// @param _v Last byte of the signed data
    /// @param _r The first 64 bytes of the signed data
    /// @param _s Bytes 64…128 of the signed data
    function burnSwapValueWithPermit(
        BurnSwapParams calldata _params,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external returns (uint256 _amount);

    /// @notice Index registry address
    /// @return Returns index registry address
    function registry() external view returns (address);

    /// @notice WETH contract address
    /// @return Returns WETH contract address
    function WETH() external view returns (address);

    /// @notice Amount of index to be minted for the given amount of token
    /// @param _params Mint params structure containing mint recipient, amounts and other details
    /// @return _amount Amount of index to be minted for the given amount of token
    function mintSwapIndexAmount(MintSwapParams calldata _params) external view returns (uint256 _amount);

    /// @notice Amount of tokens returned after index burn
    /// @param _index Index contract address
    /// @param _amount Amount of index to burn
    /// @return _amounts Returns amount of tokens returned after burn
    function burnTokensAmount(address _index, uint256 _amount) external view returns (uint256[] memory _amounts);
}