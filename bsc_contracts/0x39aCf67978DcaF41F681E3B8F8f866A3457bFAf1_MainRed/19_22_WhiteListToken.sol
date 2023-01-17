// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../secutiry/Administered.sol";

contract WhiteListToken is Administered {
    /**
     * @dev ERC20List struct
     * @param addr                  Token address
     * @param oracle                 Address of the oracle
     * @param orcDecimals          Decimal of the oracle
     * @param active                        Status of the token
     * @param isNative                      Is the token native
     */
    struct ERC20List {
        address addr;
        address oracle;
        uint256 orcDecimals;
        bool active;
        bool isNative;
    }

    /**
     * @dev ERC20AddressList struct
     * @param addr                  Token address
     * @param index                         Index of the token
     */
    struct ERC20AddressList {
        address addr;
        uint256 index;
    }

    /// @dev mapping of ERC20 tokens into the whitelist
    mapping(uint256 => ERC20List) whitelist;

    /// @dev mapping for index token address
    mapping(address => ERC20AddressList) whitelistIndex;

    uint256 public whitelistTokenCount = 0;

    constructor() {}

    /**
     * @dev Get tokens list
     */
    function tokensList() external view returns (ERC20List[] memory) {
        unchecked {
            ERC20List[] memory p = new ERC20List[](whitelistTokenCount);
            for (uint256 i = 0; i < whitelistTokenCount; i++) {
                ERC20List storage s = whitelist[i];
                p[i] = s;
            }
            return p;
        }
    }

    /**
     * @dev Add a token to the whitelist
     * @param _addr                            Address of the token contract
     * @param _orc                           Address of the Oracle contract
     * @param _orcDcm                    Decimals of the Oracle contract
     * @param _act                                  Status of the pair
     * @param _ntv                                Is Native token
     */
    function addToken(
        address _addr,
        address _orc,
        uint256 _orcDcm,
        bool _act,
        bool _ntv
    ) external onlyUser {
        require(!isToken(_addr), "Token already exist");

        whitelist[whitelistTokenCount] = ERC20List(
            _addr,
            _orc,
            _orcDcm,
            _act,
            _ntv
        );
        whitelistIndex[_addr] = ERC20AddressList(_addr, whitelistTokenCount);
        whitelistTokenCount++;
    }

    /**
     * @dev Update WhiteList Token
     * @param _id                  Index of the token
     * @param _type                Type of change to be made
     * @param _addr                Address of the contract or Oracle
     * @param _dcm                 Decimal of the contract
     * @param _bool                Status of the pair
     */
    function updateToken(
        uint256 _id,
        uint256 _type,
        address _addr,
        uint256 _dcm,
        bool _bool
    ) external onlyUser {
        /// @dev Update oracle address
        if (_type == 1) {
            whitelist[_id].oracle = _addr;

            /// @dev Update oracle decimals
        } else if (_type == 2) {
            whitelist[_id].orcDecimals = _dcm;

            /// @dev Update token status
        } else if (_type == 3) {
            whitelist[_id].active = _bool;

            /// @dev Update token native status
        } else if (_type == 4) {
            whitelist[_id].isNative = _bool;
        }
    }

    /**
     * @dev Verify if the token is in the whitelist
     * @param _addr                     Address of the token contract
     */
    function isToken(address _addr) public view returns (bool) {
        return (whitelistIndex[_addr].addr == address(0x0)) ? false : true;
    }

    /**
     * @dev Get Token By Address
     * @param _addr                     Address of the token
     */
    function getTokenByAddr(
        address _addr
    ) public view returns (ERC20List memory) {
        require(isToken(_addr), "Invalid Token");
        ERC20AddressList storage row = whitelistIndex[_addr];
        return _getTokenByIdx(row.index);
    }

    /**
     * @dev Get Token by Index
     * @param _idx                     Index of the token
     */
    function _getTokenByIdx(
        uint256 _idx
    ) private view returns (ERC20List memory) {
        unchecked {
            return whitelist[_idx];
        }
    }
}