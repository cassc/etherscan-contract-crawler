// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract DAD {
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns (uint256);

    function balanceOf(address owner) external view virtual returns (uint256 balance);
}

contract CryptoMoms is ERC721Enumerable, Ownable {
    using Strings for uint256;

    DAD private constant dad = DAD(0xECDD2F733bD20E56865750eBcE33f17Da0bEE461);

    uint256 public constant MAX_MOMS = 9205;

    uint256 public numMomsMinted;

    string public baseTokenURI;

    bool public holderClaimStarted = false;
    bool public permanentShutdown = false;

    uint256 private _royaltyBps;
    address payable private _royaltyRecipient;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;

    mapping(address => bool) public holderClaimed;
    mapping(uint256 => bool) public usedToClaim;

    event CryptoMomMinted(address minter);

    modifier whenHolderClaimStarted() {
        require(holderClaimStarted, "Holder claim has not started");
        _;
    }

    constructor(
        string memory baseURI,
        address payable recipient,
        uint256 bps
    ) ERC721("CryptoMoms", "MOM") {
        baseTokenURI = baseURI;
        _royaltyRecipient = recipient;
        _royaltyBps = bps;

        numMomsMinted += 1;
        _safeMint(msg.sender, numMomsMinted);
    }

    function mint() external whenHolderClaimStarted {
        require(totalSupply() < MAX_MOMS, "All CryptoMoms have been minted");
        require(totalSupply() + 1 <= MAX_MOMS, "Minting would exceed CryptoMoms max supply");
        require(!holderClaimed[msg.sender], "You have already claimed your CryptoMom");

        uint256 balance = dad.balanceOf(msg.sender);
        require(balance > 0, "Must hold at least one CryptoDad to claim");

        bool eligibleToClaim = true;

        for (uint256 i = 0; i < balance; i++) {
            uint256 dadId = dad.tokenOfOwnerByIndex(msg.sender, i);
            if (usedToClaim[dadId]) {
                eligibleToClaim = false;
            }
            usedToClaim[dadId] = true;
        }
        require(eligibleToClaim, "The CryptoDads you are holding have already claimed");

        numMomsMinted += 1;
        holderClaimed[msg.sender] = true;
        _safeMint(msg.sender, numMomsMinted);

        emit CryptoMomMinted(msg.sender);
    }

    function resetDadClaimedStatus(uint256 dadId) external onlyOwner {
        usedToClaim[dadId] = false;
    }

    function toggleHolderClaimStarted() external onlyOwner {
        require(!permanentShutdown, "Holder claimed has been permanently shutdown");
        holderClaimStarted = !holderClaimStarted;
    }

    function mintingPermanentShutdown() external onlyOwner {
        require(!holderClaimStarted, "Holder claiming is still active");
        permanentShutdown = true;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function updateRoyalties(address payable recipient, uint256 bps) external onlyOwner {
        require(bps <= 10000, "BPS too high");
        _royaltyRecipient = recipient;
        _royaltyBps = bps;
    }

    function getRoyalties(uint256) external view returns (address payable[] memory recipients, uint256[] memory bps) {
        if (_royaltyRecipient != address(0x0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
            bps = new uint256[](1);
            bps[0] = _royaltyBps;
        }
        return (recipients, bps);
    }

    function getFeeRecipients(uint256) external view returns (address payable[] memory recipients) {
        if (_royaltyRecipient != address(0x0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
        }
        return recipients;
    }

    function getFeeBps(uint256) external view returns (uint256[] memory bps) {
        if (_royaltyRecipient != address(0x0)) {
            bps = new uint256[](1);
            bps[0] = _royaltyBps;
        }
        return bps;
    }

    function royaltyInfo(uint256, uint256 value) external view returns (address, uint256) {
        return (_royaltyRecipient, (value * _royaltyBps) / 10000);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable) returns (bool) {
        return
            interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981 ||
            interfaceId == _INTERFACE_ID_ROYALTIES_RARIBLE ||
            super.supportsInterface(interfaceId);
    }
}