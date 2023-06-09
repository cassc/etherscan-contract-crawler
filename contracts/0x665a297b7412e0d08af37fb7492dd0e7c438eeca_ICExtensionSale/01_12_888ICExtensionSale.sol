// SPDX-License-Identifier: MIT
/*
     888888888           888888888           888888888     
   8888888888888       8888888888888       8888888888888   
 88888888888888888   88888888888888888   88888888888888888 
8888888888888888888 8888888888888888888 8888888888888888888
8888888     8888888 8888888     8888888 8888888     8888888
8888888     8888888 8888888     8888888 8888888     8888888
 88888888888888888   88888888888888888   88888888888888888 
  888888888888888     888888888888888     888888888888888  
 88888888888888888   88888888888888888   88888888888888888 
8888888     8888888 8888888     8888888 8888888     8888888
8888888     8888888 8888888     8888888 8888888     8888888
8888888     8888888 8888888     8888888 8888888     8888888
8888888888888888888 8888888888888888888 8888888888888888888
 88888888888888888   88888888888888888   88888888888888888 
   8888888888888       8888888888888       8888888888888   
     888888888           888888888           888888888
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ICExtensionSale is ERC721, Ownable {
    using Strings for uint256;

    uint256 private IC_PRICE = 0.0888 ether;
    uint256 private constant IC_CODE = 1111;
    uint256 private constant IC_MEMBERS = 3000;
    uint256 private constant IC_COMMUNITY = 4000;
    uint256 private constant IC_MAX = 10000;
    uint256 private constant IC_MAX_PER_TX = 8;
    address private constant IC_PAYOUT_ADDRESS = 0x31712E09c24efe4d30d9C89B09DAE15283932C50;

    mapping(bytes32 => bool) private _hashes;
    mapping(address => uint256) public purchases;
    string private __baseURI;
    address private _signer = 0x48AcED49470bb1A326062d36e4185ff9C0888888;
    address private _controller;

    uint256 public totalSupply;
    uint256 public codeCounter;
    uint256 public privateCounter;
    uint256 public allowListCounter;
    bool public saleEnabled;
    bool public codeClaimEnabled;
    bool public innerCircleSaleEnabled;
    bool public allowListEnabled;

    constructor(string memory _name, string memory _symbol, string memory _uri, address _admin) ERC721(_name, _symbol) { 
        _controller = _admin;
        __baseURI = _uri;

        _mint(msg.sender, ++totalSupply);
    }

    modifier onlyController {
        require(msg.sender == _controller || msg.sender == owner(), "ONLY_CONTROLLER");

        _;
    }

    function verifyCode(bytes32 codeHash, bytes calldata signature) internal view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(address(this), msg.sender, codeHash));
        return _signer == ECDSA.recover(hash, signature);
    }

    function verifySignature(uint256 amount, bytes32 nonce, bytes calldata signature, uint256 saleType) internal view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(address(this), msg.sender, amount, nonce, saleType));
        return _signer == ECDSA.recover(hash, signature);
    }

    function redeemCode(bytes32 codeHash, bytes calldata signature) external payable {
        require(codeClaimEnabled, "CLAIM_DISABLED");
        require(!_hashes[codeHash], "CODE_USED");
        require(totalSupply < IC_MAX, "MAX_SUPPLY_REACHED");
        require(codeCounter++ < IC_CODE, "MAX_CODES_CLAIMED");
        require(verifyCode(codeHash, signature), "INVALID_TRANSACTION");
        require(msg.value >= IC_PRICE, "INSUFFICIENT_ETH_SENT");

        _hashes[codeHash] = true;

        _mint(msg.sender, ++totalSupply);
    }

    function innerCircleSale(uint256 amount, uint256 maxAmount, bytes calldata signature) external payable {
        require(innerCircleSaleEnabled, "NOT_RELEASED");
        require(totalSupply + amount <= IC_MAX, "MAX_SUPPLY_REACHED");
        require(privateCounter + amount <= IC_MEMBERS, "MAX_PRIVATE_SALE");
        require(purchases[msg.sender] + amount <= maxAmount, "MAX_PRIVATE_SALE");
        purchases[msg.sender] += amount;

        require(verifySignature(amount, bytes32(maxAmount), signature, 1), "INVALID_TRANSACTION");
        require(msg.value >= IC_PRICE * amount, "INSUFFICIENT_ETH_SENT");

        privateCounter += amount;

        for (uint256 i = 1; i <= amount; i++) {
            _mint(msg.sender, totalSupply + i);
        }

        totalSupply += amount;
    }

    function allowListSale(uint256 amount, bytes32 nonce, bytes calldata signature) external payable {
        require(allowListEnabled, "NOT_RELEASED");
        require(!_hashes[nonce], "NONCE_USED");
        require(totalSupply + amount <= IC_MAX, "MAX_SUPPLY_REACHED");
        require(amount <= IC_MAX_PER_TX, "MAX_PER_TX");
        require(allowListCounter + amount + privateCounter <= IC_COMMUNITY + IC_MEMBERS, "MAX_ALLOW_SALE");
        require(verifySignature(amount, nonce, signature, 2), "INVALID_TRANSACTION");
        require(msg.value >= IC_PRICE * amount, "INSUFFICIENT_ETH_SENT");
        
        _hashes[nonce] = true;
        allowListCounter += amount;

        for (uint256 i = 1; i <= amount; i++) {
            _mint(msg.sender, totalSupply + i);
        }

        totalSupply += amount;
    }

    function mint(uint256 amount, bytes32 nonce, bytes calldata signature) external payable {
        require(saleEnabled, "NOT_RELEASED");
        require(!_hashes[nonce], "NONCE_USED");
        require(amount <= IC_MAX_PER_TX, "MAX_PER_TX");
        require(totalSupply + amount - codeCounter <= IC_MAX - IC_CODE, "MAX_PUBLIC_SALE");
        require(verifySignature(amount, nonce, signature, 3), "INVALID_TRANSACTION");
        require(msg.value >= IC_PRICE * amount, "INSUFFICIENT_ETH_SENT");
        
        _hashes[nonce] = true;

        for (uint256 i = 1; i <= amount; i++) {
            _mint(msg.sender, totalSupply + i);
        }

        totalSupply += amount;
    }

    function toggleSale() public onlyController {
        saleEnabled = !saleEnabled;
    }

    function toggleClaimCode() public onlyController {
        codeClaimEnabled = !codeClaimEnabled;
    }

    function toggleInnerCircle() public onlyController {
        innerCircleSaleEnabled = !innerCircleSaleEnabled;
    }

    function toggleAllowList() public onlyController {
        allowListEnabled = !allowListEnabled;
    }
    
    function updatePrice(uint256 newPrice) public onlyController {
        IC_PRICE = newPrice;
    }

    function setSignerAddress(address newSigner) public onlyController {
        _signer = newSigner;
    }

    function withdraw() public onlyController {
        payable(IC_PAYOUT_ADDRESS).transfer(address(this).balance);
    }

    function setBaseURI(string memory _uri) public onlyController {
        __baseURI = _uri;
    }

    function tokensOfOwner(address _owner, uint startId, uint endId) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index = 0;

            for (uint256 tokenId = startId; tokenId < endId; tokenId++) {
                if (index == tokenCount) break;

                if (ownerOf(tokenId) == _owner) {
                    result[index] = tokenId;
                    index++;
                }
            }

            return result;
        }
    }
    
    function tokenURI(uint256 _id) public view override returns (string memory) {
        require(_exists(_id), "TOKEN_DOES_NOT_EXIST");
                
        return string(abi.encodePacked(__baseURI, "/", _id.toString()));
    }
}