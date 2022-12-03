/* SPDX-License-Identifier: UNLICENSED */
pragma solidity ^0.6.12;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Snapshot.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./../TokenTransfer.sol";

contract UtilityDynamicSupply is TokenTransfer {
    /**
     * @dev The total amount of minted tokens, regardless of burned
     * @notice A quantidade total de tokens emitidos
     */
    uint256 private nTotalMintedTokens;

    /**
     * @dev The total amount of burned tokens
     * @notice A quantidade total de tokens queimados
     */
    uint256 private nTotalBurnedTokens;

    constructor(
        address _issuer,
        string memory _tokenName,
        string memory _tokenSymbol
    ) public TokenTransfer(_issuer, 0, _tokenName, _tokenSymbol) {}

    function onCreate(uint256 _totalTokens) internal override {}

    function mint(address _account, uint256 _amount) public onlyOwner {
        nTotalMintedTokens = nTotalMintedTokens.add(_amount);
        _mint(_account, _amount);
    }

    function burn(address _account, uint256 _amount) public onlyOwner {
        nTotalBurnedTokens = nTotalBurnedTokens.add(_amount);
        _burn(_account, _amount);
    }

    /**
     * @dev Returns the total amount of minted tokens, regardless of burned
     * @notice Retorna a quantidade total de tokens emitidos
     */
    function getTotalMinted() public view returns (uint256) {
        return nTotalMintedTokens;
    }

    /**
     * @dev Returns the total amount of minted tokens, regardless of burned
     * @notice Retorna a quantidade total de tokens emitidos
     */
    function getTotalBurned() public view returns (uint256) {
        return nTotalBurnedTokens;
    }
}