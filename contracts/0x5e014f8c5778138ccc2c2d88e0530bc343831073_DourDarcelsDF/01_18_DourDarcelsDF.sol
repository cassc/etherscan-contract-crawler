// SPDX-License-Identifier: MIT

/*
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0xl;'..      ..';ld0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMNOl'.                  .'ckXMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMWKd,                          'oKWMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMKo.                              .oKWMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMNx'                                  'dNMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMW0:                                      :0WMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMNx.                                        .dNMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMXl.                                          .cXMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMK:                                              ;KMMMMMMMMMMMMMMM
MMMMMMMMMMMMMM0;                .';:clooooll:;'.                ,0MMMMMMMMMMMMMM
MMMMMMMMMMMMM0;             .;okKNWMMMMMMMMMMWNKko:.             ,0WMMMMMMMMMMMM
MMMMMMMMMMMMK;           .:xKWWMMMMMMMMMMMMMMMMMMMWXx:.           ,0MMMMMMMMMMMM
MMMMMMMMMMMX:          .lOK0OxxxxkOXWMMMMMMWX0kxxxxk0KOl.          :KMMMMMMMMMMM
MMMMMMMMMMNl          :O0dc;;,,,,,;:o0NWWN0o:;,,,,,,;cdOO:.         lNMMMMMMMMMM
MMMMMMMMMWk.        .o0d:,,,,,,,,,,,,:okko:,,,,,,,,,,,,:d0o.        .xWMMMMMMMMM
MMMMMMMMMK,        .d0o;,,,,,,,,,,,,,,,;;,,,,,,,,,,,,,,,;o0x.        ,0MMMMMMMMM
MMMMMMMMWo         lXx;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,;xXo.        lNMMMMMMMM
MMMMMMMM0'        ,0Xo,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,oXK;        'OMMMMMMMM
MMMMMMMWo.        lNXo,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,oKWo         lNMMMMMMM
MMMMMMMX;        .xWNx;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,;dNMk.        ,KMMMMMMM
MMMMMMMO.        .xMW0l,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,c0WMk.        .kMMMMMMM
MMMMMMMx.         oWMWOc,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,:kNMWd.        .dMMMMMMM
MMMMMMMd          ;KMMWOc,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,cONMMX:          oWMMMMMM
MMMMMMMd          .dWMMW0o;,,,,,,,,,,,,,,,,,,,,,,,,,,;l0WMMWx.          lNMMMMMM
MMMMMMMd           .kWMMWXkc;,,,,,,,,,,,,,,,,,,,,,,;cxXWMMWO'           oWMMMMMM
MMMMMMMx.           .xWMMMWKxc;,,,,,,,,,,,,,,,,,,;:dKWMMMWk'           .dMMMMMMM
MMMMMMM0'            .lKWMMMWKxc;,,,,,,,,,,,,,,;cxKWMMMMXo.            .OMMMMMMM
MMMMMMMNc              'dXWMMMWXOo:;,,,,,,,,,:okXWMMMWXd,              :XMMMMMMM
MMMMMMMMO.               'o0NMMMMNKxl:,,,,;lxKNMMMMN0o'               .kWMMMMMMM
MMMMMMMMNo.                .,lkKNWMWN0xddx0NWMWNKkl,.                 oNMMMMMMMM
MMMMMMMMMXc                    .':codxxxxxxdol:'.                    cXMMMMMMMMM
MMMMMMMMMMXc                                                        cKMMMMMMMMMM
MMMMMMMMMMMNo.                                                    .oXMMMMMMMMMMM
MMMMMMMMMMMMWk,                                                  ,kNMMMMMMMMMMMM
MMMMMMMMMMMMMMXo.                 ,:.      .:,                 .oXMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMWKo'               ;kOoc::coOk;               .lKWMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMWXx;.             .,loddol,.             .;xXWMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMWKd:.                              .;d0WMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMWXOo:'.                    .':okXWMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMWXOdc,..          ..,cdOXWMMMMMMMMMMMMMMMMMMMMMMMMMMM

*/

pragma solidity ^0.8.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';

contract DourDarcelsDF is ERC721A, ERC2981, ReentrancyGuard, AccessControl, Ownable {
    struct SendData {
        address receiver;
        uint256 amount;
    }

    bytes32 public constant SUPPORT_ROLE = keccak256('SUPPORT');
    string public provenance;
    string private _baseURIextended;
    mapping(uint256 => bool) public unclaimedTokenIds;

    IERC721Enumerable public immutable baseContractAddress;

    constructor(
        address contractAddress,
        string memory name,
        string memory symbol
    ) ERC721A(name, symbol) {
        require(
            IERC721Enumerable(contractAddress).supportsInterface(0x780e9d63),
            'Contract address does not support ERC721Enumerable'
        );

        // set immutable variables
        baseContractAddress = IERC721Enumerable(contractAddress);

        // setup roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(SUPPORT_ROLE, msg.sender);
    }

    ////////////////
    // tokens
    ////////////////
    /**
     * @dev sets the base uri for {_baseURI}
     */
    function setBaseURI(string memory baseURI_) external onlyRole(SUPPORT_ROLE) {
        _baseURIextended = baseURI_;
    }

    /**
     * @dev See {ERC721-_baseURI}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    /**
     * @dev sets the provenance hash
     */
    function setProvenance(string memory provenance_) external onlyRole(SUPPORT_ROLE) {
        provenance = provenance_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC721A, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally clears the royalty information for the token.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }

    ////////////////
    // royalty
    ////////////////
    /**
     * @dev See {ERC2981-_setDefaultRoyalty}.
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyRole(SUPPORT_ROLE) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @dev See {ERC2981-_deleteDefaultRoyalty}.
     */
    function deleteDefaultRoyalty() external onlyRole(SUPPORT_ROLE) {
        _deleteDefaultRoyalty();
    }

    /**
     * @dev See {ERC2981-_setTokenRoyalty}.
     */
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyRole(SUPPORT_ROLE) {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /**
     * @dev See {ERC2981-_resetTokenRoyalty}.
     */
    function resetTokenRoyalty(uint256 tokenId) external onlyRole(SUPPORT_ROLE) {
        _resetTokenRoyalty(tokenId);
    }

    /**
     * @dev executes an airdrop
     */
    function airdrop(SendData[] calldata sendData) external onlyRole(SUPPORT_ROLE) nonReentrant {
        uint256 ts = baseContractAddress.totalSupply();

        // loop through all addresses
        for (uint256 index = 0; index < sendData.length; index++) {
            require(totalSupply() + sendData[index].amount <= ts, 'Exceeds original supply');
            _safeMint(sendData[index].receiver, sendData[index].amount);
        }
    }

    /**
     * @dev explicitly set token ids that have not been claimed
     */
    function setUnclaimedTokenIds(uint256[] calldata tokenIds) external onlyRole(SUPPORT_ROLE) {
        for (uint256 index = 0; index < tokenIds.length; index++) {
            unclaimedTokenIds[tokenIds[index]] = true;
        }
    }

    /**
     * @dev redeems an array of token ids
     */
    function redeem(uint256[] calldata tokenIds) external nonReentrant {
        uint256 numberOfTokens = tokenIds.length;

        for (uint256 index = 0; index < numberOfTokens; index++) {
            require(unclaimedTokenIds[tokenIds[index]], 'Token has already been claimed');

            try baseContractAddress.ownerOf(tokenIds[index]) returns (address ownerOfAddress) {
                require(ownerOfAddress == msg.sender, 'Caller must own NFTs');
            } catch (bytes memory) {
                revert('Bad token contract');
            }

            unclaimedTokenIds[tokenIds[index]] = false;
        }

        uint256 ts = baseContractAddress.totalSupply();
        require(totalSupply() + numberOfTokens <= ts, 'Exceeds original supply');

        _safeMint(msg.sender, numberOfTokens);
    }
}