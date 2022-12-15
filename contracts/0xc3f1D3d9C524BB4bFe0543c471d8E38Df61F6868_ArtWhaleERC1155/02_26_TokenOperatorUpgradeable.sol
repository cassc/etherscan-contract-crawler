// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

// solhint-disable no-empty-blocks, func-name-mixedcase

// inheritance
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../../interface/ITokenOperator.sol";

abstract contract TokenOperatorUpgradeable is
    OwnableUpgradeable,
    ITokenOperator
{
    address private _operator;

    modifier onlyOperator() {
        require(
            operator() == _msgSender(),
            "TokenOperatorUpgradeable: caller is not the operator"
        );
        _;
    }

    //
    // proxy constructors
    //

    function __TokenOperator_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __TokenOperator_init_unchained() internal onlyInitializing {}

    //
    // public methods
    //

    function setOperator(
        address newOperator_
    ) public virtual override onlyOwner {
        _setOperator(newOperator_);
    }

    function operator() public view virtual override returns (address) {
        return _operator;
    }

    //
    // internal methods
    //

    function _setOperator(address newOperator_) internal {
        emit SetOperator({
            sender: msg.sender,
            oldOperator: _operator,
            newOperator: newOperator_
        });

        _operator = newOperator_;
    }

    uint256[48] private __gap;
}