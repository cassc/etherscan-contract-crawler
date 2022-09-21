//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165StorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import "./interface/IMojoMilestone.sol";
import "./interface/IMojoMilestoneStaking.sol";


contract MojoMilestone is IMojoMilestone, ERC1155Upgradeable, AccessControlUpgradeable, ERC165StorageUpgradeable, IERC2981Upgradeable {

    bytes32 public constant MINT_ROLE = keccak256("MINT");
    bytes32 public constant URI_ROLE = keccak256("URI");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    address public royaltyAddress;
    uint256 public royaltyPercentage;
    IMojoMilestoneStaking public mojoMilestoneStaking;


    function initialize(string memory uri_, address royaltyAddress_, uint256 royaltyPercentage_, address stakingAddress) external initializer {

        require(royaltyPercentage_ <= 10000, "royaltyPercentage_ must be lte 10000.");

        __ERC1155_init(uri_);
        __ERC165Storage_init();
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINT_ROLE, _msgSender());
        _setupRole(URI_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, _msgSender());

        royaltyAddress = royaltyAddress_;
        royaltyPercentage = royaltyPercentage_;

        _registerInterface(type(IERC2981Upgradeable).interfaceId);
        _registerInterface(type(IERC1155Upgradeable).interfaceId);
        _registerInterface(type(IAccessControlUpgradeable).interfaceId);
        mojoMilestoneStaking = IMojoMilestoneStaking(stakingAddress);

    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC165StorageUpgradeable, ERC1155Upgradeable, AccessControlUpgradeable) returns (bool) {
        return ERC165StorageUpgradeable.supportsInterface(interfaceId);
    }

    function stake(
        uint256 id,
        uint256 amount
    ) public override {
        _burn(_msgSender(), id, amount);
        mojoMilestoneStaking.stake(_msgSender(), id, amount);
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount
    ) public override onlyRole(MINT_ROLE) {
        _mint(account, id, amount, "");
    }

    function mintAndBurn(
        address account,
        uint256 id,
        uint256 amount
    ) public override onlyRole(MINT_ROLE) {
        emit TransferSingle(_msgSender(), address(0), account, id, amount);
        emit TransferSingle(_msgSender(), account, address(0), id, amount);
    }

    function mintBatch(
        address[] memory tos,
        uint256[] memory ids,
        uint256 amount
    ) public override onlyRole(MINT_ROLE) {
        require(tos.length == ids.length, "address list and id list must be equal");
        for (uint i = 0; i > tos.length; i++) {
            _mint(tos[i], ids[i], amount, "");
        }
    }

    function mintMultiple(
        address[] calldata to,
        uint256 id,
        uint256 amount
    ) public override onlyRole(MINT_ROLE) {
        for (uint i = 0; i < to.length; i++) {
            _mint(to[i], id, amount, "");
        }
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address royaltyReceiver, uint256 royaltyAmount) {
        royaltyReceiver = royaltyAddress;
        royaltyAmount = salePrice * royaltyPercentage / 10000;
    }

    function setURIDefault(string memory uri) external onlyRole(URI_ROLE) {
        _setURI(uri);
    }

    function uri(uint256 tokenId) public view virtual override(ERC1155Upgradeable) returns (string memory) {
        return string(abi.encodePacked(super.uri(tokenId), StringsUpgradeable.toString(tokenId)));
    }

    function setRoyaltyInfo(address royaltyAddress_, uint256 royaltyPercentage_) external onlyRole(ADMIN_ROLE) {
        require(royaltyPercentage_ <= 10000, "royaltyPercentage must be lt 10000");
        royaltyAddress = royaltyAddress_;
        royaltyPercentage = royaltyPercentage_;
    }

    function updateMojoMilestoneStaking(address _mojoMilestoneStaking)external onlyRole(ADMIN_ROLE) {
        mojoMilestoneStaking = IMojoMilestoneStaking(_mojoMilestoneStaking);

    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override (ERC1155Upgradeable, IERC1155Upgradeable) {
        revert FunctionNotSupported();
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override (ERC1155Upgradeable, IERC1155Upgradeable) {
        revert FunctionNotSupported();
    }

    function setApprovalForAll(
        address,
        bool
    ) public pure override (ERC1155Upgradeable, IERC1155Upgradeable) {
        revert FunctionNotSupported();
    }
}