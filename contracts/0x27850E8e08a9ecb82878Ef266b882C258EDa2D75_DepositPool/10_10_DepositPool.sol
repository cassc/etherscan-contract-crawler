// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]

    maintainers:
    - [email protected]
    - [email protected]
    - [email protected]
    - [email protected]

    contributors:
    - [email protected]

**************************************/

// OpenZeppelin imports
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// Local imports
import { AbstractPool } from "./AbstractPool.sol";
import { IPool721 } from "../interfaces/IPool721.sol";

/**************************************

    Deposit pool

    ------------------------------

    @notice Holds staked $THOL and NFTs

**************************************/

contract DepositPool is AbstractPool, IPool721 {

    // storage
    IERC721 public immutable nft;

    /**************************************

        Constructor

     **************************************/

    constructor(address _erc20, address _nft, address _keeper)
    AbstractPool(_erc20, _keeper) {

        // storage
        nft = IERC721(_nft);

    }

    /**************************************

        Withdraw (with NFTs)

     **************************************/

    function withdraw(
        address _receiver,
        uint256[] calldata _nfts
    ) public override
    onlyKeeper {
        // tx.members
        address self_ = address(this);

        // transfer nfts
        for (uint256 i = 0; i < _nfts.length; i++) {
            nft.transferFrom(self_, _receiver, _nfts[i]);
        }
    }
}