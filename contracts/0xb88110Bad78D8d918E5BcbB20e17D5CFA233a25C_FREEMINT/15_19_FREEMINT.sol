// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

// METAKAWAII MUSIC
contract FREEMINT is ERC1155, ERC2981, Ownable, DefaultOperatorFilterer {
    mapping(uint256 => string) private _tokenURI;                             // tokenID => uri
    mapping(uint256 => uint256) public totalSupply;                           // tokenID => totalSuooly
    mapping(uint256 => uint256) public quantityLimit;                         // tokenID => quantityLimit
    mapping(uint256 => mapping(address => uint256)) public minted;            // tokenId => walletAddress => minted
    mapping(uint256 => uint256) public mintLimit;                             // tokenID => mintLimit
    mapping(uint256 => bool) public saleStart;                                // tokenID => saleStart

    constructor() ERC1155("") {
        _setDefaultRoyalty(0xa9b8AA4B566ed81D737131Aa9B9175c67Ee1ebCD, 1000);

        // firstTokenSetting
        quantityLimit[0] = 3000;
        mintLimit[0] = 1;
        _tokenURI[0] = 'https://duun5sybelitqsprm6i7bneoob6dyoi2ba57zavxqlrv4kc66bhq.arweave.net/HSjeywEi0ThJ8WeR8LSOcHw8ORoIO_yCt4LjXihe8E8';
    }

    // tokenUri setting
    function uri(uint256 _tokenId) public view override returns (string memory) {
        return _tokenURI[_tokenId];
    }
    function setURI(uint256 _tokenId, string memory _uri) public onlyOwner {
        _tokenURI[_tokenId] = _uri;
    }

    // saleStart setting
    function setSaleStart(uint256 _tokenId, bool _state) public onlyOwner {
        saleStart[_tokenId] = _state;
    }

    // limit setting
    function setQuantityLimit(uint256 _tokenId, uint256 _size) public onlyOwner {
        require(totalSupply[_tokenId] >= _size, "under totalSupply");
        quantityLimit[_tokenId] = _size;
    }

    function setMintLimit(uint256 _tokenId, uint256 _size) public onlyOwner {
        mintLimit[_tokenId] = _size;
    }

    // mint funcs
    function mint(uint256 _tokenId, uint256 _amount) public {
        require(saleStart[_tokenId], "before saleStart");
        require(
            mintLimit[_tokenId] >= minted[_tokenId][msg.sender] + _amount,
            "mintLimit over"
        );
        require(
            quantityLimit[_tokenId] >= totalSupply[_tokenId] + _amount,
            "quantityLimit over"
        );

        _mint(msg.sender, _tokenId, _amount, "");
        totalSupply[_tokenId] += _amount;
        minted[_tokenId][msg.sender] += _amount;
    }

    function ownerMint(uint256 _tokenId, uint256 _amount) public onlyOwner {
        require(
            quantityLimit[_tokenId] >= totalSupply[_tokenId] + _amount,
            "quantityLimit over"
        );

        _mint(msg.sender, _tokenId, _amount, "");
        totalSupply[_tokenId] += _amount;
    }


    // OpenSea OperatorFilterer
    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    // Royality setting
    function setRoyalty(address _royaltyAddress, uint96 _feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(_royaltyAddress, _feeNumerator);
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC2981)
        returns (bool)
    {
        return
            ERC1155.supportsInterface(_interfaceId) ||
            ERC2981.supportsInterface(_interfaceId);
    }
}