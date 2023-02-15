// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract OrdinalsFrogs is ERC721A, ReentrancyGuard, DefaultOperatorFilterer {
    uint256 public supplyCounter;
    uint256 public constant MAX_SUPPLY = 111;
    uint256 public BurnPrice = 0.1 ether;
    uint256 burnStartTime;
    uint256 burnEndTime;
    address public contractOwner;
    bool soldOut;
    struct TokenData {
        address ETHAddressOfOwner;
        string BTCAddressOfOwner;
    }
    mapping(uint256 => TokenData) public tokenData;
    mapping(address => uint256) public tokendInWallet;

    constructor(uint256 _burnStartTime, uint256 _burnEndTime)
        ERC721A("Ordinals Frogs", "ORDFRG")
    {
        contractOwner = msg.sender;
        burnStartTime = _burnStartTime;
        burnEndTime = _burnEndTime;
    }

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "not owner");
        _;
    }

    function Mint(uint256 _amount) external {
        require(!soldOut, "sold out");
        require(_amount > 0, "mint more than 0");
        require(supplyCounter + _amount <= MAX_SUPPLY, "mint less tokens");
        require(tokendInWallet[msg.sender] + _amount <= 5, "max 5 nft");
        if (supplyCounter + _amount == MAX_SUPPLY) {
            soldOut = true;
        }
        tokendInWallet[msg.sender] += _amount;
        supplyCounter += _amount;
        _safeMint(msg.sender, _amount);
    }

    function TeamMint(uint256 _amount, address _reciver) external onlyOwner {
        require(!soldOut, "sold out");
        require(_amount > 0, "mint more than 0");
        require(supplyCounter + _amount <= MAX_SUPPLY, "mint less tokens");
        if (supplyCounter + _amount == MAX_SUPPLY) {
            soldOut = true;
        }
        supplyCounter += _amount;
        _safeMint(_reciver, _amount);
    }

    function bridgeToBitcoin(uint256 _id, string memory _bitcoinAddress)
        external
        payable
        nonReentrant
    {
        require(
            block.timestamp >= burnStartTime && block.timestamp <= burnEndTime,
            "burn time is off"
        );
        require(ownerOf(_id) == msg.sender, "not token Owner");
        require(msg.value >= BurnPrice, "send more ETH");
        super._burn(_id);
        TokenData storage tokenInformation = tokenData[_id];
        tokenInformation.BTCAddressOfOwner = _bitcoinAddress;
        tokenInformation.ETHAddressOfOwner = msg.sender;
    }

    function changeBurnTime(uint256 _burnStartTime, uint256 _burnEndTime)
        external
        onlyOwner
    {
        burnStartTime = _burnStartTime;
        burnEndTime = _burnEndTime;
    }

    function changeBurnPrice(uint256 _newPrice) external onlyOwner {
        BurnPrice = _newPrice;
    }

    function tokenURI(uint256 _id)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        return "https://ipfs.ordinalsfrogs.xyz/pass.json";
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool sent, bytes memory data) = contractOwner.call{value: balance}("");
        require(sent, "TX_FAILED");
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}