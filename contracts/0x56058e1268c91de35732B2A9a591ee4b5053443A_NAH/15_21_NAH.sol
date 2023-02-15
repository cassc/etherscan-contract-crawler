// SPDX-License-Identifier: MIT
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////                                                                                                                                                                       
//   _____    _____           ____            ___________            _____         ____________           _____                _____        ______  ______              _____    //
//  |\    \   \    \      ____\_  \__        /           \         /      |_       \           \         |\    \             /      |_      \     \|\     \        _____\    \   //
//   \\    \   |    |    /     /     \      /    _   _    \       /         \       \           \         \\    \           /         \      |     |\|     |      /    / \    |  //
//    \\    \  |    |   /     /\      |    /    //   \\    \     |     /\    \       |    /\     |         \\    \         |     /\    \     |     |/____ /      |    |  /___/|  //
//     \|    \ |    |  |     |  |     |   /    //     \\    \    |    |  |    \      |   |  |    |          \|    | ______ |    |  |    \    |     |\     \   ____\    \ |   ||  //
//      |     \|    |  |     |  |     |  /     \\_____//     \   |     \/      \     |    \/     |           |    |/      \|     \/      \   |     | |     | /    /\    \|___|/  //
//     /     /\      \ |     | /     /| /       \ ___ /       \  |\      /\     \   /           /|           /            ||\      /\     \  |     | |     ||    |/ \    \       //
//    /_____/ /______/||\     \_____/ |/________/|   |\________\ | \_____\ \_____\ /___________/ |          /_____/\_____/|| \_____\ \_____\/_____/|/_____/||\____\ /____/|      //
//   |      | |     | || \_____\   | /|        | |   | |        || |     | |     ||           | /          |      | |    ||| |     | |     ||    |||     | || |   ||    | |      //
//   |______|/|_____|/  \ |    |___|/ |________|/     \|________| \|_____|\|_____||___________|/           |______|/|____|/ \|_____|\|_____||____|/|_____|/  \|___||____|/       //
//                       \|____|                                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "erc721a/contracts/ERC721A.sol"; 
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract NAH is 
    DefaultOperatorFilterer,
    ERC721A,
    ERC2981,
    Ownable,
    ReentrancyGuard 

{
    using Strings for uint256;
    bool public isRevealed = false;
    uint256 public maxSupply = 150;
    string internal baseTokenUri;
    string public hiddenMetadataUri;
    address payable public withdrawWallet;
    error MaxSupplyExceeded();

    constructor() ERC721A("NAH Genesis Pass", "NAH") {}

    function setBaseTokenUri(string calldata _baseTokenUri) external onlyOwner {
        baseTokenUri = _baseTokenUri;
    }

    function setRevealed(bool _state) public onlyOwner {
    isRevealed = _state;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function mint(uint256 _quantity) public onlyOwner nonReentrant {
        uint256 totalMinted = totalSupply();
        require(totalMinted + _quantity <= maxSupply, "sold out");

        _safeMint(msg.sender, _quantity);
    }

    function mintBatch(
        address[] calldata _accounts,
        uint256[] calldata _amounts
    ) public onlyOwner nonReentrant {
        uint256 length = _accounts.length;

        for (uint256 i = 0; i < length; ) {
            address account = _accounts[i];
            uint256 amount = _amounts[i];

            if (totalSupply() + amount > maxSupply)
                revert MaxSupplyExceeded();

            _mint(account, amount);

            unchecked {
                i += 1;
            }
        }
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setRoyaltyInfo(
        address receiver,
        uint96 feeBasisPoints
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenUri;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (isRevealed == false) {
        return hiddenMetadataUri;
        }

        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    // ========= OPERATOR FILTERER OVERRIDES =========

    function setApprovalForAll(
        address operator,
        bool approved
    )
        public
        override(ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    )
        public
        payable
        override(ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        payable
        override(ERC721A)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        payable
        override(ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    )
        public
        payable
        override(ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}