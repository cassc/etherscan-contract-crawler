// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable//utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract WagmiTraits is Initializable, ERC1155Upgradeable, ERC2981Upgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable, PausableUpgradeable, ERC1155BurnableUpgradeable, ERC1155SupplyUpgradeable, DefaultOperatorFiltererUpgradeable {
    string public name = "WAGMI Traits";
    string public symbol = "WAT";
    address private signer;
    address private sales;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        signer = msg.sender;
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC1155_init("https://wagmiarmy.io/api/metadata/traits?id={id}");
        __ERC2981_init();
        __DefaultOperatorFilterer_init();
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __ERC1155Burnable_init();
        __ERC1155Supply_init();
    }

    struct Transfer {
        address holder;
        uint256 traitId;
        uint256 amount;
    }

    struct Trait {
        uint256 traitId;
        uint256 amount;
    }

    event BuyTrait (
        address indexed buyer,
        Transfer[] transfers
    );

    event ClaimTrait (
        address indexed receiver,
        Trait[] traits
    );

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function setSales(address _sales) external onlyOwner {
        sales = _sales;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function teamMint(uint256 _traitId, address receiver, uint256 amount)
    external
    onlyOwner
    {
        _mint(receiver, _traitId, amount, "");
    }

    function claim(bytes calldata signature, Trait[] memory _traits)
    external
    nonReentrant
    {
        require(_isVerifiedSignature(signature), "Invalid Signature");

        uint256[] memory ids;
        uint256[] memory amounts;
        
        for (uint256 i = 0; i < _traits.length; ++i) { 
            ids[i] = _traits[i].traitId;
            amounts[i] = _traits[i].amount;
        }

        _mintBatch(msg.sender, ids, amounts, "");
        emit ClaimTrait(msg.sender, _traits);
    }

    function buyTraits(Transfer[] memory _transfers)
    external
    onlySales
    {
        uint256[] memory ids;
        uint256[] memory amounts;
        for (uint256 i = 0; i < _transfers.length; ++i) { 
            ids[i] = _transfers[i].traitId;
            amounts[i] = _transfers[i].amount;
        }

        _mintBatch(msg.sender, ids, amounts, "");
        emit BuyTrait(msg.sender, _transfers);
    }

    function sendAirdrop(Transfer[] memory _transfers)
    external
    onlyOwner
    {
        for (uint256 i = 0; i < _transfers.length; ++i) { 
            _mint(_transfers[i].holder, _transfers[i].traitId, _transfers[i].amount, "");
        }
    }

    function _isVerifiedSignature(bytes calldata signature)
    internal
    view
    returns (bool)
    {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                bytes32(uint256(uint160(msg.sender)))
            )
        );
        return ECDSAUpgradeable.recover(digest, signature) == signer;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
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
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155Upgradeable, ERC2981Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155Upgradeable, ERC1155SupplyUpgradeable)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    modifier onlySales() {
        require(msg.sender == sales, "Invalid Access");
        _;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}