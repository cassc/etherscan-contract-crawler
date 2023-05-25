// SPDX-License-Identifier: MIT

/*
MMMMMMMMMMMMMMMMMMMMMMMMMMMMWN0dl;'..      ..';ld0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMXkc'.                  .'ckXMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMWKd'                          'dKWMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMKo.                              .oKMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMNx'                                  'xNMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMW0:                                      :0WMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMNx.                                        .xNMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMXl.                                          .lXMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMK:                                              :KMMMMMMMMMMMMMMM
MMMMMMMMMMMMMM0;                .';:llooooll:;'.                ;0MMMMMMMMMMMMMM
MMMMMMMMMMMMW0,             .:okKNWMMMMMMMMMMWNKko:.             ,0WMMMMMMMMMMMM
MMMMMMMMMMMM0;           .:xXWMMMMMMMMMMMMMMMMMMMMWXx:.           ;0MMMMMMMMMMMM
MMMMMMMMMMMX:          .l0WMMMMMMMMMMMMMMMMMMMMMMMMMMW0l.          :XMMMMMMMMMMM
MMMMMMMMMMNl          :0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0:          lNMMMMMMMMMM
MMMMMMMMMWx.        .dNMMMMMMMMMMMWNKOkkkkOKNWMMMMMMMMMMMNd.        .xWMMMMMMMMM
MMMMMMMMM0,        .xWMMMMMMMMMWKd:..      ..:dKWMMMMMMMMMWx.        ,0MMMMMMMMM
MMMMMMMMNl        .oNMMMMMMMMMXo.              .oXMMMMMMMMMNo.        oNMMMMMMMM
MMMMMMMM0'        ;KMMMMMMMMM0;                  ;0MMMMMMMMMK;        '0MMMMMMMM
MMMMMMMWo         oWMMMMMMMMX:                    :XMMMMMMMMWo         oWMMMMMMM
MMMMMMMK;        .xMMMMMMMMMO.                    .OMMMMMMMMMx.        ;KMMMMMMM
MMMMMMMO.        .xMMMMMMMMMk.                    .kMMMMMMMMMx.        .OMMMMMMM
MMMMMMMd.         dWMMMMMMMMK;                    ;KMMMMMMMMWd         .xMMMMMMM
MMMMMMMd          ;XMMMMMMMMWk'                  'kWMMMMMMMMX;          dMMMMMMM
MMMMMMWo          .dWMMMMMMMMW0:.              .:0WMMMMMMMMWd.          dWMMMMMM
MMMMMMMd           .kWMMMMMMMMMNOl'.        .'lONMMMMMMMMMWk.           dMMMMMMM
MMMMMMMx.           'kWMMMMMMMMMMWN0kdoooodk0NWMMMMMMMMMMWk.           .xMMMMMMM
MMMMMMMO.            .oXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo.            .OMMMMMMM
MMMMMMMXc              'xXWMMMMMMMMMMMMMMMMMMMMMMMMMMWXx'              cXMMMMMMM
MMMMMMMMk.               'o0NMMMMMMMMMMMMMMMMMMMMMMN0o'               .kMMMMMMMM
MMMMMMMMNo.                .,lkKNWMMMMMMMMMMMMWNKkl,.                .oNMMMMMMMM
MMMMMMMMMXc                    .':lodxkkkkxdol:'.                    cXMMMMMMMMM
MMMMMMMMMMXc                                                        cXMMMMMMMMMM
MMMMMMMMMMMXo.                                                    .oXMMMMMMMMMMM
MMMMMMMMMMMMWk,                                                  ,kWMMMMMMMMMMMM
MMMMMMMMMMMMMMXo.                 ,:.      .:,                 .oXMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMWKo'               ;kOo::::oOk;               'oKWMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMWXx;.             .;loddol,.             .;xXWMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMW0d:.                              .:d0WMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMWXko:'.                    .':okXWMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMWXOdc,..          ..,cdOXWMMMMMMMMMMMMMMMMMMMMMMMMMMM

*/

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import 'erc721a/contracts/ERC721A.sol';
import './lib/MerkleDistributor.sol';

contract DourDarcels is ERC721A, MerkleDistributor, ReentrancyGuard, AccessControl {
    bytes32 public constant SUPPORT_ROLE = keccak256('SUPPORT');
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant MAX_ALLOWLIST_MINT = 3;
    uint256 public constant MAX_PUBLIC_MINT = 3;
    uint256 public constant MAX_RESERVE_SUPPLY = 150;
    uint256 public constant PRICE_PER_TOKEN = 0.1 ether;

    string public provenance;
    string private _baseURIextended;
    bool public saleActive;
    uint256 public reserveSupply;

    address payable public immutable shareholderAddress;

    constructor(address payable shareholderAddress_) ERC721A("Dour Darcels", "DARCEL") {
        require(shareholderAddress_ != address(0));

        // set immutable variables
        shareholderAddress = shareholderAddress_;

        // setup roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(SUPPORT_ROLE, msg.sender);
    }

    modifier ableToMint(uint256 numberOfTokens) {
        require(totalSupply() + numberOfTokens <= MAX_SUPPLY, 'Purchase would exceed max tokens');
        _;
    }

    modifier isPublicSaleActive() {
        require(saleActive, 'Public sale is not active');
        _;
    }

    /**
     * admin
     */
    function devMint(uint256 numberOfTokens) external onlyRole(SUPPORT_ROLE) ableToMint(numberOfTokens) nonReentrant {
        require(reserveSupply + numberOfTokens <= MAX_RESERVE_SUPPLY, 'Number would exceed max reserve supply');

        reserveSupply += numberOfTokens;
        _safeMint(msg.sender, numberOfTokens);
    }

    function setSaleActive(bool state) external onlyRole(SUPPORT_ROLE) {
        saleActive = state;
    }

    /**
     * allow list
     */
    function setAllowListActive(bool allowListActive) external onlyRole(SUPPORT_ROLE) {
        _setAllowListActive(allowListActive);
    }

    function setAllowList(bytes32 merkleRoot) external onlyRole(SUPPORT_ROLE) {
        _setAllowList(merkleRoot);
    }

    /**
     * tokens
     */
    function setBaseURI(string memory baseURI_) external onlyRole(SUPPORT_ROLE) {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setProvenance(string memory provenance_) external onlyRole(SUPPORT_ROLE) {
        provenance = provenance_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721A) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * public
     */
    function mintAllowList(uint256 numberOfTokens, bytes32[] memory merkleProof)
        external
        payable
        isAllowListActive
        ableToClaim(msg.sender, merkleProof)
        tokensAvailable(msg.sender, numberOfTokens, MAX_ALLOWLIST_MINT)
        ableToMint(numberOfTokens)
        nonReentrant
    {
        require(numberOfTokens * PRICE_PER_TOKEN == msg.value, 'Ether value sent is not correct');

        _setAllowListMinted(msg.sender, numberOfTokens);
        _safeMint(msg.sender, numberOfTokens);
    }

    function mint(uint256 numberOfTokens) external payable isPublicSaleActive ableToMint(numberOfTokens) nonReentrant {
        require(numberOfTokens <= MAX_PUBLIC_MINT, 'Exceeded max token purchase');
        require(numberOfTokens * PRICE_PER_TOKEN == msg.value, 'Ether value sent is not correct');

        _safeMint(msg.sender, numberOfTokens);
    }

    /**
     * withdraw
     */
    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        (bool success, ) = shareholderAddress.call{value: address(this).balance}('');
        require(success, 'Transfer failed.');
    }
}