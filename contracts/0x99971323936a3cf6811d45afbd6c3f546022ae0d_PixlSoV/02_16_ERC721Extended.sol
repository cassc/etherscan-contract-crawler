// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../base/OwnableRecoverable.sol";

// ERC721Extended wraps multiple commonly used base contracts into a single contract
// 
// it includes:
//  ERC721 with Enumerable
//  contract ownership & recovery
//  contract pausing
//  base uri management
//  treasury 
//  proxy registry for opensea
//  ERC2981 

abstract contract ERC721Extended is ERC721Enumerable, Pausable, OwnableRecoverable 
{   
    // the treasure address that can make withdrawals from the contract balance
    address public treasury;

    // the base url used for all meta data 
    // used for tokens and for the contract
    string private _baseTokenURI;

    // support for ERC2981
    uint16 private _royaltyFee;
    address private _royaltyReciever;    

    // the opensea proxy registry contract (can be changed if this registry ever moves to a new contract)
    // 0xa5409ec958C83C3f309868babACA7c86DCB077c1  mainnet
    // 0xF57B2c51dED3A29e6891aba85459d600256Cf317  rinkeby
    // 0x0000000000000000000000000000000000000000  local
    address private _proxyRegistryAddress;
    
    constructor(address _owner, address _recovery, address _treasury, string memory _baseUri, address proxyRegistryAddress)  
    {
        // set the owner, recovery & treasury addresses
        transferOwnership(_owner);
        recovery = _recovery;
        treasury = _treasury;

        // set the meta base url
        _baseTokenURI = _baseUri;

        // set the open sea proxy registry address
        _proxyRegistryAddress = proxyRegistryAddress;

        // royalties
        _royaltyFee = 250;
        _royaltyReciever = _owner;
    }

    // used to stop a contract function from being reentrant-called 
    bool private _reentrancyLock = false;
    modifier reentrancyGuard {
        require(!_reentrancyLock, "reentrant");
 
        _reentrancyLock = true;
        _;
        _reentrancyLock = false;
    }


    /// PAUSING

    // only the contract owner can pause and unpause
    // can't pause if already paused
    // can't unpause if already unpaused
    // disables minting, burning, transfers (including marketplace accepted offers)

    function pause(bool on_off) external virtual onlyOwner {        
        if (on_off) _pause(); 
        else _unpause();      
    }
    // function unpause() external virtual onlyOwner {
    //     _unpause();
    // }

    // this hook is called by _mint, _burn & _transfer 
    // it allows us to block these actions while the contract is paused
    // also prevent transfers to the contract address
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        require(to != address(this), "to is contract");
        
        super._beforeTokenTransfer(from, to, tokenId);

        require(!paused(), "contract paused");
    }


    /// NAMES

    function setName(string memory name_, string memory symbol_) external onlyOwner {
        ERC721._name = name_;
        ERC721._symbol = symbol_;
    }

    /// TREASURY

    // can only be called by the contract owner
    // withdrawals can only be made to the treasury account

    // allows for a dedicated address to be used for withdrawals
    function setTreasury(address newTreasury) external onlyOwner { 
        require(newTreasury!=address(0), "0 address");
        treasury = newTreasury;
    }

    // funds can be withdrawn to the treasury account for safe keeping
    function treasuryOut(uint amount) external onlyOwner reentrancyGuard {
        
        // can withdraw any amount up to the account balance (0 will withdraw everything)
        uint balance = address(this).balance;
        if(amount == 0 || amount > balance) amount = balance;

        // make the withdrawal
        (bool success, ) = treasury.call{value:amount}("");
        require(success, "call fail");
    }
    
    // the owner can pay funds in at any time although this is not needed
    // perhaps the contract needs to hold a certain balance in future for some external requirement
    function treasuryIn() external payable onlyOwner {

    } 


    /// BASE URI

    // base uri is where the metadata lives
    // only the owner can change this

    function setBaseURI(string memory baseTokenURI) external onlyOwner {
        _baseTokenURI = baseTokenURI;
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    function contractURI() public view returns (string memory) {
        return bytes(_baseTokenURI).length > 0 ? string(abi.encodePacked(_baseTokenURI, "contract")) : "";
    }


    /// PROXY REGISTRY

    // registers a proxy address for OpenSea or others
    // can only be changed by the contract owner
    // setting address to 0 will disable the proxy 

    function setProxyRegistry(address proxyRegistry) external onlyOwner { 

        // check the contract address is correct (will revert if not)
        if(proxyRegistry!= address(0)) {
            ProxyRegistry(proxyRegistry).proxies(address(0));
        }

        _proxyRegistryAddress = proxyRegistry;    
    }

    // this override allows us to whitelist user's OpenSea proxy accounts to enable gas-less listings
    function isApprovedForAll(address token_owner, address operator) public view override returns (bool)
    {
        // whitelist OpenSea proxy contract for easy trading.
        if(_proxyRegistryAddress!= address(0)) {
            ProxyRegistry proxyRegistry = ProxyRegistry(_proxyRegistryAddress);
            if (address(proxyRegistry.proxies(token_owner)) == operator) {
                return true;
            }
        }

        return super.isApprovedForAll(token_owner, operator);
    }


    /// ERC2981 support

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == 0x2a55205a  // ERC2981
               || super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount)
    {
        return (_royaltyReciever, (salePrice * _royaltyFee) / 10000);
    }

    // the royalties fee is set in basis points (eg. 250 basis points = 2.5%)
    function setRoyalties(address newReceiver, uint16 basisPoints) external onlyOwner {
        require(basisPoints <= 10000);
        _royaltyReciever = newReceiver;
        _royaltyFee = basisPoints;
    }

}

// used to whitelist proxy accounts of OpenSea users so that they are automatically able to trade any item on OpenSea
contract OwnableDelegateProxy {}
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}