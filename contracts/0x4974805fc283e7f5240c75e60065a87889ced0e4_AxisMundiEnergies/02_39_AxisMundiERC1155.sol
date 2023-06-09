// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@interplanetary-lab/smart-contracts/contracts/ERC1155Upgradeable/ERC1155RoundsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";


/// @title Axis Mundi - ERC1155
/// @author [email protected]
/// @custom:project-website  https://www.axismundi.art/
/// @custom:security-contact [email protected]
abstract contract AxisMundiERC1155 is ERC1155Upgradeable, AccessControlUpgradeable, PausableUpgradeable, ERC1155BurnableUpgradeable, ERC1155RoundsUpgradeable, UUPSUpgradeable {

    using SafeMathUpgradeable for uint256;

    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    mapping(uint256 => uint256) internal _amountBurnt;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function __AxisMundiERC1155_init(string memory uri) initializer public {
        __ERC1155Rounds_init();
        __Pausable_init();
        __AccessControl_init();
        __ERC1155Burnable_init();
        __ERC1155Rounds_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(URI_SETTER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        _setURI(uri);
    }

    function setURI(string memory newuri) virtual public onlyRole(URI_SETTER_ROLE) {
        _setURI(newuri);
    }

    function pause() virtual public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() virtual public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function privateMint(
        address to,
        uint256 roundId,
        uint256 amount,
        uint256 maxMint,
        uint256 payloadExpiration,
        bytes memory sig
    ) public payable virtual whenNotPaused {
        _privateRoundMint(to, roundId, amount, maxMint, payloadExpiration, sig);
    }

    function publicMint(
        address to,
        uint256 roundId,
        uint256 amount
    ) public payable virtual whenNotPaused {
        _publicRoundMint(to, roundId, amount);
    }

    function setupRound(
        uint256 roundId,
        uint256 tokenId,
        uint32 supply,
        uint64 startTime,
        uint64 duration,
        address validator,
        uint256 price
    ) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _setupRound(
            roundId,
            tokenId,
            supply,
            startTime,
            duration,
            validator,
            price
        );
    }


    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function burn(address account, uint256 id, uint256 value) public virtual override {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );

        _burn(account, id, value);
        _amountBurnt[id] = _amountBurnt[id] + value;
    }

    function burnBatch(address account, uint256[] memory ids, uint256[] memory values) public virtual override {

    }

    function totalSupply(uint256 tokenId) public view virtual override returns (uint256) {
        return super.totalSupply(tokenId) - _amountBurnt[tokenId];
    }
}