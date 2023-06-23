// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;
import "./ERC721ABurnable.sol";
import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import {DefaultOperatorFilterer} from "./DefaultOperatorFilterer.sol";
contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract Destinations is ERC721ABurnable, DefaultOperatorFilterer, Ownable, ReentrancyGuard {
    using Strings for uint256;
    string public baseURI;
    uint256 public totalWithdrawn = 0;
    uint256 public phaseMaxPerWallet = 2; // max allowance per wallet in the phases
    uint256 public maxPerTx = 2; // max allowance per transaction
    uint256 public price = 0.005 ether; // mint price
    uint256 public phase = 1; // current phase
    uint256 public maxSupply = 70; // increases to 100 in phase 2
    uint256 public saleStartTime = 1687442400; // Thursday, June 22, 2023 15:00:00 GMT+01:00
    bool public burningDisabled = true;

    mapping(address => uint256) public airdropMints; // mapping of mints per address for airdrop
    mapping(address => uint256) public phase2Mints; // mapping of mints per address for Phase 2

    address public constant PHASE_1_SIGNER = 0x7E3734637DCB3a1Ae4019f46db57B33a3d96b096;
    address public constant PHASE_2_SIGNER = 0x4BBFB4B577dad0eAF72B44E869Aa09c34CF3E6aF;
    
    string _name = "Destinations";
    string _symbol = "DEST";
    string _initBaseURI = "https://houseoffirst.com:1335/destinations/opensea/";

    address public proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1; // OpenSea Mainnet Proxy Registry address
    
    constructor() ERC721A(_name, _symbol) {
        setBaseURI(_initBaseURI);
    }

    function getNFTPrice() public view returns (uint256) {
        return price;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function setPhaseMaxPerWallet(uint256 _newMax) public onlyOwner {
        phaseMaxPerWallet = _newMax;
    }

    function setMaxPerTx(uint256 _maxPerTx) public onlyOwner {
        maxPerTx = _maxPerTx;
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
    
    /* allowlist */
    function isAllowlistedPhase1(address user, bytes memory signature) public pure returns (bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(user));
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        return recoverSigner(ethSignedMessageHash, signature) == PHASE_1_SIGNER;
    }

    function isAllowlistedPhase2(address user, bytes memory signature) public pure returns (bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(user));
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        return recoverSigner(ethSignedMessageHash, signature) == PHASE_2_SIGNER;
    }
    
    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) private pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }
    
    function splitSignature(bytes memory sig) private pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function getPhase() public view returns (uint256) {
        return phase;
    }

    function mintingStarted() public view returns (bool) {
        return block.timestamp >= saleStartTime;
    }

    function getSaleStartTime() public view returns (uint256) {
        return saleStartTime;
    }

    function getAirdropMints(address addr) public view returns (uint256) {
        return airdropMints[addr];
    }

    function getNumberMinted(address addr) public view returns (uint256) {
        return _numberMinted(addr);
    }

    function setSaleStartTime(uint256 _saleStartTime) public onlyOwner {
        saleStartTime = _saleStartTime;
    }

    function setAirdropMints(address addr, uint256 _airdropMintQty) public onlyOwner {
        airdropMints[addr] = _airdropMintQty;
    }

    // manually call before each phase
    function setPhase(uint256 _phase) public onlyOwner {
        phase = _phase;
        if(phase == 1) {
            maxSupply = 70;
            saleStartTime = 1687442400; // Thursday, June 22, 2023 15:00:00 GMT+01:00
            maxPerTx = 2;
        }
        else if(phase == 2) {
            maxSupply = 100;
            saleStartTime = 1687528800; // Friday, June 23, 2023 15:00:00 GMT+01:00
            maxPerTx = 2;
        }
        else {
            maxSupply = 100;
            saleStartTime = 1687615200; // Saturday, June 24, 2023 15:00:00 GMT+01:00
            maxPerTx = 50;
        }
    }

    function getAllowance(address addr) public view returns (uint256) {
        if(phase == 1) {
            return phaseMaxPerWallet - (_numberMinted(addr) - airdropMints[addr]); // qty user can mint based on existing mints
        }
        else if(phase == 2) {
            return phaseMaxPerWallet - phase2Mints[addr];
        }
        return 50; // default allowance in public
    }

    /**
     * public mint nfts (no signature required)
     */
    function mintNFT(uint256 numberOfNfts) public payable nonReentrant {
        require(phase == 3 && block.timestamp >= saleStartTime, "Public sale not started");
        require(numberOfNfts > 0, "Invalid numberOfNfts");
        require(msg.value >= price * numberOfNfts, "Not Enough ETH");
        uint256 supply = _totalMinted(); // total minted globally
        require((supply + numberOfNfts) <= maxSupply, "Exceeds max supply");
        _mint(msg.sender, numberOfNfts);
        delete supply;
    }

    /**
     * allowlist mint nfts (signature required)
     */
    function allowlistMintNFT(uint256 numberOfNfts, bytes memory signature) public payable nonReentrant {
        require(phase == 1 || phase == 2, "Allowlist Phases ended");
        require(block.timestamp >= saleStartTime, "Sale has not started");
        require(numberOfNfts > 0 && numberOfNfts <= phaseMaxPerWallet, "Invalid numberOfNfts");
        require(msg.value >= price * numberOfNfts, "Not Enough ETH");
        uint256 userMinted;
        // use signature for allowlist validation
        if(phase == 1) {
            require(isAllowlistedPhase1(msg.sender, signature), "Address not allowlisted for Phase 1");
            userMinted = _numberMinted(msg.sender) - airdropMints[msg.sender]; // qty user has minted (ignores airdrop mints)
        }
        else if(phase == 2) {
            require(isAllowlistedPhase2(msg.sender, signature), "Address not allowlisted for Phase 2");
            userMinted = phase2Mints[msg.sender]; // in phase 2, only look at phase2 number minted
            phase2Mints[msg.sender] += numberOfNfts; // increment
        }

        uint256 userCanMint = phaseMaxPerWallet - userMinted; // qty user can mint based on existing mints
        require(numberOfNfts <= userCanMint, "Exceeds user allowance");
        uint256 supply = _totalMinted(); // total minted globally
        require((supply + numberOfNfts) <= maxSupply, "Exceeds max supply");
        _mint(msg.sender, numberOfNfts);
        delete userMinted;
        delete userCanMint;
        delete supply;
    }

    // admin minting
    function airdrop(uint256[] calldata quantities, address[] calldata recipients) external onlyOwner {
        require(quantities.length == recipients.length, "Invalid quantities and recipients (length mismatch)");
        uint256 totalQuantity = 0;
        uint256 supply = _totalMinted(); // total minted globally
        for (uint256 i = 0; i < quantities.length; ++i) {
            totalQuantity += quantities[i];
        }
        require(supply + totalQuantity <= maxSupply, "Exceeds max mupply");
        delete totalQuantity;
        for (uint256 i = 0; i < recipients.length; ++i) {
            _mint(recipients[i], quantities[i]);
            airdropMints[recipients[i]] += quantities[i]; // increment
        }
        delete supply;
    }

    function burn(uint256 tokenId) public virtual override {
        require(!burningDisabled, "Burning is disabled");
        _burn(tokenId, true);
    }

    function batchTransferFrom(address _from, address _to, uint256[] memory _tokenIds) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            transferFrom(_from, _to, _tokenIds[i]);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
    }

    function setMaxSupply(uint256 _newMaxSupply) public onlyOwner {
        maxSupply = _newMaxSupply;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBurningDisabled(bool _burningDisabled) public onlyOwner {
        burningDisabled = _burningDisabled;
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getPhase2Mints(address owner) public view returns(uint256) {
        return phase2Mints[owner];
    }

    function totalBurned() public view returns (uint256) {
        return _totalBurned();
    }

    function numberBurned(address owner) public view returns (uint256) {
        return _numberBurned(owner);
    }

    function ownershipOf(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return _ownershipOf(tokenId);
    }

    function getTotalWithdrawn() public view returns (uint256) {
        return totalWithdrawn;
    }

    function getTotalBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getTotalRaised() public view returns (uint256) {
        return getTotalWithdrawn() + getTotalBalance();
    }

    /**
     * withdraw ETH from the contract (callable by Owner only)
     */
    function withdraw() public payable onlyOwner {
        uint256 val = address(this).balance;
        (bool success, ) = payable(msg.sender).call{
            value: val
        }("");
        require(success);
        totalWithdrawn += val;
        delete val;
    }
    /**
     * whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator) override public view returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }
}