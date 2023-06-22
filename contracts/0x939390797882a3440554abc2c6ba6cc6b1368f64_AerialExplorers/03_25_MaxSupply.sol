// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

abstract contract MaxSupply {
    uint256 public maxSupply; // 0 = no limit

    /**
     * @dev Implementer must specify a _totalSupply function
     */
    function _totalSupply() internal view virtual returns (uint256);

    constructor(uint256 _maxSupply) {
        maxSupply = _maxSupply;
    }

    /**
     * @dev Global max supply check
     */
    modifier wontExceedMaxSupply(uint256 quantity) {
        // require(!_willExceedMaxSupply(quantity), "Exceeds Max Supply");
        require(
            maxSupply == 0 || _totalSupply() + quantity <= maxSupply,
            "Exceeds Max Supply"
        );
        _;
    }
}