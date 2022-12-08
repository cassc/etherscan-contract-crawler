// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract NUMB3RS is ERC721A, Ownable, PaymentSplitter {

    using ECDSA for bytes32;

    // Settings
    string private baseURI;
    address private _signerAddress;
    uint256 private teamLength;
    uint256 public maxSupply = 3333;
    uint256 public mintPricePublic = 0.08 ether;
    uint256 public maxMintPublic = 2;
    uint256 constant private MAX_MINT_PER_TXN = 2;
    mapping(address => uint256) private mintedAmountPublic;

    // Whitelist settings
    uint256 public whitelistSupply = 2222;
    uint256 public mintPriceWhitelist = 0.05 ether;
    uint256 public maxMintWhitelist = 2;
    mapping(address => uint256) private mintedAmountWhitelist;

    // Sale config
    enum MintStatus {
        CLOSED,
        WHITELIST,
        PUBLIC
    }
    MintStatus public mintStatus = MintStatus.CLOSED;

    constructor(
        string memory _initialBaseURI,
        address signerAddress_,
        address[] memory payments,
        uint256[] memory shares
    ) 
        ERC721A("NUMB3RS", "NUMB3RS")
        PaymentSplitter(payments, shares)
    {
        baseURI = _initialBaseURI;
        _signerAddress = signerAddress_;
        teamLength = payments.length;
    }

    modifier mintCompliance(uint256 _amount) {
        require(tx.origin == msg.sender, "Only humans are allowed to mint!");
        require(_amount > 0, "Can't mint zero!");
        _;
    }

    // Metadata
    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setMaxSupply(uint256 _newMaxSupply) external onlyOwner {
        maxSupply = _newMaxSupply;
    }

    function setSignerAddress(address _newSignerAddress) external onlyOwner {
        _signerAddress = _newSignerAddress;
    }

    function setMaxMintPublic(uint256 _newMaxMintPublic) external onlyOwner {
        maxMintPublic = _newMaxMintPublic;
    }
    
    function setMintPricePublic(uint256 _newMintPricePublic) external onlyOwner {
        mintPricePublic = _newMintPricePublic;
    }

    // Whitelist metadata
    function setMaxMintWhitelist(uint256 _newMaxMintWhitelist) external onlyOwner {
        maxMintWhitelist = _newMaxMintWhitelist;
    }

    function setMintPriceWhitelist(uint256 _newMintPriceWhitelist) external onlyOwner {
        mintPriceWhitelist = _newMintPriceWhitelist;
    }

    function setWhitelistSupply(uint256 _newWhitelistSupply) external onlyOwner {
        whitelistSupply = _newWhitelistSupply;
    }

    // Sale metadata
    function setMintStatus(uint256 _status) external onlyOwner {
        mintStatus = MintStatus(_status);
    }

    // Withdraw funds
    function releaseAll() external onlyOwner {
        for(uint i = 0; i < teamLength; i++) {
            release(payable(payee(i)));
        }
    }

    // Mint
    function mintPublic(uint256 amount) external payable mintCompliance(amount) {
        require(mintStatus == MintStatus.PUBLIC, "Public Sale is inactive!");
        require(amount <= MAX_MINT_PER_TXN, "Max mint per transaction exceeded!");
        require(mintedAmountPublic[msg.sender] + amount <= maxMintPublic, "Can't mint that many over public!");
        require(msg.value == mintPricePublic * amount, "The ether value sent is not correct!");
        require(totalSupply() + amount <= maxSupply, "Can't mint that many!");
 
        mintedAmountPublic[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function mintWhitelist(uint256 amount, bytes calldata signature) external payable mintCompliance(amount) {
        require(mintStatus == MintStatus.WHITELIST, "Whitelist Sale is inactive!");
        require(amount <= MAX_MINT_PER_TXN, "Max mint per transaction exceeded for whitelist!");
        require(mintedAmountWhitelist[msg.sender] + amount <= maxMintWhitelist, "Can't mint that many over whitelist!");
        require(msg.value == mintPriceWhitelist * amount, "The ether value sent is not correct!");
        require(totalSupply() + amount <= whitelistSupply, "Can't mint that many via whitelist!");

        require(_signerAddress == keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                bytes32(uint256(uint160(msg.sender)))
            )
        ).recover(signature), "Not on whitelist!");

        mintedAmountWhitelist[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function airdrop(uint256[] calldata amount, address[] calldata recipient) external onlyOwner {
        require(amount.length == recipient.length, "Provide equal amount and recipients!");
        for (uint256 i = 0; i < recipient.length; ++i) {
            require(totalSupply() + amount[i] <= maxSupply, "Can't mint that many!");
            require(amount[i] > 0, "Can't mint zero!");

            _safeMint(recipient[i], amount[i]);
        }
    }
}