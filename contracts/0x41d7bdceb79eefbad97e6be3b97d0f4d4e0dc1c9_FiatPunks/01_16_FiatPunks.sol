// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "https://github.com/exo-digital-labs/ERC721R/blob/main/contracts/ERC721A.sol";
import "https://github.com/exo-digital-labs/ERC721R/blob/main/contracts/IERC721R.sol";





contract FiatPunks is ERC721A, IERC721R, Ownable, Multicall {

    uint256 public constant maxTotalSupply = 10000;
    uint256 public constant mintPrice = 0.0029 ether;
    uint256 public constant preSalePrice = 0.0025 ether;
    uint256 public constant refundPeriod = 48 hours ;
    uint256 public constant maxUserMintAmount = 5;
    uint256 public constant maxWLMintAmount = 10;


    // Sale Status
    bool public publicSaleActive;
    bool public presaleActive;
    bool public passmintActive;  


    address public refundAddress;
    bytes32 public merkleRoot;
    uint256 public presaleRefundEndBlockNumber;
    uint256 public refundEndBlockNumber;
 
    mapping(uint256 => uint256) public refundEndBlockNumbers;
    mapping(uint256 => bool) public hasRefunded; // users can search if the NFT has been refunded
    mapping(uint256 => bool) public isOwnerMint; // if the NFT was freely minted by owner
    mapping(uint256 => bool) public isPresaleMint; //if the NFT was minted on an discount
    mapping(uint256 => bool) public isPublicMint; //if it was a public mint
    mapping(uint256 => bool) public isPassMint; //if the NFT was minted on an discount'
    mapping(address => uint256) public holders; //Pass holders
    string private baseURI;


    constructor() ERC721A("FiatPunks", "fiat") {
        refundAddress = address(this);
        refundEndBlockNumber = block.number + refundPeriod;
        presaleRefundEndBlockNumber = refundEndBlockNumber;

        addHolderAddresses();
    }

    function preSaleMint(uint256 quantity, bytes32[] calldata proof)
        external
        payable
    {
        require(presaleActive, "Presale is not active");
        require(msg.value == quantity * preSalePrice, "Value");
        require(
            _isAllowlisted(msg.sender, proof, merkleRoot),
            "Not on allow list" 
        );
        require(
            _numberMinted(msg.sender) + quantity <= maxWLMintAmount,
            "Max amount"
        );
        require(_totalMinted() + quantity <= maxTotalSupply, "Max mint supply");

       
    }


    function publicSaleMint(uint256 quantity) public payable {
        require(publicSaleActive, "Public sale is not active");
        require(msg.value >= quantity * mintPrice, "Not enough eth sent");
        require(
            _numberMinted(msg.sender) + quantity <= maxUserMintAmount,
            "Over mint limit"
        );
        require(
            _totalMinted() + quantity <= maxTotalSupply,
            "Max mint supply reached"
        );

        _safeMint(msg.sender, quantity);
        refundEndBlockNumber = block.number + refundPeriod;
        for (uint256 i = _currentIndex - quantity; i < _currentIndex; i++) {
            refundEndBlockNumbers[i] = refundEndBlockNumber;
            }
        
        for (uint256 i = _currentIndex - quantity; i < _currentIndex; i++) {
        isPublicMint[i] = true;
        }

    }


    function ownerMint(uint256 quantity) external onlyOwner {
        require(
            _totalMinted() + quantity <= maxTotalSupply,
            "Max mint supply reached"
        );
        _safeMint(msg.sender, quantity);

        for (uint256 i = _currentIndex - quantity; i < _currentIndex; i++) {
        isOwnerMint[i] = true;
        } 
    
    }

    function refund(uint256 tokenId) external override {
        require(block.number < refundDeadlineOf(tokenId), "Refund expired");
        require(msg.sender == ownerOf(tokenId), "Not token owner");

        hasRefunded[tokenId] = true;
        _transfer(msg.sender, refundAddress, tokenId);

        uint256 refundAmount = refundOf(tokenId);
        Address.sendValue(payable(msg.sender), refundAmount);
    }

    function refundDeadlineOf(uint256 tokenId) public override view returns (uint256) {
        if (isOwnerMint[tokenId]) {
            return 0;
        }
        if (isPassMint[tokenId]) {
            return 0;
        }
        if (hasRefunded[tokenId]) {
            return 0;
        }
        return refundEndBlockNumbers[tokenId];
    }



    function refundOf(uint256 tokenId) public override view returns (uint256) {
        if (isOwnerMint[tokenId]) {
            return 0;
        }
        if (hasRefunded[tokenId]) {
            return 0;
        }
        if (isPassMint[tokenId]) {
            return 0;
        }
        if (isPresaleMint[tokenId])  {
            return preSalePrice;
        }
        return mintPrice;
    }


    function withdraw() external onlyOwner {
        require(block.timestamp > refundEndBlockNumber, "Refund period not over");
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

  
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI ;
    }

    function setMerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
    }


    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }



    function togglePassMintStatus() external onlyOwner {
        passmintActive = !passmintActive; 
    }

    function togglePresaleStatus() external onlyOwner {
        presaleActive = !presaleActive;
    }


    function togglePublicSaleStatus() external onlyOwner {
        publicSaleActive = !publicSaleActive;
    }

    function _leaf(address _account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account));
    }

    function _isAllowlisted(
        address _account,
        bytes32[] calldata _proof,
        bytes32 _root
    ) internal pure returns (bool) {
        return MerkleProof.verify(_proof, _root, _leaf(_account));
    }


    function PassClaim (uint256 quantity) public {
    require(passmintActive, "Pass mint is not enabled");
    require( quantity <= holders[msg.sender],
      "Exceeds max mint holder limit per wallet");          

    require(  _totalMinted() + quantity <= maxTotalSupply,
            "Max mint supply reached"
        );

      holders[msg.sender] -= quantity;
     _safeMint(msg.sender, quantity);

    for (uint256 i = _currentIndex - quantity; i < _currentIndex; i++) {
     isPassMint[i] = true;

    }

 }

    function addHolderAddresses() internal {

    holders[0x37cC41fF7f1569365216D9E01231dE1B656bBBFD] = 250;
    holders[0x8Ba4c65D4864074B7DF30ccAC98B766e6aa49E67] = 250;
    holders[0x39F906e8f2AF8Be5AA32C85eE4C6E9344e258076] = 130;
    holders[0x3Ca92d91D27Cf725c0FD3C3929e8f5F8C56424eb] = 70;
    holders[0x22A9F4Ea3b0211F0B29E62B3a7F9A0488DDD1E72] = 50;
    holders[0x45f72B3dd5B25E29169a1e283640E42E7afd632f] = 40;
    holders[0x27bC9C6d4c5D068dfd6D44A4add69BDEBe01E038] = 25;
    holders[0x578bc48EC290109940Bf256005757967f7871489] = 25; 
    holders[0x4fc8B211bbc5fF239c59B425229a410fe9351e52] = 25; 
    holders[0x169540c29A1B43e1fB34CD4034959cD5EaCE9915] = 15;
    holders[0x294CD7Db1DA684d6aB241a885fd94dB07129a2CC] = 15;
    holders[0x40F504f3B71048226b6c36D750162c0A0c418f9e] = 15;
    holders[0x5ed6B949554c688b4E6DCE7F974A18da524C131c] = 15;
    holders[0x6748c23CB9D9F40aC75ec2C43106A8BC3197f82E] = 15;
    holders[0x9A1697167Fe03164a551DaEF72755ee8bD87AAe8] = 15;
    holders[0x25f6D2c65678eE72E3d433D2E561cF3E665c30eF] = 15;
    holders[0xF22bb1C67cefcE284ef9A9B86d9376FeB987F72A] = 15;
    holders[0x2C72bc035Ba6242B7f7B7C1bdf0ed171A7c2b945] = 10;
    holders[0x4A9Cd004Fc51482f101328Cb4Cc95cA65D0411AF] = 10;
    holders[0x7C665F07f04E9e9645876312e67A67c5A091f82b] = 10;
    holders[0xB500C39Ceedd505B4176927D09CDce053A1584f3] = 10;
    holders[0xBbFb6911c17d4759d31044b5C09224E6ef28CFcc] = 10;
    holders[0xc803d31d03813fbE31729bB2370AC663C6F2bF70] = 10;
    holders[0xCD53574C6bB590B532c84960619b9df643cf3426] = 10;
    holders[0xf6B93142da083eE16d691AC22e36F21eA30de4c7] = 10;
    holders[0xe192a07C7A66357BA7D659c38182509FDe1BA5E8] = 10;
    holders[0x27bC9C6d4c5D068dfd6D44A4add69BDEBe01E038] = 10;
    holders[0x0407e799B5ec310f37f77E11bb559bA9AaEadf8c] = 5;
    holders[0x05cBA4BC52982e64532B16D75d6Dc19D74dD8f9a] = 5;
    holders[0x0f5881bfCfEAFDfCb489263b6f283f60E6B63694] = 5;
    holders[0x1a3ECe8c0180bE6c58B9cCe74a45bB374b965488] = 5;
    holders[0x1dD0e48457C79A4f74adf9aDEB582760203984D2] = 5;
    holders[0x2077Cdab8aF6bE537560236589e100a3F2F9e3Ee] = 5;
    holders[0x2248bf80865f89ae6d029c080B344D1B66aCD8C8] = 5;
    holders[0x22d9B7690eDE5eeF0Ea93726D746E98b3dF4Dd99] = 5;
    holders[0x550ABc48F6E437e9572e048ea5027c06f29F675C] = 5;
    holders[0x55d9A171Ffc88F39d45FFfD6893A2207493699a2] = 5;
    holders[0x65B5Ce66AeFF50d8893F117F13eb0C5630a7e1C4] = 5;
    holders[0x6AE7737fFB0E7862de7d6F77F48e72Ac693BC363] = 5;
    holders[0x7932CB7ecD74B556D36Ab8FAbc12D44a3C1365d6] = 5;
    holders[0x8AD7d01f3011797c2b7D33D698a3527B16936744] = 5;
    holders[0x8b34f758c93666a709D2368795485c43d4Ea0E81] = 5;
    holders[0xb22ac5e64E4C00a845f46EBDA8B2450B7f07C6f0] = 5;
    holders[0xED16a4011E979352FDDA19Df55a324AF95124149] = 5;
    holders[0xED8E924735F590572361b52657ABd9A3260F35a0] = 5;
    holders[0xffd023547E93bC5A2cC38Eb6F097518Ff8bd7b0a] = 5;
    holders[0x611aA0D6ccFb697DCD699D191359FD4F970a93Ff] = 5;
    holders[0x40E4D03F8fF764B7857D0Da4181F0f31a7130C34] = 5;
    holders[0xa225bCFE6dA37821d2000437BA7434E4fC21a749] = 5;
    holders[0xd764D596Da84934429059b08c904a013C0afb794] = 5;
    holders[0x3F595Aa56C1e27177eACD7eCD70b7F0Da789ccd6] = 5;
    holders[0xb12Ec04633F183D32F9b52aCcc4D1B41e7dcd601] = 5;
    holders[0x51f126208a5e03d546b30889F7F783dC033D1f3C] = 5;
   } 

}