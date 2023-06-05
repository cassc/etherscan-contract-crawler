// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "operator-filter-registry/src/UpdatableOperatorFilterer.sol";
import "operator-filter-registry/src/RevokableDefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Thr33zi3sPepe is ERC1155, ERC1155Burnable, ERC1155Supply, ERC2981, Ownable, RevokableDefaultOperatorFilterer, PaymentSplitter, ReentrancyGuard {
    using Strings for uint256;
    mapping(uint256 => uint256) private _totalSupply;
    uint256 public saleActiveToken = 0; //set to 0 to turn off sale, set to number to turn on sale for a tokenId
    string private baseURI = "https://api.thr33zi3s.com/Pepe/";
    address private pepe = 0x6982508145454Ce325dDbE47a25d4ec3d2311933; //production
    uint256 public price = 111333420 * 10 ** 18; // 120458682 PEPE approx 33 USDC
    uint256 public maxMint = 10;

    constructor(address[] memory payees, uint256[] memory shares)
        ERC1155("")
        PaymentSplitter(payees, shares) payable {
        }

    function updateBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }    

    function setSaleActiveToken(uint256 num) public onlyOwner {
        saleActiveToken = num;
    }

    function updatePrice(uint256 amt) public onlyOwner {
        price = amt;
    }

    function updateMaxMint(uint256 num) public onlyOwner {
        maxMint = num;
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        _totalSupply[id] += amount;
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < ids.length; ++i) {
            _totalSupply[ids[i]] += amounts[i];
        }
        _mintBatch(to, ids, amounts, data);
    }

    function _burn(address account, uint256 id, uint256 amount) internal virtual override {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        super._burn(account, id, amount);
        _totalSupply[id] -= amount;
    }

    function purchasePepe(uint256 num) public nonReentrant {
        require(saleActiveToken > 0,                    "Sale Not Active");
        require(num <= maxMint,                         "Max Mint per transaction exceeded");
        uint256 amount = price * num;
        require(IERC20(pepe).transferFrom(msg.sender, owner(), amount), "$PEPE transfer failed");
        _totalSupply[saleActiveToken] += amount;
        _mint(msg.sender, saleActiveToken, num, "");
    }

    function uri(uint256 typeId) public view override returns (string memory)
    {
        require(typeId >= 0, "URI requested for invalid token type");
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, typeId.toString())) : "";
    }    

    // ERC2981

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public virtual onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() public virtual onlyOwner {
        _deleteDefaultRoyalty();
    }

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) public virtual onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function resetTokenRoyalty(uint256 tokenId) public virtual onlyOwner {
        _resetTokenRoyalty(tokenId);
    }

    // Operator Filter Overrides

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
     * @dev Returns the owner of the ERC1155 token contract.
     */
    function owner() public view virtual override(Ownable, UpdatableOperatorFilterer) returns (address) {
        return Ownable.owner();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}