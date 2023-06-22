// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./opensea-operator-filterer/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IERC1155Burnable {
    function balanceOf(
        address account,
        uint256 id
    ) external view returns (uint256);

    function burn(address account, uint256 id, uint256 amount) external;
}

contract KeyNFT is ERC721A, ERC721AQueryable, ERC721ABurnable, Ownable, DefaultOperatorFilterer {
    using Strings for uint256;
    IERC1155Burnable erc1155;
    uint256 id;
    bool public forgingActive = true;
    string public baseURI;
    string public baseExtension = ".json";

    constructor(
        IERC1155Burnable _erc1155,
        uint256 _id,
        string memory _name,
        string memory _symbol
    ) ERC721A(_name, _symbol) {
        erc1155 = _erc1155;
        id = _id;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function forgeKey(uint256 _amount) public {
        require(forgingActive, "Forging has stopped");
        require(_amount > 0, "Amount must be greater than zero");
        require(
            erc1155.balanceOf(msg.sender, id) >= _amount * 5,
            "Insufficient balance"
        );
        erc1155.burn(msg.sender, id, _amount * 5);
        _safeMint(msg.sender, _amount);
    }

    function disableForging() external onlyOwner {
        require(forgingActive, "Already Disabled");
        forgingActive = false;
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}