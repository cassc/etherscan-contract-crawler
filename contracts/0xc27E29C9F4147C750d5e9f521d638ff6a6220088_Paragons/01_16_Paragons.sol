// SPDX-License-Identifier: MIT

// @title: Paragons
// @author: Paradox

//      ___
//    / __ \ ____ __________ _____ _____  ____  ____
//  / /_/  / __ `/ ___/ __ `/ __ `/ __ \/ __ \/ ___/
// / ____/ /_/ / /  / /_/ / /_/ / /_/ / / / (__  )
//_/    \__,_/_/   \__,_/\__, /\____/_/ /_/____/
//                     /____/


pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/Counters.sol';
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

contract Paragons is ERC721Enumerable, Ownable, ReentrancyGuard {

    using ECDSA for bytes32;
    using Counters for Counters.Counter;
    using Address for address payable;

    Counters.Counter private _tokenIds;

    enum State {
        Setup,
        PreSale,
        Sale,
        Pause
    }

    State private state;

    address private _signer;

    uint256 public constant MAX_PARAGONS = 9424;
    uint256 public constant MAX_PURCHASE_PER_TX = 5;
    uint256 public constant AMOUNT_RESERVED = 400;
    uint256 public RESERVED_AMOUNT_MINTED = 0;
    uint256 public constant PARAGON_PRICE = 0.15 ether;

    mapping(bytes => bool) public usedToken;
    mapping(address => uint) public presaleMinted;

    address payable[] private _communityWallet = [payable(address(0x001394722c2eAC08767bEB7DE6fdBcADe2c43483))];
    address payable[] private _artistWallet = [payable(address(0x7953319DeEdCEbD8ef845bC9Ea1cdfA08A29228a))];
    address payable[] private _devWallets = [payable(address(0x1110F53856674AAeCE08309530aBBE86138a1450)), payable(address(0x930CbFFA8361fFca05f70aA2B39B189B4EAE302f))];
    address payable[] private _marketingWallets = [payable(address(0xCac83515113e9Ece5CF63c4FA7BF1a0e79ab5B72)), payable(address(0xe4bae9B138f84a420F41a9238a491e16F50563eb)), payable(address(0x0d96C944ff359B12De16e1bCFe43985b6FB8C7B4)), payable(address(0x79a0Ba15C7bF6BE94Ee74BA053DE73b4Bd4C508C))];
    address payable[] private _advisorWallet = [payable(address(0x054838FB00e7B33318B43fC9511eABFED192652b))];

    event Minted(address minter, uint256 amount);
    event StateChanged(State state);
    event BaseURIChanged(string newBaseURI);
    event SignerChanged(address signer);

    string public baseURI;

    constructor(address signer) ERC721("PARAGONS","PARAGONS") {
        _signer = signer;
    }

    function _hash(string calldata salt, address _address, uint amount, uint allowedAmount) internal view returns (bytes32){
        return keccak256(abi.encode(salt, address(this), _address, amount, allowedAmount));
    }

    function _verify(bytes32 hash, bytes memory token) internal view returns (bool){
        return (_recover(hash, token) == _signer);
    }

    function _recover(bytes32 hash, bytes memory token) internal pure returns (address){
        return hash.toEthSignedMessageHash().recover(token);
    }

    function setState(State _state) external onlyOwner {
        state = _state;
        emit StateChanged(state);
    }

    function getState() public view returns (State) {
        return state;
    }

    function mintReserve(address reserveAddress, uint amount) public onlyOwner {
        require(RESERVED_AMOUNT_MINTED + amount <= AMOUNT_RESERVED, "Reserved Amount is over the reserve limit.");
        for(uint256 i = 0; i < amount; i++) {
            _safeMint(reserveAddress, _tokenIds.current());
            _tokenIds.increment();
        }
        RESERVED_AMOUNT_MINTED += amount;
    }

    function presaleMint(string calldata salt, bytes calldata token, uint256 amount, uint allowedAmount) external payable nonReentrant {
        require(state == State.PreSale, 'Presale is not active.');
        require(!Address.isContract(msg.sender), 'Contracts are not allowed to mint.');
        require(presaleMinted[msg.sender] + amount <= allowedAmount, 'The wallet is trying to mint more than allowed.');
        require(_tokenIds.current() + amount <= MAX_PARAGONS, 'Amount should not exceed max supply of tokens.');
        require(_verify(_hash(salt, msg.sender, amount, allowedAmount), token), 'Invalid token.');
        require(msg.value >= PARAGON_PRICE, 'Ether value sent is incorrect.');

        for (uint256 i = 0; i < amount; i++) {
            uint256 newItemId = _tokenIds.current();
            _safeMint(msg.sender, newItemId);
            _tokenIds.increment();
        }
        presaleMinted[msg.sender] += amount;
        emit Minted(msg.sender, amount);
    }

    function mint(string calldata salt, bytes calldata token, uint256 amount) external payable nonReentrant {
        require(state == State.Sale, 'Sale is not active.');
        require(!Address.isContract(msg.sender), 'Contracts are not allowed to mint.');
        require(amount <= MAX_PURCHASE_PER_TX, 'Amount should not exceed Max purchase per transaction.');
        require(_tokenIds.current() + amount <= MAX_PARAGONS, 'Amount should not exceed max supply of tokens.');
        require(msg.value >= PARAGON_PRICE * amount, 'Ether value sent is incorrect.');
        require(_verify(_hash(salt, msg.sender, amount, MAX_PURCHASE_PER_TX), token), 'Invalid token.');
        require(!usedToken[token], 'The token has been used.');

        for (uint256 i = 0; i < amount; i++) {
            uint256 newItemId = _tokenIds.current();
            _safeMint(msg.sender, newItemId);
            _tokenIds.increment();
        }

        usedToken[token] = true;
        emit Minted(msg.sender, amount);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
        emit BaseURIChanged(newBaseURI);
    }

     function withdrawAllEth() public virtual onlyOwner {
         uint256 currentBalance = address(this).balance;
         uint8 communityPercent = 10;
         uint8 artistPercent = 16;
         uint8 devPercent = 15;
         uint8 marketingPercent = 10;
         uint8 advisorPercent = 4;
         _artistWallet[0].transfer(currentBalance * artistPercent / 100);
        for(uint8 i = 0; i < _devWallets.length; i++) {
            _devWallets[i].transfer(currentBalance * devPercent / 100);
        }
        for(uint8 i = 0; i < _marketingWallets.length; i++) {
            _marketingWallets[i].transfer(currentBalance * marketingPercent / 100);
        }
         _communityWallet[0].transfer(currentBalance * communityPercent / 100);
         _advisorWallet[0].transfer(currentBalance * advisorPercent / 100);
     }

    function setSigner(address signer) external onlyOwner {
        _signer = signer;
        emit SignerChanged(signer);
    }
}