// SPDX-License-Identifier: GPL-3.0
// solhint-disable-next-line
pragma solidity 0.8.12;
import "./ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BAPGenesis is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    uint256 public maxSupply;
    uint256 public mintPrice;
    uint256 public mintMax;
    uint256 public holdMax;
    bool public open;
    string public baseURI;
    bool public whitelisted = true;
    uint256 public stage = 1;
    uint256 public constant maxBreedings = 3;
    uint256 public constant mintedAllowedCap = 8810;
    uint256 public constant manualDistCap = 1200;
    uint256 public maxGodBulls = 500;
    address public orchestrator;
    uint256 public userMintedTokens;
    uint256 public manualAirdropsAmount;
    uint256 public genesisTimestamp;
    address public secret;
    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => uint256) public mintingDatetime;
    mapping(uint256 => uint256) public originalMintingPrice;
    mapping(uint256 => uint256) public breedings;
    mapping(address => uint256) public walletHoldings;
    mapping(uint256 => uint256) public tokenTxs;
    mapping(uint256 => bool) public notAvailableForRefund;
    event Received(address, uint256);

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        uint256 _mintPrice,
        uint256 _mintMax,
        uint256 _holdMax,
        address _secret
    ) ERC721A(_name, _symbol) {
        maxSupply = _totalSupply;
        mintPrice = _mintPrice;
        mintMax = _mintMax;
        holdMax = _holdMax;
        secret = _secret;
    }

    modifier onlyOrchestrator() {
        require(
            orchestrator == _msgSender(),
            "Ownable: caller is not the orchestrator"
        );
        _;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function airdrop(address receiver, uint256 amount)
        public
        onlyOwner
        nonReentrant
    {
        require(maxSupply >= amount + _totalMinted(), "Supply limit");
        require(
            manualAirdropsAmount + amount <= manualDistCap,
            "Manual distribution cap reached"
        );
        _buy(receiver, amount, 0);
        manualAirdropsAmount += amount;
    }

    function breedBulls(uint256 token1, uint256 token2)
        external
        onlyOrchestrator
    {
        require(
            breedings[token1] > 0 &&
                breedings[token2] > 0 &&
                ownerOf(token1) == tx.origin &&
                ownerOf(token2) == tx.origin,
            "The bull cant be used to buy an Incubator"
        );
        _setBreeds(token1);
        _setBreeds(token2);
    }

    function contractURI() external view returns (string memory) {
        return baseURI;
    }

    function generateGodBull() external onlyOrchestrator {
        require(maxGodBulls-- >= 10, "All God bulls are created");
        _safeMint(tx.origin, 1);
    }

    function mint(
        bytes memory signature,
        uint256 tokenAmount,
        uint256 tier,
        uint256 walletLimit
    ) public payable nonReentrant {
        require(open, "Contract closed");
        require(msg.value >= tokenAmount * mintPrice, "Insufficient ETH");
        require(maxSupply >= tokenAmount + _totalMinted(), "Supply limit");
        require(
            _verify(signature, tokenAmount, tier, walletLimit),
            "Wallet is not whitelisted"
        );
        if (whitelisted) {
            require(tier <= stage || (tier == 3), "Tier is not valid");
            if (tier != 3) {
                require(
                    _checkHolding(msg.sender, tokenAmount),
                    "Holding limit reached"
                );
                require(mintMax >= tokenAmount, "Too many tokens");
            } else {
                require(
                    walletHoldings[msg.sender] + tokenAmount <= walletLimit,
                    "Holding limit reached"
                );
            }
        } else {
            require(mintMax >= tokenAmount, "Too many tokens");
        }

        require(
            userMintedTokens + tokenAmount <= mintedAllowedCap,
            "User Minting Amount Reached"
        );
        userMintedTokens += tokenAmount;
        walletHoldings[msg.sender] += tokenAmount;
        _buy(msg.sender, tokenAmount, mintPrice);
    }

    function minted() external view returns (uint256) {
        return _totalMinted();
    }

    function refund(address depositAddress, uint256 tokenId)
        public
        nonReentrant
        onlyOrchestrator
    {
        uint256 balance = originalMintingPrice[tokenId];
        require(balance > 0, "Original Minting Price is zero");
        require(
            notAvailableForRefund[tokenId] == false,
            "The token is not available for refund"
        );
        require(
            this.ownerOf(tokenId) == depositAddress,
            "Permission Denied : Token Owner not valid"
        );
        (bool success, ) = depositAddress.call{value: balance}("");
        notAvailableForRefund[tokenId] = true;
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _checkTransferPeriod(tokenId);
        super.safeTransferFrom(from, to, tokenId, "");
        tokenTxs[tokenId]++;
        if (tokenTxs[tokenId] > 1) notAvailableForRefund[tokenId] = true;
    }

    function setTokenURI(uint256 id, string memory newURL) external onlyOwner {
        require(bytes(newURL).length > 0, "New URL Invalid");
        require(_exists(id), "Invalid Token");
        _tokenURIs[id] = newURL;
    }

    function setSecret(address _secret) external onlyOwner {
        require(_secret != address(0), "200:ZERO_ADDRESS");
        secret = _secret;
    }

    function setOpen(bool _open) external onlyOwner {
        if (_open && genesisTimestamp == 0) {
            genesisTimestamp = block.timestamp;
        }
        open = _open;
    }

    function setWhitelisted(bool _whitelisted) external onlyOwner {
        whitelisted = _whitelisted;
    }

    function setMultiple(
        uint256 _maxSupply,
        uint256 _mintPrice,
        uint256 _mintMax,
        uint256 _holdMax,
        uint256 _newStage,
        string memory _newBaseURI
    ) external onlyOwner {
        require(_maxSupply > _totalMinted(), "Total supply too low");
        maxSupply = _maxSupply;
        mintPrice = _mintPrice;
        mintMax = _mintMax;
        holdMax = _holdMax;
        stage = _newStage;
        baseURI = _newBaseURI;
    }

    function setMaxSupply(uint256 _totalSupply) external onlyOwner {
        require(_totalSupply >= _totalMinted(), "Total supply too low");
        maxSupply = _totalSupply;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */

    function setOrchestrator(address newOrchestrator) external onlyOwner {
        require(newOrchestrator != address(0), "200:ZERO_ADDRESS");
        orchestrator = newOrchestrator;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _checkTransferPeriod(tokenId);
        super.transferFrom(from, to, tokenId);
        tokenTxs[tokenId]++;
        if (tokenTxs[tokenId] > 1) notAvailableForRefund[tokenId] = true;
    }

    function tokenExist(uint256 id) external view returns (bool) {
        return _exists(id);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

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

    function updateBullBreedings(uint256 id) external onlyOrchestrator {
        _setBreeds(id);
    }

    function withdrawETH(address _address, uint256 amount)
        public
        nonReentrant
        onlyOwner
    {
        require(_address != address(0), "200:ZERO_ADDRESS");
        require(amount <= address(this).balance, "Insufficient funds");
        (bool success, ) = _address.call{value: amount}("");
    }

    function _buy(
        address to,
        uint256 quantity,
        uint256 price
    ) internal {
        uint256 _totalTokens = _totalMinted();
        _safeMint(to, quantity);
        for (uint256 i = _totalTokens; i < _totalTokens + quantity; i++) {
            uint256 id = i + 1;
            mintingDatetime[id] = block.timestamp;
            originalMintingPrice[id] = price;
            breedings[id] = maxBreedings;
        }
    }

    function _checkHolding(address wallet, uint256 tokenAmount)
        internal
        view
        returns (bool)
    {
        uint256 holding = walletHoldings[wallet];
        return (holding + tokenAmount) <= holdMax;
    }

    function _checkTransferPeriod(uint256 tokenId) internal {
        if (
            block.timestamp > mintingDatetime[tokenId] + 3 hours &&
            !notAvailableForRefund[tokenId]
        ) {
            notAvailableForRefund[tokenId] = true;
        }
    }

    function _setBreeds(uint256 tokenId) internal {
        require(_exists(tokenId), "Invalid Token");
        require(
            breedings[tokenId] >= 0,
            "The bull already evolved to maximum capacity"
        );
        breedings[tokenId]--;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _verify(
        bytes memory signature,
        uint256 tokenAmount,
        uint256 tier,
        uint256 walletLimit
    ) internal view returns (bool) {
        if (!whitelisted) {
            return true;
        }
        if (tier < 3) {
            walletLimit = holdMax;
        }
        bytes32 freshHash = keccak256(
            abi.encode(msg.sender, tokenAmount, tier, walletLimit)
        );
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

        address signer = address(0);
        // If the version is correct, gather info
        if (v == 27 || v == 28) {
            // solium-disable-next-line arg-overflow
            signer = ecrecover(hash, v, r, s);
        }
        return secret == signer;
    }
}