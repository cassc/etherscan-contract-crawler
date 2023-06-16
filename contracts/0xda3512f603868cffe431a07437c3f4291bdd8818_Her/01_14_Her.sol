// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import { ERC721A } from 'erc721a/contracts/ERC721A.sol';
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { ERC2981 } from '@openzeppelin/contracts/token/common/ERC2981.sol';
import { MerkleProof } from '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import { DefaultOperatorFilterer } from 'operator-filter-registry/src/DefaultOperatorFilterer.sol';

struct MintParameters {
    uint256 price;
    bytes32 root;
    uint16 quantity;
}

contract Her is ERC721A, ERC2981, Ownable, DefaultOperatorFilterer {

    error MintNotEnabled();
    error ExceedsSupply();
    error ExceedsAllowance();
    error WrongAmount();
    error InvalidProof();
    error InvalidMintType();

    string private baseURI;
    MintParameters[5] public mintParameters;
    uint256 public constant MAX_SUPPLY = 1000;
    address withdrawAddress;
    bool public mintEnabled = false;

    constructor(address payee) ERC721A("Her", "HER") {
        _setDefaultRoyalty(payee, 1000);
        withdrawAddress = payee;
    }

    function toggleMintEnabled() external onlyOwner {
        mintEnabled = !mintEnabled;
    }
    
    function mintOwner(uint256 quantity, address to) external onlyOwner {
        if (_totalMinted() + quantity > MAX_SUPPLY) {
            revert ExceedsSupply();
        }

        _mint(to, quantity);
    }

    function mint(uint256 quantity, uint16 type_, bytes32[] calldata proof) external payable {
        ensureValidMint(type_, quantity, proof);

        _mint(msg.sender, quantity);
    }

    function setMintParameters(uint16 type_, MintParameters calldata parameters) external onlyOwner {
        if (type_ > 4) {
            revert InvalidMintType();
        }
        mintParameters[type_] = parameters;
    }

    function setAllMintParameters(MintParameters[5] calldata parameters) external onlyOwner {
        for (uint16 i; i < 5; i++) {
            mintParameters[i] = parameters[i];
        }
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function numberMinted(address user) external view returns(uint256) {
        return _numberMinted(user);
    }

    function ensureValidMint(uint16 type_, uint256 quantity, bytes32[] calldata proof) private view {
        if (!mintEnabled) {
            revert MintNotEnabled();
        }
        if (type_ >= mintParameters.length) {
            revert InvalidMintType();
        }
        if (_totalMinted() + quantity > MAX_SUPPLY) {
            revert ExceedsSupply();
        }
        MintParameters storage parameters = mintParameters[type_];   
        if (_numberMinted(msg.sender) + quantity > parameters.quantity) {
            revert ExceedsAllowance();
        }
        if (msg.value != quantity * parameters.price) {
            revert WrongAmount();
        }

        if (parameters.root != bytes32(0x00)) {
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            if (!MerkleProof.verifyCalldata(proof, parameters.root, leaf)) {
                revert InvalidProof();
            }
        }
    }

    function withdraw() external onlyOwner {
        uint256 currentBalance = address(this).balance;
        (bool success, ) = payable(withdrawAddress).call{value: currentBalance}("");
        
        require(success, "Withdraw failed");
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) || 
            ERC2981.supportsInterface(interfaceId);
    }

    /** Operator filter overrides */
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

}