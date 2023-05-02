// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import 'erc721a/contracts/IERC721A.sol';

contract AirdropNFTs is Ownable {

    error Invalid();

    address public metazeus;
    address public vault;


    constructor(address _metazeus, address _vault ) {

        vault = _vault;
        metazeus = _metazeus;

        // nft vault that holds nfts to airdrop.
        //Vault must aproveForAll this contract in order to perform the airdrop function

    }
    function sendNFTs(address[] calldata receipients, uint[] calldata tokenIDs) external onlyOwner{

        if(receipients.length!=tokenIDs.length) revert Invalid();

        uint256 length = receipients.length;

        for (uint256 i; i<length; i++) {

            IERC721A(metazeus).safeTransferFrom(vault,receipients[i],tokenIDs[i]);
        }

    }





    //uint256 [] memory tokenIDs = IERC721AQueryable(metazeus).tokensOfOwner(vault);

    // function getTokenIDs() internal view onlyOwner returns (uint256[] memory) {

    //     return IERC721AQueryable(metazeus).tokensOfOwner(vault);

    // }

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
}