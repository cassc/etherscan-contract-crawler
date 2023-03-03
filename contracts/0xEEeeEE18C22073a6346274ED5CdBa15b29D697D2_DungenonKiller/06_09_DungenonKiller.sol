//░░███░░░░███
// ░███   ░░███ █████ ████ ████████    ███████  ██████  ████████    ██████  ████████
// ░███    ░███░░███ ░███ ░░███░░███  ███░░███ ███░░███░░███░░███  ███░░███░░███░░███
// ░███    ░███ ░███ ░███  ░███ ░███ ░███ ░███░███████  ░███ ░███ ░███ ░███ ░███ ░███
// ░███    ███  ░███ ░███  ░███ ░███ ░███ ░███░███░░░   ░███ ░███ ░███ ░███ ░███ ░███
// ██████████   ░░████████ ████ █████░░███████░░██████  ████ █████░░██████  ████ █████
//░░░░░░░░░░     ░░░░░░░░ ░░░░ ░░░░░  ░░░░░███ ░░░░░░  ░░░░ ░░░░░  ░░░░░░  ░░░░ ░░░░░
//                                    ███ ░███
//                                   ░░██████
//                                    ░░░░░░
// █████   ████  ███  ████  ████
//░░███   ███░  ░░░  ░░███ ░░███
// ░███  ███    ████  ░███  ░███   ██████  ████████
// ░███████    ░░███  ░███  ░███  ███░░███░░███░░███
// ░███░░███    ░███  ░███  ░███ ░███████  ░███ ░░░
// ░███ ░░███   ░███  ░███  ░███ ░███░░░   ░███
// █████ ░░████ █████ █████ █████░░██████  █████
//░░░░░   ░░░░ ░░░░░ ░░░░░ ░░░░░  ░░░░░░  ░░░░░
//
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/utils/Strings.sol";
import "./ERC721A.sol";
import "./MerkleWhitelist.sol";

contract DungenonKiller is Ownable, ERC721A, MerkleWhitelist {

    uint256 public MAX_SUPPLY = 2222;
    uint256 public MINT_AMOUNT = 216;
    uint256 public MINT_PRICE = 0 ether;
    uint256 public SINGLE_ADDR_LIMIT = 5;
    bool _isActive = true;

    bytes32 private _MerkleHash = 0xd2d3ce1d422d967f2ea79ab091e9640d8bb6a16186730574f00ffc5a214cf9bd;

    string public BASE_URI="https://dungenonkiller.s3.ap-northeast-1.amazonaws.com/metadata/";
    string public CONTRACT_URI ="https://dungenonkiller.s3.ap-northeast-1.amazonaws.com/contracturi.json";

    constructor() ERC721A("Dungenon Killer", "DungenonKiller") MerkleWhitelist(_MerkleHash) {
        _safeMint(msg.sender, 1);
    }

    function mint(uint256 amount, bytes32[] calldata proof) external payable onlyWl1Whitelist(proof) {
        require(msg.sender == tx.origin, "Cannot mint from contract");
        require(_isActive, "not active");
        require(amount > 0, "amount can't be 0");
        require(totalSupply() + amount <= MINT_AMOUNT, "Max supply reached!");
        require(totalSupply() + amount <= MAX_SUPPLY, "Max exceeded");

        uint minted = _numberMinted(msg.sender);
        require(minted + amount <= SINGLE_ADDR_LIMIT, "Max mint exceeded");

        require(msg.value >= MINT_PRICE * amount, "ETH value not enough");
        _safeMint(msg.sender, amount);
    }

   function withdraw() public onlyOwner {
        (bool succ, ) = payable(owner()).call{value: address(this).balance}('');
        require(succ, "transfer failed");
   }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        BASE_URI = _baseURI;
    }

    function contractURI() public view returns (string memory) {
        return CONTRACT_URI;
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        CONTRACT_URI = _contractURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return string(abi.encodePacked(BASE_URI, Strings.toString(_tokenId), ".json"));
    }

    function flipState(bool isActive) external onlyOwner {
        _isActive = isActive;
    }

    function setPrice(uint256 price) public onlyOwner
    {
        MINT_PRICE = price;
    }

    function setAmount(uint256 amount) public onlyOwner
    {
        MINT_AMOUNT = amount;
    }

    function setLimit(uint256 limit) public onlyOwner
    {
        SINGLE_ADDR_LIMIT = limit;
    }

}