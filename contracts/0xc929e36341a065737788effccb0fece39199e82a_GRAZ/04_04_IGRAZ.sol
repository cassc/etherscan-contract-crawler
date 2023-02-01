//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//
//@@@@@@@@@@     @@@@@@@@           @@@@@@@@@@@@@@@   @@@@@@@@@@              @@@@//
//@@@@@@             @@@@               @@@@@@@@@@     @@@@@@@@@              @@@@//
//@@@@      @@@@@     @@@    @@@@@@@     @@@@@@@@       @@@@@@@@@@@@@@@@@     @@@@//
//@@@@     @@@@@@@@@@@@@@    @@@@@@@     @@@@@@@@        @@@@@@@@@@@@@@     @@@@@@//
//@@@@     @@@@        @@               @@@@@@@     @@    @@@@@@@@@@@     @@@@@@@@//
//@@@@     @@@@        @@            @@@@@@@@@     @@@@    @@@@@@@@#     @@@@@@@@@//
//@@@@     @@@@@@@     @@    @@@@     @@@@@@@               @@@@@@     @@@@@@@@@@@//
//@@@@@               @@@    @@@@@@     @@@@                 @@@               @@@//
//@@@@@@@           @@@@@    @@@@@@@     @@     @@@@@@@@@@    @@               @@@//
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//

import { Owned } from "solmate/auth/Owned.sol";
import { ERC1155 } from "solmate/tokens/ERC1155.sol";

struct Edition {
    uint256 maxSupply;
    uint256 editionPrice;
    string editionURI;
    uint256 mintCap;
}

interface IGRAZ {
    /*//////////////////////////////////////////////////////////////
                                 Functions start
    //////////////////////////////////////////////////////////////*/

    /// MINTING FUNCTIONS

    function ownerMint(address reciever, uint256 tokenId, uint256 quantity) external;

    function mintToken(uint256 tokenId, uint256 quantity) external payable;

    /// BURNING FUNCTIONS

    function burnToken(address from, uint256 id, uint256 amount) external;

    function batchBurnTokens(address from, uint256[] memory ids, uint256[] memory amounts) external;

    /// MANAGEMENT FUNCTIONS

    function toggleMint() external;

    function setFactoryAddress(address factory) external;

    function createEdition(uint256 _supply, uint256 _price, string memory _uri, uint256 _mintCap) external;

    function editEdition(uint256 _tokenId, uint256 _supply, uint256 _price, string memory _uri, uint256 _mintCap) external;

    function withdrawFunds(address receiver) external;

    /// VIEW FUNCTIONS

    function mintStarted() external view returns (bool);

    function grazFactory() external view returns (address);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function editionSupply(uint256) external view returns (uint256);

    function editions(uint256) external view returns (uint256, uint256, string memory, uint256);
}