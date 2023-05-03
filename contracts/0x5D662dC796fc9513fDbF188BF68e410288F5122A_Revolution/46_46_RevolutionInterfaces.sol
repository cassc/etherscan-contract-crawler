pragma solidity ^0.8.10;

import {ERC1155Creator} from "./Manifold/ERC1155Creator.sol";

contract RevolutionStorageV1 {
    ERC1155Creator public tokenAddress;

    address public daoAddress;

    DaoType public daoType;

    uint16 public daoSplit;

    uint16 public governanceCreatorSplit;

    mapping(uint256 => Drop) public drops;

    struct Drop {
        uint256 dropEndTime;
        uint256 dropPrice;
        address payable creator;
        uint256 totalValuePurchased;
    }

    enum DaoType {
        REVOLUTION_VRGDA,
        SIMPLE_TREASURY
    }
}