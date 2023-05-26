// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

abstract contract NFT {
    function balanceOf(address owner)
        public
        view
        virtual
        returns (uint256 balance);
}

contract WLNFT_MintPass is ERC721A, Ownable {

    address constant WALLET1 = 0xffe5CBCDdF2bd1b4Dc3c00455d4cdCcf20F77587;
    address constant WALLET2 = 0xe5c07AcF973Ccda3a141efbb2e829049591F938e;
    address constant WALLET3 = 0xC87C8BF777701ccFfB1230051E33f0524E5975b5;
    uint256 public basePrice = 0.1 * 10 ** 18;
    uint256 public maxPerWallet = 1;
    uint256 public maxPerTransaction = 5;
    uint256 public maxSupply = 10000;
    uint256 public preSalePhase = 1;
    bool public preSaleIsActive = true;
    bool public saleIsActive = false;
    address[] public contracts;
    address proxyRegistryAddress;
    string _baseTokenURI;
    bytes32 private merkleRoot;

    constructor(address _proxyRegistryAddress, bytes32 _root) ERC721A("WhitelistNFT MintPass", "WxMINT", 100) {
        proxyRegistryAddress = _proxyRegistryAddress;
        merkleRoot = _root;
    }

    struct ContractWhitelist {
        bool exists;
        NFT nft;
        uint256 usedSpots;
        uint256 availSpots;
    }
    mapping(address => ContractWhitelist) public contractWhitelist;

    struct Minter {
        bool exists;
        uint256 hasMintedByAddress;
        uint256 hasMintedByContract;

    }
    mapping(address => Minter) minters;

    function setBaseTokenURI(string memory _uri) public onlyOwner {
        _baseTokenURI = _uri;
    }

    function setRoot(bytes32 _root) public onlyOwner {
        merkleRoot = _root;
    }

    function baseTokenURI() virtual public view returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId)));
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function isWhitelistedByContract(address _address)
        public
        view
        returns (bool, uint256)
    {
        for (uint256 i = 0; i < contracts.length; i += 1) {
            if (
                contractWhitelist[contracts[i]].nft.balanceOf(_address) > 0 &&
                contractWhitelist[contracts[i]].usedSpots < contractWhitelist[contracts[i]].availSpots
            ) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function addContractToWhitelist(address _address, uint256 _availSpots)
        public
        onlyOwner
        returns (bool)
    {
        (bool _isWhitelisted, ) = isWhitelistedContract(_address);
        require(!_isWhitelisted,  "Contract already whitelisted.");
        contractWhitelist[_address].exists = true;
        contractWhitelist[_address].nft = NFT(_address);
        contractWhitelist[_address].availSpots = _availSpots;
        contracts.push(_address);
        return true;
    }

    function updateContractWhitelist(address _address, uint256 _availSpots)
        public
        onlyOwner
        returns (bool)
    {
        (bool _isWhitelisted, ) = isWhitelistedContract(_address);
        require(_isWhitelisted,  "Contract is not whitelisted.");
        contractWhitelist[_address].availSpots = _availSpots;
        return true;
    }

    function removeContractFromWhitelist(address _address)
        public
        onlyOwner
        returns (bool)
    {
        (bool _isWhitelisted, uint256 i) = isWhitelistedContract(_address);
        require(_isWhitelisted, "Contract is not whitelisted.");
        contracts[i] = contracts[contracts.length - 1];
        contracts.pop();
        delete contractWhitelist[_address];
        return true;
    }

    function isWhitelistedContract(address _address)
        internal
        view
        returns (bool, uint256)
    {
        for (uint256 i = 0; i < contracts.length; i += 1) {
            if (_address == contracts[i] && contractWhitelist[_address].exists) return (true, i);
        }
        return (false, 0);
    }


    function setPreSalePhase(uint8 _phase) public onlyOwner {
        require(_phase == 1 || _phase == 2, "Invalid presale phase.");
        preSalePhase = _phase;
    }

    function setBasePrice(uint256 _price) public onlyOwner {
        basePrice = _price;
    }

    function setMaxPerWallet(uint256 _maxToMint) public onlyOwner {
        maxPerWallet = _maxToMint;
    }

    function setMaxPerTransaction(uint256 _maxToMint) public onlyOwner {
        maxPerTransaction = _maxToMint;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipPreSaleState() public onlyOwner {
        preSaleIsActive = !preSaleIsActive;
    }

    function reserve(address _address, uint256 _quantity) public onlyOwner {
        _safeMint(_address, _quantity);
    }

    function preSalePrice() public view returns (uint256) {
        return getPrice();
    }

    function pubSalePrice() public view returns (uint256) {
        return getPrice();
    }

    function getPrice() public view returns (uint256) {
        if (totalSupply() >= 6101) {
            return basePrice * 4;
        } else if (totalSupply() >= 3101) {
            return basePrice * 3;
        } else if (totalSupply() >= 1101) {
            return basePrice * 2;
        } else {
            return basePrice;
        }
    }

    function verify(
        bytes32 leaf,
        bytes32[] memory proof
      )
        public
        view
        returns (bool)
      {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
          bytes32 proofElement = proof[i];

          if (computedHash <= proofElement) {
            // Hash(current computed hash + current element of the proof)
            computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
          } else {
            // Hash(current element of the proof + current computed hash)
            computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
          }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == merkleRoot;
    }

    // whitelist minting
    function mintPhase1(uint256 _quantity, bytes32[] memory proof) internal {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(verify(leaf, proof), "You are not on the whitelist.");
        require(minters[msg.sender].hasMintedByAddress + _quantity <= maxPerWallet, "Exceeds per wallet presale limit.");
        if (!minters[msg.sender].exists) minters[msg.sender].exists = true;
        minters[msg.sender].hasMintedByAddress = minters[msg.sender].hasMintedByAddress + _quantity;
        _safeMint(msg.sender, _quantity);
    }

    // partner minting
    function mintPhase2(uint256 _quantity) internal {
        (bool _isWhitelisted, uint256 idx) = isWhitelistedByContract(msg.sender);
        require(_isWhitelisted, "You are not a holder of a whitelisted collection with available spots remaining.");
        require(minters[msg.sender].hasMintedByContract + _quantity <= maxPerWallet, "Exceeds per wallet presale limit.");
        if (minters[msg.sender].exists) {
            if (minters[msg.sender].hasMintedByContract == 0) {
                contractWhitelist[contracts[idx]].usedSpots++;
            }
            minters[msg.sender].hasMintedByContract = minters[msg.sender].hasMintedByContract + _quantity;
        } else {
            minters[msg.sender].exists = true;
            minters[msg.sender].hasMintedByContract = _quantity;
            contractWhitelist[contracts[idx]].usedSpots++;
        }
        _safeMint(msg.sender, _quantity);
    }

    function mint(
        uint _quantity, 
        bytes32[] memory proof
        ) public payable {

        uint256 currentSupply = totalSupply();
        require(saleIsActive, "Sale is not active.");
        require(msg.value > 0, "Must send ETH to mint.");
        require(currentSupply <= maxSupply, "Sold out.");
        require(currentSupply + _quantity <= maxSupply, "Requested quantity would exceed total supply.");
        if(preSaleIsActive) {
            require(getPrice() * _quantity <= msg.value, "ETH sent is incorrect.");
            require(_quantity <= maxPerWallet, "Exceeds wallet presale limit.");
            if (preSalePhase == 1) {
                mintPhase1(_quantity, proof);
            }
            if (preSalePhase == 2) {
                mintPhase2(_quantity);
            }
        } else {
            require(getPrice() * _quantity <= msg.value, "ETH sent is incorrect.");
            require(_quantity <= maxPerTransaction, "Exceeds per transaction limit for public sale.");
            _safeMint(msg.sender, _quantity);
        }
    }

    function withdraw() external onlyOwner {
        uint256 totalBalance = address(this).balance;
        uint256 balance1 = totalBalance * 450/1000;
        uint256 balance2 = totalBalance * 225/1000;
        uint256 balance3 = totalBalance * 225/1000;
        payable(WALLET1).transfer(balance1);
        payable(WALLET2).transfer(balance2);
        payable(WALLET3).transfer(balance3);
        uint256 balance4 = totalBalance - (balance1 + balance2 + balance3);
        payable(msg.sender).transfer(balance4);
    }
}