// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/*    
    BearApes / 2022 / V.1
*/

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract BearApes is ERC721, Ownable {
    using Strings for uint256;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenSupply;

    uint256 public constant SUPPLY = 10000;
    uint256 public constant PRICE = 0.0029 ether;
    uint256 public constant PER_ADDRESS = 20;
    uint256 public constant COMMUNITY_VAULT_BATCH = 50;
    uint256 public constant COMMUNITY_VAULT_REST = 19;
    uint256 public constant COMMUNITY_VAULT_TOTAL = 369;

    mapping(address => uint256) public mintCount;

    string private _contractURI;
    string private _tokenBaseURI;
    address private _ownerAddress = 0x9040ea039fE998c7173A5D4605F3678760cf92aF;

    bool public saleLive = false;
    bool public locked = false;

    constructor() ERC721("Bear Apes", "BApe") { }

    modifier notLocked {
        require(!locked, "Contract metadata is locked");
        _;
    }

    function mintCommunityBatch() external onlyOwner {
        require(_tokenSupply.current() + COMMUNITY_VAULT_BATCH <= SUPPLY, "EXCEED_MAX_MINT");

        for (uint256 i = 0; i < COMMUNITY_VAULT_BATCH; i++) {
            _tokenSupply.increment();
            _safeMint(msg.sender, _tokenSupply.current());
        }
    }

    function mintCommunityRest() external onlyOwner {
        require(_tokenSupply.current() + COMMUNITY_VAULT_REST <= SUPPLY, "EXCEED_MAX_MINT");

        for (uint256 i = 0; i < COMMUNITY_VAULT_REST; i++) {
            _tokenSupply.increment();
            _safeMint(msg.sender, _tokenSupply.current());
        }
    }

    function mint(uint256 tokenQuantity) external payable {
        require(saleLive, "SALE_CLOSED");
        require(tokenQuantity > 0 && tokenQuantity <= PER_ADDRESS, "MINT AT LEAST 1 TOKEN AND AT MOST 20");
        require(_tokenSupply.current() + tokenQuantity <= SUPPLY, "EXCEED_MAX_MINT");
        require(mintCount[msg.sender] + tokenQuantity <= PER_ADDRESS, "MAXIMUM 20 TOKENS PER ADDRESS");

        uint256 payCount = tokenQuantity;

        if(mintCount[msg.sender] == 0) {
            payCount--;
        }

        require(PRICE * payCount <= msg.value, "INSUFFICIENT_ETH");
        mintCount[msg.sender] += tokenQuantity;

        for(uint256 i = 0; i < tokenQuantity; i++) {
            _tokenSupply.increment();
            _safeMint(msg.sender, _tokenSupply.current());
        }
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");

        return string(abi.encodePacked(_tokenBaseURI, tokenId.toString()));
    }

    function totalSupply() public view returns (uint256) {
        return _tokenSupply.current();
    }

    //functions allowed only for OWNER
    function withdraw() external onlyOwner {
        uint _balance = address(this).balance;
        payable(_ownerAddress).transfer(_balance);
    }

    function lockMetadata() external onlyOwner {
        locked = true;
    }

    function toggleSaleStatus() external onlyOwner {
        saleLive = !saleLive;
    }

    function setContractURI(string calldata URI) external onlyOwner notLocked {
        _contractURI = URI;
    }

    function setBaseURI(string calldata URI) external onlyOwner notLocked {
        _tokenBaseURI = URI;
    }
}