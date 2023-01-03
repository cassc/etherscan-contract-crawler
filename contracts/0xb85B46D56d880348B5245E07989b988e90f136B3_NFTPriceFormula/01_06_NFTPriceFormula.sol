// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./NFTPriceFormulaStorage.sol";

contract NFTPriceFormula is NFTPriceFormulaStorage {
    /** DON"T ADD ADDITIONAL STORAGE HERE EXCEPT CONSTANT */
    uint256 public constant FORMULA_TYPE_1 = 1;

    uint256 public constant FORMULA_TYPE_2 = 2;

    uint256 public constant FORMULA_TYPE_3 = 3;

    /** EVENTS */
    event FormulaPriceUpdated(uint256 _formulaType, uint256 _price);

    /** FUNCTIONS */
    fallback() external {}

    constructor() {}

    function initialize() external initializer {
        __Ownable_init_unchained();
    }

    function getTokenPrice(uint256 _formulaType, address _collectionAddress) external view returns (uint256) {
        require(_collectionAddress != address(0), "formula: zero collection address");

        if (_formulaType == FORMULA_TYPE_1) {
            return formula1();
        } else if (_formulaType == FORMULA_TYPE_2) {
            return formula2();
        } else if (_formulaType == FORMULA_TYPE_3) {
            return formula3();
        } else {
            revert("formula: unsupported formula type");
        }
    }

    function formula1() private view returns (uint256) {
        return formulaPrices[FORMULA_TYPE_1];
    }

    function formula2() private view returns (uint256) {
        return formulaPrices[FORMULA_TYPE_2];
    }

    function formula3() private view returns (uint256) {
        return formulaPrices[FORMULA_TYPE_3];
    }

    function setFormulaPrices(uint256 _formulaType, uint256 _price) external onlyOwner {
        require(_formulaType != 0, "formula: zero formula type");
        formulaPrices[_formulaType] = _price;

        emit FormulaPriceUpdated(_formulaType, _price);
    }
}