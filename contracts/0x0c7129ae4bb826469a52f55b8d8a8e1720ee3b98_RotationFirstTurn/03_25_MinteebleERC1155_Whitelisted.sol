// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

//  =============================================
//   _   _  _  _  _  ___  ___  ___  ___ _    ___
//  | \_/ || || \| ||_ _|| __|| __|| o ) |  | __|
//  | \_/ || || \\ | | | | _| | _| | o \ |_ | _|
//  |_| |_||_||_|\_| |_| |___||___||___/___||___|
//
//  Website: https://minteeble.com
//  Email: [email protected]
//
//  =============================================

import "../MinteebleERC1155.sol";
import "../../extensions/WhitelistExtension.sol";

contract MinteebleERC1155_Whitelisted is MinteebleERC1155, WhitelistExtension {
    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _uri
    ) MinteebleERC1155(_tokenName, _tokenSymbol, _uri) {}

    function whitelistMint(
        uint256 _id,
        uint256 _amount,
        bytes32[] calldata _merkleProof
    ) public payable virtual canWhitelistMint(_amount, _merkleProof) {
        for (uint256 i = 0; i < idsInfo.length; i++) {
            if (idsInfo[i].id == _id) {
                if (idsInfo[i].maxSupply != 0) {
                    require(
                        totalSupply(_id) + _amount <= idsInfo[i].maxSupply,
                        "Max supply reached"
                    );
                }

                require(
                    msg.value >= idsInfo[i].price * _amount,
                    "Insufficient funds"
                );

                _mint(msg.sender, _id, _amount, "");
                _consumeWhitelist(msg.sender, _amount);
                return;
            }
        }

        revert("Invalid id");
    }

    function setWhitelistMintEnabled(bool _state)
        public
        requireAdmin(msg.sender)
    {
        _setWhitelistMintEnabled(_state);
    }

    function setMerkleRoot(bytes32 _merkleRoot)
        public
        requireAdmin(msg.sender)
    {
        _setMerkleRoot(_merkleRoot);
    }

    function setWhitelistMaxMintAmountPerTrx(uint256 _maxAmount)
        public
        requireAdmin(msg.sender)
    {
        _setWhitelistMaxMintAmountPerTrx(_maxAmount);
    }

    function setWhitelistMaxMintAmountPerAddress(uint256 _maxAmount)
        public
        requireAdmin(msg.sender)
    {
        _setWhitelistMaxMintAmountPerAddress(_maxAmount);
    }
}