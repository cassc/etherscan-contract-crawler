// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "../util/ERC721ALockable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ThreeEarsBunny is AccessControl, ERC721ALockable, DefaultOperatorFilterer, ERC2981, Ownable {
    uint256 public constant MAX_TOTAL_SUPPLY = 10000;
    address public constant PROJECT_MANAGER = 0x36ee5acbeED8627437D94856AFA069c281F1979f;
    bytes32 public constant MAINTAIN_ROLE = keccak256("MAINTAIN_ROLE");

    uint256 public publicPrice = 0.075 ether;
    uint256 public guaranteeWhiteListPrice = 0.07 ether;
    uint256 public nonGuaranteeWhiteListPrice = 0.075 ether;
    uint256 constant public MAX_GUARANTEE_COUNT = 4;
    uint256 constant public MAX_NONE_GUARANTEE_COUNT = 2;
    uint256 constant public MAX_PUBLIC_COUNT = 2;
    string public baseImageUri = "https://mysterybox.3eb.io/";

    address private constant SIGNER = 0x0Ac584A240fbae9e6403c569A7cE29fC5C4d8912;
    mapping(address => bool) private guaranteeMinted;
    mapping(address => bool) private nonGuaranteeMinted;
    mapping(address => bool) private publicMinted;

    using Strings for uint256;
    using ECDSA for bytes32;

    enum Phase {
        Waiting,
        GuaranteeWhiteList,
        NonGuaranteeWhiteList,
        Public,
        Close
    }

    uint256 public guaranteeWhiteListStartTime;
    uint256 public guaranteeWhiteListEndTime;
    uint256 public nonGuaranteeWhiteListStartTime;
    uint256 public nonGuaranteeWhiteListEndTime;
    uint256 public publicTime;

    constructor() ERC721ALockable("ThreeEarsBunny", "TEB"){
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, PROJECT_MANAGER);

        _grantRole(MAINTAIN_ROLE, msg.sender);
        _grantRole(MAINTAIN_ROLE, PROJECT_MANAGER);
    }

    function mintForPublic(uint256 quantity) external payable {
        require(msg.sender == tx.origin, "TEB: Prohibit contract calls");
        require(getCurrentPhase() == Phase.Public, "TEB: Phase mismatch");
        require(quantity <= MAX_PUBLIC_COUNT, "TEB: Quantity exceed limit");
        require(publicPrice * quantity <= msg.value, "TEB: Ether value sent is not correct");
        require(!publicMinted[msg.sender], "TEB: Only mint once");
        require(_totalMinted() + quantity <= MAX_TOTAL_SUPPLY, "TEB: Mint would exceed max total supply");

        _safeMint(msg.sender, quantity, "");
        publicMinted[msg.sender] = true;
    }

    function mintForGuaranteeWhiteList(uint256 quantity, uint256 maxCount, uint256 nonce, bytes memory sign) payable external {
        require(maxCount <= MAX_GUARANTEE_COUNT, "TEB: Max count exceed limit");
        mintForWhiteList(quantity, guaranteeWhiteListPrice, maxCount, nonce, sign, guaranteeMinted, Phase.GuaranteeWhiteList);
    }

    function mintForNonGuaranteeWhiteList(uint256 quantity, uint256 maxCount, uint256 nonce, bytes memory sign) payable external {
        require(maxCount <= MAX_NONE_GUARANTEE_COUNT, "TEB: Max count exceed limit");
        mintForWhiteList(quantity, nonGuaranteeWhiteListPrice, maxCount, nonce, sign, nonGuaranteeMinted, Phase.NonGuaranteeWhiteList);
    }

    function mintForWhiteList(
        uint256 quantity,
        uint256 price,
        uint256 maxCount,
        uint256 nonce,
        bytes memory sign,
        mapping(address => bool) storage mintedToken,
        Phase phase) private {

        require(msg.sender == tx.origin, "TEB: Prohibit contract calls");
        require(quantity <= maxCount, "TEB: Quantity exceed limit");
        require(getCurrentPhase() == phase, "TEB: Phase mismatch");
        require(price * quantity <= msg.value, "TEB: Ether value sent is not correct");
        require(!mintedToken[msg.sender], "TEB: Only mint once");
        require(_totalMinted() + quantity <= MAX_TOTAL_SUPPLY, "TEB: Mint would exceed max total supply");

        bytes32 digest = keccak256(abi.encodePacked(msg.sender, maxCount, nonce, phase));
        require(digest.recover(sign) == SIGNER, "TEB: Sign error");

        _safeMint(msg.sender, quantity, "");
        mintedToken[msg.sender] = true;
    }

    function mintForAdmin(uint256 quantity) external onlyRole(MAINTAIN_ROLE) {
        require(Address.isContract(msg.sender) == false, "TEB: Prohibit contract calls");
        require(_totalMinted() + quantity <= MAX_TOTAL_SUPPLY, "TEB: Mint would exceed max total supply");

        _safeMint(msg.sender, quantity, "");
    }

    function hasMinted() external view returns (bool, bool) {
        return (guaranteeMinted[msg.sender], nonGuaranteeMinted[msg.sender]);
    }

    function setConfig(
        uint256 guaranteeWhiteListPrice_,
        uint256 nonGuaranteeWhiteListPrice_,
        uint256 publicPrice_,
        uint256 guaranteeWhiteListStartTime_,
        uint256 guaranteeWhiteListEndTime_,
        uint256 nonGuaranteeWhiteListStartTime_,
        uint256 nonGuaranteeWhiteListEndTime_,
        uint256 publicTime_) external onlyRole(MAINTAIN_ROLE) {
        guaranteeWhiteListPrice = guaranteeWhiteListPrice_;
        nonGuaranteeWhiteListPrice = nonGuaranteeWhiteListPrice_;
        publicPrice = publicPrice_;
        guaranteeWhiteListStartTime = guaranteeWhiteListStartTime_;
        guaranteeWhiteListEndTime = guaranteeWhiteListEndTime_;
        nonGuaranteeWhiteListStartTime = nonGuaranteeWhiteListStartTime_;
        nonGuaranteeWhiteListEndTime = nonGuaranteeWhiteListEndTime_;
        publicTime = publicTime_;
    }

    function getConfig() external view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256){
        return (
        guaranteeWhiteListPrice,
        nonGuaranteeWhiteListPrice,
        publicPrice,
        guaranteeWhiteListStartTime,
        guaranteeWhiteListEndTime,
        nonGuaranteeWhiteListStartTime,
        nonGuaranteeWhiteListEndTime,
        publicTime);
    }

    function getCurrentPhase() public view returns (Phase){
        if (block.timestamp < guaranteeWhiteListStartTime - 60) {
            return Phase.Waiting;
        } else if (block.timestamp < guaranteeWhiteListEndTime) {
            return Phase.GuaranteeWhiteList;
        } else if (block.timestamp < nonGuaranteeWhiteListStartTime - 60) {
            return Phase.Waiting;
        } else if (block.timestamp < nonGuaranteeWhiteListEndTime) {
            return Phase.NonGuaranteeWhiteList;
        }
        return Phase.Public;
    }

    function updateContractApprovalStatus(address contractAddress, bool status) external onlyRole(MAINTAIN_ROLE) {
        super._updateContractApprovalStatus(contractAddress, status);
    }

    function setBaseImageUri(string memory newuri) external onlyRole(MAINTAIN_ROLE) {
        baseImageUri = newuri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseImageUri;
    }

    function withdraw() external onlyRole(MAINTAIN_ROLE) {
        uint256 balance = address(this).balance;
        (bool sent,) = msg.sender.call{value : balance}("");
        require(sent, "TEB: Withdraw failed");
    }

    function totalMintedCount() external view returns (uint256){
        return _totalMinted();
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721A, IERC721A, AccessControl, ERC2981)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _startTokenId()
    internal
    view
    override
    returns (uint256) {
        return 1;
    }


    ////////////////////////////////
    // Operator Filter Registry
    ////////////////////////////////

    function setApprovalForAll(address operator, bool approved)
    public
    override(ERC721A, IERC721A)
    onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
    public
    override(ERC721A, IERC721A)
    onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
    public
    override(ERC721A, IERC721A)
    onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
    public
    override(ERC721A, IERC721A)
    onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    override(ERC721A, IERC721A)
    onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    ////////////////
    // royalty
    ////////////////
    /**
     * @dev See {ERC2981-_setDefaultRoyalty}.
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyRole(MAINTAIN_ROLE) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @dev See {ERC2981-_deleteDefaultRoyalty}.
     */
    function deleteDefaultRoyalty() external onlyRole(MAINTAIN_ROLE) {
        _deleteDefaultRoyalty();
    }

    /**
     * @dev See {ERC2981-_setTokenRoyalty}.
     */
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyRole(MAINTAIN_ROLE) {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /**
     * @dev See {ERC2981-_resetTokenRoyalty}.
     */
    function resetTokenRoyalty(uint256 tokenId) external onlyRole(MAINTAIN_ROLE) {
        _resetTokenRoyalty(tokenId);
    }
}