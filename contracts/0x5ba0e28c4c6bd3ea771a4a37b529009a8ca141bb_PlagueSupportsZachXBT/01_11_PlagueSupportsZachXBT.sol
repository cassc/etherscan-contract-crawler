// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IERC2981, ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {ERC1155} from "solady/src/tokens/ERC1155.sol";
import {OperatorFilterer} from "./common/OperatorFilterer.sol";

/**
 * @title PlagueSupportsZachXBT
 * @custom:website www.plaguebrands.io/zachxbt
 * @author @ThePlagueNFT
 * @notice READ MORE - https://twitter.com/zachxbt/status/1669783717236342785
 *         1% of funds go to the artist, 99% goes to zachxbt directly.
 *         100% of royalties will also go to zachxbt
 * @dev Shoutout to vectorized.eth / @optimizoor / https://twitter.com/optimizoor
 *
 * \____    /____    ____ |  |__ \   \/  /\______   \__    ___/
 *   /     /\__  \ _/ ___\|  |  \ \     /  |    |  _/ |    |
 *  /     /_ / __ \\  \___|   Y  \/     \  |    |   \ |    |
 * /_______ (____  /\___  >___|  /___/\  \ |______  / |____|
 *         \/    \/     \/     \/      \_/        \/
 *
 */
contract PlagueSupportsZachXBT is ERC1155, OperatorFilterer, Ownable, ERC2981 {
    using Strings for uint256;

    uint256 private constant ONE_PERCENT = 10000000000000000;
    address private constant FALLBACK_DEPLOYER =
        0xeA9B1Ed511632e48dDD3E5A231cd2f5F3A3a4a9b;

    address public artistAddress;
    address public zachXBTAddress;
    bool public operatorFilteringEnabled;
    uint256 public price;
    bool public isMintOpen;
    string public baseURI = "";

    constructor() ERC1155() {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        _setDefaultRoyalty(msg.sender, 500);
        price = 0.005 ether;
        isMintOpen = false;
    }

    /**
     * @dev Open edition mint, specify amount and payable ether
     * @param _amount The amount to mint
     */
    function mint(uint256 _amount) external payable {
        require(isMintOpen, "Mint is not active.");
        require(msg.value >= _amount * price, "Not enough funds.");
        _mint(msg.sender, 1, _amount, "");
    }

    function uri(uint256 id) public view override returns (string memory) {
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, id.toString(), ".json"))
                : "";
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155, ERC2981) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC1155: 0xd9b67a26
        // - IERC1155MetadataURI: 0x0e89341c
        // - IERC2981: 0x2a55205a
        return
            ERC1155.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(
        address operator
    ) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }

    /**
     * @notice Sets the mint open
     * @param _isMintOpen state of mint openness
     */
    function setMintIsOpen(bool _isMintOpen) public onlyOwner {
        isMintOpen = _isMintOpen;
    }

    /**
     * @notice Sets the price
     * @param _price price in wei
     */
    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    /**
     * @notice Sets base uri
     * @param _baseURI The uri of asset
     */
    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    /**
     * @notice Sets the withdraw wallets
     * @param artist - Artist address
     * @param zachxbt - ZachXBTs address
     */
    function setWithdrawWallets(
        address artist,
        address zachxbt
    ) public onlyOwner {
        artistAddress = artist;
        zachXBTAddress = zachxbt;
    }

    /// @notice Withdraw funds from contract to artist and zachxbt directly
    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        (bool s1, ) = payable(artistAddress).call{value: amount * ONE_PERCENT}(
            ""
        );
        (bool s2, ) = payable(zachXBTAddress).call{
            value: amount * (ONE_PERCENT * 99)
        }("");
        if (s1 && s2) return;
        // fallback
        (bool s3, ) = payable(FALLBACK_DEPLOYER).call{value: amount}("");
        require(s3, "Payment failed");
    }
}