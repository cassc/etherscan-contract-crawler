pragma solidity 0.6.6;

import {Initializable} from "../shared/Initializable.sol";
import {ERC1155Upgradeable} from "../shared/ERC1155Upgradeable.sol";
import {ERC1155BurnableUpgradeable} from "../shared/ERC1155BurnableUpgradeable.sol";
import {ERC1155SupplyUpgradeable} from "../shared/ERC1155SupplyUpgradeable.sol";
import {ERC1155PausableUpgradeable} from "../shared/ERC1155PausableUpgradeable.sol";
import {IMintableERC1155} from "./shared/IMintableERC1155.sol";
import {AccessControlMixinUpgradeable} from "../shared/AccessControlMixinUpgradeable.sol";
import {NativeMetaTransactionUpgradeable} from "../shared/NativeMetaTransactionUpgradeable.sol";
import {ContextMixinUpgradeable} from "../shared/ContextMixinUpgradeable.sol";


contract MetaPassRootUpgradeable is Initializable, ERC1155SupplyUpgradeable, ERC1155BurnableUpgradeable, ERC1155PausableUpgradeable, AccessControlMixinUpgradeable, NativeMetaTransactionUpgradeable, ContextMixinUpgradeable, IMintableERC1155 {

    bytes32 public constant PREDICATE_ROLE = keccak256("PREDICATE_ROLE");

    string private _name;
    string private _symbol;

    address _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function __MetaPassRoot_init(
        string memory name_,
        string memory symbol_,
        string memory uri_
    ) public initializer {
        __ERC1155_init(uri_);
        __ERC1155Pausable_init();
        _name = name_;
        _symbol = symbol_;
        _setupContractId("MetaPassRootUpgradeable");
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PREDICATE_ROLE, _msgSender());
        _initializeEIP712(uri_);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external override only(PREDICATE_ROLE) {
        _mint(account, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external override only(PREDICATE_ROLE) {
        _mintBatch(to, ids, amounts, data);
    }

    function setUri(string calldata newUri) external only(DEFAULT_ADMIN_ROLE) {
        _setURI(newUri);
    }

    function pause() public only(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public only(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public only(DEFAULT_ADMIN_ROLE) {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155SupplyUpgradeable, ERC1155PausableUpgradeable, ERC1155Upgradeable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function _msgSender() internal override view returns (address payable sender) {
        return ContextMixinUpgradeable.msgSender();
    }
}