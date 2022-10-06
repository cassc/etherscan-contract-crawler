// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.12;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 *Error codes following the convention:
 * 10: invalid value
 * 20: not allowed
 * 30: not enough founds
 * 40: contract error
 *
 * A short description or parameter name must follow the code. Some of these short messages
 * can be standardized, but many of them will be project dependant
 * For example
 * 10:open          expands to: Contract not open
 * 20:wallet        expands to: Wallet not allowed to
 * 30:token         expands to: Not enough token amounts
 * 40:external      expands to: Unable to access external contract
 */
contract NPS is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    uint256 public maxSupply;
    uint256 public mintPrice;
    uint256 public mintMax;
    uint256 public holdMax;
    address public signer;
    bool public open;
    string public baseURI;
    uint256 public earnings;
    address public gateway;
    uint256 public maxFreebies;
    uint256 public freebieCount;
    mapping(uint256 => string) private _tokenURIs;
    mapping(address => uint256) public freebies;
    mapping(uint256 => bool) public freeTokens;

    event Received(address, uint256);
    event WithdrawalSuccess(uint256 amount);

    struct SettingsStruct {
        string name;
        string symbol;
        uint256 maxSupply;
        uint256 mintPrice;
        uint256 mintMax;
        uint256 holdMax;
        address signer;
        bool open;
        string baseURI;
        uint256 earnings;
        address gateway;
        uint256 totalMinted;
        uint256 totalBurned;
        uint256 totalSupply;
        uint256 maxFreebies;
        uint256 freebieCount;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        uint256 _mintPrice,
        uint256 _mintMax,
        uint256 _holdMax,
        address _signer
    ) ERC721A(_name, _symbol) {
        maxSupply = _maxSupply;
        mintPrice = _mintPrice;
        mintMax = _mintMax;
        holdMax = _holdMax;
        signer = _signer;
        open = false;
        maxFreebies = 1555;
        freebieCount = 0;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function totalBurned() public view returns (uint256) {
        return _totalBurned();
    }

    function nextTokenId() public view returns (uint256) {
        return _nextTokenId();
    }

    function exists(uint256 id) public view returns (bool) {
        return _exists(id);
    }

    function setBaseURI(string memory newURI) external onlyOwner {
        require(bytes(newURI).length > 0, "10:url");
        baseURI = newURI;
    }

    function setGateway(address _gateway) external onlyOwner {
        require(_gateway != address(0), "10:gateway");
        gateway = _gateway;
    }

    function setTokenURI(uint256 id, string memory newURI) external onlyOwner {
        require(_exists(id), "10:id");
        require(bytes(newURI).length > 0, "10:url");
        _tokenURIs[id] = newURI;
    }

    function setMaxSupply(uint256 amount)
        public
        payable
        onlyOwner
        nonReentrant
    {
        require(amount > 0 && amount >= _totalMinted(), "10:amount");
        maxSupply = amount;
    }

    function setSigner(address _signer) external onlyOwner {
        require(_signer != address(0), "10:signer");
        signer = _signer;
    }

    function setOpen(bool _open) external onlyOwner {
        open = _open;
    }

    function setMintPrice(uint256 price) public payable onlyOwner nonReentrant {
        require(price > 0, "10:price");
        mintPrice = price;
    }

    function setMintMax(uint256 limit) public payable onlyOwner nonReentrant {
        require(limit > 0, "10:limit");
        mintMax = limit;
    }

    function setHoldMax(uint256 limit) public payable onlyOwner nonReentrant {
        require(limit > 0, "10:limit");
        holdMax = limit;
    }

    function airdrop(address receiver, uint256 amount)
        public
        onlyOwner
        nonReentrant
    {
        require(amount > 0 && amount <= mintMax, "20:mintingLimit");
        require(maxSupply >= amount + _totalMinted(), "20:maxSupply");
        _buy(receiver, amount);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "20:tokenId");
        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI;

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    function mint(uint256 quantity) public payable nonReentrant {
        require(open, "20:!open");
        require(quantity > 0, "10:quantity");
        require(quantity <= mintMax, "20:mintMax");
        require(maxSupply >= _totalMinted() + quantity, "20:maxSupply");
        require(_numberMinted(msg.sender) + quantity <= holdMax, "20:holdMax");
        require(msg.value >= mintPrice * quantity, "30:amount");
        // Check for freebie only after validating the request and checking the quantity is not zero
        _buy(msg.sender, quantity);
        earnings += quantity * mintPrice;
    }

    function mintFreebie(bytes memory signature) public nonReentrant {
        require(open, "20:!open");
        require(freebieCount < maxFreebies, "20:maxFreebies");
        require(maxSupply >= _totalMinted() + 1, "20:maxSupply");
        require(_numberMinted(msg.sender) + 1 <= holdMax, "20:holdMax");
        require(freebies[msg.sender] == 0, "20:freebies");
        require(_verify(signature), "20:signature");
        _buy(msg.sender, 1);
        // Map the freebie Ids per wallet
        uint256 tokenId = _nextTokenId() - 1;
        freebies[msg.sender] = tokenId;
        freeTokens[tokenId] = true;
        ++freebieCount;
    }

    function mintCrossMint(uint256 quantity, address _to)
        public
        payable
        nonReentrant
    {
        require(msg.sender == gateway, "20:gateway");
        require(open, "20:!open");
        require(quantity > 0, "10:quantity");
        require(quantity <= mintMax, "20:mintMax");
        require(maxSupply >= _totalMinted() + quantity, "20:maxSupply");
        require(_numberMinted(_to) + quantity <= holdMax, "20:holdMax");
        _buy(_to, quantity);
        earnings += quantity * mintPrice;
    }

    function _buy(address to, uint256 quantity) internal {
        _safeMint(to, quantity);
    }

    function burn(uint256 tokenId, bool approvalCheck)
        public
        payable
        nonReentrant
    {
        _burn(tokenId, approvalCheck);
    }

    function withdrawByOwner(address _address, uint256 amount)
        public
        payable
        onlyOwner
        nonReentrant
    {
        require(_address != address(0), "10:address");
        require(amount > 0, "10:amount");
        require(address(this).balance >= amount, "30:balance");
        (bool success, ) = payable(_address).call{value: amount}("");
        require(success, "40:transfer");
        emit WithdrawalSuccess(amount);
    }

    function _verify(bytes memory signature) internal view returns (bool) {
        bytes32 freshHash = keccak256(abi.encode(msg.sender));
        bytes32 candidateHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", freshHash)
        );
        return _verifyHashSignature(candidateHash, signature);
    }

    function _verifyHashSignature(bytes32 hash, bytes memory signature)
        internal
        view
        returns (bool)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (signature.length != 65) {
            return false;
        }

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        address recoverySigner = address(0);
        // If the version is correct, gather info
        if (v == 27 || v == 28) {
            // solium-disable-next-line arg-overflow
            recoverySigner = ecrecover(hash, v, r, s);
        }
        return signer == recoverySigner;
    }

    function setMultiple(
        uint256 _maxSupply,
        uint256 _mintPrice,
        uint256 _mintMax,
        uint256 _holdMax
    ) external onlyOwner {
        require(_maxSupply > _totalMinted(), "10:maxSupply");
        maxSupply = _maxSupply;
        mintPrice = _mintPrice;
        mintMax = _mintMax;
        holdMax = _holdMax;
    }

    function getSettings() public view returns (SettingsStruct memory) {
        SettingsStruct memory settings = SettingsStruct({
            name: name(),
            symbol: symbol(),
            maxSupply: maxSupply,
            mintPrice: mintPrice,
            mintMax: mintMax,
            holdMax: holdMax,
            signer: signer,
            open: open,
            baseURI: baseURI,
            earnings: earnings,
            gateway: gateway,
            totalMinted: _totalMinted(),
            totalBurned: _totalBurned(),
            totalSupply: totalSupply(),
            maxFreebies: maxFreebies,
            freebieCount: freebieCount
        });
        return settings;
    }
}