// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Strings.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "closedsea/src/OperatorFilterer.sol";

contract ImaginaryArtifacts is
    ERC1155Burnable,
    ERC2981,
    Ownable,
    ReentrancyGuard,
    OperatorFilterer
{
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY_PER_ARTIFACT = 8928;

    bool public operatorFilteringEnabled;

    string public name;
    string public symbol;
    string private baseURI;
    bool public mergeStatus;
    address public mergeContract;
    uint256[] public idsForMerge;

    mapping(uint256 => uint256) public supplies;
    mapping(uint256 => bool) public claimStatus;
    mapping(uint256 => mapping(address => uint256)) public allowlistClaimed;
    mapping(uint256 => bytes32) public merkleRoots;

    error ClaimNotOpened();
    error ExceedsArtifactSupply();
    error ExceedsAllocatedForArtifact();
    error NotOnAllowlist();
    error MergeNotOpened();
    error UnauthorizedMergeAddress();

    event Claimed();
    event Merged();

    modifier isClaimable(uint256 _id) {
        if (!claimStatus[_id]) revert ClaimNotOpened();
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI
    ) ERC1155(_baseURI) {
        name = _name;
        symbol = _symbol;
        baseURI = _baseURI;

        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        _setDefaultRoyalty(msg.sender, 1000);
    }

    function totalSupply(uint256 _id) public view returns (uint256) {
        return supplies[_id];
    }

    function updateBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function uri(uint256 typeId) public view override returns (string memory) {
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, typeId.toString()))
                : baseURI;
    }

    function updateClaimStatus(uint256 _id, bool _status) external onlyOwner {
        claimStatus[_id] = _status;
    }

    function updateMergeStatus(bool _status) external onlyOwner {
        mergeStatus = _status;
    }

    function updateMergeContract(address _contractAddress) external onlyOwner {
        mergeContract = _contractAddress;
    }

    function updateIDsForMerge(uint256[] calldata _ids) external onlyOwner {
        idsForMerge = _ids;
    }

    function updateMerkleRoot(uint256 _id, bytes32 _merkleRoot)
        external
        onlyOwner
    {
        merkleRoots[_id] = _merkleRoot;
    }

    function airdrop(
        address _to,
        uint256 _id,
        uint256 _amount
    ) external onlyOwner nonReentrant isClaimable(_id) {
        if (totalSupply(_id) + _amount > MAX_SUPPLY_PER_ARTIFACT)
            revert ExceedsArtifactSupply();

        _mint(_to, _id, _amount, "");
        supplies[_id] += _amount;
    }

    function claim(
        uint256 _id,
        uint256 _amount,
        bytes32[] calldata _merkleproof,
        uint256 _allowedClaimQuantity
    ) external nonReentrant isClaimable(_id) {
        if (totalSupply(_id) + _amount > MAX_SUPPLY_PER_ARTIFACT)
            revert ExceedsArtifactSupply();

        if (allowlistClaimed[_id][msg.sender] + _amount > _allowedClaimQuantity)
            revert ExceedsAllocatedForArtifact();

        bytes32 leaf = keccak256(
            abi.encodePacked(msg.sender, _allowedClaimQuantity)
        );
        if (!MerkleProof.verifyCalldata(_merkleproof, merkleRoots[_id], leaf))
            revert NotOnAllowlist();

        supplies[_id] += _amount;
        allowlistClaimed[_id][msg.sender] += _amount;

        _mint(msg.sender, _id, _amount, "");

        emit Claimed();
    }

    function merge(address _account, uint256[] calldata _amounts)
        external
        nonReentrant
    {
        if (!mergeStatus) revert MergeNotOpened();

        if (msg.sender != mergeContract) revert UnauthorizedMergeAddress();

        _burnBatch(_account, idsForMerge, _amounts);

        emit Merged();
    }

    /*
     * @notice Override for DefaultOperatorFilterer, which automatically registers the token and subscribes it to OpenSea's curated filters.
     * @dev Makes use of Vectorized/closedsea (https://github.com/Vectorized/closedsea) package
     */
    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    /*
     * @notice Override for DefaultOperatorFilterer, which automatically registers the token and subscribes it to OpenSea's curated filters.
     * @dev Makes use of Vectorized/closedsea (https://github.com/Vectorized/closedsea) package
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    /*
     * @notice Override for DefaultOperatorFilterer, which automatically registers the token and subscribes it to OpenSea's curated filters.
     * @dev Makes use of Vectorized/closedsea (https://github.com/Vectorized/closedsea) package
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /*
     * @notice Override for DefaultOperatorFilterer, which automatically registers the token and subscribes it to OpenSea's curated filters.
     * @dev Makes use of Vectorized/closedsea (https://github.com/Vectorized/closedsea) package
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC2981)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC1155: 0xd9b67a26
        // - IERC1155MetadataURI: 0x0e89341c
        // - IERC2981: 0x2a55205a
        return
            ERC1155.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    /*
     * @notice Override for DefaultOperatorFilterer, which automatically registers the token and subscribes it to OpenSea's curated filters.
     * @dev Makes use of Vectorized/closedsea (https://github.com/Vectorized/closedsea) package
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        public
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /*
     * @notice Override for DefaultOperatorFilterer, which automatically registers the token and subscribes it to OpenSea's curated filters.
     * @dev Makes use of Vectorized/closedsea (https://github.com/Vectorized/closedsea) package
     */
    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    /*
     * @notice Override for DefaultOperatorFilterer, which automatically registers the token and subscribes it to OpenSea's curated filters.
     * @dev Makes use of Vectorized/closedsea (https://github.com/Vectorized/closedsea) package
     */
    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    /*
     * @notice Override for DefaultOperatorFilterer, which automatically registers the token and subscribes it to OpenSea's curated filters.
     * @dev Makes use of Vectorized/closedsea (https://github.com/Vectorized/closedsea) package
     */
    function _isPriorityOperator(address operator)
        internal
        pure
        override
        returns (bool)
    {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }
}