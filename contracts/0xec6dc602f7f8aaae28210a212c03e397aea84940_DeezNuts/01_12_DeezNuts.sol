//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol"; // ERC2981 NFT Royalty Standard
import "./OperatorFilterer.sol";

contract DeezNuts is Ownable, ERC721A, OperatorFilterer, ERC2981 {
    using Strings for uint256;
    bool public operatorFilteringEnabled;

    //base url for metadata
    string _baseTokenURI;
    //mint price
    uint256 public cost = 0.003 ether;
    //maximum supply of the collection
    uint256 public maxSupply = 5555;
    uint256 public freeSupply = 1111;
    uint256 public freeMints = 0;
    bool isRevealed = false;
    bool public isSaleActive = true;

    constructor(string memory baseURI) ERC721A("Deez Nuts", "DzN") {
        _baseTokenURI = baseURI;
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;

        // Set royalty receiver to the contract creator,
        // at 10% (default denominator is 10000).
        _setDefaultRoyalty(0x89D22d046DBB487E32E07440794CD2B913Aa0B72, 420);
    }

    /**
     * @dev Returns the first token id.
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @dev change cost
     * @param _cost cost of the token
     */
    function setCost(uint256 _cost) external onlyOwner {
        cost = _cost;
    }

    function toggleSale() external onlyOwner {
        isSaleActive = !isSaleActive;
    }

    /**
     * @dev _baseURI overides the Openzeppelin's ERC721 implementation which by default
     * returned an empty string for the baseURI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev setBaseURI
     * @param _uri base url for metadata
     */
    function setBaseURI(string memory _uri) external onlyOwner {
        _baseTokenURI = _uri;
    }

    /**
     * @dev reveal the collection
     */
    function reveal(string memory _uri) external onlyOwner {
        isRevealed = true;
        _baseTokenURI = _uri;
    }

    function mint(uint256 _quantity) external payable {
        require(isSaleActive, "Sale is not active");
        uint256 supply = _totalMinted();
        require(
            _numberMinted(msg.sender) + _quantity <= 10,
            "Exceed max mintable amount"
        );
        require(supply + _quantity <= maxSupply, "Exceed maximum supply");
        uint256 price = getCost(msg.sender, _quantity);
        require(msg.value == price, "Incorrect value sent");
        _mint(msg.sender, _quantity);
        freeMints++;
    }

    function getCost(
        address _address,
        uint256 _quantity
    ) public view returns (uint256) {
        uint256 quantity = _quantity;
        // If the address has not minted a free NFT, deduct the cost from the quantity
        if (_numberMinted(_address) == 0 && freeMints < freeSupply) {
            quantity -= 1;
        }

        return cost * quantity;
    }

    /**
     * @dev Get token URI
     * @param tokenId ID of the token to retrieve
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override(ERC721A) returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();

        if (isRevealed == false) {
            return string(currentBaseURI);
        }

        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        Strings.toString(tokenId),
                        ".json"
                    )
                )
                : "";
    }

    /**
     * @dev withdraw ETH from contract
     */
    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        (bool sent, ) = payable(owner()).call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721A.supportsInterface(interfaceId) ||
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
}