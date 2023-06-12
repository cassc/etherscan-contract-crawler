// SPDX-License-Identifier: MIT
// 
//     __  ___                        ______                     _     
//    /  |/  /___ _____  ____ _____ _/ ____/__  ____  ___  _____(_)____
//   / /|_/ / __ `/ __ \/ __ `/ __ `/ / __/ _ \/ __ \/ _ \/ ___/ / ___/
//  / /  / / /_/ / / / / /_/ / /_/ / /_/ /  __/ / / /  __(__  ) (__  ) 
// /_/  /_/\__,_/_/ /_/\__, /\__,_/\____/\___/_/ /_/\___/____/_/____/  
//                    /____/                                           
// 

pragma solidity ^0.8.17;

import "./ERC721A/ERC721A.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {DefaultOperatorFilterer} from "./OperatorFilterRegistry/DefaultOperatorFilterer.sol";

contract MangaGenesis is ERC721A, ERC2981, DefaultOperatorFilterer, Ownable {
    bool public isPublic;
    uint256 public constant MAX_SUPPLY = 1000;
    uint256 public constant WALLET_MINT_CAP = 1;
    address public constant TEAM_WALLET = 0xeEeEb568a5b4c1d88f2E5E356933A42c780A67d9;
    string private _imageUri = "QmST692ENDJE4wyUg2dKvbbiDMcPtLCZ3s9541LDzGZJ2v";
    bytes32 public whiteListMerkleRoot;
    mapping(address => uint256) public minted;

    modifier callerIsUser() {
        require(msg.sender == tx.origin, "Only user can call this function");
        _;
    }

    constructor() ERC721A("MangaGenesis", "MG") {
        _safeMint(TEAM_WALLET, 150);
        _setDefaultRoyalty(TEAM_WALLET, 750); // Royalty 7.5%
        transferOwnership(TEAM_WALLET);
    }

    modifier onlyWhitelisted(bytes32[] calldata merkleProof) {
        if (!isPublic) {
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(merkleProof, whiteListMerkleRoot, leaf), "Not in whitelist");
        }
        _;
    }

    function getMaxMintable(address user) external view returns(uint256) {
        return WALLET_MINT_CAP - minted[user];
    }

    function mint(bytes32[] calldata proof, uint256 quantity) external onlyWhitelisted(proof) callerIsUser {
        require(minted[msg.sender] + quantity <= WALLET_MINT_CAP && _totalMinted() + quantity <= MAX_SUPPLY, "You can not mint any more");
        minted[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function setImageUri(string memory newImage) external onlyOwner {
        _imageUri = newImage;
    }

    function setMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        whiteListMerkleRoot = merkleRoot;
    }

    function togglePublicSale() external onlyOwner {
        isPublic = !isPublic;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721A) returns (string memory) {
        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(
            abi.encodePacked(
                '{',
                    '"name":"MangaGenesis #', Strings.toString(tokenId), '",',
                    '"description":"The Mother on the Genesis NFT is the symbolic character of manga factory. Our IP revolution begins with the Genesis NFT. Our goal is to create a unique experience for collectors to connect with creators, own and support their IP. Come on, let the revolution begin.",',
                    '"image":"', _imageUri, '",',
                    '"attributes":[{"trait_type":"id","display_type":"number","value":', Strings.toString(tokenId), '},'
                    '{"trait_type":"type","value":"Genesis"}]',
                '}'
            )
        ) ) );
    }

    //=======================================================================
    // [public/override] supportsInterface
    //=======================================================================
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return 
            ERC721A.supportsInterface(interfaceId) || 
            ERC2981.supportsInterface(interfaceId);
    }

    //=======================================================================
    // [external/onlyOwnerOrManager] for ERC2981
    //=======================================================================
    function setDefaultRoyalty( address receiver, uint96 feeNumerator ) external onlyOwner { _setDefaultRoyalty( receiver, feeNumerator ); }
    function deleteDefaultRoyalty() external onlyOwner { _deleteDefaultRoyalty(); }

    //=======================================================================
    // [public/override/onlyAllowedOperatorApproval] for OperatorFilter
    //=======================================================================
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) { super.setApprovalForAll(operator, approved); }
    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) { super.approve(operator, tokenId); }
    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) { super.transferFrom(from, to, tokenId); }
    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) { super.safeTransferFrom(from, to, tokenId); }
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override onlyAllowedOperator(from) { super.safeTransferFrom(from, to, tokenId, data); }
}