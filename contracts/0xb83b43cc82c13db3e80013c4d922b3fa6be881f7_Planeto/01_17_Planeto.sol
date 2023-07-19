// SPDX-License-Identifier: MIT

/*
   ___    __       __    _      __  _____    ___ 
  / _ \  / /    /\ \ \  /_\    /__\/__   \  /___\
 / /_)/ / /    /  \/ / //_\\  /_\    / /\/ //  //
/ ___/ / /___ / /\  / /  _  \//__   / /   / \_// 
\/     \____/ \_\ \/  \_/ \_/\__/   \/    \___/ 
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Planeto is ERC721, Pausable, PaymentSplitter, Ownable {
    event Merge(uint256 indexed tokenIdA, uint256 indexed tokenIdB);

    uint256 constant private _supplyLimit = 10000;
    uint256 constant private _reserved = 100;

    address public immutable proxyRegistryAddress;
    address public immutable communityWallet;

    using MerkleProof for bytes32[];
    using Counters for Counters.Counter;
    Counters.Counter private _tokenSupply;

    mapping(address => bool) proxyToApproved;
    
    uint256 private latestTokenId = 0;
    bytes32 private _root;
    string private _baseTokenURI = "https://api.planeto.io/metadata/";
    uint256 private _price = 0.0981 ether;

    constructor(address _proxyRegistryAddress, address _communityWallet, address[] memory payees, uint256[] memory shares_) ERC721("Planeto", "PLNT") PaymentSplitter(payees, shares_) {
        proxyRegistryAddress = _proxyRegistryAddress;
        communityWallet = _communityWallet;
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!paused(), "ERC721Pausable: token transfer while paused");
    }

    function mint(uint256 num) public payable whenNotPaused {
        uint256 supply = _tokenSupply.current();

        require(num > 0 && num < 21, "Amount not valid" );
        require(supply + num < _supplyLimit, "Exceeds Planet supply" );
        require(msg.value >= _price * num, "Ether sent not correct" );

        _mintPlaneto(num, _msgSender());
    }

    function freeMint(bytes32[] calldata proof) public whenNotPaused {
        address account = _msgSender();

        require(proof.verify(_root, _leaf(account)), "Invalid proof");
        require(balanceOf(account) == 0, "Minted before");

        _mintPlaneto(1, account);
    }

    function merge(uint256 tokenIdA, uint256 tokenIdB) public {
        require(ownerOf(tokenIdA) == _msgSender() , "Planeto: not owner of tokenIdA");
        require(ownerOf(tokenIdB) == _msgSender() , "Planeto: not owner of tokenIdB");

        _burn(tokenIdB);
        _tokenSupply.decrement();

        emit Merge(tokenIdA, tokenIdB);
    }

    function collectReserves() external onlyOwner {
        require(_tokenSupply.current() == 0, 'Reserves already taken.');
        _mintPlaneto(_reserved, communityWallet);
    }

    function _mintPlaneto(uint256 num, address account) private {
        require(num > 0, "Amount not valid");

        if (num == 1) {
            _tokenSupply.increment();
            _safeMint(account, latestTokenId);
            latestTokenId += 1;
        } else {
            uint256 tokenId = latestTokenId;
            for(uint256 i; i < num; i++){
                _tokenSupply.increment();
                _safeMint(account, tokenId);
                tokenId += 1;
            }
            latestTokenId = tokenId;
        }
    }

    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    function setRoot(bytes32 root) public onlyOwner {
        _root = root;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        _price = _newPrice;
    }

    function setPaused(bool paused) public onlyOwner {
        if (paused) {
            _pause();
        } else {
            _unpause();
        }
    }

    function totalSupply() public view returns (uint256) {
        return _tokenSupply.current();
    }

    function flipProxyState(address proxyAddress) public onlyOwner {
        proxyToApproved[proxyAddress] = !proxyToApproved[proxyAddress];
    }

    function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == operator ||
        proxyToApproved[operator]) return true;
        return super.isApprovedForAll(_owner, operator);
    }
}

contract OwnableDelegateProxy {}
contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}