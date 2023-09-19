// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC721A, ERC721A} from "erc721a/ERC721A.sol";
import {ERC721AQueryable} from "erc721a/extensions/ERC721AQueryable.sol";
import {ERC721ABurnable} from "erc721a/extensions/ERC721ABurnable.sol";
import {OperatorFilterer} from "../OperatorFilterer.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {IERC2981, ERC2981} from "openzeppelin-contracts/token/common/ERC2981.sol";
import {MerkleProof} from "openzeppelin-contracts/utils/cryptography/MerkleProof.sol";

contract Turds is
    ERC721AQueryable,
    ERC721ABurnable,
    OperatorFilterer,
    Ownable,
    ERC2981
{
    bool public operatorFilteringEnabled;
    string private _uri;
    bytes32 public merkleRoot;
    mapping(address => bool) public allowListMinted;
    uint256 public constant MAX_SUPPLY = 5555;
    uint256 public price = 0.004 ether;

    // 0x5357b61a7caeec6120ce84392fc265b5fe114b80d802324df06c93ca8509bcfc
    constructor(bytes32 _merkleRoot) ERC721A("Turds", "TURD") {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        merkleRoot = _merkleRoot;

        _mint(msg.sender, 1);

        // Set royalty receiver to the contract creator,
        // at 5% (default denominator is 10000).
        _setDefaultRoyalty(msg.sender, 500);
    }

    function updatePrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function updateRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function updateMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    // Check the Merkle proof using this function
    function allowListed(address _wallet, bytes32[] calldata _proof)
        public
        view
        returns (bool)
    {
    return
        MerkleProof.verify(
            _proof,
            merkleRoot,
            keccak256(abi.encodePacked(_wallet))
        );
    }
    
    function mintAllowList(bytes32[] calldata _proof) external {
        require(allowListed(msg.sender, _proof), "You are not on the allowlist");
        require(totalSupply() < MAX_SUPPLY, "All tokens have been minted");
        require(!allowListMinted[msg.sender], "You already minted your token");
        allowListMinted[msg.sender] = true;
        _mint(msg.sender, 1);
    }

    function mint(uint256 amount) external payable {
        require(msg.value == price * amount, "Not enough ETH sent; check price!");
        require(totalSupply() + amount < MAX_SUPPLY, "All tokens have been minted");
        payable(owner()).transfer(msg.value);
        _mint(msg.sender, amount);
    }

    function setBaseURI(string memory uri) public onlyOwner {
        _uri = uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override(IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override(IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    /**
     * @dev Both safeTransferFrom functions in ERC721A call this function
     * so we don't need to override them.
     */
    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override(IERC721A, ERC721A)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC721A, ERC721A, ERC2981)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }
}