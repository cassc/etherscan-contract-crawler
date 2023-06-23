// SPDX-License-Identifier: MIT
// Creator: @casareafer at 1TM.io

pragma solidity ^0.8.17;

import "./openzeppelin/ERC721.sol";
import "./openzeppelin/Strings.sol";
import "./openzeppelin/MerkleProof.sol";
import "./openzeppelin/Ownable.sol";
import "./ContractURI.sol";

contract OneCuPFPToken is ERC721, ContractURI, Ownable {
    using Strings for uint256;
    using Strings for address;
    address public royaltyAddress;

    /**
    *   Burn event values
    */

    uint256 private constant burnedId = 1;
    uint256 private burnSupply;
    address private pioneerPass;
    uint256 private totalBurned;
    bool private burnActive;
    bool private earlyBirdsDiscount;

    /**
    *   Mint event values
    */

    bytes32 internal whitelistRoot;
    uint256 internal maxMint;
    uint256 internal maxSupply;
    uint256 internal totalMinted;
    uint256 internal price;
    uint256 internal whitelistPrice;
    bool internal mintActive;
    bool internal preMintActive;

    /**
    *   Metadata values
    */

    string private baseUri;
    string public notRevealedUri;
    bool public revealed;

    /**
    *   Mappings
    */

    mapping(address => bool) private preSaleMinted;
    mapping(address => uint256) internal _userBurned;

    constructor(
        string memory name,
        string memory symbol,
        string memory _notRevealedUri,
        string memory contractUri,
        uint256 _burnSupply) ERC721(name, symbol) {
        maxSupply = 1111;
        burnActive = false;
        mintActive = false;
        preMintActive = false;
        revealed = false;
        transferLock = false;
        earlyBirdsDiscount = false;
        notRevealedUri = _notRevealedUri;
        _setContractURI(contractUri);
        burnSupply = _burnSupply;
    }

    /**
    *   Art controls
    */

    function reveal(bool _revealed) external onlyOwner {
        revealed = _revealed;
    }

    function setBaseUri(string memory _baseUri) external onlyOwner {
        baseUri = _baseUri;
    }

    /**
    *   Burning Tools
    */

    function setPioneerPass(address PioneerPassAddress) external onlyOwner {
        pioneerPass = PioneerPassAddress;
    }

    function setBurnActive(bool burnIt) external onlyOwner {
        burnActive = burnIt;
    }

    function setEarlyBirdsEvent(bool crankIt) external onlyOwner {
        earlyBirdsDiscount = crankIt;
    }

    function setBurnSupply(uint256 _burnSupply) external onlyOwner {
        burnSupply = _burnSupply;
    }

    /**
    *   Manual mint controls
    */

    function setWhitelist(bytes32 root) external onlyOwner {
        whitelistRoot = root;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setWhitelistPrice(uint256 _whitelistPrice) external onlyOwner {
        whitelistPrice = _whitelistPrice;
    }

    function setActiveSales(bool preMint, bool mint) external onlyOwner {
        mintActive = mint;
        preMintActive = preMint;
    }

    function setMaxMint(uint256 amount) external onlyOwner {
        maxMint = amount;
    }

    function setMaxSupply(uint256 amount) external onlyOwner {
        maxSupply = amount;
    }

    /**
    *   Miscellaneous
    */

    function setRoyaltyWallet(address receiver) external onlyOwner {
        royaltyAddress = receiver;
    }

    function lock(bool lockTransfers) external onlyOwner {
        transferLock = lockTransfers;
    }

    /**
    *   Withdraw
    */

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /**
    *   Detail getters
    */

    function getUserStatus(address user) external view returns (uint256 userBurned, bool minted) {
        return (_userBurned[user], preSaleMinted[user]);
    }

    function getSalesStatus() external view returns (
        bytes32 _whitelistRoot,
        uint256 _maxMint,
        uint256 _maxSupply,
        uint256 _totalMinted,
        uint256 _price,
        uint256 _whitelistPrice,
        bool _mintActive,
        bool _preMintActive) {

        return (whitelistRoot, maxMint, maxSupply, totalMinted, price, whitelistPrice, mintActive, preMintActive);
    }

    function getBurnStatus() external view returns (
        address _pioneerPass,
        uint256 _burnSupply,
        uint256 _burnedId,
        uint256 _totalBurned,
        bool _burnActive,
        bool _earlyBirdsDiscount) {
        return (pioneerPass, burnSupply, burnedId, totalBurned, burnActive, earlyBirdsDiscount);
    }

    /**
    *   EIP-2981 Royalty Info
    */

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
    external view returns (address receiver, uint256 royaltyAmount){
        return (royaltyAddress, salePrice * 80 / 1000);
    }

    /**
    *   Overrides
    */

    function onERC1155Received(
        address,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata
    ) external override(ERC721) returns (bytes4){
        if (burnActive) {
            require(burnedId == id, "Wrong token");
            uint256 receivedArks = value;
            if (earlyBirdsDiscount) {
                value += value;
            }
            require(_userBurned[from] + receivedArks <= 10, "Max 10 burns per wallet");
            require((totalBurned + receivedArks) <= burnSupply, "Burn amount exceeds the available burnable supply");

            require(value + totalMinted <= maxSupply, "Exceeds available supply");

            totalBurned += receivedArks;
            _userBurned[from] += receivedArks;

            (bool burned,) = address(pioneerPass).call(
                abi.encodeWithSignature("burn(address,uint256,uint256)", address(this), burnedId, receivedArks)
            );
            require(burned, "Burn Failed");
            for (uint bar = 0; bar < value; bar++) {
                totalMinted += 1;
                _safeMint(from, (totalMinted - 1));
            }
            return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
        } else {
            revert("Unable to receive tokens");
        }
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override(ERC721) returns (bytes4){
        revert("No transfers allowed");
    }

    /**
    *   Token Metadata
    */

    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override(ERC721)
    returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist");
        if (revealed == false) {
            return notRevealedUri;
        }
        return string(abi.encodePacked(baseUri, tokenId.toString()));
    }

    /**
    *   Miscellaneous
    */

    function ValidateMint(
        uint256 _amount,
        bool _whitelisted,
        bytes32[] calldata merkleProof
    ) internal returns (bool){
        require(maxSupply >= (_amount + totalMinted), "Exceeds available supply");
        require(_amount <= maxMint, "Too many mints");
        if (_whitelisted) {
            require(preMintActive, "No presale active");
            require(!preSaleMinted[msg.sender], "Already minted");
            require(MerkleProof.verify(
                    merkleProof, whitelistRoot, keccak256(abi.encodePacked(msg.sender))
                ), "Invalid proof");
            require(msg.value == whitelistPrice * _amount, "Invalid tx amount");
            preSaleMinted[msg.sender] = true;
        } else {
            require(msg.value == price * _amount, "Invalid tx amount");
        }
        return true;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }
}