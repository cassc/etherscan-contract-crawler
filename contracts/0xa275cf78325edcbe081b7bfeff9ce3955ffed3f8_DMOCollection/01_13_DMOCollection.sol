// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract DMOCollection is ERC721A, ReentrancyGuard, ERC2981, DefaultOperatorFilterer {
    mapping(uint256 => uint256) public royalties;
    uint8 public TOKEN_PER_WALLET = 10;
    uint256 public constant MAX_SUPPLY = 5000;
    uint256 public constant PRICE = 0.2 ether;
    uint256 public constant WHIELIST_PRICE = 0.15 ether;
    address public VAULT_ADDRESS = 0x511A19CF116fA8D5dE5AAB3dE7f33271FcC80504;
    address public NEW_OWNER;
    address public OWNER;
    string public BASE_URI = "https://ipfs.io/ipfs/QmbQ5kGitFWEMfdWran5LnVfW7NG6Ck5kqWCGYQ9ptUCH8/";
    bytes32 public MERKEL_ROOT = 0x33b5b63d12d22e0c61d3773d1c3050d53c91cd3a41b27a57a638ff6f5e5562d3;
    bool private IS_PUBLIC_SALE;
    
    enum ContractStatus {
        DEPLOY,
        WHITELIST,
        SALE,
        SOLD
    }
    ContractStatus public CONTRACT_STATUS;

    constructor() ERC721A("DMO The Army", "DMO") {
        OWNER = msg.sender;
        CONTRACT_STATUS = ContractStatus.DEPLOY;
    }

    modifier onlyOwner() {
        require(msg.sender == OWNER, "YOU_ARE_NOT_OWNER");
        _;
    }
    modifier onlyNewOwner() {
        require(msg.sender == NEW_OWNER, "YOU_ARE_NOT_NEW_OWNER");
        _;
    }

    function verifyAddress(
        bytes32[] calldata _merkleProof,
        address _address
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        return MerkleProof.verify(_merkleProof, MERKEL_ROOT, leaf);
    }

    function presaleMint(
        bytes32[] calldata _merkleProof,
        uint256 _amount
    ) external payable nonReentrant {
        require(verifyAddress(_merkleProof, msg.sender), "INVALID_PROOF");
        require(CONTRACT_STATUS != ContractStatus.SOLD, "SOLD_OUT");
        require(
            CONTRACT_STATUS == ContractStatus.WHITELIST,
            "WHITELSIT_NOT_STARTED_OR_ENDED"
        );
        uint256 _price = WHIELIST_PRICE * _amount;
        require(msg.value >= _price, "SEND_MORE_FUND");
        require(_amount > 0, "MINT_1_TOKEN");
        require(totalSupply() + _amount <= MAX_SUPPLY, "SOLD_OUT");
        require(
            balanceOf(msg.sender) + _amount <= TOKEN_PER_WALLET,
            "YOU_CAN_NOT_MINT_MORE"
        );
        if (totalSupply() + _amount == MAX_SUPPLY) {
            CONTRACT_STATUS = ContractStatus.SOLD;
        }
        _mint(msg.sender, _amount, _price);
    }

    function mint(uint256 _amount) external payable nonReentrant {
        require(CONTRACT_STATUS != ContractStatus.SOLD, "SOLD_OUT");
        require(CONTRACT_STATUS == ContractStatus.SALE, "SALE_NOT_STARTED");
        uint256 _price = PRICE * _amount;
        require(msg.value >= _price, "SEND_MORE_FUND");
        require(_amount > 0, "MINT_1_TOKEN");
        require(
            balanceOf(msg.sender) + _amount <= TOKEN_PER_WALLET,
            "YOU_CAN_NOT_MINT_MORE"
        );
        require(totalSupply() + _amount <= MAX_SUPPLY, "SOLD_OUT");
        if (totalSupply() + _amount == MAX_SUPPLY) {
            CONTRACT_STATUS = ContractStatus.SOLD;
        }
        _mint(msg.sender, _amount, _price);
    }

    function MintOwner(uint256 _amount) external onlyOwner {
        _safeMint(msg.sender, _amount);
    }

    function _mint(address _user, uint256 _amount, uint256 _price) internal {
        _safeMint(_user, _amount);
        if (msg.value > _price) {
            (bool sent, bytes memory data) = _user.call{
                value: msg.value - _price
            }("");
            require(sent, "TX_FAILED");
        }
    }

    function setMerkleRoot(bytes32 _MERKEL_ROOT) external onlyOwner {
        MERKEL_ROOT = _MERKEL_ROOT;
    }

    function startSale() external onlyOwner {
        require(!IS_PUBLIC_SALE, "SALE_IS_ACTIVE");
        IS_PUBLIC_SALE = true;
        CONTRACT_STATUS = ContractStatus.SALE;
    }

    function startWhitelist() external onlyOwner {
        require(!IS_PUBLIC_SALE, "PUBLIC_SALE_IS_ACTIVE");
        CONTRACT_STATUS = ContractStatus.WHITELIST;
    }

    function transferOwnership(address _NEW_OWNER) public onlyOwner {
        NEW_OWNER = _NEW_OWNER;
    }

    function acceptOwnership() public onlyNewOwner {
        OWNER = NEW_OWNER;
        NEW_OWNER = address(0x0);
    }

    function setBaseURI(string memory _URI) public onlyOwner {
        BASE_URI = _URI;
    }

    function tokenURI(
        uint256 _id
    ) public view override(ERC721A) returns (string memory) {
        return
            bytes(BASE_URI).length > 0
                ? string(abi.encodePacked(BASE_URI, _toString(_id)))
                : "";
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance != 0, "BALANCE_IS_EMPTY");
        (bool sent, bytes memory data) = VAULT_ADDRESS.call{value: balance}("");
        require(sent, "TX_FAILED");
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    /////////////////////////////
    // OPENSEA FILTER REGISTRY 
    /////////////////////////////
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}