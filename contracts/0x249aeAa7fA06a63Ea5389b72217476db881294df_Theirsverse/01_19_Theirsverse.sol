// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// @title Theirsverse NFT
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "erc721a/contracts/ERC721A.sol";

interface IStarNFT is IERC721, IERC721Enumerable {}

contract Theirsverse is Ownable, ERC721A, Pausable, AccessControl, ReentrancyGuard {
    uint256 public immutable maxSupply;
    uint256 public constant MAX_BATCH_SIZE = 5;

    IStarNFT public starNFT;
    address payable public payment;
    uint256 public saleStartTime;
    bytes32[4] public merkleRoots;
    uint256[4] public whitelistPhasePrices;
    uint256 public goldMemberSalePrice;
    uint256 public publicSalePrice;
    string public baseURI;

    mapping(uint256 => uint256) public amountNFTsGoldMemberSale;
    mapping(address => uint256) public amountNFTsPerWhitelistSale;
    mapping(address => uint256) public amountNFTsPerPublicSale;

    constructor(
        uint256[4] memory _whitelistPhasePrices,
        uint256 _goldMemberSalePrice,
        uint256 _publicSalePrice,
        uint256 _saleStartTime,
        uint256 _maxSupply,
        address _owner,
        address _devAdmin,
        address _starNFTAddress,
        address _paymentAddress
    ) ERC721A("Theirsverse Official", "THEIRS") {
        whitelistPhasePrices = _whitelistPhasePrices;
        goldMemberSalePrice = _goldMemberSalePrice;
        publicSalePrice = _publicSalePrice;
        saleStartTime = _saleStartTime;
        maxSupply = _maxSupply;
        starNFT = IStarNFT(_starNFTAddress);
        payment = payable(_paymentAddress);
        _setupRole(DEFAULT_ADMIN_ROLE, _devAdmin);
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
        transferOwnership(_owner);
    }

    modifier _notContract() {
        uint256 size;
        address addr = msg.sender;
        assembly {
            size := extcodesize(addr)
        }
        require(size == 0, "contract not allowed");
        require(msg.sender == tx.origin, "proxy contract not allowed");
        _;
    }

    modifier _saleBetweenPeriod(uint256 _start, uint256 _end) {
        require(currentTime() >= saleStartTime + _start * 1 days, "sale has not started yet");
        require(currentTime() < saleStartTime + _end * 1 days, "sale is finished");
        _;
    }

    function goldMemberMint(uint256 _quantity)
        external
        payable
        whenNotPaused
        _notContract
        _saleBetweenPeriod(0, 1)
        nonReentrant
    {
        require(_quantity % 10 == 0, "quantity must be a multiple of 10");
        require(totalSupply() + _quantity <= maxSupply, "Max supply exceed");
        uint256 totalPrice = goldMemberSalePrice * _quantity;
        require(msg.value >= totalPrice, "Not enough funds");
        uint256 neededNFTs = _quantity / 10;
        uint256[] memory nfts = verifiedStarNFT(msg.sender, neededNFTs);
        require(nfts.length == neededNFTs, "Goldmember does not own enough verified StarNFTs");
        for (uint256 i = 0; i < neededNFTs; i++) {
            amountNFTsGoldMemberSale[nfts[i]] += 10;
        }
        _batchMint(msg.sender, _quantity);
        refundIfOver(totalPrice);
    }

    function whitelistMint(
        uint256 _quantity,
        bytes32[] calldata _proof,
        uint16 phase
    ) external payable whenNotPaused _notContract _saleBetweenPeriod(1, 2) nonReentrant {
        if (phase == 0 || phase == 1) {
            require(
                amountNFTsPerWhitelistSale[msg.sender] + _quantity <= 1,
                "You can only get 1 NFT on the Whitelist Sale"
            );
        } else {
            require(
                amountNFTsPerWhitelistSale[msg.sender] + _quantity <= 2,
                "You can only get 2 NFT on the Whitelist Sale"
            );
        }
        require(totalSupply() + _quantity <= maxSupply, "Max supply exceed");
        uint256 totalPrice = whitelistPhasePrices[phase] * _quantity;
        require(msg.value >= totalPrice, "Not enough funds");
        require(isWhiteListed(_proof, merkleRoots[phase], msg.sender), "Not Whitelisted");
        amountNFTsPerWhitelistSale[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
        refundIfOver(totalPrice);
    }

    function publicSaleMint(uint256 _quantity)
        external
        payable
        whenNotPaused
        _notContract
        _saleBetweenPeriod(2, 3)
        nonReentrant
    {
        require(amountNFTsPerPublicSale[msg.sender] + _quantity <= 1, "You can only get 1 NFT on the Public Sale");
        require(totalSupply() + _quantity <= maxSupply, "Max supply exceed");
        uint256 totalPrice = publicSalePrice * _quantity;
        require(msg.value >= totalPrice, "Not enough funds");
        amountNFTsPerPublicSale[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
        refundIfOver(totalPrice);
    }

    function goldMemberAirdrop(address[] calldata _accounts, uint256[] calldata _quantity)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        nonReentrant
    {
        require(_accounts.length > 0, "No accounts provided");
        require(_accounts.length == _quantity.length, "Accounts and quantities must have the same length");
        for (uint256 i = 0; i < _accounts.length; i++) {
            uint256 quantity = _quantity[i];
            require(quantity > 0, "Quantity must be greater than 0");
            require(quantity % 10 == 0, "Quantity must be a multiple of 10");
            require(totalSupply() + quantity <= maxSupply, "Max supply exceed");
            uint256 neededNFT = quantity / 10;
            uint256[] memory nfts = verifiedStarNFT(_accounts[i], neededNFT);
            require(nfts.length == neededNFT, "Goldmember does not own enough verified StarNFTs");
            for (uint256 j = 0; j < neededNFT; j++) {
                amountNFTsGoldMemberSale[nfts[j]] += 10;
            }
            _batchMint(_accounts[i], quantity);
        }
    }

    function batchClaim(address[] calldata _accounts, uint256[] calldata _quantity)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        nonReentrant
    {
        require(_accounts.length > 0, "No accounts provided");
        require(_accounts.length == _quantity.length, "Accounts and quantities must have the same length");
        for (uint256 i = 0; i < _accounts.length; i++) {
            uint256 quantity = _quantity[i];
            require(totalSupply() + quantity <= maxSupply, "Max supply exceed");
            _batchMint(_accounts[i], quantity);
        }
    }

    function goldMemberMaxCount(address account) public view returns (uint256) {
        uint256 starNFTCounts = starNFT.balanceOf(account);
        uint256 count = 0;
        for (uint256 i = 0; i < starNFTCounts; i++) {
            uint256 tokenId = starNFT.tokenOfOwnerByIndex(account, i);
            if (amountNFTsGoldMemberSale[tokenId] < 1) {
                count = count + 1;
            }
        }
        return count;
    }

    function withdraw() public {
        uint256 amount = address(this).balance;
        if (amount > 0) {
            Address.sendValue(payment, amount);
        }
    }

    function withdraw(IERC20 token) public {
        uint256 amount = token.balanceOf(address(this));
        require(amount > 0, "No tokens to withdraw");
        SafeERC20.safeTransfer(token, payment, amount);
    }

    function supportsInterface(bytes4 interfaceId) public view override(AccessControl, ERC721A) returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    function setPayment(address _paymentAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        payment = payable(_paymentAddress);
    }

    function setStarNFT(address _starNFTAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        starNFT = IStarNFT(_starNFTAddress);
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function currentTime() private view returns (uint256) {
        return block.timestamp;
    }

    function setBaseURI(string calldata uri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = uri;
    }

    function setMerkleRoot(bytes32[4] calldata _merkleRoots) external onlyRole(DEFAULT_ADMIN_ROLE) {
        merkleRoots = _merkleRoots;
    }

    function setSaleStartTime(uint256 _saleStartTime) external onlyRole(DEFAULT_ADMIN_ROLE) {
        saleStartTime = _saleStartTime;
    }

    function grantAdminRole(address account) external onlyOwner {
        _grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    function revokeAdminRole(address account) external onlyOwner {
        _revokeRole(DEFAULT_ADMIN_ROLE, account);
    }

    function refundIfOver(uint256 price) private {
        if (msg.value > price) {
            Address.sendValue(payable(msg.sender), msg.value - price);
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function verifiedStarNFT(address account, uint256 quantity) private view returns (uint256[] memory) {
        uint256 starNFTCounts = starNFT.balanceOf(account);
        uint256[] memory verified = new uint256[](quantity);
        uint256 verifiedIndex = 0;
        uint256 lastIndex = quantity - 1;
        for (uint256 i = 0; i < starNFTCounts; i++) {
            uint256 tokenId = starNFT.tokenOfOwnerByIndex(account, i);
            if (amountNFTsGoldMemberSale[tokenId] < 1) {
                verified[verifiedIndex] = tokenId;
                if (verifiedIndex == lastIndex) {
                    return verified;
                }
                verifiedIndex = verifiedIndex + 1;
            }
        }
        return new uint256[](0);
    }

    function _batchMint(address _account, uint256 _quantity) internal {
        if (_quantity <= MAX_BATCH_SIZE) {
            _safeMint(_account, _quantity);
        } else {
            uint256 batchNumber = _quantity / MAX_BATCH_SIZE;
            uint256 remainder = _quantity % MAX_BATCH_SIZE;
            uint256 i = 0;
            while (i < batchNumber) {
                _safeMint(_account, MAX_BATCH_SIZE);
                i++;
            }
            if (remainder > 0) {
                _safeMint(_account, remainder);
            }
        }
    }

    function isWhiteListed(
        bytes32[] calldata _proof,
        bytes32 _merkleRoot,
        address _account
    ) private pure returns (bool) {
        return MerkleProof.verify(_proof, _merkleRoot, leaf(_account));
    }

    function leaf(address _account) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account));
    }
}