// SPDX-License-Identifier: MIT
// ARTWORK LICENSE: CC0
// ahodler.world - Totaler Mint, Blitzmint, 10% Royalties
pragma solidity 0.8.15;
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
contract aHODLer is ERC721A, Ownable {
    address private constant TEAMWALLET = 0x30394DD17758092e72AF2283F57aB9DeD6E93d87;
    string private baseURI;
    bool public started = false;
    bool public claimed = false;
    uint256 public constant MAXSUPPLY = 8818;
    uint256 public constant WALLETLIMIT = 3;
    uint256 public constant TEAMCLAIMAMOUNT = 418;
    uint256 public reichsMark = 0.18 ether;
    uint256 public attackDate = 1662011100;         // 1st of September, 5.45am GMT
    mapping(address => uint) public addressClaimed;
    constructor() ERC721A("aHODLer", "HODL") {}
    // Start at token 1 instead of 0
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
    function mint(uint256 _count) external payable {
        uint256 total = totalSupply();
        uint256 minCount = 0;
        require(started, "Achtung: Mint has not started yet");
        require(_count > minCount, "Achtung: You need to mint at least one");
        require(total + _count <= MAXSUPPLY, "Achtung: Mint out, no more NFTs left to mint");
        require(addressClaimed[_msgSender()] + _count <= WALLETLIMIT, "Achtung: Wallet limit, you can't mint more than that");
        require(total <= MAXSUPPLY, "Achtung: Mint out");

        if(block.timestamp > attackDate) {
            require(msg.value >= reichsMark, "Achtung: the war has started and you have not sent enough Reichsmark!");
        }
        // Own the Adolf
        addressClaimed[_msgSender()] += _count;
        _safeMint(msg.sender, _count);
    }
    function teamClaim() external onlyOwner {
        require(!claimed, "Achtung: Team has already claimed");
        // The team gets some
        _safeMint(TEAMWALLET, TEAMCLAIMAMOUNT);
        claimed = true;
    }
    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    function startBlitz(bool blitzMint) external onlyOwner {
        started = blitzMint;
    }
    function inflationCall(uint256 _newmarks) external onlyOwner {
        reichsMark = _newmarks;
    }
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), 'Achtung: There is no token with that ID');
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, _toString(_tokenId), '.json')) : '';
    }
}