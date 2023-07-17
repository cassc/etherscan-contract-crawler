// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@dlsl/dev-modules/diamond/presets/OwnableDiamond/OwnableDiamond.sol";

import "./SwapDiamondStorage.sol";

contract SwapDiamond is OwnableDiamond, SwapDiamondStorage {
    receive() external payable {}

    function addFacet(address facet_, bytes4[] calldata selectors_) public override {
        super.addFacet(facet_, selectors_);

        _setType(selectors_, SelectorType.SwapDiamond);
    }

    function removeFacet(address facet_, bytes4[] calldata selectors_) public override {
        super.removeFacet(facet_, selectors_);

        _setType(selectors_, SelectorType.Undefined);
    }

    function updateFacet(
        address facet_,
        bytes4[] calldata fromSelectors_,
        bytes4[] calldata toSelectors_
    ) public override {
        super.updateFacet(facet_, fromSelectors_, toSelectors_);

        _setType(fromSelectors_, SelectorType.Undefined);
        _setType(toSelectors_, SelectorType.SwapDiamond);
    }

    function addFacet(
        address facet_,
        bytes4[] calldata selectors_,
        SelectorType[] calldata types_
    ) external {
        super.addFacet(facet_, selectors_);

        _setTypes(selectors_, types_);
    }

    function updateFacet(
        address facet_,
        bytes4[] calldata fromSelectors_,
        bytes4[] calldata toSelectors_,
        SelectorType[] calldata toTypes_
    ) external {
        super.updateFacet(facet_, fromSelectors_, toSelectors_);

        _setType(fromSelectors_, SelectorType.Undefined);
        _setTypes(toSelectors_, toTypes_);
    }

    function _setType(bytes4[] calldata selectors_, SelectorType type_) internal {
        for (uint256 i = 0; i < selectors_.length; ++i) {
            _getSwapDiamondStorage().selectorTypes[selectors_[i]] = type_;
        }
    }

    function _setTypes(bytes4[] calldata selectors_, SelectorType[] calldata types_) internal {
        require(selectors_.length == types_.length, "SwapDiamond: lengths mismatch");

        for (uint256 i = 0; i < selectors_.length; ++i) {
            _getSwapDiamondStorage().selectorTypes[selectors_[i]] = types_[i];
        }
    }

    function _beforeFallback(address facet_, bytes4 selector_) internal override {
        super._beforeFallback(facet_, selector_);

        require(
            _getSwapDiamondStorage().selectorTypes[selector_] == SelectorType.SwapDiamond,
            "SwapDiamond: wrong selector type"
        );
    }
}