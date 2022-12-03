// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "./DefaultOperatorFilterer.sol";

contract WsbMembershipPass is ERC1155, ERC1155Supply, DefaultOperatorFilterer, Ownable {
    uint256 public WSB_SUPPLY = 50;
    uint256 public constant WSB = 0;
    uint256 public WSB_PRICE = 0.04 ether;
    uint256 public WSB_LIMIT = 1;
    bool public IS_MINT_ACTIVE = false;
    bool public _revealed = false;

    mapping(address => uint256) addressBlockBought;
    mapping (address => uint256) public mintedWSB;

    string private _baseUri;
    string public name;
    string public symbol;

    address public constant ADDRESS_2 = 0xc9b5553910bA47719e0202fF9F617B8BE06b3A09; //ROYAL LABS

    constructor(string memory _name, string memory _symbol) ERC1155("https://rl.mypinata.cloud/ipfs/QmPcrko5Spt17GEfLeKkDqEXTgiwSnQnsCNk7Gfrhmvpgp/") {
        name = _name;
        symbol = _symbol;
        _mint(msg.sender, WSB, 5, "");
    }

    modifier isSecured(uint8 mintType) {
        require(addressBlockBought[msg.sender] < block.timestamp, "CANNOT_MINT_ON_THE_SAME_BLOCK");
        require(tx.origin == msg.sender,"CONTRACTS_NOT_ALLOWED_TO_MINT");

        if(mintType == 1) {
            require(IS_MINT_ACTIVE, "MINT_IS_NOT_YET_ACTIVE");
        }
        _;
    }

    function uri(uint256 _id) public view virtual override returns (string memory) {
        return string(abi.encodePacked(_baseUri, Strings.toString(_id)));
    }

    // Function for winter
    function mintPublic(address _owner) external isSecured(1) payable{
        require(1 + totalSupply(WSB) <= WSB_SUPPLY,"NOT_ENOUGH_SUPPLY");
        require(msg.value == WSB_PRICE * 1, "WRONG_ETH_VALUE");
        addressBlockBought[msg.sender] = block.timestamp;
        mintedWSB[msg.sender] += 1;

        _mint(_owner, WSB, 1, "");
    }

    // Function for crypto mint
    function mintCrypto() external isSecured(1) payable{
        require(1 + totalSupply(WSB) <= WSB_SUPPLY,"NOT_ENOUGH_SUPPLY");
        require(mintedWSB[msg.sender] + 1 <= WSB_LIMIT,"MINTED_ALREADY");

        require(msg.value == WSB_PRICE * 1, "WRONG_ETH_VALUE");
        addressBlockBought[msg.sender] = block.timestamp;
        mintedWSB[msg.sender] += 1;

        _mint(msg.sender, WSB, 1, "");
    }

    function reveal(bool revealed, string calldata _baseURI) public onlyOwner {
        _revealed = revealed;
        _baseUri = _baseURI;
    }

    // Base URI
    function setBaseURI(string calldata URI) external onlyOwner {
        _baseUri = URI;
    }

    // Ruby's WL status
    function setSaleStatus() external onlyOwner {
        IS_MINT_ACTIVE = !IS_MINT_ACTIVE;
    }

    function setPrice(uint256 _price) external onlyOwner {
      WSB_PRICE = _price;
    }

    function setSupply(uint256 _supply) external onlyOwner {
      WSB_SUPPLY = _supply;
    }

    function setLimit(uint256 _limit) external onlyOwner {
      WSB_LIMIT = _limit;
    }
    //Essential

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        payable(ADDRESS_2).transfer((balance * 600) / 10000);
        payable(msg.sender).transfer(address(this).balance);
    }

    // OPENSEA's royalties functions

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}