//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "hardhat/console.sol";

contract BabyBoss is ERC721A, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;
    using Strings for uint256;

    enum Period {
        PAUSED,
        GENESIS,
        PRESALE,
        PUBLIC
    }

    Period public saleState;

    // For signatures
    address private _signerAddress = 0x9cD0Dea148Cbb3502ca2ce5F6BcD803A0DD6C81e; // TESTING ADDRESS

    uint256 public maxSupply = 3999;
    uint256 public reserved = 300;
    uint256 public maxMint = 5; // CHANGE
    uint256 public priceGenesis = 0.055 ether; //CHANGE
    uint256 public priceWL = 0.066 ether; //CHANGE
    uint256 public pricePS = 0.088 ether; //CHANGE
    uint256 public collabMaxId = 11;
    uint256 public revealTime;
    uint256 public reserveMinted;

    string public baseURI;
    string public unrevealedURI =
        "ipfs://QmXC1XCk4LXUGmDFYH6gcgFPSiHfDJuUVXS3GD9dDTHtgQ"; // CHANGE
    string public collabURI =
        "ipfs://QmT3NRT3C52iMSdTPgscqEXnUBMAsLFjPV342BbE9fe2Kx/"; // CHANGE
    address public withdrawalAddress;

    mapping(address => uint256) minted;
    mapping(address => uint256) genesisMinted;
    mapping(address => uint256) wlMinted;
    mapping(address => bool) team;

    constructor(address _withdrawalAddress, uint256 _batchSize)
        ERC721A("Baby Boss", "$BBOSS", _batchSize)
    {
        withdrawalAddress = _withdrawalAddress;
        team[msg.sender] = true;
    }

    // --------- USER API ----------

    function mint(uint256 quantity)
        external
        payable
        callerIsUser
        nonReentrant
        verifyPrice(quantity, pricePS)
        onlyPeriod(Period.PUBLIC)
        supplyLimit(quantity, reserved)
    {
        require(
            minted[msg.sender] + quantity <= maxMint,
            "MAX_MINT: AMOUNT_TOO_HIGH"
        );

        minted[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function whitelistMint(
        bytes calldata _signature,
        uint256 quantity,
        uint256 limit
    )
        external
        payable
        callerIsUser
        nonReentrant
        verifyPrice(quantity, priceWL)
        onlyPeriod(Period.PRESALE)
        verifySignature(_signature, saleState, limit)
        supplyLimit(quantity, reserved)
    {
        require(
            wlMinted[msg.sender] + quantity <= limit,
            "MAX_MINT: AMOUNT_TOO_HIGH"
        );

        wlMinted[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function genesisMint(
        bytes calldata _signature,
        uint256 quantity,
        uint256 limit
    )
        external
        payable
        callerIsUser
        nonReentrant
        verifyPrice(quantity, priceGenesis)
        onlyPeriod(Period.GENESIS)
        verifySignature(_signature, saleState, limit)
        supplyLimit(quantity, reserved)
    {
        require(
            genesisMinted[msg.sender] + quantity <= limit,
            "MAX_MINT: AMOUNT_TOO_HIGH"
        );
        genesisMinted[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }

    // --------- VIEW --------------

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

        if (tokenId <= collabMaxId) {
            return
                bytes(collabURI).length > 0
                    ? string(
                        abi.encodePacked(collabURI, tokenId.toString(), ".json")
                    )
                    : unrevealedURI;
        }

        if (block.timestamp >= revealTime) {
            return
                bytes(baseURI).length > 0
                    ? string(
                        abi.encodePacked(baseURI, tokenId.toString(), ".json")
                    )
                    : unrevealedURI;
        } else {
            return unrevealedURI;
        }
    }

    function isTeam(address _user) public view onlyOwner returns (bool) {
        return team[_user];
    }

    function getSignerAddress() public view onlyOwner returns (address) {
        return _signerAddress;
    }

    // --------- RESTRICTED -----------

    function airdrop(address _user, uint256 _quantity)
        external
        callerIsUser
        onlyTeam
        supplyLimit(_quantity, 0)
    {
        require(reserveMinted + _quantity <= reserved, "OVER_RESERVE");
        reserveMinted += _quantity;
        _safeMint(_user, _quantity);
    }

    function airdropBatch(address[] calldata users, uint256 quantity)
        external
        callerIsUser
        onlyTeam
        supplyLimit(quantity * users.length, 0)
    {
        require(
            reserveMinted + (users.length * quantity) <= reserved,
            "OVER_RESERVE"
        );
        reserveMinted += users.length * quantity;
        for (uint256 i; i < users.length; i++) {
            _safeMint(users[i], quantity);
        }
    }

    function setPricePS(uint256 _price) external onlyOwner {
        pricePS = _price;
    }

    function setPriceWL(uint256 _price) external onlyOwner {
        priceWL = _price;
    }

    function setPriceGenesis(uint256 _price) external onlyOwner {
        priceGenesis = _price;
    }

    function setCollabMaxId(uint256 _id) external onlyOwner {
        collabMaxId = _id;
    }

    function setTeam(address _user, bool _state) external onlyOwner {
        require(team[_user] != _state, "NO_CHANGE");
        team[_user] = _state;
    }

    function setMaxMint(uint256 _amount) external onlyOwner {
        require(_amount > 0, "AMOUNT_TOO_LOW");
        maxMint = _amount;
    }

    function setSignerAddress(address _signer) external onlyOwner {
        _signerAddress = _signer;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setUnrevealedURI(string memory _uri) external onlyOwner {
        unrevealedURI = _uri;
    }

    function setCollabURI(string memory _uri) external onlyOwner {
        collabURI = _uri;
    }

    function setRevealTime(uint256 _revealTime) external onlyOwner {
        revealTime = _revealTime;
    }

    function setSaleState(uint256 _state) external onlyOwner {
        saleState = Period(_state);
    }

    function setWithdrawalAddress(address _withdrawal) external onlyOwner {
        withdrawalAddress = _withdrawal;
    }

    function withdraw() external onlyOwner {
        (bool os, ) = payable(withdrawalAddress).call{
            value: address(this).balance
        }("");
        require(os);
    }

    function recoverToken(IERC20 _token) external onlyOwner {
        uint256 balance = _token.balanceOf(address(this));
        bool _success = _token.transfer(owner(), balance);
        require(_success, "Token could not be transferred");
    }

    // --------- MODIFIERS ----------

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "CALLER_IS_CONTRACT");
        _;
    }

    modifier verifySignature(
        bytes calldata _signature,
        Period _period,
        uint256 _maxMint
    ) {
        bytes32 msgHash = keccak256(
            abi.encode(address(this), uint256(_period), _maxMint, msg.sender)
        );
        require(
            msgHash.toEthSignedMessageHash().recover(_signature) ==
                _signerAddress,
            "INCORRECT_SIGNATURE"
        );
        _;
    }

    modifier verifyPrice(uint256 _quantity, uint256 _price) {
        require(msg.value >= _quantity * _price, "PRICE: VALUE_TOO_LOW");
        _;
    }

    modifier onlyPeriod(Period _state) {
        require(saleState == _state, "WRONG_SALE_STATE");
        _;
    }

    modifier supplyLimit(uint256 _quantity, uint256 _reserved) {
        require(
            totalSupply() + _quantity + _reserved <= maxSupply,
            "MAX_SUPPLY: AMOUNT_TOO_HIGH"
        );
        _;
    }

    modifier onlyTeam() {
        require(team[msg.sender], "NOT_IN_TEAM");
        _;
    }
}