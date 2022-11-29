// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "contracts/interfaces/IChainlink.sol";

contract TokenManager is Ownable {
    string[] public tokenSymbols;
    mapping(string => TokenData) tokenMetaData;

    struct TokenData { address addr; uint8 dec; address chainlinkAddr; uint8 chainlinkDec; }

    /// @param _wethAddress address of WETH token
    /// @param _ethUsdCL address of Chainlink data feed for ETH / USD
    constructor(address _wethAddress, address _ethUsdCL) {
        addAcceptedToken(_wethAddress, _ethUsdCL);
    }

    // Gets the details for the given token, if it is accepted
    /// @param _symbol The token symbol e.g. "WETH", "USDC", "USDT"
    function get(string memory _symbol) external view returns(TokenData memory) {
        for (uint256 i = 0; i < tokenSymbols.length; i++) if (cmpString(tokenSymbols[i], _symbol)) return tokenMetaData[_symbol];
        revert("err-tok-not-found");
    }

    function getAcceptedTokens() external view returns (string[] memory) {
        return tokenSymbols;
    }

    function getTokenDecimalFor(string memory _symbol) external view returns(uint8) {
        return tokenMetaData[_symbol].dec;
    }

    function getChainlinkDecimalFor(string memory _symbol) external view returns(uint8) {
        return tokenMetaData[_symbol].chainlinkDec;
    }

    function getTokenAddressFor(string memory _symbol) external view returns(address) {
        return tokenMetaData[_symbol].addr;
    }

    function getChainlinkAddressFor(string memory _symbol) external view returns(address) {
        return tokenMetaData[_symbol].chainlinkAddr;
    }

    function addUniqueSymbol(string memory _symbol) private {
        for (uint256 i = 0; i < tokenSymbols.length; i++) if (cmpString(tokenSymbols[i], _symbol)) revert("err-token-exists");
        tokenSymbols.push(_symbol);
    }

    // Add a token to the accepted list of tokens
    /// @param _addr the address of the token
    /// @param _chainlinkAddr the address of the token / USD Chainlink data feed
    function addAcceptedToken(address _addr, address _chainlinkAddr) public onlyOwner {
        (string memory symbol, uint8 decimals) = getTokenMetaData(_addr);
        addUniqueSymbol(symbol);
        tokenMetaData[symbol] = TokenData(_addr, decimals, _chainlinkAddr, IChainlink(_chainlinkAddr).decimals());
    }

    function deleteToken(uint256 index) private {
        for (uint256 i = index; i < tokenSymbols.length - 1; i++) tokenSymbols[i] = tokenSymbols[i+1];
        tokenSymbols.pop();
    }

    // Remove accepted token from accepted list of tokens
    /// @param _symbol The token symbol e.g. "WETH", "USDT"
    function removeAcceptedToken(string memory _symbol) external onlyOwner {
        for (uint256 i = 0; i < tokenSymbols.length; i++) if (cmpString(tokenSymbols[i], _symbol)) deleteToken(i);
        tokenMetaData[_symbol] = TokenData(address(0), 0, address(0), 0);
    }

    function cmpString(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function getTokenMetaData(address _addr) private view returns (string memory, uint8) {
        string memory sym = ERC20(_addr).symbol();
        require(!cmpString(sym, ""), "err-empty-symbol");
        uint8 dec = ERC20(_addr).decimals();
        require(dec > 0, "err-zero-decimals");
        return (sym, dec);
    }
}