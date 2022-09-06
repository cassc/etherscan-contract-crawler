pragma solidity ^0.8.6;

import "../interfaces/ICombinableTokenBasis.sol";
import "../interfaces/ICombinationToken.sol";
import "./Basis.sol";
import "./Withdrawable.sol";

contract CombinableTokenBasis is ICombinableTokenBasis, Basis, Withdrawable {
    ICombinationToken internal child_;
    bool public transferProhibitedForCombined;
    bool public transferProhibited;
    bool internal soldOut_;

    event SetChildAddress(address child);
    event SetTransferProhibitedForCombined(bool prohibited);
    event SetTransferProhibited(bool prohibited);

    constructor(
        address _proxyRegistry,
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        string memory _contractURI,
        address _paymentToken
    )
    Basis(
        _proxyRegistry,
        _name,
        _symbol,
        _baseURI,
        _contractURI,
        _paymentToken
    )
    {
    }

    function soldOut() external view override returns (bool){
        return soldOut_;
    }

    function child() external view override returns (ICombinationToken) {
        return child_;
    }

    function setChildAddress(address _child) external override onlyOwner {
        child_ = ICombinationToken(_child);

        emit SetChildAddress(_child);
    }

    function setTransferProhibitedForCombined(bool _prohibited) external override onlyOwner {
        transferProhibitedForCombined = _prohibited;

        emit SetTransferProhibitedForCombined(_prohibited);
    }

    function setTransferProhibited(bool _prohibited) external override onlyOwner {
        transferProhibited = _prohibited;

        emit SetTransferProhibited(_prohibited);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        if (transferProhibited || (transferProhibitedForCombined && child_.baseIsCombined(tokenId))) {
            require(
                from == address(0),
                "CombinableTokenBasis: Sorry, it is prohibited to transfer Base tokens"
            );
        }
    }
}