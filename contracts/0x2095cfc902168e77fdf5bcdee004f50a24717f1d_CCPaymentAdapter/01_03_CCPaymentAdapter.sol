// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import {IERC721A} from "lib/ERC721A/contracts/IERC721A.sol";
import {IBurnCrosschainMinter} from "./interfaces/IBurnCrosschainMinter.sol";

contract CCPaymentAdapter {
    IBurnCrosschainMinter public crossChainMinterContract;
    address public deployedCrossChainMinterContractAddress;

    constructor(address _deployedMinterContractAddress) {
        deployedCrossChainMinterContractAddress = _deployedMinterContractAddress;
        crossChainMinterContract = IBurnCrosschainMinter(
            deployedCrossChainMinterContractAddress
        );
    }

    function purchase(
        address _targetERC721ContractAddress,
        address _to,
        bytes calldata _data
    ) external payable returns (uint256) {
        uint256 tokenId = crossChainMinterContract.purchase{value: msg.value}(
            _targetERC721ContractAddress,
            _data
        );
        IERC721A(_targetERC721ContractAddress).transferFrom(
            address(this),
            _to,
            tokenId
        );

        return tokenId;
    }
}