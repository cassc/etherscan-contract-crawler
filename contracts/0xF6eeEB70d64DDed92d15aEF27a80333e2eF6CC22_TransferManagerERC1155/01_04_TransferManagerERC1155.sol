/**
                                                ....                      ....                              ....       
                                                 #@@@?                    ^@@@@                             :@@@@       
                                                 P&&&!                    :@@@@                             :@@@@       
     ....  ....  ....     .....................  ....   ............   [email protected]@@@:...   ............  [email protected]@@@       
    [email protected]@@&  @@@@: [email protected]@@Y   [email protected]@@@@@@@@@@@@@@@@@@@@. #@@@? [email protected]@@@@@@@@@@@~ [email protected]@@@@@@@@@@@^ [email protected]@@@@@@@@@@@. [email protected]@@@@@@@@@@@       
    [email protected]@@&  @@@@: [email protected]@@5   [email protected]@@@&&&&@@@@@&&&&@@@@. #@@@? [email protected]@@@&&&&@@@@~ 7&&&&@@@@&&&&: [email protected]@@@#&&&@@@@. [email protected]@@@&&&&@@@@       
    ~&&&G  #&&&. [email protected]@@5   [email protected]@@@.   [email protected]@@5   [email protected]@@@. #@@@? [email protected]@@&    &@@@~     ^@@@@      [email protected]@@[email protected]@@@. [email protected]@@Y   ^@@@@       
                 [email protected]@@5   [email protected]@@@.   [email protected]@@5   [email protected]@@@. #@@@? [email protected]@@&    &@@@~     ^@@@@      [email protected]@@@@@@@@@@@. [email protected]@@J   :@@@@       
                 [email protected]@@5   [email protected]@@@.   [email protected]@@5   [email protected]@@@. #@@@? [email protected]@@&    &@@@~     ^@@@@      [email protected]@@@#&&&##&#. [email protected]@@J   :@@@@       
     [email protected]@@5   [email protected]@@@.   [email protected]@@5   [email protected]@@@. #@@@? [email protected]@@&    &@@@~     ^@@@@      [email protected]@@G........  [email protected]@@[email protected]@@@       
    [email protected]@@@@@@@@@@@@@@@5   [email protected]@@@.   [email protected]@@5   [email protected]@@@. #@@@? [email protected]@@&    &@@@~     ^@@@@      [email protected]@@@@@@@@@@@. [email protected]@@@@@@@@@@@       
    ~&&&&&&&&&&&&&&&&?   .&&&#    Y&&&?   .&&&#. P&&&! ~&&&G    B&&&^     :&&&#      J&&&&&&&&&&&&. 5&&&&&&&&&&&#   
                                                                                                                                                                                            
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import {ITransferManagerNFT} from "../interfaces/ITransferManagerNFT.sol";

/**
 * @title TransferManagerERC1155
 * @notice It allows the transfer of ERC1155 tokens.
 */
contract TransferManagerERC1155 is ITransferManagerNFT {
    address public immutable MINTED_EXCHANGE;

    /**
     * @notice Constructor
     * @param _mintedExchange address of the Minted exchange
     */
    constructor(address _mintedExchange) {
        MINTED_EXCHANGE = _mintedExchange;
    }

    /**
     * @notice Transfer ERC1155 token(s)
     * @param collection address of the collection
     * @param from address of the sender
     * @param to address of the recipient
     * @param tokenId tokenId
     * @param amount amount of tokens (1 and more for ERC1155)
     */
    function transferNonFungibleToken(
        address collection,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) external override {
        require(msg.sender == MINTED_EXCHANGE, "Transfer: Only Minted Exchange");
        // https://docs.openzeppelin.com/contracts/3.x/api/token/erc1155#IERC1155-safeTransferFrom-address-address-uint256-uint256-bytes-
        IERC1155(collection).safeTransferFrom(from, to, tokenId, amount, "");
    }
}