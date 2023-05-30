pragma solidity 0.8.10;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./ERC721A.sol";
import "../interfaces/IMerkle.sol";
import "../interfaces/IClaimMerkle.sol";

contract MMNFT is ERC721A, Ownable, ReentrancyGuard, Pausable {
    using Strings for uint256;
    uint256 public price = 0.15 ether;
    string public baseUri;
    uint256 public supply = 12000;
    string public extension = ".json";    

    bool public whitelistLive;
    bool public isFreeClaimActive;

    address payable public paymentSplitter;
    uint256 public maxPerTx = 1;
    uint256 public maxPerWallet = 1;

    IMerkle public whitelist;
    IClaimMerkle public claimMerkle;
    
    mapping(address => uint256) whitelistLimitPerWallet;
    mapping(address => uint256) limitPerWallet;
    mapping(address => bool) admins;
    mapping(address => uint256) totalClaimed;

    event WhitelistLive(bool live);
    event FreeClaimActive(bool live);
    event Claimed(uint256 count, address sender);

    constructor(
        string memory name,
        string memory symbol
    ) ERC721A(name, symbol) { _pause(); }

     function claim(uint256 count, bytes32[] calldata proof)
        external
        nonReentrant
    {
        require(isFreeClaimActive, "Not Live");
        require(claimMerkle.isPermitted(msg.sender, count, proof), "Invalid");
        require(totalClaimed[msg.sender] != count, "Already claimed");

        _callMint(count, msg.sender);
        totalClaimed[msg.sender] += count;
        emit Claimed(count, msg.sender);
    }

    function whitelistMint(uint256 count, bytes32[] memory proof) external payable nonReentrant {
        require(whitelistLive, "Not live");
        require(msg.value >= price * count, "invalid price");
        require(whitelist.isPermitted(msg.sender, proof), "not whitelisted");
        require(whitelistLimitPerWallet[msg.sender] + count <= maxPerWallet, "Exceeds max");
        require(count <= maxPerTx, "Exceeds max");
        _callMint(count, msg.sender);
        whitelistLimitPerWallet[msg.sender] += count;
    }

    function adminMint(uint256 count, address to) external adminOrOwner {
        _callMint(count, to);
    }

    function _callMint(uint256 count, address to) internal {        
        uint256 total = totalSupply();
        require(count > 0, "Count is 0");
        require(total + count <= supply, "Sold out");
        _safeMint(to, count);
    }

    function burn(uint256 tokenId) external {
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);

        bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
            isApprovedForAll(prevOwnership.addr, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        require(isApprovedOrOwner, "Not approved");
        _burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        string memory currentBaseURI = baseUri;
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        extension
                    )
                )
                : "";
    }

    function setExtension(string memory _extension) external adminOrOwner {
        extension = _extension;
    }

    function setUri(string memory _uri) external adminOrOwner {
        baseUri = _uri;
    }

    function setPaused(bool _paused) external adminOrOwner attributesSet {
        if(_paused) {
            _pause();
        } else {
            _unpause();
        }
    }

    function viewClaimed(address account) external view returns (uint256) {
        return totalClaimed[account];
    }

    function toggleWhitelistLive() external adminOrOwner attributesSet {
        bool isLive = !whitelistLive;
        whitelistLive = isLive;
        emit WhitelistLive(isLive);
    }

    function toggleFreeClaim() external onlyOwner {
        isFreeClaimActive = !isFreeClaimActive;
        emit FreeClaimActive(isFreeClaimActive);
    }

    function setMerkle(IMerkle _whitelist) external adminOrOwner {
        whitelist = _whitelist;
    }

    function setClaimMerkle(IClaimMerkle _merkle) external onlyOwner {
        claimMerkle = _merkle;
    }

    function setPrice(uint256 _price) external adminOrOwner {
        price = _price;
    }

    function setMaxPerWallet(uint256 _maxPerWallet) external adminOrOwner {
        maxPerWallet = _maxPerWallet;
    }

    function setMaxPerTx(uint256 _maxPerTx) external adminOrOwner {
        maxPerTx = _maxPerTx;
    }

    function setPaymentSplitter(address payable _paymentSplitter) external adminOrOwner {
        paymentSplitter = _paymentSplitter;
    }
     
    function withdraw() external adminOrOwner {
        (bool success, ) = paymentSplitter.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function addAdmin(address _admin) external adminOrOwner {
        admins[_admin] = true;
    }

    function removeAdmin(address _admin) external adminOrOwner {
        delete admins[_admin];
    }

    modifier adminOrOwner() {
        require(msg.sender == owner() || admins[msg.sender], "Unauthorized");
        _;
    }

    modifier attributesSet() {
        require(
            supply != 0 && address(whitelist) != address(0x0) && address(claimMerkle) != address(0x0) && price != 0 && maxPerWallet != 0 && maxPerTx != 0 && paymentSplitter != address(0x0), 
            "Set everything before starting"
        );
        _;
    }
}