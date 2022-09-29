// SPDX-License-Identifier: MIT
/*
MMMMMMMMMMMMMMMMMMMMN0kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOXMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMWd.                                   lNMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMK,                                    '0MMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMNl                                      :XMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMWx.                                      .dWMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMX:                                        ,KMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMWx.                                         lNMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMK,                                          'OMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMWd.                 .oOOOOo.                  cNMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMO.                  ;KMMMMX:                  .xWMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMNl                   ;KMMMMX:                   ,KMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMWk.                   ;XMMMMNl                   .dWMMMMMMMMMMMMMMM
MMMMMMMMMMMMMK;                   .dWMMMMMk.                   'OMMMMMMMMMMMMMMM
MMMMMMMMMMMMWd                    .kMMMMMMK,                    lNMMMMMMMMMMMMMM
MMMMMMMMMMMM0,                    ;KMMMMMMWl                    .kWMMMMMMMMMMMMM
MMMMMMMMMMMNl                     oWMMMMMMWd.                    ;KMMMMMMMMMMMMM
MMMMMMMMMMMO.                    .kMMMMMMMMK,                     dWMMMMMMMMMMMM
MMMMMMMMMMX:                     ;XMMMMMMMMX;                     ,KMMMMMMMMMMMM
MMMMMMMMMWo.                     :XMMMMMMMMWd.                     lNMMMMMMMMMMM
MMMMMMMMMK,                     'OMMMMMMMMMMK:                     .OMMMMMMMMMMM
MMMMMMMMNl                     :0WMMMMMMMMMMMXl.                    :XMMMMMMMMMM
MMMMMMMMO'                    cXMMMMMMMMMMMMMMWx.                   .xWMMMMMMMMM
MMMMMMMNl                    'OMMMMMMMMMMMMMMMMX;                    ;KMMMMMMMMM
MMMMMMWx.                    ;XMMMMMMMMMMMMMMMMX;                     oNMMMMMMMM
MMMMMMK,                     ;XMMMMMMMMMMMMMMMMX;                     'OMMMMMMMM
MMMMMWo.                     ;XMMMMMMMMMMMMMMMMX;                      lNMMMMMMM
MMMMMO.                      ;XMMMMMMMMMMMMMMMMX;                      .xMMMMMMM
MMMMNc                       ;XMMMMMMMMMMMMMMMMX;                       :XMMMMMM
MMMWk.                       ;XMMMMMMMMMMMMMMMMX;                       .dWMMMMM
MMMX:                        ;XMMMMMMMMMMMMMMMMX;                        .OMMMMM
MMWx.                        ;XMMMMMMMMMMMMMMMMX;                         cNMMMM
MMK,                         ;XMMMMMMMMMMMMMMMMX;                         .kWMMM
MNl                          ;XMMMMMMMMMMMMMMMMX;                          :XMMM
MO.                          ;XMMMMMMMMMMMMMMMMX;                          .kMMM
X:                           ;XMMMMMMMMMMMMMMMMX;                           ,KMM
O,                           cXMMMMMMMMMMMMMMMMXc                            oNM
NOkkkkkkkkkkkkkkkkkkkkkkkkkkk0WMMMMMMMMMMMMMMMMW0kkkkkkkkkkkkkkkkkkkkkkkkkkkk0WM
*/
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract F50 is ERC721, Ownable {
    using Strings for uint256;
    uint256 public constant MAX_SUPPLY = 50;
    uint256 public tokenPrice = 5 ether;
    uint256 public tokenID;
    string private baseTokenURI;
    bytes32 private merkleRoot;
    mapping(address => bool) public minted;
    error BeyondMaxSupply();
    error AlreadyMinted();
    error WrongAmountOfEther();
    error NotAFounder();

    constructor(string memory _baseTokenURI, bytes32 _merkleRoot)
        ERC721("F50", "F50")
    {
        baseTokenURI = _baseTokenURI;
        merkleRoot = _merkleRoot;
    }

    function isValidUser(bytes32[] memory _merkleProof, bytes32 _leaf)
        public
        view
        returns (bool)
    {
        return MerkleProof.verify(_merkleProof, merkleRoot, _leaf);
    }

    function mint(bytes32[] memory _merkleProof) external payable {
        if (tokenID >= MAX_SUPPLY) revert BeyondMaxSupply();
        if (minted[msg.sender]) revert AlreadyMinted();
        if (msg.value != tokenPrice) revert WrongAmountOfEther();
        if (!isValidUser(_merkleProof, keccak256(abi.encodePacked(msg.sender)))) revert NotAFounder();
        minted[msg.sender] = true;
        _mint(msg.sender, tokenID);
        tokenID++;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 _tokenID)
        public
        view
        override
        returns (string memory)
    {
        return
            string(abi.encodePacked(baseTokenURI, Strings.toString(_tokenID)));
    }

    function setTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setTokenPrice(uint256 _tokenPrice) external onlyOwner {
        tokenPrice = _tokenPrice;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function withdraw() external payable onlyOwner {
        (bool os, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(os);
    }
}