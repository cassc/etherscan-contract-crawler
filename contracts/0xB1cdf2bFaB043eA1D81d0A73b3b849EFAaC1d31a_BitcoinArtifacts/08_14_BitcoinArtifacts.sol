// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "closedsea/src/OperatorFilterer.sol";

contract BitcoinArtifacts is
    ERC721AQueryable,
    OperatorFilterer,
    Ownable,
    ERC2981
{
    event TokenOrdinalRedeemed(address indexed by, uint256 tokenId, string btc);
    error IncorrectAmountError();
    error IncorrectWalletError();
    error BurnIsNotEnabled();

    uint256 public constant SUPPLY = 101;

    string public baseURI;

    bool public burnEnabled;
    bool public taprootCheckEnabled;
    bool public operatorFilteringEnabled;

    constructor(
        string memory uri,
        address payable royaltiesReceiver)
        ERC721A("Bitcoin Artifacts", "BTCA")
    {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;

        baseURI = uri;
        burnEnabled = false;
        taprootCheckEnabled = true;

        _mint(msg.sender, SUPPLY);
        _setDefaultRoyalty(royaltiesReceiver, 1000);
    }

    // #######################################################################################
    // #                                                                                     #
    // #                                      Modifiers                                      #
    // #                                                                                     #
    // #######################################################################################

    modifier ensureBtcTaprootFormat(string calldata btc) {
        if(taprootCheckEnabled) {
            bytes memory _btc = bytes(btc);
            bool isTaproot = _btc.length == 62 && uint8(_btc[0]) == 98 && uint8(_btc[1]) == 99 && uint8(_btc[2]) == 49 && uint8(_btc[3]) == 112;
            if(!isTaproot) revert IncorrectWalletError();
        }
        _;
    }

    modifier ensureBurnEnabled() {
        if(!burnEnabled) revert BurnIsNotEnabled();
        _;
    }

    // #######################################################################################
    // #                                                                                     #
    // #                                     Unwrapping                                      #
    // #                                                                                     #
    // #######################################################################################

    function totalBurnt() external view returns(uint256) {
        return _totalBurned();
    }

    function burntBy(address owner) external view returns(uint256) {
        return _numberBurned(owner);
    }

    function burn(uint256 tokenId, string calldata btc) external ensureBtcTaprootFormat(btc) ensureBurnEnabled {
        _burn(tokenId, true);
        emit TokenOrdinalRedeemed(msg.sender, tokenId, btc);
    }

    // #######################################################################################
    // #                                                                                     #
    // #                                      Accessors                                      #
    // #                                                                                     #
    // #######################################################################################

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function setBurnEnabled(bool _burnEnabled) public onlyOwner {
        burnEnabled = _burnEnabled;
    }

    function setTaprootCheckEnabled(bool _taprootCheckEnabled) public onlyOwner {
        taprootCheckEnabled = _taprootCheckEnabled;
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function setDefaultRoyalty(address payable receiver, uint96 numerator)
        public
        onlyOwner
    {
        _setDefaultRoyalty(receiver, numerator);
    }

    // #######################################################################################
    // #                                                                                     #
    // #                                  OperatorFilterer                                   #
    // #                                                                                     #
    // #######################################################################################

    function setApprovalForAll(address operator, bool approved)
        public
        override (IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override (IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override (IERC721A, ERC721A)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override (IERC721A, ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override (IERC721A, ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }

    // #######################################################################################
    // #                                                                                     #
    // #                                       ERC721A                                       #
    // #                                                                                     #
    // #######################################################################################

    function _startTokenId() internal view virtual override returns (uint256) {
        return 0;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // #######################################################################################
    // #                                                                                     #
    // #                                       ERC165                                        #
    // #                                                                                     #
    // #######################################################################################

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC721A, ERC721A, ERC2981)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }
}