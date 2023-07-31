// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "hardhat/console.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

error NotTokenOwner();
error NotExists();
error NoETHLeft();
error ETHTransferFailed();

contract NFT is Ownable, ERC721AQueryable, DefaultOperatorFilterer, ERC2981 {
    using Strings for uint256;

    struct UserMintInfo {
        uint256 revenueShareAmount;
        uint256 claimedRevenueShareAmount;
        uint256 freeClaimedAmount;
        bool freeClaimed;
        uint256 wlMintAmount;
    }

    string private baseURI;

    address internal _devWallet;
    ERC721AQueryable public beta;

    uint256 public MAX_TOTAL_SUPPLY;
    uint256 public DISTRIBUTION_AMOUNT = 1;
    uint256 public MINT_PRICE = 0.0077 ether;
    uint256 public PUBLIC_MINT_PRICE = 0.01 ether;
    uint256 public MAX_TOKENS_PER_PURCHASE = 5;
    uint256 public DEV_RESERVE = 200;
    uint256 public revenueSharePercentage = 3000;

    uint256 public totalClaimed;

    bool public mintActive = false;
    bool public isPayoutActive = true;

    bytes32 public root;
    bytes32 public hoppiRoot;

    mapping(uint256 => bool) public betaClaimed;
    mapping(address => UserMintInfo) public userMintInfo;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        address devWallet_,
        address betaContractAddress_,
        uint96 royalty_,
        uint96 maxSupply_,
        bytes32 root_,
        bytes32 hoppiRoot_
    ) ERC721A(_name, _symbol) {
        _devWallet = devWallet_;
        MAX_TOTAL_SUPPLY = maxSupply_;

        setBetaContract(betaContractAddress_);
        setBaseURI(_initBaseURI);
        _setDefaultRoyalty(devWallet_, royalty_);
        setMerkleRoot(root_);
        setHoppiRoot(hoppiRoot_);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, IERC721A, ERC2981) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721A, IERC721A) returns (string memory) {
        if (!_exists(tokenId)) {
            revert NotExists();
        }
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    // Owner functions
    function setMerkleRoot(bytes32 _root) public onlyOwner {
        root = _root;
    }

    function setHoppiRoot(bytes32 _hoppiRoot) public onlyOwner {
        hoppiRoot = _hoppiRoot;
    }

    function setBetaContract(address _betaContractAddress) public onlyOwner {
        require(
            _betaContractAddress != address(0),
            "The Beta contract address can't be 0"
        );

        beta = ERC721AQueryable(_betaContractAddress);
    }

    function setDevWalletAddress(address payable _address) external onlyOwner {
        require(_address != address(0), "Cannot set to zero address");
        _devWallet = _address;
    }

    function setRoyaltyInfo(
        address receiver,
        uint96 feeBasisPoints
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    function toggleMintActive() public onlyOwner {
        mintActive = !mintActive;
    }

    function togglePayoutStatus(bool _isPayoutActive) external onlyOwner {
        if (isPayoutActive != _isPayoutActive) {
            isPayoutActive = _isPayoutActive;
        }
    }

    function withdrawETH() public onlyOwner {
        if (address(this).balance <= 0) {
            revert NoETHLeft();
        }

        (bool success, ) = address(_devWallet).call{
            value: address(this).balance
        }("");

        if (!success) {
            revert ETHTransferFailed();
        }
    }

    /*
        MINT
    */
    function devMintTo(address to, uint256 amount) external onlyOwner {
        require(DEV_RESERVE > 0, "No more dev reserve");
        require(amount <= DEV_RESERVE, "Exceeds dev reserve");
        DEV_RESERVE -= amount;

        _mint(to, amount);
    }

    function mint(
        uint256 _mintAmount,
        address referralWalletAddress,
        bytes32[] calldata _proof
    ) external payable {
        require(
            tx.origin == _msgSenderERC721A(),
            "Purchase cannot be called from another contract"
        );
        require(
            referralWalletAddress != _msgSenderERC721A(),
            "Invalid referral"
        );
        require(mintActive, "Must be active to mint");

        require(
            (totalSupply() + _mintAmount) <= MAX_TOTAL_SUPPLY,
            "Exceeds maximum tokens available for purchase"
        );
        uint256 totalPrice = PUBLIC_MINT_PRICE * _mintAmount; // public mint price

        // check if hoppi holder or wl people first
        // for anyone who already claim free nft then want to mint more on a separate transaction
        // check if already mint 5 for their allocation on top of free claim yet
        if (
            (beta.balanceOf(_msgSenderERC721A()) > 0 ||
                isValid(_proof) ||
                userMintInfo[_msgSenderERC721A()].freeClaimedAmount > 0) &&
            userMintInfo[_msgSenderERC721A()].wlMintAmount + _mintAmount <=
            MAX_TOKENS_PER_PURCHASE
        ) {
            _recordPaidMintAmount(_mintAmount);

            totalPrice = MINT_PRICE * _mintAmount;
        }

        require(
            _mintAmount > 0 && _mintAmount <= MAX_TOKENS_PER_PURCHASE,
            "Exceeds maximum tokens you can purchase in a single transaction"
        );

        require(msg.value >= totalPrice, "ETH amount is not sufficient");

        _handleRevenueShare(referralWalletAddress, totalPrice);
        _mint(_msgSenderERC721A(), _mintAmount);
    }

    function freeMint(
        bytes32[] calldata _proof,
        uint256 _amount
    ) external payable {
        require(
            tx.origin == _msgSenderERC721A(),
            "Purchase cannot be called from another contract"
        );

        require(mintActive, "Must be active to mint");

        require(
            (totalSupply() + _amount) <= MAX_TOTAL_SUPPLY,
            "Exceeds maximum tokens available for purchase"
        );

        require(
            MerkleProof.verify(
                _proof,
                hoppiRoot,
                keccak256(abi.encodePacked(_msgSenderERC721A(), _amount))
            ),
            "Unauthorized whitelist mint this user"
        );

        bool freeClaimed = userMintInfo[_msgSenderERC721A()].freeClaimed;

        require(!freeClaimed, "You already claimed");

        _recordFreeClaim(_amount);

        require(_amount > 0, "no free tokens to claim");

        _mint(_msgSenderERC721A(), _amount);
    }

    function isValid(bytes32[] memory _proof) public view returns (bool) {
        return
            MerkleProof.verify(
                _proof,
                root,
                keccak256(abi.encodePacked(_msgSenderERC721A()))
            );
    }

    function _recordFreeClaim(uint256 _tokensToClaim) internal {
        userMintInfo[_msgSenderERC721A()].freeClaimed = true;
        userMintInfo[_msgSenderERC721A()].freeClaimedAmount += _tokensToClaim;
        totalClaimed += _tokensToClaim;
    }

    function _recordPaidMintAmount(uint256 _paidMintAmount) internal {
        if (_paidMintAmount > 0) {
            userMintInfo[_msgSenderERC721A()].wlMintAmount += _paidMintAmount;
        }
    }

    function burnMany(uint256[] memory tokenIds) public {
        uint256 n = tokenIds.length;
        for (uint256 i = 0; i < n; ++i) {
            address to = ownerOf(tokenIds[i]);
            if (to != _msgSenderERC721A()) {
                revert NotTokenOwner();
            }

            _burn(tokenIds[i], true);
        }
    }

    function _handleRevenueShare(
        address referralWalletAddress,
        uint256 totalPrice
    ) internal {
        uint256 devShareAmount = totalPrice;
        if (referralWalletAddress != address(0)) {
            uint256 referrerRevenueShareAmount = (msg.value *
                revenueSharePercentage) / 10000;

            devShareAmount = totalPrice - referrerRevenueShareAmount;

            _handleRefferal(referralWalletAddress, referrerRevenueShareAmount);
        }

        address to = _devWallet;
        require(to != address(0), "Transfer to zero address");
        (bool success, ) = payable(to).call{value: devShareAmount}("");
        if (!success) {
            revert ETHTransferFailed();
        }
    }

    function _handleRefferal(
        address referralWalletAddress,
        uint256 revenueShareAmount
    ) internal {
        userMintInfo[referralWalletAddress]
            .revenueShareAmount += revenueShareAmount;
    }

    function claimPayout() external {
        require(isPayoutActive, "Payout is not active");

        uint256 payoutAmount = userMintInfo[_msgSenderERC721A()]
            .revenueShareAmount;

        userMintInfo[_msgSenderERC721A()].revenueShareAmount = 0;
        userMintInfo[_msgSenderERC721A()]
            .claimedRevenueShareAmount = payoutAmount;
        address to = _msgSenderERC721A();

        if (address(this).balance <= 0) {
            revert NoETHLeft();
        }

        if (payoutAmount <= 0) {
            revert NoETHLeft();
        }

        require(to != address(0), "Transfer to zero address");
        (bool success, ) = payable(to).call{value: payoutAmount}("");
        if (!success) {
            revert ETHTransferFailed();
        }
    }
}