// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "closedsea/src/OperatorFilterer.sol";
import "@rari-capital/solmate/src/auth/Owned.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

contract MonkeyTrip is
    ERC721A,
    ERC2981,
    ERC721AQueryable,
    ERC721ABurnable,
    OperatorFilterer,
    Owned
{
    uint256 constant MAX_SUPPLY = 6969;
    uint256 constant MAX_PER_TRANSACTION = 10;
    uint256 constant EXTRA_MINT_PRICE = 0.005 ether;

    string tokenBaseUri = "ipfs://QmP4vPe4k6bmwrgWJyhNrkH8heihPcfiVV1CzWaMya6FdB/?";

    bool public paused = true;
    bool public operatorFilteringEnabled = true;

    mapping(address => uint256) private _freeMintedCount;

    constructor() ERC721A("Monkey Trip", "MT") Owned(msg.sender) {
        _registerForOperatorFiltering();
        _setDefaultRoyalty(msg.sender, 750);
    }

    function mint(uint256 _quantity) external payable {
        unchecked {
            require(!paused, "Minting paused");

            uint256 _totalSupply = totalSupply();

            require(
                _totalSupply + _quantity <= MAX_SUPPLY,
                "Max supply reached"
            );
            require(
                _quantity <= MAX_PER_TRANSACTION,
                "Max per transaction is 10"
            );

            uint256 payForCount = _quantity;
            uint256 freeMintCount = _freeMintedCount[msg.sender];

            if (freeMintCount < 1) {
                if (_quantity > 1) {
                    payForCount = _quantity - 1;
                } else {
                    payForCount = 0;
                }

                _freeMintedCount[msg.sender] = 1;
            }

            require(
                msg.value == payForCount * EXTRA_MINT_PRICE,
                "Incorrect ETH amount"
            );

            _mint(msg.sender, _quantity);
        }
    }

    function batchTransfer(
        uint256[] calldata tokenIds,
        address[] calldata recipients
    ) external {
        require(tokenIds.length == recipients.length, "Invalid input");

        for (uint256 i = 0; i < tokenIds.length; ++i) {
            transferFrom(msg.sender, recipients[i], tokenIds[i]);
        }
    }

    function freeMintedCount(address owner) external view returns (uint256) {
        return _freeMintedCount[owner];
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return tokenBaseUri;
    }

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

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator)
        internal
        pure
        override
        returns (bool)
    {
        // OpenSea
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override(IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override(IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        public
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function setBaseURI(string calldata _newBaseUri) external onlyOwner {
        tokenBaseUri = _newBaseUri;
    }

    function flipSale() external onlyOwner {
        paused = !paused;
    }

    function collectReserves() external onlyOwner {
        require(totalSupply() == 0, "Reserves taken");

        _mint(msg.sender, 300);
    }

    function withdraw() external onlyOwner {
        require(payable(owner).send(address(this).balance), "Unsuccessful");
    }
}