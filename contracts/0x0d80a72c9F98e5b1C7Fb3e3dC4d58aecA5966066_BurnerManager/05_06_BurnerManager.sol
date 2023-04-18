// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "../interfaces/IBurner.sol";

contract BurnerManager is Ownable2Step {
    event AddBurner(address indexed token, IBurner indexed newBurner, IBurner indexed oldBurner);

    /// tokenAddress => burnerAddress
    mapping(address => IBurner) public burners;

    /**
     * @notice Contract constructor
     */
    constructor() {}

    /**
     * @notice Set burner of `token` to `burner` address
     * @param token token address
     * @param burner burner address
     */
    function setBurner(address token, IBurner burner) external onlyOwner returns (bool) {
        return _setBurner(token, burner);
    }

    /**
     * @notice Set burner of `token` to `burner` address
     * @param tokens token address
     * @param burnerList token address
     */
    function setManyBurner(address[] memory tokens, IBurner[] memory burnerList) external onlyOwner returns (bool) {
        require(tokens.length == burnerList.length, "invalid param");

        for (uint256 i = 0; i < tokens.length; i++) {
            _setBurner(tokens[i], burnerList[i]);
        }

        return true;
    }

    function _setBurner(address token, IBurner burner) internal returns (bool) {
        require(token != address(0), "CE000");
        require(burner != IBurner(address(0)), "CE000");

        IBurner oldBurner = burners[token];
        burners[token] = burner;

        emit AddBurner(token, burner, oldBurner);

        return true;
    }
}