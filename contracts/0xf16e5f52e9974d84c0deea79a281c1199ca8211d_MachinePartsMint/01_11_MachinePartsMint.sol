// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IERC1155Mintable} from "./interfaces/IERC1155Mintable.sol";
import {AccessProtected} from "./libraries/AccessProtected.sol";
import {RandomGenerator} from "./libraries/RandomGenerator.sol";
import {SignatureProtected} from "./libraries/SignatureProtected.sol";
import {TimeProtected} from "./libraries/TimeProtected.sol";

contract MachinePartsMint is AccessProtected, RandomGenerator, SignatureProtected, TimeProtected {
    IERC1155Mintable public erc1155Contract;
    uint256 public mintsPerStage = 3;

    mapping(address => mapping(uint8 => uint256)) public mintsPerWallet;

    constructor(address _signerAddress, address _erc1155Address) SignatureProtected(_signerAddress) {
        erc1155Contract = IERC1155Mintable(_erc1155Address);
    }

    function setMintsPerStage(uint256 _mintsPerStage) external onlyOwner {
        mintsPerStage = _mintsPerStage;
    }

    function mint(
        uint256 _maxPerWallet,
        uint256 _fromTimestamp,
        uint256 _toTimestamp,
        uint8 _stage,
        bytes calldata _signature
    ) external onlyUser {
        validateSignature(abi.encodePacked(_maxPerWallet, _fromTimestamp, _toTimestamp, _stage), _signature);

        isMintOpen(_fromTimestamp, _toTimestamp);

        require(getAvailableForWallet(1, _maxPerWallet, _stage) > 0, "No tokens left to be minted");

        uint256[] memory ids = new uint256[](mintsPerStage);
        uint256[] memory amounts = new uint256[](mintsPerStage);

        for (uint256 i; i < mintsPerStage; i++) {
            ids[i] = uint8(getRandomNumber(4, i)) + (_stage * 4);
            amounts[i] = 1;
        }

        erc1155Contract.mint(msg.sender, ids, amounts);
    }

    function getAvailableForWallet(uint256 _amount, uint256 _maxPerWallet, uint8 _stage) internal returns (uint256) {
        if (mintsPerWallet[msg.sender][_stage] + _amount > _maxPerWallet) {
            _amount = _maxPerWallet - mintsPerWallet[msg.sender][_stage];
        }

        require(_amount > 0, "LimitPerWallet: The caller address can not mint more tokens");

        mintsPerWallet[msg.sender][_stage] += _amount;

        return _amount;
    }
}