pragma solidity ^0.8.0;

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./DefaultOperatorFilterer.sol";

import "./ERC1155CollectionBase.sol";
import "hardhat/console.sol";

//  ▄▄▄       ██▓     ██▓        ██▓▄▄▄█████▓   ▄▄▄█████▓ ▄▄▄       ██ ▄█▀▓█████   ██████
// ▒████▄    ▓██▒    ▓██▒       ▓██▒▓  ██▒ ▓▒   ▓  ██▒ ▓▒▒████▄     ██▄█▒ ▓█   ▀ ▒██    ▒
// ▒██  ▀█▄  ▒██░    ▒██░       ▒██▒▒ ▓██░ ▒░   ▒ ▓██░ ▒░▒██  ▀█▄  ▓███▄░ ▒███   ░ ▓██▄
// ░██▄▄▄▄██ ▒██░    ▒██░       ░██░░ ▓██▓ ░    ░ ▓██▓ ░ ░██▄▄▄▄██ ▓██ █▄ ▒▓█  ▄   ▒   ██▒
//  ▓█   ▓██▒░██████▒░██████▒   ░██░  ▒██▒ ░      ▒██▒ ░  ▓█   ▓██▒▒██▒ █▄░▒████▒▒██████▒▒
//  ▒▒   ▓▒█░░ ▒░▓  ░░ ▒░▓  ░   ░▓    ▒ ░░        ▒ ░░    ▒▒   ▓▒█░▒ ▒▒ ▓▒░░ ▒░ ░▒ ▒▓▒ ▒ ░
//   ▒   ▒▒ ░░ ░ ▒  ░░ ░ ▒  ░    ▒ ░    ░           ░      ▒   ▒▒ ░░ ░▒ ▒░ ░ ░  ░░ ░▒  ░ ░
//   ░   ▒     ░ ░     ░ ░       ▒ ░  ░           ░        ░   ▒   ░ ░░ ░    ░   ░  ░  ░
//       ░  ░    ░  ░    ░  ░    ░                             ░  ░░  ░      ░  ░      ░

//  ██▓  ██████     ▒█████   ███▄    █ ▓█████    ▄▄▄█████▓ ██▀███   ▄▄▄      ▓█████▄ ▓█████
// ▓██▒▒██    ▒    ▒██▒  ██▒ ██ ▀█   █ ▓█   ▀    ▓  ██▒ ▓▒▓██ ▒ ██▒▒████▄    ▒██▀ ██▌▓█   ▀
// ▒██▒░ ▓██▄      ▒██░  ██▒▓██  ▀█ ██▒▒███      ▒ ▓██░ ▒░▓██ ░▄█ ▒▒██  ▀█▄  ░██   █▌▒███
// ░██░  ▒   ██▒   ▒██   ██░▓██▒  ▐▌██▒▒▓█  ▄    ░ ▓██▓ ░ ▒██▀▀█▄  ░██▄▄▄▄██ ░▓█▄   ▌▒▓█  ▄
// ░██░▒██████▒▒   ░ ████▓▒░▒██░   ▓██░░▒████▒     ▒██▒ ░ ░██▓ ▒██▒ ▓█   ▓██▒░▒████▓ ░▒████▒
// ░▓  ▒ ▒▓▒ ▒ ░   ░ ▒░▒░▒░ ░ ▒░   ▒ ▒ ░░ ▒░ ░     ▒ ░░   ░ ▒▓ ░▒▓░ ▒▒   ▓▒█░ ▒▒▓  ▒ ░░ ▒░ ░
//  ▒ ░░ ░▒  ░ ░     ░ ▒ ▒░ ░ ░░   ░ ▒░ ░ ░  ░       ░      ░▒ ░ ▒░  ▒   ▒▒ ░ ░ ▒  ▒  ░ ░  ░
//  ▒ ░░  ░  ░     ░ ░ ░ ▒     ░   ░ ░    ░        ░        ░░   ░   ░   ▒    ░ ░  ░    ░
//  ░        ░         ░ ░           ░    ░  ░               ░           ░  ░   ░       ░  ░
//                                                                            ░

contract OzV2 is ERC1155, ERC1155CollectionBase, DefaultOperatorFilterer {
    address public OZ_V1_ADDRESS;
    mapping(address => bool) freezeList;
    string public name = "OzDAO";
    string public symbol = "OZ";

    constructor(address signingAddress_, address _ozV1Address) ERC1155("") {
        _initialize(
            // total supply
            500,
            // total supply available to purchase
            500,
            0,
            // purchase limit (0 for no limit)
            0,
            // transaction limit (0 for no limit)
            0,
            0,
            // presale limit (unused but 0 for no limit)
            0,
            signingAddress_,
            // use dynamic presale purchase limit
            true
        );
        OZ_V1_ADDRESS = _ozV1Address;
        _setURI("https://ozdao.art/");
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC1155CollectionBase)
        returns (bool)
    {
        return
            ERC1155CollectionBase.supportsInterface(interfaceId) ||
            ERC1155.supportsInterface(interfaceId) ||
            AdminControl.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155Collection-balanceOf}.
     */
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return ERC1155.balanceOf(owner, TOKEN_ID);
    }

    /**
     * @dev See {IERC1155Collection-balanceOf}.
     */
    function balanceOf(address owner, uint256 _tokenId)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return ERC1155.balanceOf(owner, _tokenId);
    }

    /**
     * @dev See {IERC1155Collection-withdraw}.
     */
    function withdraw(address payable recipient, uint256 amount)
        external
        override
        adminRequired
    {
        _withdraw(recipient, amount);
    }

    function exchange(uint16 tokenId) external {
        ERC1155(OZ_V1_ADDRESS).safeTransferFrom(
            msg.sender,
            address(0x000000000000000000000000000000000000dEaD),
            tokenId,
            1,
            ""
        );
        _mint(msg.sender, tokenId, 1, "");
    }

    function uri(uint256 _id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(TOKEN_ID >= _id, "Token ID does not exist");
        return string(abi.encodePacked(baseMetadataURI, Strings.toString(_id)));
    }

    /**
     * @dev See {IERC1155Collection-activate}.
     */
    function activate() external override adminRequired {
        _activate();
    }

    /**
     * @dev See {IERC1155Collection-deactivate}.
     */
    function deactivate() external override adminRequired {
        _deactivate();
    }

    /**
     *  @dev See {IERC1155Collection-setCollectionURI}.
     */
    function setCollectionURI(string calldata uri)
        external
        override
        adminRequired
    {
        _setURI(uri);
    }

    /**
     * @dev See {ERC1155CollectionBase-_mint}.
     */
    function _mintERC1155(address to, uint16 amount) internal virtual override {
        ERC1155._mint(to, TOKEN_ID, amount, "");
    }

    function setFreezeList(address _address, bool _freeze)
        external
        adminRequired
    {
        freezeList[_address] = _freeze;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        require(
            !freezeList[from],
            "Transfers of the pass are frozen for this address"
        );
    }

    /**
     * @dev Update royalties
     */
    function updateRoyalties(address payable recipient, uint256 bps)
        external
        adminRequired
    {
        _updateRoyalties(recipient, bps);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}