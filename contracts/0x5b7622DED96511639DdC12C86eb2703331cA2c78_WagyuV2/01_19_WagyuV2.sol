// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../lib/OGBlockBasedSale.sol";

contract WagyuV2 is
    Ownable,
    ERC721,
    ERC721Enumerable,
    OGBlockBasedSale,
    ReentrancyGuard
{
    using Address for address;
    using SafeMath for uint256;

    event Airdrop(address[] addresses, uint256 amount);
    event AssignAirdropAddress(address indexed _address);
    event AssignBaseURI(string _value);
    event AssignDefaultURI(string _value);
    event AssignRevealBlock(uint256 _blockNumber);
    event Purchased(address indexed account, uint256 indexed index);
    event MintAttempt(address indexed account, bytes data);
    event PermanentURI(string _value, uint256 indexed _id);
    event WithdrawNonPurchaseFund(uint256 balance);

    PaymentSplitter private _splitter;

    struct revenueShareParams {
        address[] payees;
        uint256[] shares;
    }

    uint256 public revealBlock = 0;
    uint256 public maxSaleCapped = 1;

    string public _defaultURI;
    string public _tokenBaseURI;
    mapping(address => bool) private _airdropAllowed;
    mapping(address => uint256) public purchaseCount;

    constructor(
        string memory name,
        string memory symbol,
        uint256 _maxSupply,
        uint256 price,
        revenueShareParams memory revenueShare
    ) ERC721(name, symbol) {
        _splitter = new PaymentSplitter(
            revenueShare.payees,
            revenueShare.shares
        );
        maxSupply = _maxSupply;
        publicSalePrice = price;
    }

    modifier airdropRoleOnly() {
        require(_airdropAllowed[msg.sender], "Only airdrop role allowed.");
        _;
    }

    modifier shareHolderOnly() {
        require(_splitter.shares(msg.sender) > 0, "not a shareholder");
        _;
    }

    function airdrop(address[] memory addresses, uint256 amount)
        external
        nonReentrant
        airdropRoleOnly
    {
        require(
            totalSupply().add(addresses.length.mul(amount)) <= maxSupply,
            "Exceed max supply limit."
        );

        require(
            totalReserveMinted.add(addresses.length.mul(amount)) <= maxReserve,
            "Insufficient reserve."
        );

        totalReserveMinted = totalReserveMinted.add(
            addresses.length.mul(amount)
        );

        for (uint256 i = 0; i < addresses.length; i++) {
            _mintToken(addresses[i], amount);
        }
        emit Airdrop(addresses, amount);
    }

    function setAirdropRole(address addr) external onlyOwner {
        emit AssignAirdropAddress(addr);
        _airdropAllowed[addr] = true;
    }

    function setRevealBlock(uint256 blockNumber) external operatorOnly {
        emit AssignRevealBlock(blockNumber);
        revealBlock = blockNumber;
    }

    function mintToken(uint256 amount, bytes calldata signature)
        external
        payable
        nonReentrant
        returns (bool)
    {
        require(msg.sender == tx.origin, "Contract is not allowed.");
        require(
            getState() == SaleState.PublicSaleDuring,
            "Sale not available."
        );

        if (getState() == SaleState.PublicSaleDuring) {
            require(
                amount <= maxPublicSalePerTx,
                "Mint exceed transaction limits."
            );
            require(
                msg.value >= amount.mul(getPriceByMode()),
                "Insufficient funds."
            );
            require(
                totalSupply().add(amount).add(availableReserve()) <= maxSupply,
                "Purchase exceed max supply."
            );
        }

        require(
            purchaseCount[msg.sender] + amount <= maxSaleCapped,
            "Max purchase reached"
        );

        emit MintAttempt(msg.sender, signature);

        if (getState() == SaleState.PublicSaleDuring) {
            _mintToken(msg.sender, amount);
            totalPublicMinted = totalPublicMinted + amount;
            if (isSubsequenceSale()) {
                nextSubsequentSale = block.number + subsequentSaleBlockSize;
            }
            payable(_splitter).transfer(msg.value);
        }

        return true;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _tokenBaseURI = baseURI;
        emit AssignBaseURI(baseURI);
    }

    function setDefaultURI(string memory defaultURI) external onlyOwner {
        _defaultURI = defaultURI;
        emit AssignDefaultURI(defaultURI);
    }

    function tokenBaseURI() external view returns (string memory) {
        return _tokenBaseURI;
    }

    function isRevealed() public view returns (bool) {
        return revealBlock > 0 && block.number > revealBlock;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(tokenId <= totalSupply(), "Token not exist.");

        return
            isRevealed()
                ? string(
                    abi.encodePacked(
                        _tokenBaseURI,
                        Strings.toString(tokenId),
                        ".json"
                    )
                )
                : _defaultURI;
    }

    function availableForSale() external view returns (uint256) {
        return maxSupply - totalSupply();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function release(address payable account) external virtual shareHolderOnly {
        require(
            msg.sender == account || msg.sender == owner(),
            "Release: no permission"
        );

        _splitter.release(account);
    }

    function withdraw() external governorOnly {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
        emit WithdrawNonPurchaseFund(balance);
    }

    function _mintToken(address addr, uint256 amount) internal returns (bool) {
        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenIndex = totalSupply();
            purchaseCount[addr] += 1;
            if (tokenIndex < maxSupply) {
                _safeMint(addr, tokenIndex + 1);
                emit Purchased(addr, tokenIndex);
            }
        }
        return true;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}