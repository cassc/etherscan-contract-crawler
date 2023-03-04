/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./ISDKApproveCheckerFeature.sol";


interface IElement {
    function getHashNonce(address maker) external view returns (uint256);
}

interface ISeaport {
    function getCounter(address maker) external view returns (uint256);
}

contract SDKApproveCheckerFeature is ISDKApproveCheckerFeature {

    IElement public immutable ELEMENT;
    ISeaport public immutable SEAPORT;

    constructor(IElement element, ISeaport seaport) {
        ELEMENT = element;
        SEAPORT = seaport;
    }

    function getSDKApprovalsAndCounter(
        address account,
        SDKApproveInfo[] calldata list
    )
        external
        override
        view
        returns (uint256[] memory approvals, uint256 elementCounter, uint256 seaportCounter)
    {
        approvals = new uint256[](list.length);
        for (uint256 i; i < list.length; i++) {
            uint8 tokenType = list[i].tokenType;
            if (tokenType == 0 || tokenType == 1) {
                if (isApprovedForAll(list[i].tokenAddress, account, list[i].operator)) {
                    approvals[i] = 1;
                }
            } else if (tokenType == 2) {
                approvals[i] = allowanceOf(list[i].tokenAddress, account, list[i].operator);
            }
        }

        elementCounter = ELEMENT.getHashNonce(account);
        if (address(SEAPORT) != address(0)) {
            seaportCounter = SEAPORT.getCounter(account);
        }
        return (approvals, elementCounter, seaportCounter);
    }

    function isApprovedForAll(address nft, address owner, address operator) internal view returns (bool isApproved) {
        if (nft != address(0) && operator != address(0)) {
            try IERC721(nft).isApprovedForAll(owner, operator) returns (bool _isApprovedForAll) {
                isApproved = _isApprovedForAll;
            } catch {
            }
        }
        return isApproved;
    }

    function allowanceOf(address erc20, address owner, address spender) internal view returns (uint256 allowance) {
        if (erc20 != address(0)) {
            try IERC20(erc20).allowance(owner, spender) returns (uint256 _allowance) {
                allowance = _allowance;
            } catch {
            }
        }
        return allowance;
    }
}