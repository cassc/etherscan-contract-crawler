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

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ITransferManagerNFT} from "../interfaces/ITransferManagerNFT.sol";

/**
 * @title TransferManagerNonCompliantERC721
 * @notice It allows the transfer of ERC721 tokens without safeTransferFrom.
 */
contract TransferManagerNonCompliantERC721 is ITransferManagerNFT {
    address public immutable MINTED_EXCHANGE;

    /**
     * @notice Constructor
     * @param _mintedExchange address of the Minted exchange
     */
    constructor(address _mintedExchange) {
        MINTED_EXCHANGE = _mintedExchange;
    }

    /**
     * @notice Transfer ERC721 token
     * @param collection address of the collection
     * @param from address of the sender
     * @param to address of the recipient
     * @param tokenId tokenId
     */
    function transferNonFungibleToken(
        address collection,
        address from,
        address to,
        uint256 tokenId,
        uint256
    ) external override {
        require(msg.sender == MINTED_EXCHANGE, "Transfer: Only Minted Exchange");
        IERC721(collection).transferFrom(from, to, tokenId);
    }
}