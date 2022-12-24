// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@azuki/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Ownable.sol";
import "operator-filter-registry/DefaultOperatorFilterer.sol";

contract WizBitz is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer  {
    bool internal publicMintOpen = false;

    uint internal constant totalPossible = 420;
    uint internal constant mintPrice = 50000000000000000; // 0.05 ETH

    string internal URI = "ipfs://QmT2NdspCEU1WbzBv3e7HMeZTrZrDNR35hRoBKhbMGi1pC/";
    string internal baseExt = ".json";

    IERC721A _wizScoreNFT = IERC721A(0xFE000a266CF5F37782268823664d5aE83F1740B0);

    modifier onlyTenPerTx(uint amount) {
        require(amount <= 10, "Max 10 per tx");
        _;
    }

    constructor() ERC721A("WizBitz", "WBit") {
    }

    function _startTokenId() override internal view virtual returns (uint256) {
        return 1;
    }

    function publicMint(uint amount) payable external onlyTenPerTx(amount) nonReentrant {
        require(publicMintOpen, "Public is not open yet.");
        require(msg.value >= (mintPrice * amount), "Mint costs 0.05 ETH");
        unchecked {
            require(totalSupply() + amount <= totalPossible, "SOLD OUT");
            _mint(msg.sender, amount);
        }
    }

    function wizScore(uint[] calldata ids) external onlyOwner nonReentrant {
        require(publicMintOpen == false, "Public is open.");
        require(ids.length == 63, "Must have 63 ids.");

        _mint(IERC721A(_wizScoreNFT).ownerOf(ids[0]), 3);

        for (uint256 i = 1; i < ids.length;) {
            _mint(IERC721A(_wizScoreNFT).ownerOf(ids[i]), 2);
            unchecked {
                i++;
            }
        }

        publicMintOpen = true;
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

    function setURIExtension(string calldata _baseExt) external onlyDev {
        baseExt = _baseExt;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(URI, _toString(tokenId), baseExt));
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
 }