//
//   /$$$$$$$$          /$$     /$$
//  |__  $$__/         | $$    | $$
//     | $$  /$$$$$$  /$$$$$$ /$$$$$$    /$$$$$$   /$$$$$$
//     | $$ |____  $$|_  $$_/|_  $$_/   /$$__  $$ /$$__  $$
//     | $$  /$$$$$$$  | $$    | $$    | $$  \ $$| $$  \ $$
//     | $$ /$$__  $$  | $$ /$$| $$ /$$| $$  | $$| $$  | $$
//     | $$|  $$$$$$$  |  $$$$/|  $$$$/|  $$$$$$/|  $$$$$$/
//     |__/ \_______/   \___/   \___/   \______/  \______/
//
//
//
//    /$$$$$$              /$$     /$$             /$$
//   /$$__  $$            | $$    |__/            | $$
//  | $$  \ $$  /$$$$$$  /$$$$$$   /$$  /$$$$$$$ /$$$$$$   /$$$$$$$
//  | $$$$$$$$ /$$__  $$|_  $$_/  | $$ /$$_____/|_  $$_/  /$$_____/
//  | $$__  $$| $$  \__/  | $$    | $$|  $$$$$$   | $$   |  $$$$$$
//  | $$  | $$| $$        | $$ /$$| $$ \____  $$  | $$ /$$\____  $$
//  | $$  | $$| $$        |  $$$$/| $$ /$$$$$$$/  |  $$$$//$$$$$$$/
//  |__/  |__/|__/         \___/  |__/|_______/    \___/ |_______/
//
// Author: Olive

pragma solidity >=0.8.0 <0.9.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract TattooArtists is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string public _baseTokenURI;
    string public hiddenMetadataUri;

    uint256 public cost = 1 ether;
    uint256 public freemint_supply = 6428;
    uint256 public maxSupply = 6428;
    uint256 public maxMintAmountPerTx = 3;
    uint256 public timeLimit = 60;

    bool public paused = true;
    bool public revealed = false;

    bool public isSignature = true;
    bool public isFreemintOpen = false;

    mapping(address => bool) internal admins;

    modifier onlyAdmin() {
        require(admins[_msgSender()], "Caller is not the admin");
        _;
    }


    
    constructor(string memory _hiddenMetadataUri)
        ERC721A("Tattoo Artists", "TA")
    {
        setHiddenMetadataUri(_hiddenMetadataUri);
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function mint(
        uint256 _mintAmount,
        uint256 _timestamp,
        bytes memory _signature
    ) public payable nonReentrant {
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
            "Invalid mint amount!"
        );
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        require(!paused, "The contract is paused!");
        require(msg.value >= cost * _mintAmount, "Insufficient funds!");

        address wallet = _msgSender();
        if (isSignature) {
            address signerOwner = signatureWallet(
                wallet,
                _mintAmount,
                _timestamp,
                _signature
            );
            require(signerOwner == owner(), "Not authorized to mint");

            require(block.timestamp >= _timestamp - 30, "Out of time");

            _safeMint(wallet, _mintAmount);
        } else {
            _safeMint(wallet, _mintAmount);
        }
    }

    function setSignature(bool _isSignature) public onlyOwner {
        isSignature = _isSignature;
    }

    function signatureWallet(
        address wallet,
        uint256 _tokenAmount,
        uint256 _timestamp,
        bytes memory _signature
    ) public pure returns (address) {
        return
            ECDSA.recover(
                keccak256(abi.encode(wallet, _tokenAmount, _timestamp)),
                _signature
            );
    }

    function freemint(
        uint256 _mintAmount,
        uint256 _timestamp,
        bytes memory _signature
    ) public nonReentrant {
        require(isFreemintOpen, "Freemint is Closed!");
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
            "Invalid mint amount!"
        );
        require(
            totalSupply() + _mintAmount <= freemint_supply,
            "Freemint Max supply exceeded!"
        );
        require(!paused, "The contract is paused!");
        // require(msg.value >= cost * _mintAmount, "Insufficient funds!");

        address wallet = _msgSender();
        if (isSignature) {
            address signerOwner = signatureWallet(
                wallet,
                _mintAmount,
                _timestamp,
                _signature
            );
            require(signerOwner == owner(), "Not authorized to mint");

            require(block.timestamp >= _timestamp - 30, "Out of time");

            _safeMint(wallet, _mintAmount);
        } else {
            _safeMint(wallet, _mintAmount);
        }
    }

    function mintForAddress(uint256 _mintAmount, address _receiver)
        public
        onlyOwner
    {
        _safeMint(_receiver, _mintAmount);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx)
        public
        onlyOwner
    {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setFreemintSupply(uint256 _freemintSupply) public onlyOwner {
        freemint_supply = _freemintSupply;
    }

    function withdrawAll(address _withdrawAddress) public onlyOwner {
        (bool os, ) = payable(_withdrawAddress).call{
            value: address(this).balance
        }("");
        require(os);
    }

    // METADATA HANDLING

    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyOwner
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setFreemintOpen(bool _freemintOpen) public onlyOwner {
        isFreemintOpen = _freemintOpen;
    }

    function setBaseURI(string calldata baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    // function walletOfOwner(address _owner)
    //     external
    //     view
    //     returns (uint256[] memory)
    // {
    //     uint256 tokenCount = balanceOf(_owner);

    //     uint256[] memory tokensId = new uint256[](tokenCount);
    //     for (uint256 i = 0; i < tokenCount; i++) {
    //         tokensId[i] = tokenOfOwnerByIndex(_owner, i);
    //     }

    //     return tokensId;
    // }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "URI does not exist!");

        if (revealed) {
            return
                string(
                    abi.encodePacked(_baseURI(), _tokenId.toString(), ".json")
                );
        } else {
            return hiddenMetadataUri;
        }
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        if (admins[_msgSender()]) {
            _transfer(from, to, tokenId);
        } else {
            super.transferFrom(from, to, tokenId);
        }
    }

    function addAdminRole(address _address) external onlyOwner {
        admins[_address] = true;
    }

    function revokeAdminRole(address _address) external onlyOwner {
        admins[_address] = false;
    }

    function hasAdminRole(address _address) external view returns (bool) {
        return admins[_address];
    }

    function burn(uint256 tokenId) external onlyAdmin {
        _burn(tokenId);
    }

    // function setTokenContract(address _kiraContract) public onlyOwner {
    //     Kira = IKiraToken(_kiraContract);
    // }

    function updateTimeLimit(uint256 _limit) public onlyOwner {
        timeLimit = _limit;
    }
}