// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

contract NEOFINNFT is
    Pausable,
    ERC1155,
    AccessControl,
    ERC1155Supply,
    ERC1155Burnable
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bool public transferPaused;
    uint256 currentId;

    mapping(uint256 => uint256) public supplyLeft;
    mapping(uint256 => bool) public mintAllowed;

    constructor() ERC1155("NEOFINNFT") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(BURNER_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    modifier whenNotTransferPaused() {
        require(!transferPaused, "transfer paused");
        _;
    }

    modifier whenTransferPaused() {
        require(transferPaused, "transfer unpaused");
        _;
    }

    modifier whenMintAllowed(uint256[] memory _ids) {
        for (uint256 i; i < _ids.length; i++) {
            require(mintAllowed[_ids[i]], "mint of one nft is not allowed");
        }
        _;
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function pauseTransfer()
        public
        whenNotTransferPaused
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        transferPaused = true;
    }

    function unpauseTransfer()
        public
        whenTransferPaused
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        transferPaused = false;
    }

    function setURI(string memory newuri) public onlyRole(ADMIN_ROLE) {
        _setURI(newuri);
    }

    function allowSelling(uint256 _id) public onlyRole(ADMIN_ROLE) {
        require(!mintAllowed[_id], "sell already allowed");
        mintAllowed[_id] = true;
    }

    function disableSelling(uint256 _id) public onlyRole(ADMIN_ROLE) {
        require(mintAllowed[_id], "sell already disabled");
        mintAllowed[_id] = false;
    }

    function addNFT(
        uint256 _supply,
        bool _allowSell
    ) public onlyRole(ADMIN_ROLE) {
        currentId += 1;
        supplyLeft[currentId] = _supply;
        _setSellStatus(currentId, _allowSell);
    }

    function updateSupplyLeft(uint256 _id, uint256 _supply)
        public
        onlyRole(ADMIN_ROLE)
    {
        require(currentId >= _id, "id doesn't exist");
        require(supplyLeft[_id] != _supply, "supply already up to date");
        supplyLeft[_id] = _supply;
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyRole(MINTER_ROLE) whenMintAllowed(_asSingletonArr(id)) {
        _mint(account, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyRole(MINTER_ROLE) whenMintAllowed(ids) {
        _mintBatch(to, ids, amounts, data);
    }

    function burn(
        address _account,
        uint256 _id,
        uint256 _value
    ) public override onlyRole(BURNER_ROLE) {
        super.burn(_account, _id, _value);
    }

    function burnBatch(
        address _account,
        uint256[] memory _ids,
        uint256[] memory _values
    ) public override onlyRole(BURNER_ROLE) {
        super.burnBatch(_account, _ids, _values);
    }

    function _asSingletonArr(uint256 element)
        private
        pure
        returns (uint256[] memory)
    {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override whenNotTransferPaused {
        return super.safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override whenNotTransferPaused {
        return super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function _setSellStatus(uint256 _id, bool _newStatus) private {
        mintAllowed[_id] = _newStatus;
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) whenNotPaused {
        if (to != address(0)) {
            for (uint256 i; i < ids.length; i++) {
                require(supplyLeft[ids[i]] >= amounts[i], "not enough NFT");
                supplyLeft[ids[i]] -= amounts[i];
            }
        }
        ERC1155Supply._beforeTokenTransfer(
            operator,
            from,
            to,
            ids,
            amounts,
            data
        );
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}