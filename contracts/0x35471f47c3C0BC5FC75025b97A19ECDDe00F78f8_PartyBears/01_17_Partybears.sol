// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract PartyBears is
    ERC721Enumerable,
    ERC721URIStorage,
    ReentrancyGuard,
    Ownable
{
    using ECDSA for bytes32;
    using Address for address;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    enum State {
        Setup,
        PreParty,
        PartyBear, 
        Finished
    }
    
    State private _state;
    address private _signer;
    string private _tokenUriBase;
    uint256 public constant MAX_BEARS = 9669;
    uint256 public constant MAX_MINT = 5;
    uint256 private BEAR_PRICE = 9E16; // 0.09 ETH
    mapping(bytes => bool) public usedToken;
    mapping(address => bool) public presaleMinted;
    event Minted(address minter, uint256 amount);
    event StateChanged(State _state);
    event SignerChanged(address signer);
    event BalanceWithdrawed(address recipient, uint256 value);

    constructor(address signer) ERC721("Party Bears", "PartyBears") {
        _signer = signer;
        _state = State.Setup;
    }

    function updateMintPrice(uint256 __price) public onlyOwner {
        BEAR_PRICE = __price;
    }

    function updateSigner(address __signer) public onlyOwner {
        _signer = __signer;
    }

    function _hash(string calldata salt, address _address)
        public
        view
        returns (bytes32)
    {
        return keccak256(abi.encode(salt, address(this), _address));
    }

    function _verify(bytes32 hash, bytes memory token)
        public
        view
        returns (bool)
    {
        return (_recover(hash, token) == _signer);
    }

    function _recover(bytes32 hash, bytes memory token)
        public
        pure
        returns (address)
    {
        return hash.toEthSignedMessageHash().recover(token);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return
            string(abi.encodePacked(baseTokenURI(), Strings.toString(tokenId)));
    }

    function baseTokenURI() public view virtual returns (string memory) {
        return _tokenUriBase;
    }

    function setTokenURI(string memory tokenUriBase_) public onlyOwner {
        _tokenUriBase = tokenUriBase_;
    }

    function setStateToSetup() public onlyOwner {
        _state = State.Setup;
    }
    
    function startPreParty() public onlyOwner {
        _state = State.PreParty;
    }

    function setStateToParty() public onlyOwner {
        _state = State.PartyBear;
    }
    
    function setStateToFinished() public onlyOwner {
        _state = State.Finished;
    }

    function presaleMint(string calldata salt, bytes calldata token)
        external
        payable
        nonReentrant
    {
        require(_state == State.PreParty, "Presale is not active.");
        require(
            !Address.isContract(msg.sender),
            "Contracts are not allowed to party with bears."
        );
        require(
            !presaleMinted[msg.sender],
            "The wallet address has already minted in presale."
        );
        require(
            _tokenIds.current() + 1 <= MAX_BEARS,
            "Max supply of tokens exceeded."
        );
        require(msg.value >= BEAR_PRICE, "Ether value sent is incorrect.");
        require(_verify(_hash(salt, msg.sender), token), "Invalid token.");
        uint256 newItemId = _tokenIds.current();
        _safeMint(msg.sender, newItemId);
        _tokenIds.increment();
        presaleMinted[msg.sender] = true;
        emit Minted(msg.sender, 1);
    }

    function mint(
        string calldata salt,
        bytes calldata token,
        uint256 amount
    ) external payable nonReentrant {
        require(_state == State.PartyBear, "Sale is not active.");
        require(
            !Address.isContract(msg.sender),
            "Contracts are not allowed to party with bears."
        );
        require(
            amount <= MAX_MINT,
            "You can only bring 5 Party Bears to dance per transaction."
        );
        require(
            _tokenIds.current() + amount <= MAX_BEARS,
            "Amount should not exceed max supply of Party Bears."
        );
        require(
            msg.value >= BEAR_PRICE * amount,
            "Ether value sent is incorrect."
        );
        require(!usedToken[token], "The token has been used.");
        require(_verify(_hash(salt, msg.sender), token), "Invalid token.");
        for (uint256 i = 0; i < amount; i++) {
            uint256 newItemId = _tokenIds.current();
            _safeMint(msg.sender, newItemId);
            _tokenIds.increment();
        }
        usedToken[token] = true;
        emit Minted(msg.sender, amount);
    }

    function withdrawAll(address recipient) public onlyOwner {
        uint256 balance = address(this).balance;
        payable(recipient).transfer(balance);
        emit BalanceWithdrawed(recipient, balance);
    }

    function withdrawAllViaCall(address payable _to) public onlyOwner {
        uint256 balance = address(this).balance;
        (bool sent, bytes memory data) = _to.call{value: balance}("");
        require(sent, "Failed to send Ether");
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}