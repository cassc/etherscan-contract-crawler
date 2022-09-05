//SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import "@openzeppelin-v4/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin-v4/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../interfaces/IQuoteToken.sol";

contract ExplicitQuotationMetadata is IQuoteToken, IERC165 {
    string internal _quoteTokenName;
    string internal _quoteTokenSymbol;
    address internal immutable _quoteTokenAddress;
    uint8 internal immutable _quoteTokenDecimals;

    constructor(
        string memory quoteTokenName_,
        address quoteTokenAddress_,
        string memory quoteTokenSymbol_,
        uint8 quoteTokenDecimals_
    ) {
        _quoteTokenName = quoteTokenName_;
        _quoteTokenSymbol = quoteTokenSymbol_;
        _quoteTokenAddress = quoteTokenAddress_;
        _quoteTokenDecimals = quoteTokenDecimals_;
    }

    /// @inheritdoc IQuoteToken
    function quoteTokenName() public view virtual override returns (string memory) {
        return _quoteTokenName;
    }

    /// @inheritdoc IQuoteToken
    function quoteTokenAddress() public view virtual override returns (address) {
        return _quoteTokenAddress;
    }

    /// @inheritdoc IQuoteToken
    function quoteTokenSymbol() public view virtual override returns (string memory) {
        return _quoteTokenSymbol;
    }

    /// @inheritdoc IQuoteToken
    function quoteTokenDecimals() public view virtual override returns (uint8) {
        return _quoteTokenDecimals;
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IQuoteToken).interfaceId;
    }
}