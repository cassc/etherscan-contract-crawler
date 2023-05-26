// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./ERC721Namable.sol";
import "./AVGLToken.sol";

contract AVYC is ERC721Namable {
    using Strings for uint256;

    uint256 public constant MAX_ARTS = 10000;
    uint256 public price = 0.1 ether;
    uint256 public constant MAX_PER_MINT = 20;
    uint256 public presaleMaxMint = 20;
    uint256 public constant MAX_ARTS_MINT = 100;

    string public baseTokenURI;

    bool public publicSaleStarted;
    bool public presaleStarted;

    address private signer;

    mapping(address => uint256) private _totalClaimed;

    event BaseURIChanged(string baseURI);
    event PresaleMint(address minter, uint256 amountOfArts);
    event PublicSaleMint(address minter, uint256 amountOfArts);
    event AirdropMint(address receiver, uint256 amountOfArts);

    modifier whenPresaleStarted() {
        require(presaleStarted, "XStart");
        _;
    }

    modifier whenPublicSaleStarted() {
        require(publicSaleStarted, "XStart");
        _;
    }

    constructor(address _signer, string memory baseURI, address tokenAddress)
        ERC721Namable("AV Yacht Club", "AVYC")
    {
        baseTokenURI = baseURI;
        signer = _signer;
        if (tokenAddress != address(0)) {
            setYieldToken(tokenAddress);
        }
    }

    function checkPresaleEligibility(bytes32 hash, bytes memory signature)
        public
        view
        returns (bool)
    {
        require(
            ECDSA.toEthSignedMessageHash(
                keccak256(abi.encodePacked(msg.sender))
            ) == hash,
            "XHash"
        );
        return ECDSA.recover(hash, signature) == signer;
    }

    function amountClaimedBy(address owner) external view returns (uint256) {
        require(owner != address(0), "nullAddr");
        return _totalClaimed[owner];
    }

    function airdrop(address receiver, uint256 amountOfArts)
        external
        onlyOwner {
        require(initializedYieldToken, "TNI");
        uint256 _nextTokenId = totalSupply();
        for (uint256 i = 0; i < amountOfArts; i++) {
            _safeMint(receiver, _nextTokenId++);
        }
        yieldToken.updateRewardOnMint(receiver);
        emit AirdropMint(receiver, amountOfArts);
    }

    function mintPresale(
        uint256 amountOfArts,
        bytes32 hash,
        bytes memory signature
    ) external payable whenPresaleStarted {
        require(initializedYieldToken, "TNI");
        require(
            checkPresaleEligibility(hash, signature),
            "NotEligible"
        );
        require(totalSupply() < MAX_ARTS, "AllMinted");
        require(
            amountOfArts <= presaleMaxMint,
            "exceeds max"
        );
        require(
            totalSupply() + amountOfArts <= MAX_ARTS,
            "exceed supply"
        );
        require(
            _totalClaimed[msg.sender] + amountOfArts <= presaleMaxMint,
            "exceed per address"
        );
        require(amountOfArts > 0, "at least 1");
        require(price * amountOfArts == msg.value, "wrong ETH amount");
        uint256 _nextTokenId = totalSupply();
        for (uint256 i = 0; i < amountOfArts; i++) {
            _safeMint(msg.sender, _nextTokenId++);
        }
        _totalClaimed[msg.sender] += amountOfArts;
        yieldToken.updateRewardOnMint(msg.sender);
        emit PresaleMint(msg.sender, amountOfArts);
    }

    function mint(uint256 amountOfArts) external payable whenPublicSaleStarted {
        require(initializedYieldToken, "TNI");
        require(totalSupply() < MAX_ARTS, "All tokens have been minted");
        require(
            amountOfArts <= MAX_PER_MINT,
            "exceeds max"
        );
        require(
            totalSupply() + amountOfArts <= MAX_ARTS,
            "exceed supply"
        );
        require(
            _totalClaimed[msg.sender] + amountOfArts <= MAX_ARTS_MINT,
            "exceed per address"
        );
        require(amountOfArts > 0, "at least 1");
        require(price * amountOfArts == msg.value, "wrong ETH amount");
        uint256 _nextTokenId = totalSupply();
        for (uint256 i = 0; i < amountOfArts; i++) {
            _safeMint(msg.sender, _nextTokenId++);
        }
        _totalClaimed[msg.sender] += amountOfArts;
        yieldToken.updateRewardOnMint(msg.sender);
        emit PublicSaleMint(msg.sender, amountOfArts);
    }

    function setSigner(address addr) external onlyOwner {
        signer = addr;
    }

    function setPrice(uint256 p) external onlyOwner {
        price = p;
    }

    function setPresaleMaxMint(uint256 p) external onlyOwner {
        presaleMaxMint = p;
    }

    function togglePresaleStarted() external onlyOwner {
        presaleStarted = !presaleStarted;
    }

    function togglePublicSaleStarted() external onlyOwner {
        publicSaleStarted = !publicSaleStarted;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
        emit BaseURIChanged(baseURI);
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "no balance");
        _widthdraw(owner(), address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "failed withdraw");
    }

    AVGLToken public yieldToken;
    bool initializedYieldToken;

    function setYieldToken(address _yield) public onlyOwner {
        yieldToken = AVGLToken(_yield);
        initializedYieldToken = true;
    }

    function changeNamePrice(uint256 _price) external onlyOwner {
        nameChangePrice = _price;
    }

    function getReward() external {
        require(initializedYieldToken, "TNI");
        yieldToken.updateReward(msg.sender, address(0));
        yieldToken.getReward(msg.sender);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        require(initializedYieldToken, "TNI");
        yieldToken.updateReward(from, to);
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        require(initializedYieldToken, "TNI");
        yieldToken.updateReward(from, to);
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    function changeName(uint256 tokenId, string memory newName)
        public
        override
    {
        require(initializedYieldToken, "TNI");
        yieldToken.burn(msg.sender, nameChangePrice);
        super.changeName(tokenId, newName);
    }

    function changeBio(uint256 tokenId, string memory _bio) public override {
        require(initializedYieldToken, "TNI");
        yieldToken.burn(msg.sender, bioChangePrice);
        super.changeBio(tokenId, _bio);
    }

    function changeBioPrice(uint256 _price) external onlyOwner {
        bioChangePrice = _price;
    }
}