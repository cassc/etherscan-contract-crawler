// SPDX-License-Identifier: MIT

/*
MMMMMMMMMMMMMMMMMMMMMMMMWX0xoc;'..            ..';coxOXWMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMN0xc,.                            .cKMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMWXkl,.                                .oNMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMNkc.                                   .oNMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMWKd,                                      lNMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMWKl.                                       cXMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMXo.                                        cXMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMWk,                                         :XMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMXl.                                         ;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMK:                                          ;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMM0,                                          ,0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MM0,                                          '0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MX:                                          'OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
Wo                      ,llllllc.  'clllllllo0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
O'                     :KMMMMMMWk. 'OWMMMMMMMMWWWWWWWWWWWWWMMMMMMMMMMMMMMMMMMMMM
l                     ;KMMMWNWMMWk. ,0MMMMMMMMKl,''''','';xWMMMMMMMMMMMMMMMMMMMM
'                    ,0MMMNo;OWMMWx. ,0MMMMMWWWx.         .xWMMMMMMMMMMMMMMMMMMM
.                   ,0MMMWd. 'OWMMWd. ;KMMMXolXWd.....     .xWMMMMMMMMMMMMMMMMMM
                   'OWMMWx.   ,0MMMWd..kWWNl  cXWK0000O:    .kWMMMMMMMMMMMMMMMMM
                  .OWMMWx.     ,0MMMNxxNMWo.   lNMMMMMMK:    'OWMMMMMMMMMMMMMMMM
                 .kWMMWk.       ;KMMMMMMMWd.   .lNMMMMMMK;    'OMMMMMMMMMMMMMMMM
                .xWMMWk' .......'dNMMMNXKNNo.   .oNMMMMMM0,    ,0MMMMMMMMMMMMMMM
.              .xWMMWO' 'kXNNNNNNNWMMWd'.oNNl    .dNMMMMMM0,    ;0MMMMMMMMMMMMMM
;             .dWMMM0, .kWMMMMMMMMMMWx.  .oNNl    .:ooooooo,     ;KMMMMMMMMMMMMM
d.            ,dkkkd,  :xkkkkkkkOXMWx.    .dWXc                   :XMMMMMMMMMMMM
K;                              :KWk.      .xWX:                   cXMMMMMMMMMMM
Wk.                            ,0MWOoooooolokNMXxooooooooooooooollldKMMMMMMMMMMM
MWd.                          'OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMNo.                        'OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMNo.                      .kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMNx.                    .kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMW0;                  .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMXd.               .dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMWKl.            .dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMW0l.         .oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMWKd,.     .lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMNOl,.  lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMN0dxXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM

*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NiXIDs is ERC721Enumerable, Ownable, ReentrancyGuard {

    bytes32 merkleRoot;
    string public PROVENANCE;
    bool public isSaleActive;
    string private _baseURIextended;

    bool public isAllowListActive;
    uint public constant MAX_SUPPLY = 1000;
    uint public constant RESERVE_SUPPLY = 35;
    uint public constant MAX_ALLOWLIST_MINT = 3;
    uint public constant MAX_PUBLIC_MINT = 3;
    uint public constant PRICE_PER_TOKEN = 0.03 ether;

    mapping(address => uint) private _allowListNumMinted;

    address payable public immutable shareholderAddress;

    constructor(address payable shareholderAddress_) ERC721("NiX IDs", "NIXID") {
        require(shareholderAddress_ != address(0));
        shareholderAddress = shareholderAddress_;
    }

    function setAllowListActive(bool _isAllowListActive) external onlyOwner {
        isAllowListActive = _isAllowListActive;
    }

    function setAllowList(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function onAllowList(address claimer, bytes32[] memory proof) public view returns(bool){
        bytes32 leaf = keccak256(abi.encodePacked(claimer));
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    function numAvailableToMint(address claimer, bytes32[] memory proof) public view returns (uint) {
        if (onAllowList(claimer, proof)) {
            return MAX_ALLOWLIST_MINT - _allowListNumMinted[claimer];
        } else {
            return 0;
        }
    }

    function mintAllowList(uint numberOfTokens, bytes32[] memory merkleProof) external payable nonReentrant {
        uint ts = totalSupply();
        require(isAllowListActive, "Allow list is not active");
        require(onAllowList(msg.sender, merkleProof), "Not on allow list");
        require(numberOfTokens <= MAX_ALLOWLIST_MINT - _allowListNumMinted[msg.sender], "Exceeded max available to purchase");
        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");

        _allowListNumMinted[msg.sender] += numberOfTokens;
        for (uint i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
        }
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setProvenance(string memory provenance) external onlyOwner {
        PROVENANCE = provenance;
    }

    function reserve() external onlyOwner {
        uint supply = totalSupply();
        uint i;
        for (i = 0; i < RESERVE_SUPPLY; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function setSaleActive(bool newState) external onlyOwner {
        isSaleActive = newState;
    }

    function mint(uint numberOfTokens) external payable nonReentrant {
        uint ts = totalSupply();
        require(isSaleActive, "Sale must be active to mint tokens");
        require(numberOfTokens <= MAX_PUBLIC_MINT, "Exceeded max token purchase");
        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");

        for (uint i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
        }
    }

    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        Address.sendValue(shareholderAddress, balance);
    }
}