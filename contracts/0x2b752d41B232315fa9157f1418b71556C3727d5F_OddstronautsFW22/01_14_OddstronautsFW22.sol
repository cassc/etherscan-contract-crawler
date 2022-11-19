// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 *                                         ..',;;::::;;,'..
 *                                   .':oxkOOOOOkkkkkkOOOOOkxl:'.
 *                               .,lxO0kxdddddxxxxxxxxxxdddddxk0Oxl,.
 *                             ,oO0kdoodkOOOkxollcccclloxkO0Okdoodk0Oo,.
 *                          .ckKkolokKKxl;..              ..,cdO0kolokKOc.
 *                        .l0KdclkXMMWKkxol:,..                .'lOKklcdK0l.
 *                       :OKd:l0WMMMMMMMMMMMWNKko:'..              ,dK0l:dK0:
 *                     .dXk::OWMMMMMMMMMMMMMMMMMMMNX0d:.             .dKOc:kXx.
 *                    ,OXo,oNMMMMMMMMMMMMMMMMMMMMMMMMMWKx;.            ,kXd,lKO,
 *                   ;0Kc,kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0l.           .oXk,cK0;
 *                  ,0K:'kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKo.           lXO,:K0,
 *                 .kNl.dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKl.         .oNx.lNk.
 *                 lNk.:XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO,         .kNc.xNl
 *                .OX:.kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXl.        :XO.:XO.
 *                :XO.,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd.       .OX;.OX:
 *                lNx.:NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx.      .xNc.dNl
 *                oWo.cNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd.     .xNl.oWo
 *                oWd.:XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl     .kNc.dWo
 *                cNk.'0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK;    '0K,.kNc
 *                ,KK,.dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx.   lNx.,KK,
 *                .dNo.,0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:  ,0K;.oNd.
 *                 ,KK; cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd..kXl.,KK,
 *                  cXO..lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0lkXo..kXl
 *                  .oXk..cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXl..xXo.
 *                   .oXO' ;OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0; 'kXo.
 *                     cK0:..lKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo..:0Kc
 *                      'kXx' .oKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKo' .dXO,
 *                       .:OKd' .:kXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkc.   .kNk.
 *                         .cOKx:...cx0NWMMMMMMMMMMMMMMMMMMMMWN0xc'       .oX0:
 *                           .;d00d:...':oxOKXNWWWWMWWWNXKOkdol::clodxxkkkkOXMNd.
 *                              .:dO0ko:'.....',;;;;;;:loddxOOOOkxdolc:;;;;;:l0Wd.
 *                                 .'cdkO0Oo.    .;clxO0Oxoc;'..            .l0K:
 *                                      .lXK:.:dO0Okdl;..               .,lk0Ol.
 *                                       :XN00Od:.                 .':ok00kl,.
 *                                       lWNx,.             ..,:ldkOOkdc,.
 *                                       cXKo:;,,,;;;:clodkOOOOkdl:'.
 *                                        ,lxkkOOOkkkxxdoc:;'..
 * @author @inetdave
 */
contract OddstronautsFW22 is ERC1155, AccessControl, Pausable, Ownable {
    bytes32 public constant AIRDROPPER_ROLE = keccak256("AIRDROPPER_ROLE");

    string public name;
    string public symbol;

    constructor() ERC1155("https://storage.googleapis.com/airdrop-fw22/json/{id}.json") {
        name = "Oddstronauts FW22";
        symbol = "FW22";

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(AIRDROPPER_ROLE, msg.sender);
        _pause();
    }

    function setURI(string memory newuri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setURI(newuri);
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function airdropMint(
        address account,
        uint256 id,
        uint256 amount
    ) public onlyRole(AIRDROPPER_ROLE) {
        _mint(account, id, amount, "");
    }

    function airdropMintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) public onlyRole(AIRDROPPER_ROLE) {
        _mintBatch(to, ids, amounts, "");
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function withdraw() public onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(msg.sender).transfer(address(this).balance);
    }
}