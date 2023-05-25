// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";

abstract contract NFT {
    function balanceOf(address owner)
        public
        view
        virtual
        returns (uint256 balance);
}

abstract contract MintPass {
    function balanceOf(address owner, uint256 id)
        public
        view
        virtual
        returns (uint256 balance);
}

/**
 * @title Paradise
 * Paradise - a contract for Paradise Trippies
 */
contract Paradise is ERC721Tradable {

    using SafeMath for uint256;
    bool public preSaleIsActive = true;
    bool public saleIsActive = false;
    address constant WALLET1 = 0xffe5CBCDdF2bd1b4Dc3c00455d4cdCcf20F77587;
    address constant WALLET2 = 0xA6AAEa8BFA339f602906413CfD22f281eb480D6F;
    uint256 public preSalePhase = 1;
    uint256 public maxSupply = 10000;
    uint256 public preSalePrice = 70000000000000000;
    uint256 public pubSalePrice = 70000000000000000;
    uint256 public maxPerWallet = 3;
    uint256 public maxPerTransaction = 5;
    string _baseTokenURI;
    address[] public contracts;
    MintPass mintpass;

    constructor(
        address _proxyRegistryAddress,
        string memory _name,
        string memory _symbol,
        address _mintPassAddress
    ) ERC721Tradable(_name, _symbol, _proxyRegistryAddress) {
        mintpass = MintPass(_mintPassAddress);
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
        uint256 hasMintedByMintPass;
        uint256 hasMintedByContract;
    }
    mapping(address => Minter) public minters;

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

    function isWhitelisted(address _address)
        public
        view
        returns (bool)
    {
        if (preSaleIsActive && preSalePhase == 1) {
            return isWhitelistedByMintPass(_address);
        }
        if (preSaleIsActive && preSalePhase == 2) {
            (bool _isWhitelisted, ) = isWhitelistedByContract(_address);
            return _isWhitelisted;
        }
        return false;
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

    function isWhitelistedByMintPass(address _address)
        public
        view
        returns (bool)
    {
        return mintpass.balanceOf(_address, 1) > 0;
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

    function setPubSalePrice(uint256 _price) external onlyOwner {
        pubSalePrice = _price;
    }

    function setPreSalePrice(uint256 _price) external onlyOwner {
        preSalePrice = _price;
    }

    function baseTokenURI() override virtual public view returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseTokenURI(string memory _uri) public onlyOwner {
        _baseTokenURI = _uri;
    }

    function setMaxPerWallet(uint256 _maxToMint) external onlyOwner {
        maxPerWallet = _maxToMint;
    }

    function setMaxPerTransaction(uint256 _maxToMint) external onlyOwner {
        maxPerTransaction = _maxToMint;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipPreSaleState() public onlyOwner {
        preSaleIsActive = !preSaleIsActive;
    }

    function setPreSalePhase(uint8 _phase) public onlyOwner {
        // 1 = mintpasses, 2 = wl contracts
        require(_phase == 1 || _phase == 2, "Invalid presale phase.");
        preSalePhase = _phase;
    }

    function reserve(address _address, uint256 _quantity) public onlyOwner {
        uint i;
        for (i = 0; i < _quantity; i++) {
            mintTo(_address);
        }
    }

    function mint(uint _quantity) public payable {
        require(saleIsActive, "Sale is not active.");
        require(totalSupply() <= maxSupply, "Sold out.");
        require(totalSupply().add(_quantity) <= maxSupply, "Requested quantity would exceed total supply.");
        if(preSaleIsActive) {
            require(preSalePrice.mul(_quantity) <= msg.value, "ETH sent is incorrect.");
            require(_quantity <= maxPerWallet, "Exceeds wallet presale limit.");
            if (preSalePhase == 1) {
                require(isWhitelistedByMintPass(msg.sender), "You do not have a MintPass.");
                require(
                    minters[msg.sender].hasMintedByMintPass.add(_quantity) <=
                        maxPerWallet,
                    "Exceeds per wallet presale limit."
                );
                if (!minters[msg.sender].exists) minters[msg.sender].exists = true;
                minters[msg.sender].hasMintedByMintPass = minters[msg.sender].hasMintedByMintPass.add(
                    _quantity
                );
            }
            if (preSalePhase == 2) {
                (bool _isWhitelisted, uint256 i) = isWhitelistedByContract(msg.sender);
                require(_isWhitelisted, "You are not a holder of a whitelisted collection with available spots remaining.");
                require(
                    minters[msg.sender].hasMintedByContract.add(_quantity) <=
                        maxPerWallet,
                    "Exceeds per wallet presale limit."
                );
                if (minters[msg.sender].exists) {
                    if (minters[msg.sender].hasMintedByContract == 0) {
                        contractWhitelist[contracts[i]].usedSpots = contractWhitelist[contracts[i]].usedSpots.add(1);
                    }
                    minters[msg.sender].hasMintedByContract = minters[msg.sender].hasMintedByContract.add(
                        _quantity
                    );
                } else {
                    minters[msg.sender].exists = true;
                    minters[msg.sender].hasMintedByContract = _quantity;
                    contractWhitelist[contracts[i]].usedSpots = contractWhitelist[contracts[i]].usedSpots.add(1);
                }
            }
        } else {
            require(pubSalePrice.mul(_quantity) <= msg.value, "ETH sent is incorrect.");
            require(_quantity <= maxPerTransaction, "Exceeds per transaction limit for public sale.");
        }
        for(uint i = 0; i < _quantity; i++) {
            mintTo(msg.sender);
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        uint256 wallet1Balance = balance.mul(10).div(100);
        uint256 wallet2Balance = balance.mul(19).div(100);
        payable(WALLET1).transfer(wallet1Balance);
        payable(WALLET2).transfer(wallet2Balance);
        payable(msg.sender).transfer(
            balance.sub(wallet1Balance.add(wallet2Balance))
        );
    }
}