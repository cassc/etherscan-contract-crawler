// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "operator-filter-registry/src/UpdatableOperatorFilterer.sol";
import "operator-filter-registry/src/RevokableDefaultOperatorFilterer.sol";

contract Thr33som3s is ERC1155, ERC1155Burnable, ERC1155Supply, ERC2981, Ownable, AccessControl, RevokableDefaultOperatorFilterer, PaymentSplitter, ReentrancyGuard {
    using Strings for uint256;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MERKLE_ROLE = keccak256("MERKLE_ROLE");

    string public name = "thr33som3s";
    string public symbol = "THR33";

    mapping(uint256 => uint256) public saleActiveTokens; //tokenID => maxMint; set to 0 to turn off sale, set to maxQuantity to turn on sale for a tokenId
    string public baseURI = "https://api.thr33zi3s.com/thr33som3s/";
    uint256 public price = 0;
    uint256 public maxMint = 100; // maximum per transaction, if user and token limit allow

    mapping (uint256 => bytes32) public merkleRoots; // saleActiveToken => "address:number","address:number"...
    mapping (address => mapping(uint256 => uint256)) public mints; //address => saleActiveToken => number


    constructor(address[] memory payees, uint256[] memory shares, address admin, address allowlistAdmin)
        ERC1155("thr33som3s")
        PaymentSplitter(payees, shares) payable {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
        _grantRole(MERKLE_ROLE, admin);
        _grantRole(MERKLE_ROLE, allowlistAdmin);
        }

    function updateBaseUri(string memory _baseURI) external onlyRole(ADMIN_ROLE) {
        baseURI = _baseURI;
    }    

    function setSaleActiveToken(uint256 tokenId, uint256 quantity) public onlyRole(ADMIN_ROLE) {
        saleActiveTokens[tokenId] = saleActiveTokens[quantity];
    }

    function bulkSetSaleActiveTokens(uint256[] calldata tokenIds, uint256[] calldata quantities) external onlyRole(ADMIN_ROLE) {
        require(tokenIds.length == quantities.length,                               "Must submit equal counts of tokenIds and quantities");
        for(uint256 i = 0; i < tokenIds.length; i++){
            saleActiveTokens[tokenIds[i]] = quantities[i];
        }
    }

    function updatePrice(uint256 amt) public onlyRole(ADMIN_ROLE) {
        price = amt;
    }

    function updateMaxMint(uint256 num) public onlyRole(ADMIN_ROLE) {
        maxMint = num;
    }

    function setMerkleRootOfToken(uint256 token, bytes32 root) external onlyRole(MERKLE_ROLE) {
        merkleRoots[token] = root;
    }

    function bulkSetMerkleRootOfTokens(uint256[] calldata tokenIds, bytes32[] calldata roots) external onlyRole(MERKLE_ROLE) {
        require(tokenIds.length == roots.length,                                    "Must submit equal counts of tokenIds and roots");
        for(uint256 i = 0; i < tokenIds.length; i++){
            merkleRoots[tokenIds[i]] = roots[i];
        }
    }

    //requires front end calculating proof allotted number to match number allotted on contract
    function verify(uint256 token, uint256 num, bytes32[] memory _proof) public view returns (bool)
    {
        bytes32 _leaf = keccak256(abi.encodePacked(msg.sender,num));

        return MerkleProof.verify(_proof, merkleRoots[token], _leaf);
    }      

    function ownerMint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyRole(ADMIN_ROLE)
    {
        require(totalSupply(id) + amount <= saleActiveTokens[id],                   "Exceeds Max mint for Token");
        _mint(account, id, amount, data);
    }

    error ExceedsMaxMint(uint256 tokenId, uint256 requested, uint256 available);

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyRole(ADMIN_ROLE)
    {
        for (uint256 i = 0; i < ids.length; ++i) {
            if(totalSupply(ids[i]) + amounts[i] > saleActiveTokens[ids[i]]) 
                revert ExceedsMaxMint({
                    tokenId: ids[i],
                    requested: amounts[i],
                    available: saleActiveTokens[ids[i]] - totalSupply(ids[i])
                });
        }
        _mintBatch(to, ids, amounts, data);
    }

    function mint(uint256 token, uint256 num, bytes32[] memory proof) public payable nonReentrant {
        require(saleActiveTokens[token] > 0,                                        "Sale Not Active");
        require(num > mints[msg.sender][token],                                     "Allowed mints exceeded.");
        require(verify(token, num, proof),                                          "Address not on Allow List");
        uint256 numToMint = num - mints[msg.sender][token];
        require(msg.value == price * numToMint,                                     "Ether sent is not correct");
        require(numToMint <= maxMint,                                               "Max Mint Per Transaction exceeded"); //100 should be more than sufficient, but can be raised
        require(totalSupply(token) + numToMint <= saleActiveTokens[token],          "Exceeds Max mint for Token");
        mints[msg.sender][token] += numToMint;
        _mint(msg.sender, token, numToMint, "");
    }

    function uri(uint256 typeId) public view override returns (string memory)
    {
        require(typeId >= 0, "URI requested for invalid token type");
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, typeId.toString())) : "";
    }    

    // ERC2981

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public virtual onlyRole(ADMIN_ROLE) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() public virtual onlyRole(ADMIN_ROLE) {
        _deleteDefaultRoyalty();
    }

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) public virtual onlyRole(ADMIN_ROLE) {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function resetTokenRoyalty(uint256 tokenId) public virtual onlyRole(ADMIN_ROLE) {
        _resetTokenRoyalty(tokenId);
    }

    // Operator Filter Overrides

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Returns the owner of the ERC1155 token contract.
     */
    function owner() public view virtual override(Ownable, UpdatableOperatorFilterer) returns (address) {
        return Ownable.owner();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC2981, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}