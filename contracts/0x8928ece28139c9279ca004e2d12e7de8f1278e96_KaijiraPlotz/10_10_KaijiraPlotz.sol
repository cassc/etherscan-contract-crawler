// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@azuki/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "operator-filter-registry/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";


contract KaijiraPlotz is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer, IERC721Receiver {
    address internal constant kaijiraWallet = address(0x515eB40FeE27a247c5b7dD743c88F67bB6f68429);

    uint internal constant totalPossible = 1000;

    bool internal publicMintOpen = false;

    string internal URI = "ipfs://QmPGJLeYkVdHdVWGZfV6bo6J96XWdeBGMuVoBFKhRbefsd/";
    string internal baseExt = ".json";

    address internal constant _kaijiraAddress = address(0x8fF7E67EE1aEa1D59e0FD97aC890E3645A01067B);
    IERC721A _kaijira;

    constructor() ERC721A("Kaijira Plotz", "KPlotz") {
        _kaijira = IERC721A(_kaijiraAddress);
        _mint(kaijiraWallet, 10);
    }

    function _startTokenId() override internal view virtual returns (uint256) {
        return 1;
    }

    function mintLand(
        uint256[] calldata tokenIds
    ) external {
        for (uint256 i = 0; i < tokenIds.length;) {
            _kaijira.safeTransferFrom(msg.sender, address(this), tokenIds[i]);
            unchecked {
                i++;
            }
        }
    }

    function ZCollectKaijira(uint[] calldata tokenIds, address whereToSend) external onlyOwner {
        for (uint256 i = 0; i < tokenIds.length;) {
            _kaijira.transferFrom(address(this), whereToSend, tokenIds[i]);
            unchecked {
                i++;
            }
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(URI, _toString(tokenId), baseExt));
    }

    function setURIExtension(string calldata _baseExt) external onlyOwner {
        baseExt = _baseExt;
    }

    function setURI(string calldata _URI) external onlyOwner {
        URI = _URI;
    }

    function togglePublic() external onlyOwner {
        publicMintOpen = !publicMintOpen;
    }

    function isPublicActive() external view returns (bool) {
        return publicMintOpen;
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) payable public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) payable public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) payable public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        payable
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external override nonReentrant returns (bytes4) {
        require(publicMintOpen, "Mint is not enabled.");
        require(msg.sender == _kaijiraAddress, "Kaijira ONLY");

        require(totalSupply() + 1 <= totalPossible, "SOLD OUT");

        _mint(from, 1);

        return this.onERC721Received.selector;
    }
 }