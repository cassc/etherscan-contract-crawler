// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract CryptoTitVags is ERC721, Ownable {
		
    using SafeMath for uint256;

    event Mint(uint tokenId, address sender);

    uint256 public TOTAL_SUPPLY = 4200;

    uint256 public price = 0.02 ether;

    uint8 public MAX_PURCHASE = 20;

    uint public MAX_PRESALE_TOKENS = 9;

    bool public saleIsActive = false;

    bool public presaleIsActive = false;

    bool public revealed = false;

    string private baseURI;

    uint256 private _currentTokenId = 0;

    bytes32 public merkleRoot;

    mapping(address => uint) public whitelistClaimed;

    constructor() ERC721("CryptoTitVags","CTV") {
        setBaseURI("ipfs://QmRPzKDVZvPsPLHapUCA9wRr3yi1m4QKrgKEKQxkANpWbo", false);

        mintTo(msg.sender, 69);

        mintTo(0x422605D2f4Ac07b2e8Ee9E09045B64947cDEC17D, 20);
    }
	
    function mintTitVagsTo(address _to, uint numberOfTokens) public payable {

        require(saleIsActive, "Wait for sales to start!");
        require(numberOfTokens <= MAX_PURCHASE, "Too many CryptoTitVags to mint!");
        require(_currentTokenId.add(numberOfTokens) <= TOTAL_SUPPLY, "All CryptoTitVags has been minted!");
        require(msg.value >= price.mul(numberOfTokens), "insufficient ETH");

        for (uint i = 0; i < numberOfTokens; i++) {
            uint256 newTokenId = _nextTokenId();

            if (newTokenId <= TOTAL_SUPPLY) {
                _safeMint(_to, newTokenId);
                emit Mint(newTokenId, msg.sender);
                _incrementTokenId();
            }
        }
    }

    function mintTo(address _to, uint numberOfTokens) public onlyOwner {
        for (uint i = 0; i < numberOfTokens; i++) {
            uint256 newTokenId = _nextTokenId();

            if (newTokenId <= TOTAL_SUPPLY) {
                _safeMint(_to, newTokenId);
                emit Mint(newTokenId, msg.sender);
                _incrementTokenId();
                
            }
        }
    }

  	function whitelistMint(bytes32[] calldata _merkelProof, uint numberOfTokens) public payable {
        
        require(presaleIsActive, "Wait for presale to start!");
        require(numberOfTokens <= MAX_PRESALE_TOKENS, "Too many CryptoTitVags to mint!");
        require(_currentTokenId.add(numberOfTokens) <= TOTAL_SUPPLY, "All CryptoTitVags has been minted!");
        require(msg.value >= price.mul(numberOfTokens), "insufficient ETH");
        require(MAX_PRESALE_TOKENS >= whitelistClaimed[msg.sender].add(numberOfTokens), "All whitelist Titvags Has been minted");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkelProof, merkleRoot, leaf), "Invalid proof.");

        whitelistClaimed[msg.sender] += numberOfTokens;

        for (uint i = 0; i < numberOfTokens; i++) {
            uint256 newTokenId = _nextTokenId();

            if (newTokenId <= TOTAL_SUPPLY) {
                _safeMint(msg.sender, newTokenId);
                emit Mint(newTokenId, msg.sender);
                _incrementTokenId();
            }
        }
    }

    function assetsLeft() public view returns (uint256) {

        if (supplyReached()) {
            return 0;
        }

        return TOTAL_SUPPLY - _currentTokenId;
    }

    function whiteListMintIsActive() public view returns(bool) {
        return presaleIsActive;
    }

    function publicMintIsActive() public view returns(bool) {
        return saleIsActive;
    }

    function _nextTokenId() private view returns (uint256) {
        return _currentTokenId.add(1);
    }

    function _incrementTokenId() private {
        _currentTokenId++;
    }

    function supplyReached() public view returns (bool) {
        return _currentTokenId == TOTAL_SUPPLY;
    }

    function totalSupply() public view returns (uint256) {
        return TOTAL_SUPPLY;
    }

    function wlAssetsLeft(address addr) public view returns (uint) {
        return MAX_PRESALE_TOKENS.sub(whitelistClaimed[addr]);
    }

    function switchSaleIsActive() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function switchPresaleIsActive() public onlyOwner {
        presaleIsActive = !presaleIsActive;
    }

    function setPresaleMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }

    function baseTokenURI() private view returns (string memory) {
        return baseURI;
    }

    function getPrice() public view returns (uint256) {
        return price;
    }

    function setBaseURI(string memory _newUri, bool _revealed) public onlyOwner {
        baseURI = _newUri;
        revealed = _revealed;
    }

    function setTotalSupply(uint256 _newTotalSupply) public onlyOwner {
        TOTAL_SUPPLY = _newTotalSupply;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        if(revealed){
            return string(abi.encodePacked(baseURI, uint2str(_tokenId)));
        }

        return baseURI;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function uint2str(uint256 _i) internal pure  returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

}