// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "ERC721A/extensions/ERC721AQueryable.sol";
import "solmate/utils/SSTORE2.sol";
import "solmate/auth/Owned.sol";
import "solmate/utils/LibString.sol";
import "solmate/utils/ReentrancyGuard.sol";
import "openzeppelin-contracts/utils/Address.sol";
import "prb-math/PRBMathUD60x18.sol";
import "./Base64.sol";
import "./TheLPRenderer.sol";

contract TheLP is ERC721AQueryable, Owned, ReentrancyGuard {
    using LibString for uint256;
    using PRBMathUD60x18 for uint256;

    TheLPRenderer renderer;

    event PaymentReceived(address from, uint256 amount);
    event PaymentReleased(address to, uint256 amount);

    uint256 public MAX_SUPPLY;
    uint256 public MAX_PUB_SALE;
    uint256 public MAX_TEAM;
    uint256 public MAX_LP;
    uint256 public DURATION;
    uint256 public MIN_PRICE;
    uint256 public MAX_PRICE;
    uint256 public DISCOUNT_RATE;
    uint256 public startTime;
    uint256 public endTime;
    address public traitsImagePointer;
    uint256 public totalEthClaimed;
    bool public lockedIn = false;
    uint256 public feeSplit = 2 * 10**18;
    mapping(uint256 => uint256) public _rewardDebt;
    mapping(uint256 => TokenMintInfo) public tokenMintInfo;
    struct TokenMintInfo {
        bytes32 seed;
        uint256 cost;
    }

    error TokenNotForSale();
    error IncorrectPayment();
    error AlreadyLocked();
    error NotGameOver();
    error AlreadyGameOver();
    error LockedIn();
    error CannotRedeem();
    error InvalidTokenId(uint256 tokenId);
    error NotOwner(uint256 tokenId);
    error AuctionEnded();
    error NotStarted();
    error AmountRequired();
    error SoldOut();
    error NotLockedIn();

    bytes32 teamMintBlockHash;
    bytes32 lpMintBlockHash;
    address teamMintWallet;

    constructor(
        string memory name,
        string memory symbol,
        uint256 _startTime,
        TheLPRenderer _renderer,
        uint256 minPrice,
        uint256 maxPrice,
        uint256 maxPubSale,
        uint256 maxTeam,
        uint256 maxLp,
        uint256 duration,
        address _teamMintWallet
    ) ERC721A(name, symbol) Owned(msg.sender) {
        startTime = _startTime;
        endTime = startTime + duration;
        renderer = _renderer;
        MIN_PRICE = minPrice;
        MAX_PRICE = maxPrice;
        MAX_LP = maxLp;
        MAX_TEAM = maxTeam;
        MAX_PUB_SALE = maxPubSale;
        MAX_SUPPLY = MAX_LP + MAX_TEAM + MAX_PUB_SALE;
        DURATION = duration;
        DISCOUNT_RATE = uint256(MAX_PRICE - MIN_PRICE).div((duration) * 10**18);
        teamMintWallet = _teamMintWallet;
        _mintERC2309(teamMintWallet, MAX_TEAM);
        teamMintBlockHash = blockhash(block.number - 1);
    }

    /// @dev Public function to get the usable ETH balanance.
    /// This balance does not include ETH set aside of holder fees.
    function getEthBalance() external view returns (uint256) {
        return _getEthBalance(0);
    }

    /// @dev Private function to get usable ETH balance of the smart contract.
    /// This ETH balance is what is used for liquidity. It should not include
    /// ETH that is set aside for fees. Includes minus argument to subtract
    /// msg.value which should not be included in calculation.
    function _getEthBalance(uint256 minus) private view returns (uint256) {
        uint256 balance = address(this).balance - minus;
        uint256 fees = getFeeBalance();
        if (fees > balance) return 0;
        return balance - fees;
    }

    /// @dev Public function to update the fee split
    function updateFeeSplit(uint256 newSplit) public onlyOwner {
        feeSplit = newSplit;
    }

    /// @dev Public get price function
    function getBuyPrice() external view returns (uint256, uint256) {
        return _getBuyPrice(0);
    }

    /// @dev Internal function to get the current price and fee
    function _getPrice(uint256 minus, bool isBuy)
        internal
        view
        returns (uint256, uint256)
    {
        uint256 balance = balanceOf(address(this));
        uint256 priceA = _getEthBalance(minus).div(balance * 10**18);
        if (isBuy) {
            balance -= 1;
        } else {
            balance += 1;
        }
        uint256 priceB = _getEthBalance(minus).div(balance * 10**18);
        uint256 fee;
        if (priceB > priceA) {
            fee = priceB - priceA;
        } else {
            fee = priceA - priceB;
        }
        return (priceB, fee);
    }

    /// @dev Get buy price. Includes minus params to account for
    /// additional msg.value that should not be part of calculation.
    function _getBuyPrice(uint256 minus)
        private
        view
        returns (uint256, uint256)
    {
        return _getPrice(minus, true);
    }

    /// @dev Public get sell price function
    function getSellPrice() external view returns (uint256, uint256) {
        return _getSellPrice(0);
    }

    /// @dev Get sell price. Includes minus params to account for
    /// additional msg.value that should not be part of calculation.
    function _getSellPrice(uint256 minus)
        private
        view
        returns (uint256, uint256)
    {
        return _getPrice(minus, false);
    }

    /// @dev Function used to buy an NFT within the LP contract
    /// Must send buy price. Will refund any additional amounts.
    function buy(uint256 id) public payable nonReentrant {
        if (ownerOf(id) != address(this)) {
            revert NotOwner(id);
        }
        (uint256 cost, uint256 fee) = _getBuyPrice(msg.value);
        if (msg.value < cost) {
            revert IncorrectPayment();
        }

        _totalFees += fee.div(feeSplit);

        // Approve sender to move this token
        // ERC721a doesn't abstract transfer functionality by default
        _tokenApprovals[id].value = msg.sender;
        transferFrom(address(this), msg.sender, id);

        uint256 refund = msg.value - cost;
        if (refund > 0) {
            Address.sendValue(payable(msg.sender), refund);
        }
    }

    error ApprovalRequired(uint256 tokenId);

    /// @dev Function used to sell an NFT
    /// Token ID must be owned by msg.sender
    function sell(uint256 tokenId) public payable nonReentrant {
        if (ownerOf(tokenId) != msg.sender) {
            revert NotOwner(tokenId);
        }
        (uint256 sellPrice, uint256 fee) = _getSellPrice(msg.value);
        _totalFees += fee.div(feeSplit);
        transferFrom(msg.sender, address(this), tokenId);
        Address.sendValue(payable(msg.sender), sellPrice);
    }

    uint256 private _totalFees;

    /// @dev Function to get the total fees accumulated over time
    function getFeeBalance() public view returns (uint256) {
        return _totalFees;
    }

    /// @dev Function to manually migrate ETH from pool
    /// Can be disabled by changing owner to address(0)
    function migrate(uint256 amount) public onlyOwner {
        Address.sendValue(payable(owner), amount);
    }

    /// @dev Public function that can be used to calculate the pending ETH payment for a given NFT ID
    function calculatePendingPayment(uint256 nftId)
        public
        view
        returns (uint256)
    {
        uint256 a = getFeeBalance() + totalEthClaimed - _rewardDebt[nftId];
        if (a == 0) return 0;
        return (a).div(MAX_SUPPLY * 10**18);
    }

    error InvalidDepositAmount();

    /// @dev External function that can be used to add to ETH pool and total fees
    function externalDeposit(uint256 amountTowardsFees)
        external
        payable
        returns (bool)
    {
        if (msg.value == 0) {
            revert InvalidDepositAmount();
        }
        if (amountTowardsFees > msg.value) {
            revert InvalidDepositAmount();
        }
        _totalFees += amountTowardsFees;
        return true;
    }

    error NothingToClaim();

    /// @dev Internal function used to claim share of fees for a given NFT ID
    /// Throws if trying to claim for NFTs in pool
    function _claim(uint256 nftId) private {
        if (!lockedIn) {
            revert NotLockedIn();
        }
        uint256 payment = calculatePendingPayment(nftId);
        if (payment == 0) {
            revert NothingToClaim();
        }
        totalEthClaimed += payment;
        address ownerAddr = ownerOf(nftId);
        if (ownerAddr == address(this)) {
            revert NothingToClaim();
        }
        _totalFees -= payment;
        _rewardDebt[nftId] = _totalFees + totalEthClaimed;
        Address.sendValue(payable(ownerAddr), payment);
        emit PaymentReleased(ownerAddr, payment);
    }

    /// @dev Public function used to claim share of available fees for a given NFT ID
    function claim(uint256 nftId) public nonReentrant {
        _claim(nftId);
    }

    /// @dev Convenience method to claim fees for many NFT IDs
    function claimMany(uint256[] memory nftIds) public nonReentrant {
        for (uint256 i = 0; i < nftIds.length; i++) {
            _claim(nftIds[i]);
        }
    }

    /// @dev Get on-chain token URI
    /// Accounts for NFTs that were minted using ERC-2309
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A, IERC721A)
        returns (string memory)
    {
        bytes32 seed;
        // 1 - 1000
        if (tokenId <= MAX_TEAM) {
            seed = keccak256(abi.encodePacked(teamMintBlockHash, tokenId));
            // 9001 - 10000
        } else if (tokenId >= MAX_PUB_SALE + MAX_TEAM + 1) {
            seed = keccak256(abi.encodePacked(lpMintBlockHash, tokenId));
        } else {
            // 1001 - 9000
            seed = tokenMintInfo[tokenId].seed;
        }
        return renderer.getJsonUri(tokenId, seed);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /// @dev Public function that returns game over status
    function isGameOver() public view returns (bool) {
        return block.timestamp >= endTime && _totalMinted() < MAX_SUPPLY;
    }

    /// @dev Private function to redeem mint costs for a given NFT ID
    function _redeem(uint256 tokenId) private {
        if (tokenMintInfo[tokenId].cost == 0) {
            revert InvalidTokenId(tokenId);
        }
        if (ownerOf(tokenId) != msg.sender) {
            revert NotOwner(tokenId);
        }
        Address.sendValue(payable(msg.sender), tokenMintInfo[tokenId].cost);
        tokenMintInfo[tokenId].cost = 0;
    }

    /// @dev Public function to redeem mint costs for multiple NFT IDs
    /// This function can only be called if game over is true.
    function redeem(uint256[] memory tokenIds) public nonReentrant {
        if (!isGameOver()) {
            revert NotGameOver();
        }

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _redeem(tokenIds[i]);
        }
    }

    /// @dev This function disables transfers until mint is complete.
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        if (from == address(0)) return;
        if (!lockedIn) {
            revert NotLockedIn();
        }
    }

    /// @dev Private function that is called once the last NFT of public sale is minted.
    function _lockItIn() private {
        if (lockedIn) {
            revert AlreadyLocked();
        }
        uint256 half = address(this).balance.div(2 * 10**18);
        Address.sendValue(payable(owner), half);
        lpMintBlockHash = blockhash(block.number - 1);
        _mintERC2309(address(this), MAX_LP);
        lockedIn = true;
    }

    /// @dev Gets the current mint price for dutch auction
    function getCurrentMintPrice() public view returns (uint256) {
        if (block.timestamp < startTime) {
            revert NotStarted();
        }
        uint256 timeElapsed = block.timestamp - startTime;
        uint256 discount = DISCOUNT_RATE * timeElapsed;
        if (discount > MAX_PRICE) return MIN_PRICE;
        return MAX_PRICE - discount;
    }

    /// @dev Public mint function
    /// Must pass msg.value greater than or equal to current mint price * amount
    function mint(uint256 amount) public payable nonReentrant {
        if (block.timestamp >= endTime) {
            revert AuctionEnded();
        }
        if (block.timestamp < startTime) {
            revert NotStarted();
        }
        if (amount <= 0) {
            revert AmountRequired();
        }
        uint256 totalMinted = _totalMinted();
        uint256 totalAfterMint = totalMinted + amount;
        if (totalAfterMint > MAX_PUB_SALE + MAX_TEAM) {
            revert SoldOut();
        }
        uint256 mintPrice = getCurrentMintPrice();
        uint256 totalCost = amount * mintPrice;
        if (msg.value < totalCost) {
            revert IncorrectPayment();
        }
        uint256 current = _nextTokenId();
        uint256 end = current + amount - 1;

        for (; current <= end; current++) {
            tokenMintInfo[current] = TokenMintInfo({
                seed: keccak256(
                    abi.encodePacked(blockhash(block.number - 1), current)
                ),
                cost: mintPrice
            });
        }
        uint256 refund = msg.value - totalCost;
        if (refund > 0) {
            Address.sendValue(payable(msg.sender), refund);
        }
        _mint(msg.sender, amount);
        if (totalAfterMint == MAX_PUB_SALE + MAX_TEAM) {
            _lockItIn();
        }
    }

    /// @dev Receive function called when this contract receives Ether
    receive() external payable virtual {
        emit PaymentReceived(msg.sender, msg.value);
    }
}