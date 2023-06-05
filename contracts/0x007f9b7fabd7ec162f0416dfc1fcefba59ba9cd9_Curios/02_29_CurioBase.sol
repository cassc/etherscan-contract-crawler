// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/token/ERC1155/extensions/ERC1155Burnable.sol";

import "@openzeppelin/token/common/ERC2981.sol";

import "@openzeppelin/access/Ownable.sol";

import "@operator-filter-registry/RevokableDefaultOperatorFilterer.sol";
import "@operator-filter-registry/UpdatableOperatorFilterer.sol";

import "../interfaces/IERC4906.sol";

import "./CurioSignatureCheck.sol";

import "./CurioErrorsAndEvents.sol";
import "./CurioStructs.sol";

contract CurioBase is
    CurioErrorsAndEvents,
    CurioStructs,
    ERC1155Burnable,
    CurioEIP712,
    IERC4906,
    ERC2981,
    RevokableDefaultOperatorFilterer,
    Ownable
{
    address public POPPETS;
    address public PACKS;

    address private _receiver;

    string public name;
    string public symbol;

    uint public nextToken = 0;

    uint16 public currentThread = 0;

    mapping(bytes32 => bool) private _usedSignatures;

    mapping(uint => Curio) private _curios;

    mapping(address => bool) private _soulboundExempt;

    constructor(
        string memory name_,
        string memory symbol_,
        address signer_,
        string memory uri_
    ) ERC1155(uri_) CurioEIP712(name_, signer_) {
        name = name_;
        symbol = symbol_;
    }

    // ███    ███  ██████  ██████  ██ ███████ ██ ███████ ██████  ███████
    // ████  ████ ██    ██ ██   ██ ██ ██      ██ ██      ██   ██ ██
    // ██ ████ ██ ██    ██ ██   ██ ██ █████   ██ █████   ██████  ███████
    // ██  ██  ██ ██    ██ ██   ██ ██ ██      ██ ██      ██   ██      ██
    // ██      ██  ██████  ██████  ██ ██      ██ ███████ ██   ██ ███████

    modifier checkSoulbound(uint tokenId) {
        _revertIfSoulbound(tokenId);
        _;
    }

    modifier checkLocked(uint tokenId) {
        _checkLocked(tokenId);
        _;
    }

    modifier checkSoulboundBatch(uint[] memory tokenIds) {
        uint howMany = tokenIds.length;
        for (uint i = 0; i < howMany; ) {
            _revertIfSoulbound(tokenIds[i]);
            unchecked {
                ++i;
            }
        }
        _;
    }

    function _checkLocked(uint tokenId) public view {
        if (_curios[tokenId].locked) {
            revert TokenLocked();
        }
    }

    // Utility function to revert whether a token is soulbound
    function _revertIfSoulbound(uint tokenId) private view {
        if (_curios[tokenId].soulbound) {
            if (!_soulboundExempt[_msgSender()]) {
                revert SoulboundNotTransferrable();
            }
        }
    }

    //  █████  ██████  ███    ███ ██ ███    ██
    // ██   ██ ██   ██ ████  ████ ██ ████   ██
    // ███████ ██   ██ ██ ████ ██ ██ ██ ██  ██
    // ██   ██ ██   ██ ██  ██  ██ ██ ██  ██ ██
    // ██   ██ ██████  ██      ██ ██ ██   ████

    function setSigner(address signer_) external payable onlyOwner {
        _setSigner(signer_);
    }

    function setPoppetsAddress(address poppets_) external payable onlyOwner {
        _setPoppetsAddress(poppets_);
    }

    function _setPoppetsAddress(address poppets) internal {
        POPPETS = poppets;
    }

    function setPacksAddress(address packs_) external payable onlyOwner {
        _setPacksAddress(packs_);
    }

    function _setPacksAddress(address packs_) internal {
        PACKS = packs_;
    }

    function setURI(string calldata uri_) external payable onlyOwner {
        _setURI(uri_);
        emit BatchMetadataUpdate(0, nextToken - 1);
    }

    function exemptAddressFromSoulbound(
        address wallet
    ) external payable onlyOwner {
        _exemptAddressFromSoulbound(wallet);
    }

    function _exemptAddressFromSoulbound(address wallet) internal {
        _soulboundExempt[wallet] = true;
    }

    function _setCurrentThread(uint16 thread_) external payable onlyOwner {
        currentThread = thread_;
    }

    // ██████   █████   ██████ ██   ██ ███████         ██     ██████   ██████  ██████  ██████  ███████ ████████ ███████
    // ██   ██ ██   ██ ██      ██  ██  ██             ██      ██   ██ ██    ██ ██   ██ ██   ██ ██         ██    ██
    // ██████  ███████ ██      █████   ███████       ██       ██████  ██    ██ ██████  ██████  █████      ██    ███████
    // ██      ██   ██ ██      ██  ██       ██      ██        ██      ██    ██ ██      ██      ██         ██         ██
    // ██      ██   ██  ██████ ██   ██ ███████     ██         ██       ██████  ██      ██      ███████    ██    ███████

    function mintFromPack(address to_, uint[] calldata ids) external {
        if (_msgSender() != PACKS) {
            revert InsufficientPermissions();
        }
        uint howMany = ids.length;

        for (uint i = 0; i < howMany; ) {
            _mint(to_, ids[i], 1, "");
            unchecked {
                ++i;
            }
        }
    }

    function mintFromPoppets(uint[] calldata ids) external {
        if (_msgSender() != POPPETS) {
            revert InsufficientPermissions();
        }
        uint howMany = ids.length;

        for (uint i = 0; i < howMany; ) {
            _mint(POPPETS, ids[i], 1, "");
            unchecked {
                ++i;
            }
        }
    }

    //  ██████ ██    ██ ██████  ██  ██████      ███    ███  ██████  ███    ███ ████████
    // ██      ██    ██ ██   ██ ██ ██    ██     ████  ████ ██       ████  ████    ██
    // ██      ██    ██ ██████  ██ ██    ██     ██ ████ ██ ██   ███ ██ ████ ██    ██
    // ██      ██    ██ ██   ██ ██ ██    ██     ██  ██  ██ ██    ██ ██  ██  ██    ██
    //  ██████  ██████  ██   ██ ██  ██████      ██      ██  ██████  ██      ██    ██

    function _createNewItem(Curio memory curio) internal {
        curio.thread = currentThread;
        curio.timestamp = uint40(block.timestamp);
        _curios[nextToken] = curio;

        emit NewItemCreated(nextToken, curio.slotId);

        unchecked {
            ++nextToken;
        }
    }

    // Setters for Curio metadata //

    function setSlotId(
        uint tokenId,
        uint8 val
    ) external payable checkLocked(tokenId) onlyOwner {
        _curios[tokenId].slotId = val;
    }

    function setMintPrice(
        uint tokenId,
        uint80 val
    ) external payable checkLocked(tokenId) onlyOwner {
        _curios[tokenId].mintPrice = val;
    }

    function setMaxSupply(
        uint tokenId,
        uint16 val
    ) external payable checkLocked(tokenId) onlyOwner {
        _curios[tokenId].maxSupply = val;
    }

    function setSlotCollision(
        uint tokenId,
        uint8 val
    ) external payable onlyOwner {
        _curios[tokenId].slotCollision = val;
    }

    function toggleSoulbound(
        uint tokenId
    ) external payable checkLocked(tokenId) onlyOwner {
        _curios[tokenId].soulbound = !_curios[tokenId].soulbound;
    }

    function toggleMintable(
        uint tokenId
    ) external payable checkLocked(tokenId) onlyOwner {
        _curios[tokenId].mintable = !_curios[tokenId].mintable;
    }

    function togglePublicMint(
        uint tokenId
    ) external payable checkLocked(tokenId) onlyOwner {
        _curios[tokenId].publicMint = !_curios[tokenId].publicMint;
    }

    function toggleSignedMint(
        uint tokenId
    ) external payable checkLocked(tokenId) onlyOwner {
        _curios[tokenId].signedMint = !_curios[tokenId].signedMint;
    }

    function setMinGeneration(
        uint tokenId,
        uint16 val
    ) external payable checkLocked(tokenId) onlyOwner {
        _curios[tokenId].minGeneration = val;
    }

    function setMaxGeneration(
        uint tokenId,
        uint16 val
    ) external payable onlyOwner {
        _curios[tokenId].maxGeneration = val;
    }

    function setThread(
        uint tokenId,
        uint16 val
    ) external payable checkLocked(tokenId) onlyOwner {
        _curios[tokenId].thread = val;
    }

    function lockItem(
        uint tokenId
    ) external payable onlyOwner {
        Curio storage curio = _curios[tokenId];
        curio.locked = true;
        curio.maxSupply = curio.totalSupply;

    }

    //  ██████  ███████ ████████ ████████ ███████ ██████  ███████
    // ██       ██         ██       ██    ██      ██   ██ ██
    // ██   ███ █████      ██       ██    █████   ██████  ███████
    // ██    ██ ██         ██       ██    ██      ██   ██      ██
    //  ██████  ███████    ██       ██    ███████ ██   ██ ███████

    function compatibilityData(
        uint tokenId
    )
        public
        view
        returns (
            uint slotId,
            uint slotCollision,
            uint minGeneration,
            uint maxGeneration
        )
    {
        Curio storage curio = _curios[tokenId];
        return (
            curio.slotId,
            curio.slotCollision,
            curio.minGeneration,
            curio.maxGeneration
        );
    }

    function fullData(uint tokenId) public view returns (Curio memory curio) {
        return _curios[tokenId];
    }

    //  ██████  ██    ██ ███████ ██████  ██████  ██ ██████  ███████ ███████
    // ██    ██ ██    ██ ██      ██   ██ ██   ██ ██ ██   ██ ██      ██
    // ██    ██ ██    ██ █████   ██████  ██████  ██ ██   ██ █████   ███████
    // ██    ██  ██  ██  ██      ██   ██ ██   ██ ██ ██   ██ ██           ██
    //  ██████    ████   ███████ ██   ██ ██   ██ ██ ██████  ███████ ███████
    //
    // Functions that override ERC-standards, primarily for the OS Operator Filter
    // and soulbound tokens

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * Overrides here include checks for individual token supply limits, tracking
     * totalSupply for each token,
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        if (from == address(0)) {
            // Minting - make sure totalSupply is less than maxSupply

            uint howMany = ids.length;
            for (uint i = 0; i < howMany; ) {
                Curio storage curio = _curios[ids[i]];

                // avoid integer overflow
                if (amounts[i] + curio.totalSupply > type(uint16).max) {
                    revert ExceedsMaxSupply();
                }

                // Do not exceed maxSupply (if set)
                if (curio.maxSupply > 0) {
                    if (curio.totalSupply + amounts[i] > curio.maxSupply) {
                        revert ExceedsMaxSupply();
                    }
                }

                curio.totalSupply += uint16(amounts[i]);
                unchecked {
                    ++i;
                }
            }
        } else if (to == address(0)) {
            // Burns - reduce totalSupply by the amount being burned
            uint howMany = ids.length;
            for (uint i = 0; i < howMany; ) {
                _curios[ids[i]].totalSupply -= uint16(amounts[i]);
            }
        }
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(
        address account,
        address operator
    ) public view virtual override(IERC1155, ERC1155) returns (bool) {
        return super.isApprovedForAll(account, operator) || operator == POPPETS;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(IERC1155, ERC1155) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    )
        public
        override(IERC1155, ERC1155)
        onlyAllowedOperator(from)
        checkSoulbound(tokenId)
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
    )
        public
        virtual
        override(IERC1155, ERC1155)
        onlyAllowedOperator(from)
        checkSoulboundBatch(ids)
    {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Returns the owner of the ERC1155 token contract.
     */
    function owner()
        public
        view
        virtual
        override(Ownable, UpdatableOperatorFilterer)
        returns (address)
    {
        return Ownable.owner();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC165, ERC1155, ERC2981) returns (bool) {
        return
            interfaceId == bytes4(0x49064906) || // ERC-4906
            ERC1155.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    // ███████ ██ ███    ██  █████  ███    ██  ██████ ███████ ███████
    // ██      ██ ████   ██ ██   ██ ████   ██ ██      ██      ██
    // █████   ██ ██ ██  ██ ███████ ██ ██  ██ ██      █████   ███████
    // ██      ██ ██  ██ ██ ██   ██ ██  ██ ██ ██      ██           ██
    // ██      ██ ██   ████ ██   ██ ██   ████  ██████ ███████ ███████

    function withdraw() public payable {
        (bool sent, bytes memory data) = payable(_receiver).call{
            value: address(this).balance
        }("");
        require(sent, "Failed to send Ether");
    }

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) public payable onlyOwner {
        _receiver = receiver;
        _setDefaultRoyalty(_receiver, feeNumerator);
    }
}