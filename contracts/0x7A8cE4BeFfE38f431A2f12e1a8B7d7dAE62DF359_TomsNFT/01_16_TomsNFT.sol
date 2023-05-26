// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract TomsNFT is ERC721A, Ownable, PaymentSplitter, ReentrancyGuard {
    using Address for address;
    using Strings for string;

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant TEAM_RESERVED = 50;
    uint256 public constant FREE_TIER = TEAM_RESERVED + 1000; // First 1k Toms are free!
    uint256 public salePrice = 0.02 ether;
    uint256 public walletLimit = 5;
    string public baseURI;
    bool public metadataFrozen;
    bool public preminted;
    bool public isSaleActive;

    address public developer;

    constructor(
        address owner_,
        address[] memory payees_,
        uint256[] memory shares_
    )
        ERC721A("10K Toms", "10KTOMS")
        PaymentSplitter(payees_, shares_)
        Ownable()
    {
        require(owner_ != address(0));

        developer = _msgSender();
        _transferOwnership(owner_);
    }

    function mint(address _to, uint256 _amount) public payable nonReentrant {
        require(tx.origin == msg.sender, "Keep it simple, anon");
        require(isSaleActive, "Sale inactive");
        require(msg.value == salePrice * _amount, "Invalid Payment");
        require(
            _amount + _numberMinted(msg.sender) <= walletLimit,
            "Wallet limit"
        );
        uint256 totalBefore = totalSupply();
        _performMint(_to, _amount);

        if (totalBefore > FREE_TIER) {
            return; // No sale, anon
        }

        // Payback
        uint256 numRefund;
        if (totalBefore + _amount <= FREE_TIER) {
            numRefund = _amount;
        } else if (totalBefore + _amount > FREE_TIER) {
            uint256 toPay = (totalBefore + _amount) - FREE_TIER;
            numRefund = _amount - toPay;
        }
        if (numRefund > 0) {
            require(
                payable(msg.sender).send(numRefund * salePrice),
                "Refund failed"
            );
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function freezeMetadata() public onlyAuthorized {
        require(!metadataFrozen, "Metadata Frozen");
        metadataFrozen = true;
    }

    function setBaseURI(string calldata __baseURI) public onlyAuthorized {
        require(!metadataFrozen, "Metadata Frozen");
        baseURI = __baseURI;
    }

    function premint() public onlyAuthorized {
        require(!preminted);
        _performMint(owner(), TEAM_RESERVED);
        preminted = true;
    }

    function adminMint(address _to, uint256 _amount) public onlyAuthorized {
        _performMint(_to, _amount);
    }

    function setIsSaleActive(bool _isSaleActive) public onlyAuthorized {
        isSaleActive = _isSaleActive;
    }

    function setSalePrice(uint256 _salePrice) public onlyAuthorized {
        salePrice = _salePrice;
    }

    function setWalletLimit(uint256 _walletLimit) public onlyAuthorized {
        walletLimit = _walletLimit;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _performMint(address _to, uint256 amount) private {
        require(_to != address(0), "Cannot mint to 0x0");
        require(amount > 0, "Amount cannot be 0");
        require(amount + totalSupply() <= MAX_SUPPLY, "Sold out, anon");
        _safeMint(_to, amount);
    }

    // Modifiers
    modifier onlyAuthorized() {
        checkAuthorized();
        _;
    }

    function checkAuthorized() private view {
        require(
            _msgSender() == owner() || _msgSender() == developer,
            "Unauthorized"
        );
    }
}