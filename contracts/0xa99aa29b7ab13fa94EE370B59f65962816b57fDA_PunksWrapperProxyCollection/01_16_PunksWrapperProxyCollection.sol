// SPDX-License-Identifier: MIT
/// @title PunksWrapperProxy
/// @notice Punks Wrapper that proxies calls to CryptoPunksMarket.  Based on PunksV1Wrapper by @FrankPoncelet.  Acts as a wrapper, but also sends operations to CryptoPunksMarket, so that, for example, a punk can be listed in the punks market at the same time as it's listed in other ERC721-compatible markets
/// @author CyberPnk <[email protected]>
//        __________________________________________________________________________________________________________
//       _____/\/\/\/\/\______________/\/\________________________________/\/\/\/\/\________________/\/\___________
//      ___/\/\__________/\/\__/\/\__/\/\__________/\/\/\____/\/\__/\/\__/\/\____/\/\__/\/\/\/\____/\/\__/\/\_____
//     ___/\/\__________/\/\__/\/\__/\/\/\/\____/\/\/\/\/\__/\/\/\/\____/\/\/\/\/\____/\/\__/\/\__/\/\/\/\_______
//    ___/\/\____________/\/\/\/\__/\/\__/\/\__/\/\________/\/\________/\/\__________/\/\__/\/\__/\/\/\/\_______
//   _____/\/\/\/\/\________/\/\__/\/\/\/\______/\/\/\/\__/\/\________/\/\__________/\/\__/\/\__/\/\__/\/\_____
//  __________________/\/\/\/\________________________________________________________________________________
// __________________________________________________________________________________________________________

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@cyberpnk/solidity-library/contracts/RendererLockable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ICryptoPunksMarket.sol";
import "./PunksWrapperProxy.sol";
import "./IPunksWrapperProxyCollectionRenderer.sol";

contract PunksWrapperProxyCollection is Ownable, ERC721, ReentrancyGuard, RendererLockable {
    address public cryptoPunksMarket;
    uint256 public tokenSupply;

    mapping (address => address) public proxyForPunksOwner;
    mapping (address => address) public punksOwnerForProxy;

    event ProxyCreated(address indexed sender, address indexed contractAddress);
    event Withdrawal(address indexed sender);

    modifier onlyWrappedAndOwnedBySender(uint punkId) {
        address proxyFromSender = proxyForPunksOwner[msg.sender];
        address proxyFromPunk = ownerInCryptoPunksMarket(punkId);
        address wrapperOwner = ownerOfWrapper(punkId);

        require(wrapperOwner != address(0x0) && proxyFromPunk != address(0x0), "Not wrapped");
        require(wrapperOwner == msg.sender, "Not yours");
        require(proxyFromSender != address(0x0), "No proxy");
        require(proxyFromPunk == proxyFromSender, "Not wrapped by you");
      _;
   }

    constructor(address _cryptoPunksMarket, address _renderer) ERC721("Punks Wrapper Proxy", "PWP") Ownable() {
        cryptoPunksMarket = _cryptoPunksMarket;
        setRenderer(_renderer);
    }

    function createProxy() external {
        require(proxyForPunksOwner[msg.sender] == address(0x0), "Has proxy");
        PunksWrapperProxy newContract = new PunksWrapperProxy(cryptoPunksMarket, msg.sender);
        proxyForPunksOwner[msg.sender] = address(newContract);
        punksOwnerForProxy[address(newContract)] = msg.sender;

        emit ProxyCreated(msg.sender, address(newContract));
    }

    function wrap(uint _punkId) nonReentrant external payable {
        require(proxyForPunksOwner[msg.sender] != address(0x0), "No proxy");
        PunksWrapperProxy(payable(proxyForPunksOwner[msg.sender])).acquire{value: msg.value}(_punkId, msg.sender);

        tokenSupply +=1;
        _mint(msg.sender, _punkId);
    }

    function unwrap(uint256 _punkId) nonReentrant external {
        require(!isEmptyWrapper(_punkId), "Empty wrapper");
        require(ownerOf(_punkId) == msg.sender, "Not yours");
        address proxy = ICryptoPunksMarket(cryptoPunksMarket).punkIndexToAddress(_punkId);
        require(punksOwnerForProxy[proxy] != address(0x0), "Not owned by proxy");

        _burn(_punkId);
        tokenSupply -=1;
        
        PunksWrapperProxy(payable(proxy)).transferPunk(_punkId, msg.sender);
    }

    function discardEmptyWrapper(uint256 _punkId) nonReentrant external {
        require(isEmptyWrapper(_punkId), "Not empty wrapper");
        require(ownerOf(_punkId) == msg.sender, "Not yours");

        _burn(_punkId);
        tokenSupply -=1;
    }

    function rewrapFullWrapper(uint256 tokenId) nonReentrant external {
        address callersProxy = proxyForPunksOwner[msg.sender];
        address proxyFromPunk = ownerInCryptoPunksMarket(tokenId);

        require(callersProxy != address(0x0), "No proxy");
        require(_exists(tokenId), "Not wrapped");
        require(ownerOf(tokenId) == msg.sender, "Not yours");
        require(!isEmptyWrapper(tokenId), "Empty wrapper");
        require(ownerOfWrapper(tokenId) == msg.sender, "Not your wrapper");
        require(callersProxy != proxyFromPunk, "Already wrapped by you");

        PunksWrapperProxy(payable(proxyFromPunk)).transferPunk(tokenId, callersProxy);
    }

    function rewrapEmptyWrapper(uint256 tokenId) nonReentrant external payable {
        address callersProxy = proxyForPunksOwner[msg.sender];

        require(callersProxy != address(0x0), "No proxy");
        require(_exists(tokenId), "Not wrapped");
        require(ownerOf(tokenId) == msg.sender, "Not yours");
        require(isEmptyWrapper(tokenId), "Not empty wrapper");

        //burn and mint instead of transfer because an empty wrapper can't be transferred
        _burn(tokenId);
        PunksWrapperProxy(payable(callersProxy)).acquire{value: msg.value}(tokenId, msg.sender);
        _mint(msg.sender, tokenId);
    }

    function exists(uint256 tokenId) external view virtual returns (bool) {
        return _exists(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Not wrapped");
        return IPunksWrapperProxyCollectionRenderer(renderer).getTokenURI(tokenId, isEmptyWrapper(tokenId));
    }

    function contractURI() external view returns(string memory) {
        return IPunksWrapperProxyCollectionRenderer(renderer).getContractURI();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        require(punksOwnerForProxy[to] == address(0x0), "Can't transfer to proxy");
        if (to != address(0x0)) {
            require(!isEmptyWrapper(tokenId), "Can't transfer empty wrapper");
        }
        if (from != address(0x0)) {
            if (isOwnerInCryptoPunksMarketProxy(tokenId)) {
                address proxy = ownerInCryptoPunksMarket(tokenId);
                PunksWrapperProxy(payable(proxy)).beforeTransferRemoveFromSale(tokenId);
            }
        }
    }

    function ownerInCryptoPunksMarket(uint tokenId) public view returns(address) {
        return ICryptoPunksMarket(cryptoPunksMarket).punkIndexToAddress(tokenId);
    }

    function proxyOwnerFromPunk(uint tokenId) public view returns(address) {
        address ownerInPunks = ownerInCryptoPunksMarket(tokenId);
        return punksOwnerForProxy[ownerInPunks];
    }

    function isOwnerInCryptoPunksMarketProxy(uint punkId) public view returns(bool) {
        return proxyOwnerFromPunk(punkId) != address(0x0);
    }

    function isEmptyWrapper(uint tokenId) public view returns(bool) {
        return !isOwnerInCryptoPunksMarketProxy(tokenId);
    }

    function ownerOfWrapper(uint tokenId) public view returns(address) {
        return super.ownerOf(tokenId);
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "Not wrapped");

        if (isEmptyWrapper(tokenId)) {
            return ownerInCryptoPunksMarket(tokenId);
        }

        return ownerOfWrapper(tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view override returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || super.isApprovedForAll(owner, spender) || super.getApproved(tokenId) == spender);
    }


    function withdraw() external {
        address proxyFromSender = proxyForPunksOwner[msg.sender];
        require(proxyFromSender != address(0x0), "No proxy");
        PunksWrapperProxy(payable(proxyFromSender)).withdraw();
        emit Withdrawal(msg.sender);
    }

    function offerPunkForSaleToAddress(uint id, uint minSalePriceInWei, address to) external onlyWrappedAndOwnedBySender(id) {
        PunksWrapperProxy(payable(proxyForPunksOwner[msg.sender])).offerPunkForSaleToAddress(id, minSalePriceInWei, to);
    }

    function offerPunkForSale(uint id, uint minSalePriceInWei) external onlyWrappedAndOwnedBySender(id) {
        PunksWrapperProxy(payable(proxyForPunksOwner[msg.sender])).offerPunkForSale(id, minSalePriceInWei);
    }

    function punkNoLongerForSale(uint id) external onlyWrappedAndOwnedBySender(id) {
        PunksWrapperProxy(payable(proxyForPunksOwner[msg.sender])).punkNoLongerForSale(id);
    }

    function acceptBidForPunk(uint punkIndex, uint minPrice) external onlyWrappedAndOwnedBySender(punkIndex) {
        PunksWrapperProxy(payable(proxyForPunksOwner[msg.sender])).acceptBidForPunk(punkIndex, minPrice);
    }

}