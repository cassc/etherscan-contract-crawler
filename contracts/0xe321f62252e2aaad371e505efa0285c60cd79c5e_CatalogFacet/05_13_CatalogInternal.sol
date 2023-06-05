/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "../council/ICouncil.sol";
import "./CatalogStorage.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library CatalogInternal {

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 registereeId,
        uint256 value
    );
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );
    event URI(
        string value,
        uint256 indexed registereeId
    );

    function _initialize(
        address registrar,
        address deedRegistry
    ) internal {
        require(!__s().initialized, "CI:AI");
        __s().registrar = registrar;
        __s().deedRegistry = deedRegistry;
        __s().initialized = true;
    }

    function _getRegistrar() internal view returns (address) {
        return __s().registrar;
    }

    function _getDeedRegistry() internal view returns (address) {
        return __s().deedRegistry;
    }

    function _addDeed(
        uint256 registereeId,
        address grantToken,
        address council
    ) internal {
        require(msg.sender == __s().registrar, "CATI:NREG");
        require(!__exists(registereeId), "CATI:EXT");
        require(__s().deeds[registereeId].registereeId == 0, "CATI:EXT2");
        __s().deeds[registereeId].registereeId = registereeId;
        __s().deeds[registereeId].grantToken = grantToken;
        __s().deeds[registereeId].council = council;
        __s().lastRegistereeId = registereeId;
        emit TransferSingle(
            __s().registrar, address(0), council, registereeId,
                IERC20(grantToken).totalSupply());
    }

    function _submitTransfer(
        address caller,
        uint256 registereeId,
        address from,
        address to,
        uint256 amount
    ) internal {
        require(__exists(registereeId), "CATI:TNF");
        require(msg.sender == __s().deeds[registereeId].grantToken, "CATI:NST");
        emit TransferSingle(caller, from, to, registereeId, amount);
    }

    function _balanceOf(
        address account,
        uint256 registereeId
    ) internal view returns (uint256) {
        require(__exists(registereeId), "CATI:TNF");
        return IERC20(__s().deeds[registereeId].grantToken).balanceOf(account);
    }

    function _balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata registereeIds
    ) internal view returns (uint256[] memory) {
        require(accounts.length == registereeIds.length, "CATI:ILS");
        require(accounts.length > 0, "CATI:ZL");
        uint256[] memory balances = new uint256[](accounts.length);
        for (uint256 i = 1; i <= registereeIds.length; i++) {
            require(__exists(registereeIds[i]), "CATI:TNF");
            balances[i] = IERC20(__s().deeds[registereeIds[i]].grantToken).balanceOf(accounts[i]);
        }
        return balances;
    }

    function _setApprovalForAll(
        address operator,
        bool approved
    ) internal {
        __s().approvals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function _isApprovedForAll(
        address account,
        address operator
    ) internal view returns (bool) {
        return __s().approvals[account][operator];
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 registereeId,
        uint256 amount,
        bytes calldata /* data */
    ) internal {
        require(from == msg.sender || _isApprovedForAll(from, msg.sender), "CATI:NAPPR");
        require(__exists(registereeId), "CATI:TNF");
        IERC20(__s().deeds[registereeId].grantToken)
            .transferFrom(from, to, amount);
    }

    function _safeBatchTransferFrom(
        address /* from */,
        address /* to */,
        uint256[] calldata /* registereeIds */,
        uint256[] calldata /* amounts */,
        bytes calldata /* data */
    ) internal pure {
        revert("batch transfer is not supported");
    }

    function _uri(uint256 registereeId)
    internal view returns (string memory) {
        require(__exists(registereeId), "CATI:TNF");
        return IERC721Metadata(__s().deedRegistry).tokenURI(registereeId);
    }

    function _xMint(
        address to,
        uint256 registereeId,
        uint256 nrOfTokens
    ) internal {
        require(__exists(registereeId), "CATI:TNF");
        ICouncil council = ICouncil(__s().deeds[registereeId].council);
        council.icoTransferTokensFromCouncil{ value: msg.value }(
            address(0), // payErc20
            msg.sender, // payer
            to,
            nrOfTokens
        );
    }

    function __exists(uint256 registereeId) internal view returns (bool) {
        return registereeId >= 0 && registereeId <= __s().lastRegistereeId;
    }

    function __s() private pure returns (CatalogStorage.Layout storage) {
        return CatalogStorage.layout();
    }
}