//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract OBOUSHISHOTEN is
    ERC721,
    ERC2981,
    Ownable,
    ReentrancyGuard,
    DefaultOperatorFilterer
{
    using Strings for uint256;
    uint256 private _tokenIdCounter;

    bool private useLambda = true;
    bool public orderStart;
    string private _baseTokenURI = 'https://hw5mm5htqp64tvi4x64r3xk6dq0jaycn.lambda-url.ap-northeast-1.on.aws/';
    mapping(uint256 => string) public tokenImageURI;
    mapping(address => bool) private _mintableContract;

    constructor() ERC721("OBOUSHISHOTEN", "OS") {
        _setDefaultRoyalty(owner(), 1000);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 _tokenId)
        override
        public
        view
        virtual
        returns (string memory)
    {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();
        if (bytes(baseURI).length > 0) {
            return useLambda ?
                string(abi.encodePacked(baseURI, '?tokenId=', _tokenId.toString(), '&imageUri=', tokenImageURI[_tokenId])) :
                string(abi.encodePacked(baseURI, _tokenId.toString(), '.json'));
        } else {
            return '';
        }
    }

    function mint(string calldata _uri, address _to) external nonReentrant {
        require(_mintableContract[msg.sender], 'Not allowed.');

        _safeMint(_to, _tokenIdCounter);
        tokenImageURI[_tokenIdCounter] = _uri;
        _tokenIdCounter++;
    }

    function getOrderStart() external view returns(bool) {
        return orderStart;
    }

    // only owner
    function ownerMint(string calldata _uri, address _to) public onlyOwner {
        _safeMint(_to, _tokenIdCounter);
        tokenImageURI[_tokenIdCounter] = _uri;
        _tokenIdCounter++;
    }

    function setMintableContract(address _contractAddress, bool _state) external onlyOwner {
        _mintableContract[_contractAddress] = _state;
    }

    function setTokenImageURI(uint256 _tokenId, string calldata _uri) external onlyOwner {
        tokenImageURI[_tokenId] = _uri;
    }

    function setBaseURI(string calldata _uri) external onlyOwner {
        _baseTokenURI = _uri;
    }

    function setUseLambda(bool _state) external onlyOwner {
        useLambda = _state;
    }

    function setOrderStart(bool _state) external onlyOwner {
        orderStart = _state;
    }

    // OperatorFilterer
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

    // Royality
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
        override(ERC721, ERC2981)
        returns (bool)
    {
        return
            ERC721.supportsInterface(_interfaceId) ||
            ERC2981.supportsInterface(_interfaceId);
    }
}