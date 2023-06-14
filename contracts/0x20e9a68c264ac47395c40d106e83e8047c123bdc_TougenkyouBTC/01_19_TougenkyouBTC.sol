// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import { IERC2981, ERC2981 } from "openzeppelin-contracts/contracts/token/common/ERC2981.sol";
import { ERC721ABridgeBRC, ERC721A } from "ERC721BridgeBRC/src/extensions/ERC721ABridgeBRC.sol";
import { AccessControl } from "openzeppelin-contracts/contracts/access/AccessControl.sol";

enum BTCTicketID {
    AllowList,
    FamilySale
}

error MaxSupplyOver();
error NotEnoughFunds();
error NotMintable();
error InvalidMerkleProof();
error AlreadyClaimedMax();
error MintAmountOver();

contract TougenkyouBTC is AccessControl, ERC2981, ERC721ABridgeBRC {
    uint256 private constant PUBLIC_MAX_PER_TX = 10;
    string private constant BASE_EXTENSION = ".json";
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    bool public publicSale = false;
    bool public callerIsUserFlg = false;
    bool public mintable = false;
    bool public operatorFilteringEnabled = true;
    bool public renounceOwnerMintFlag = false;

    uint256 public publicCost = 0.08 ether;
    string private _baseMetadataURI = "ar://KSXteJIOs5zVu5A5KiQ_bYiF0c68sedCKY7csYf4RXw/";

    mapping(BTCTicketID => bool) public presalePhase;
    mapping(BTCTicketID => uint256) public presaleCost;
    mapping(BTCTicketID => bytes32) public merkleRoot;
    mapping(uint256 => string) private _metadataURI;

    constructor(address _originalContract) ERC721ABridgeBRC("TougenkyouBTC", "momoBTC", _originalContract) {
        _setDefaultRoyalty(_msgSender(), 750);
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
        _setBaseURI(_baseMetadataURI);

        presaleCost[BTCTicketID.AllowList] = 0.08 ether;
        presaleCost[BTCTicketID.FamilySale] = 0.08 ether;
    }

    modifier whenMintable() {
        if (mintable == false) revert NotMintable();
        _;
    }

    /**
     * @dev The modifier allowing the function access only for real humans.
     */
    modifier callerIsUser() {
        if (callerIsUserFlg == true) {
            require(tx.origin == msg.sender, "The caller is another contract");
        }
        _;
    }

    function grantOperator(address account) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantOperator(account);
    }

    function revokeOperator(address account) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeOperator(account);
    }

    /**
     * @notice Set the merkle root for the allow list mint
     */
    function setMerkleRoot(bytes32 _merkleRoot, BTCTicketID ticket) external onlyRole(DEFAULT_ADMIN_ROLE) {
        merkleRoot[ticket] = _merkleRoot;
    }

    function setCallerIsUserFlg(bool flg) external onlyRole(DEFAULT_ADMIN_ROLE) {
        callerIsUserFlg = flg;
    }

    function publicMint(address _to, uint256 _mintAmount) external payable callerIsUser whenMintable {
        if (_totalMinted() + _mintAmount > registCount) revert MaxSupplyOver();
        if (msg.value < publicCost * _mintAmount) revert NotEnoughFunds();
        if (!publicSale) revert NotMintable();
        if (_mintAmount > PUBLIC_MAX_PER_TX) revert MintAmountOver();

        _mint(_to, _mintAmount);
    }

    function preMint(uint256 _mintAmount, uint256 _presaleMax, bytes32[] calldata _merkleProof, BTCTicketID ticket) external payable whenMintable {
        if (_totalMinted() + _mintAmount > registCount) revert MaxSupplyOver();
        if (msg.value == 0 || msg.value < presaleCost[ticket] * _mintAmount) revert NotEnoughFunds();
        if (!presalePhase[ticket]) revert NotMintable();
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _presaleMax));
        uint64 claimed = getWhiteListClaimed(ticket, msg.sender) + uint64(_mintAmount);
        if (!MerkleProof.verifyCalldata(_merkleProof, merkleRoot[ticket], leaf)) revert InvalidMerkleProof();
        if (claimed > _presaleMax) revert AlreadyClaimedMax();

        setWhiteListClaimed(ticket, msg.sender, claimed);
        _mint(msg.sender, _mintAmount);
    }

    function setWhiteListClaimed(BTCTicketID ticket, address account, uint64 claimed) internal {
        uint64 packedData = (claimed << 32) | uint64(ticket);
        _setAux(account, packedData);
    }

    function getWhiteListClaimed(BTCTicketID ticket, address account) public view returns (uint64) {
        uint64 packedData = _getAux(account);
        uint64 savedTicket = packedData & uint64((1 << 32) - 1);
        uint64 claimed = packedData >> 32;
        if (savedTicket != uint64(ticket)) {
            return 0;
        }
        return claimed;
    }

    function ownerMint(address _address, uint256 count) external onlyRole(MINTER_ROLE) {
        require(!renounceOwnerMintFlag, "owner mint renounced");
        _safeMint(_address, count);
    }

    function setPresalePhase(bool _state, BTCTicketID ticket) external onlyRole(DEFAULT_ADMIN_ROLE) {
        presalePhase[ticket] = _state;
    }

    function setPresaleCost(uint256 _cost, BTCTicketID ticket) external onlyRole(DEFAULT_ADMIN_ROLE) {
        presaleCost[ticket] = _cost;
    }

    function setPublicCost(uint256 _publicCost) external onlyRole(DEFAULT_ADMIN_ROLE) {
        publicCost = _publicCost;
    }

    function setPublicPhase(bool _state) external onlyRole(DEFAULT_ADMIN_ROLE) {
        publicSale = _state;
    }

    function setMintable(bool _state) external onlyRole(DEFAULT_ADMIN_ROLE) {
        mintable = _state;
    }

    function emergencyWithdraw(address _to, uint256 tokenId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _emergencyWithdraw(_to, tokenId);
    }

    function setTokenMetadataURI(uint256 tokenId, string memory metadata) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setTokenMetadataURI(tokenId, metadata);
    }

    function setBaseURI(string memory metadata) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _setBaseURI(metadata);
    }

    function withdraw(address _to) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 balance = address(this).balance;
        payable(_to).transfer(balance);
    }

    function renounceOwnerMint() external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        renounceOwnerMintFlag = true;
    }

    function updateMapping(uint256 tokenId, uint256 _originalTokenId) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _updateMapping(tokenId, _originalTokenId);
    }

    function changeRegistCount(uint256 _count) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        registCount = _count;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981, AccessControl) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }
}