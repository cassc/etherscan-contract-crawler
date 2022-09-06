pragma solidity 0.6.6;

import {Initializable} from "../shared/Initializable.sol";
import {ERC721Upgradeable} from "../shared/ERC721Upgradeable.sol";
import {ERC721BurnableUpgradeable} from "../shared/ERC721BurnableUpgradeable.sol";
import {ERC721PausableUpgradeable} from "../shared/ERC721PausableUpgradeable.sol";
import {IMintableERC721} from "./shared/IMintableERC721.sol";
import {AccessControlMixinUpgradeable} from "../shared/AccessControlMixinUpgradeable.sol";
import {NativeMetaTransactionUpgradeable} from "../shared/NativeMetaTransactionUpgradeable.sol";
import {ContextMixinUpgradeable} from "../shared/ContextMixinUpgradeable.sol";
import {StringsUpgradeable} from "../shared/library/StringsUpgradeable.sol";


contract TokenGeneratorRootUpgradeable is Initializable, ERC721Upgradeable, ERC721BurnableUpgradeable, ERC721PausableUpgradeable, AccessControlMixinUpgradeable, NativeMetaTransactionUpgradeable, IMintableERC721, ContextMixinUpgradeable {

    bytes32 public constant PREDICATE_ROLE = keccak256("PREDICATE_ROLE");

    address _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function __TokenGeneratorRoot_init(
        string memory name_,
        string memory symbol_
    ) public initializer {
        __ERC721_init(name_, symbol_);
        __ERC721Pausable_init();
        _setupContractId("TokenGeneratorRootUpgradeable");
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PREDICATE_ROLE, _msgSender());
        _initializeEIP712(name_);
    }

    function mint(address user, uint256 tokenId) external override only(PREDICATE_ROLE) {
        _mint(user, tokenId);
    }

    function setTokenMetadata(uint256 tokenId, bytes memory data) internal virtual {

        string memory uri = abi.decode(data, (string));

        _setTokenURI(tokenId, uri);
    }

    function mint(address user, uint256 tokenId, bytes calldata metaData) external override only(PREDICATE_ROLE) {
        _mint(user, tokenId);

        setTokenMetadata(tokenId, metaData);
    }

    function burnBatch(uint256[] memory tokenIds_) public virtual {

        for (uint256 i; i < tokenIds_.length; i++) {
            burn(tokenIds_[i]);
        }
    }

    function exists(uint256 tokenId) external view override returns (bool) {
        return _exists(tokenId);
    }

    function tokensOfOwner(address owner) public view returns (uint256[] memory){
        uint256 amount = ERC721Upgradeable.balanceOf(owner);
        uint256[] memory tokens = new uint[](amount);
        for (uint256 index = 0; index < amount; index++) {
            tokens[index] = tokenOfOwnerByIndex(owner, index);
        }
        return tokens;
    }

    function tokenURI(uint256 tokenId_) public view virtual override returns (string memory) {
        require(_exists(tokenId_), "Not found");
        string memory currentBaseURI = baseURI();
        return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, StringsUpgradeable.toString(tokenId_), ".json")) : "";
    }

    function setBaseURI(string memory newBaseURI_) public only(DEFAULT_ADMIN_ROLE) {
        _setBaseURI(newBaseURI_);
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

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721PausableUpgradeable, ERC721Upgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _msgSender() internal override view returns (address payable sender) {
        return ContextMixinUpgradeable.msgSender();
    }
}