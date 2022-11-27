// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@azuki/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Ownable.sol";
import "operator-filter-registry/DefaultOperatorFilterer.sol";

contract BubbleGunGangClassic is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
    bool internal publicMintOpen = false;
    bool internal allowListMintOpen = false;

    uint internal constant totalPossible = 6550;
    uint internal constant mintPrice = 8000000000000000; // 0.008 ETH

    string internal URI = "ipfs://QmUAHj5NHpEFZuzCn3JvM49fGC9tW3XedReKwkPXxFDJgP/";
    string internal baseExt = ".json";

    IERC721A bggOG = IERC721A(0x711D12aAA8C151570ea7Ae84835EA90077bBd476);

    modifier onlyTenPerTx(uint amount) {
        require(amount <= 10, "Max 10 per tx");
        _;
    }

    constructor() ERC721A("Bubble Gun Gang Classic", "BGGC") {
        // Need to mint 550 tokens to the owners wallet
        _mint(owner(), 550);
    }

    function _startTokenId() override internal view virtual returns (uint256) {
        return 951;
    }

    function allowListMint(uint amount) payable external onlyTenPerTx(amount) nonReentrant {
        require(allowListMintOpen, "Public is not open yet.");
        require(bggOG.balanceOf(msg.sender) > 0, "Need a BBG OG to mint");
        require(msg.value >= (mintPrice * amount), "Mint costs 0.008 ETH");
        unchecked {
            require(totalSupply() + amount <= totalPossible, "SOLD OUT");
            _mint(msg.sender, amount);
        }
    }

    function publicMint(uint amount) payable external onlyTenPerTx(amount) nonReentrant {
        require(publicMintOpen, "Public is not open yet.");
        require(msg.value >= (mintPrice * amount), "Mint costs 0.008 ETH");
        unchecked {
            require(totalSupply() + amount <= totalPossible, "SOLD OUT");
            _mint(msg.sender, amount);
        }
    }

    function zCollectETH() external onlyOwner {
        (bool sent, ) = payable(owner()).call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    function zDev() external onlyDev {
        (bool sent, ) = payable(dev()).call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    function setURI(string calldata _URI) external onlyDev {
        URI = _URI;
    }

    function togglePublic() external onlyDev {
        publicMintOpen = !publicMintOpen;
    }

    function toggleAllowList() external onlyDev {
        allowListMintOpen = !allowListMintOpen;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(URI, _toString(tokenId), baseExt));
    }

    function setURIExtension(string calldata _baseExt) external onlyDev {
        baseExt = _baseExt;
    }

    function isPublicActive() external view returns (bool) {
        return publicMintOpen;
    }
    
    function isAllowListActive() external view returns (bool) {
        return allowListMintOpen;
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
 }