//SPDX-License-Identifier: Unlicense
// Creator: owenyuwono.eth
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';
import 'operator-filter-registry/src/DefaultOperatorFilterer.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

contract HammerPunch is
    ERC1155,
    ERC1155Supply,
    ERC2981,
    Ownable,
    ReentrancyGuard,
    DefaultOperatorFilterer
{
    uint constant BOX_ID = 0;
    uint constant TOTEM_ID = 5;
    uint constant AKU_ID = 6;
    uint constant MAX_BOX_SUPPLY = 2023;
    uint constant MAX_PER_TX = 20;

    // Contract
    string public name = 'HammerPunch - Genesis';
    string public symbol = 'HMP';
    string public tokenURI;

    // Limits
    uint public price = 0.0069 ether;
    mapping(uint256 => bool) isOpen;
    mapping(address => uint) public claimed;
    mapping(address => bool) public totemClaimed;
    mapping(address => bool) public akuClaimed;

    constructor(string memory tokenUri) ERC1155(tokenUri) {
        tokenURI = tokenUri;
        _setDefaultRoyalty(msg.sender, 690);
    }

    error MaxRarity();
    error InsufficientBoxes();
    error InvalidTokenId();
    error InsufficientFunds();
    error InsufficientArtifacts();
    error InvalidAmount();
    error ExceedMaxSupply();
    error NotOpenYet();
    error ExceedMaxPerTx();
    error AlreadyClaimed();

    modifier isArtifact(uint256 id) {
        if (id > 4 || id < 1) revert InvalidTokenId();
        _;
    }

    function mint(uint amount) external payable {
        if (!isOpen[0]) revert NotOpenYet();
        if (amount < 1) revert InvalidAmount();
        if (amount > MAX_PER_TX) revert ExceedMaxPerTx();
        if (totalSupply(BOX_ID) + amount > MAX_BOX_SUPPLY)
            revert ExceedMaxSupply();
        uint free = claimed[msg.sender] == 0 ? 1 : 0;
        if (claimed[msg.sender] == 0 && msg.value != (amount - free) * price)
            revert InsufficientFunds();
        claimed[msg.sender] += amount;
        _mint(msg.sender, BOX_ID, amount, '');
    }

    function open(
        uint256 artifactId,
        uint amount
    ) external isArtifact(artifactId) {
        if (!isOpen[artifactId]) revert NotOpenYet();
        if (balanceOf(msg.sender, BOX_ID) < amount) revert InsufficientBoxes();
        _burn(msg.sender, BOX_ID, amount * 10);
        _mint(msg.sender, artifactId, amount, '');
    }

    function claimAku() external {
        if (!isOpen[AKU_ID]) revert NotOpenYet();
        if (
            balanceOf(msg.sender, 1) > 1 &&
            balanceOf(msg.sender, 2) > 2 &&
            balanceOf(msg.sender, 3) > 3 &&
            balanceOf(msg.sender, 4) > 4
        ) revert InsufficientArtifacts();
        if (akuClaimed[msg.sender]) revert AlreadyClaimed();
        akuClaimed[msg.sender] = true;
        _mint(msg.sender, AKU_ID, 1, '');
    }

    function claimTotem() external {
        if (!isOpen[TOTEM_ID]) revert NotOpenYet();
        if (
            balanceOf(msg.sender, 1) > 1 &&
            balanceOf(msg.sender, 2) > 2 &&
            balanceOf(msg.sender, 3) > 3 &&
            balanceOf(msg.sender, 4) > 4
        ) revert InsufficientArtifacts();
        if (totemClaimed[msg.sender]) revert AlreadyClaimed();
        totemClaimed[msg.sender] = true;
        _mint(msg.sender, TOTEM_ID, 1, '');
    }

    function burn(address owner, uint256 id, uint amount) external {
        _burn(owner, id, amount);
    }

    // Admin
    function airdrop(
        address wallet,
        uint256[] calldata id,
        uint256[] calldata amount
    ) external onlyOwner {
        _mintBatch(wallet, id, amount, '');
    }

    function setTokenUri(string calldata v) external onlyOwner {
        tokenURI = v;
    }

    function setOpen(uint _p, bool v) external onlyOwner {
        isOpen[_p] = v;
    }

    function setDefaultRoyalty(
        address _receiver,
        uint96 _fraction
    ) public onlyOwner {
        _setDefaultRoyalty(_receiver, _fraction);
    }

    function setTokenRoyalty(
        uint256 _tokenId,
        address _receiver,
        uint96 _fraction
    ) public onlyOwner {
        _setTokenRoyalty(_tokenId, _receiver, _fraction);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // Essentials
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Supply) {
        ERC1155Supply._beforeTokenTransfer(
            operator,
            from,
            to,
            ids,
            amounts,
            data
        );
    }

    function uri(
        uint256 id
    ) public view virtual override returns (string memory) {
        if (bytes(tokenURI).length == 0) return '';

        return
            string(
                abi.encodePacked(tokenURI, '/', Strings.toString(id), '.json')
            );
    }

    function totalSupply() public view returns (uint) {
        return
            totalSupply(BOX_ID) +
            totalSupply(1) +
            totalSupply(2) +
            totalSupply(3) +
            totalSupply(4) +
            totalSupply(TOTEM_ID) +
            totalSupply(AKU_ID);
    }

    // Claim
    function withdrawToken(address _erc20) external nonReentrant onlyOwner {
        IERC20 token = IERC20(_erc20);

        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function withdrawEther() external payable nonReentrant onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }('');
        require(success, 'ETH_TRANSFER_FAILED');
    }

    // Enforcement
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}