// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "operator-filter-registry/src/UpdatableOperatorFilterer.sol";
import "operator-filter-registry/src/RevokableDefaultOperatorFilterer.sol";
import "./IReceiptArt.sol";

contract Receipt is ERC721, ERC2981, ReentrancyGuard, RevokableDefaultOperatorFilterer, Ownable {
    uint256 private _tokenSupply;
    uint256 private _mintGas = 177012;
    mapping(uint256 => IReceiptArt.TxContext) private _txData;
    mapping(uint256 => IReceiptArt.TransferContext[]) private _transferData;
    mapping(uint256 => uint256) public priceToTokenId;
    bool public isActive = true;
    string private _description;
    string private _baseExternalURI;
    IReceiptArt private art;

    event Mint(uint256 _tokenId, uint256 _value, uint256 _gas, uint256 _time, address _from);

    constructor(address _artAddress) ERC721("Receipt", "RECEIPT") {
        art = IReceiptArt(_artAddress);
        _setDefaultRoyalty(owner(), 1000);
    }

    function mint() external payable nonReentrant {
        require(isActive, "INACTIVE");
        require(priceToTokenId[msg.value] == 0, "Already minted");
        require(msg.value % 0.0001 ether == 0, "Invalid value");
        _tokenSupply++;
        uint256 gas = _mintGas * tx.gasprice;
        _txData[_tokenSupply] = IReceiptArt.TxContext(
            msg.value,
            gas,
            block.timestamp,
            _msgSender()
        );
        priceToTokenId[msg.value] = _tokenSupply;
        _safeMint(_msgSender(), _tokenSupply);
        emit Mint(_tokenSupply, msg.value, gas, block.timestamp, _msgSender());
    }

    function getReceipt(uint256 _price)
        external
        view
        returns (
            uint256 tokenId,
            string memory svg,
            uint256 price
        )
    {
        tokenId = priceToTokenId[_price];
        IReceiptArt.TxContext memory txContext;
        txContext.value = _price;
        svg = art.tokenSVG(txContext, new IReceiptArt.TransferContext[](0), 0);
        price = _price;
    }

    /* token utility */

    function setIsActive(bool _isActive) external onlyOwner {
        isActive = _isActive;
    }

    function setDescription(string memory desc) external onlyOwner {
        _description = desc;
    }

    function setBaseExternalURI(string memory URI) external onlyOwner {
        _baseExternalURI = URI;
    }

    function setMintGas(uint256 _gas) external onlyOwner {
        _mintGas = _gas;
    }

    /* nft utility */

    function getMetaData(uint256 _tokenId) private view returns (string memory) {
        IReceiptArt.TxContext memory txContext = _txData[_tokenId];
        string memory value = art.weiToEtherStr(txContext.value);

        return
            string(
                abi.encodePacked(
                    '{"name":"Receipt ',
                    value,
                    ' ETH","description":"',
                    _description,
                    '","image":"data:image/svg+xml;utf8,',
                    art.tokenSVG(txContext, _transferData[_tokenId], _tokenId),
                    '","external_url":"',
                    _baseExternalURI,
                    Strings.toString(_tokenId),
                    '","background_color":"C3C3C3","attributes":[{"trait_type":"Value","value":',
                    value,
                    '},{"trait_type":"Transfers","value":',
                    Strings.toString(_transferData[_tokenId].length),
                    '},{"trait_type":"Lines","value":',
                    Strings.toString(art.linesCount(txContext.value)),
                    "}]}"
                )
            );
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId));
        return string(abi.encodePacked("data:application/json;utf8,", getMetaData(_tokenId)));
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);
        if (from != address(0)) {
            (string memory day, string memory time) = art.timestampToString(block.timestamp);
            _transferData[tokenId].push(
                IReceiptArt.TransferContext(string(abi.encodePacked(day, " ", time)), to)
            );
        }
    }

    function totalSupply() external view returns (uint256) {
        return _tokenSupply;
    }

    function withdrawBalance() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success);
    }

    function setRoyaltyInfo(address receiver_, uint96 royaltyBps_) external onlyOwner {
        _setDefaultRoyalty(receiver_, royaltyBps_);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981, ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /* OperatorFilter */

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
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

    function owner()
        public
        view
        virtual
        override(Ownable, UpdatableOperatorFilterer)
        returns (address)
    {
        return Ownable.owner();
    }
}