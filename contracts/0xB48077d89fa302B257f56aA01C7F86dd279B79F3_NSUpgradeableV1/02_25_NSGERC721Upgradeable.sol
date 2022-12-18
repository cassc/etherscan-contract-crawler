// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;
import "./GERC721Upgradeable.sol";
import "./INSGERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";

abstract contract NSGERC721Upgradable is
    Initializable,
    GERC721Upgradeable,
    OwnableUpgradeable,
    AccessControlUpgradeable,
    INSGERC721Upgradeable,
    DefaultOperatorFiltererUpgradeable
{
    bool public mintsLocked;
    address private altarContract;
    bytes32 public constant NIGHTSHADE_ADMIN = keccak256("NIGHTSHADE_ADMIN");

    function __NSERC721_init(
        address roleAdmin_,
        string memory name_,
        string memory symbol_,
        uint256 maxSupply_
    ) internal onlyInitializing {
        __NSERC721_init_unchained(roleAdmin_, name_, symbol_, maxSupply_);
    }

    function __NSERC721_init_unchained(
        address roleAdmin_,
        string memory name_,
        string memory symbol_,
        uint256 maxSupply_
    ) internal onlyInitializing {
        __ERC721_init(name_, symbol_, maxSupply_);
        __Ownable_init();
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, roleAdmin_);
        _setupRole(NIGHTSHADE_ADMIN, roleAdmin_);
        __DefaultOperatorFilterer_init();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(GERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setAltar(address altarContract_) public onlyRole(NIGHTSHADE_ADMIN) {
        altarContract = altarContract_;
    }

    function altarTransfer(address to_, uint256 id) external {
        require(msg.sender == altarContract, "NAC");
        _altarGhostMint(to_, id);
    }

    function altarEmitMint(address to_, uint256[] calldata ids) external {
        require(msg.sender == altarContract, "NAC");
        uint256 idsLength = ids.length;
        uint256 i = 0;
        for (; i < idsLength; ) {
            emit Transfer(address(0), to_, ids[i]);
            unchecked {
                i++;
            }
        }
    }

    function mintMore(
        address to_,
        uint256 start,
        uint256 end
    ) public onlyRole(NIGHTSHADE_ADMIN) {
        require(mintsLocked == false, "ML");
        for (uint256 i = start; i <= end; i++) {
            _mint(to_, i);
        }
    }

    function preGhostMintCollection(
        address to_,
        uint256 start,
        uint256 end
    ) external onlyRole(NIGHTSHADE_ADMIN) {
        require(mintsLocked == false, "ML");
        _preGhostMintCollection(to_, start, end);
    }

    function lockMints() external onlyOwner {
        mintsLocked = true;
    }

    function walletOfOwner(address address_) public view returns (uint256[] memory) {
        uint256 _balance = balanceOf(address_); // get balance of address
        uint256[] memory _tokenIds = new uint256[](_balance); // initialize array
        uint256 i = 0;
        while (_balance > 0) {
            if (ownerOf(i) == address_) {
                _tokenIds[--_balance] = i;
            }
            i++;
        }
        return _tokenIds;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "meta.etch.sh/api/meta/ns/";
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @dev Reserved for future NS features
     */
    uint256[50] private __gap;
}