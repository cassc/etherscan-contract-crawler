//SPDX-License-Identifier: MIT
// Website : https://genpad.io

pragma solidity ^0.8.17;

import "./ERC721AQueryable.sol";
import "./IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract GENPADNFT_v4 is ERC721A, ERC721AQueryable, Ownable, ReentrancyGuard {
    struct SharedData {
        uint256 totalAmount;
        uint256 totalBoostedAmount;
        uint256 rewardPerShareEth;
        uint256 rewardPerShareToken;
    }

    struct Reward {
        uint256 totalExcludedEth; // excluded reward
        uint256 totalExcludedToken;
        uint256 lastClaim;
    }

    struct UserData {
        uint256 amount;
        uint256 boostedAmount;
        uint256 nftAmount;
        uint256 lockedTime;
    }

    //ERC Mapping
    struct TokenInfo {
        string name;
        address addr;
        uint256 price;
        bool enabled;
    }

    IERC20 public rewardToken;

    // Public variables
    uint256 public constant ACC_FACTOR = 10 ** 36;
    uint256 public MAX_MINTS = 100;
    uint256 public MAX_SUPPLY = 1000;
    uint256 public minLockTime = 7 days;
    uint256 public boostPerNft = 5; //5%
    uint256 public maxBoostAmount = 50; //50%
    uint256 public totalEthClaimed;
    uint256 public totalTokenClaimed;
    uint256 private addedTokens;

    bool public transferEnabled = true;
    bool public multisaleEnable = false;
    bool public bypricesaleEnable = false;
    bool public specialsaleEnable = true;

    // Special Mint
    uint256 public specialEthPrice;
    uint256 public specialTokenPrice;
    address public specialToken;
    uint256 public transferPrice = 0.05 ether;

    uint256 public refFee = 10; //10%

    SharedData public sharedData;

    bool public claimEnable = false;
    bool public lockEnable = true;
    bool public zeroLock;

    //mappings
    mapping(address => uint256) public ref;
    mapping(address => UserData) public userData;
    mapping(address => bool) public isExempted;
    mapping(address => bool) public isLocked;
    mapping(address => bool) public isBlackListed;
    mapping(address => Reward) public rewards;
    mapping(uint256 => TokenInfo) public allowedCrypto;

    // Royalties address
    address public royaltyAddress = 0x363D4053cfB4C77597117f1c5f178F3668801109;

    // Treasure address
    address public treasureAddress;

    // Royalties basis points (percentage using 2 decimals - 1000 = 100, 500 = 50, 0 = 0) 10% artist 90% flipper
    uint256 private royaltyBasisPoints = 100; // 10%

    //NFT events
    event RoyaltyBasisPoints(uint256 indexed _royaltyBasisPoints);
    event MintedNft(uint256 indexed _quantity, address add);
    event RoyaltyAddressUpdated(
        address newAddress,
        address oldAddress,
        uint256 time
    );
    event UriUpdated(string newUri, uint256 time);
    event MintsPerWalletUpdated(
        uint256 newAmount,
        uint256 oldAmount,
        uint256 time
    );
    event MaxSupplyUpdated(uint256 newAmount, uint256 oldAmount, uint256 time);
    event NewLock(address user, uint256 amount, uint256 boost);
    event RefFeeUpdated(uint256 newRefFee, uint256 oldRefFee, uint256 time);
    event RewardDeposited(bool isEth, uint256 amount, uint256 time);

    //Staking events
    event ClaimRewards(
        uint256 tokenId,
        uint256 _ethAmount,
        uint256 _tokenAmount,
        address recipient
    );

    string public baseURI = "ipfs://bafybeickwunetdegtuzpltrhhog5vlc2uhwp4gwxrg5iag34l3kxhqeshq/";

    address private signerAddress = 0xE10C4022882D087Ea412CbFdA745Ff841089E7Fe;

    /* CONSTRUCTOR */
    constructor() ERC721A("GenPad NFTs", "yGENS") {
        allowedCrypto[addedTokens] = TokenInfo("ETH", address(0), 0.5 ether, true);
        addedTokens++;
    }

    //  NFT Contract section
    function setrewardTokenAddress(address tokenAddress) external onlyOwner {
        rewardToken = IERC20(tokenAddress);
    }

    // Token Id start from 1
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function TotalBurned() public view returns (uint256) {
        return _totalBurned();
    }

    function next() public view returns (uint256) {
        return _nextTokenId();
    }

    function toggleStatus(
        bool _specialsaleEnable,
        bool _bypricesaleEnable,
        bool _multisaleEnable,
        bool _transferEnabled
    ) external onlyOwner {
        specialsaleEnable = _specialsaleEnable;
        bypricesaleEnable = _bypricesaleEnable;
        multisaleEnable = _multisaleEnable;
        transferEnabled = _transferEnabled;
    }

    function setminLockTime(uint256 _minLockTime) external onlyOwner {
        minLockTime = _minLockTime;
    }


    function getSigner(
        address _toAddress,
        uint _quantity,
        address _refAddrses,
        bytes memory signature
    ) internal pure returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(_toAddress, _quantity, _refAddrses)
        );
        bytes32 message = ECDSA.toEthSignedMessageHash(hash);
        address signer = ECDSA.recover(message, signature);
        return signer;
    }

    function getSignerWithPrice(
        address _toAddress,
        uint _quantity,
        uint256 _price,
        bytes memory signature
    ) internal pure returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(_toAddress, _quantity, _price)
        );
        bytes32 message = ECDSA.toEthSignedMessageHash(hash);
        address signer = ECDSA.recover(message, signature);
        return signer;
    }

    function getSignerWithPriceRef(
        address _toAddress,
        uint _quantity,
        uint256 _price,
        address _refAddrses,
        bytes memory signature
    ) internal pure returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(_toAddress, _quantity, _price, _refAddrses)
        );
        bytes32 message = ECDSA.toEthSignedMessageHash(hash);
        address signer = ECDSA.recover(message, signature);
        return signer;
    }

    function giftmint(uint256 _quantity, address add) external onlyOwner {
        // _safeMint's second argument now takes in a quantity, not a tokenId.
        require(
            totalSupply() + _quantity <= MAX_SUPPLY,
            "Not enough tokens left"
        );
        _mint(add, _quantity);
        emit MintedNft(_quantity, add);
    }

    function emergencyWithdraw() external payable onlyOwner {
        (bool success,) = payable(owner()).call{value : address(this).balance}(
            ""
        );
        require(success, "eth transfer failed");
    }

    // Emergency ERC20 withdrawal

    function rescueERC20(address tokenAdd, uint256 amount) external onlyOwner {
        require(
            IERC20(tokenAdd).balanceOf(address(this)) >= amount,
            'Insufficient ERC20 balance'
        );
        IERC20(tokenAdd).transfer(owner(), amount);
    }

    // returns base uri
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // Set royalty  address
    function setRoyaltyAddress(address _address) external onlyOwner {
        require(_address != address(0), "zero address passed");
        address oldAddress = royaltyAddress;
        royaltyAddress = _address;
        emit RoyaltyAddressUpdated(_address, oldAddress, block.timestamp);
    }

    // Set base URI
    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
        emit UriUpdated(_uri, block.timestamp);
    }

    // Set royalty basis points
    function setRoyaltyBasisPoints(uint256 _basisPoints) external onlyOwner {
        require(_basisPoints <= 1000, "more than 100%");
        royaltyBasisPoints = _basisPoints;
        emit RoyaltyBasisPoints(_basisPoints);
    }

    // Set new limit per wallet
    function changeMaxMintPerWallet(
        uint256 _max_mint_amount
    ) external onlyOwner {
        uint256 oldAmount = MAX_MINTS;
        MAX_MINTS = _max_mint_amount;
        emit MintsPerWalletUpdated(
            _max_mint_amount,
            oldAmount,
            block.timestamp
        );
    }

    // Set new max supply
    function changeMaxSupply(uint256 _newSupply) external onlyOwner {
        require(
            _newSupply > MAX_SUPPLY,
            "new supply cannot be less than current"
        );
        uint256 oldSupply = MAX_SUPPLY;
        MAX_SUPPLY = _newSupply;
        emit MaxSupplyUpdated(_newSupply, oldSupply, block.timestamp);
    }

    // TokenURI
    function tokenURI(
        uint256 tokenId
    ) public view virtual override(IERC721A, ERC721A) returns (string memory) {
        require(_exists(tokenId), "Nonexistent token");
        return string(abi.encodePacked(_baseURI(), _toString(tokenId), ".json"));
    }

    function lock(uint256 amount) external {
        require(lockEnable, "lock temporary suspended");
        require(!isBlackListed[_msgSender()], "you are blacklisted");

        uint256 nftBalance = balanceOf(_msgSender());
        require(amount > 0, "zero amount input");

        uint256 totalAmount = amount * 10 ** rewardToken.decimals();
        require(
            rewardToken.transferFrom(_msgSender(), address(this), totalAmount),
            "token transfer failed"
        );

        isLocked[_msgSender()] = true;
        uint256 boostMultiplier;

        if (zeroLock) {
            boostMultiplier = (nftBalance * boostPerNft) > maxBoostAmount
            ? maxBoostAmount
            : (nftBalance) * boostPerNft;
        } else {
            require(nftBalance > 0, "nft balance 0");
            boostMultiplier = ((nftBalance - 1) * boostPerNft) > maxBoostAmount
            ? maxBoostAmount
            : (nftBalance - 1) * boostPerNft;
        }

        uint256 boostedAmount = totalAmount +
        (totalAmount * boostMultiplier) /
        100;

        sharedData.totalAmount += totalAmount;
        sharedData.totalBoostedAmount += boostedAmount;

        userData[_msgSender()].amount += totalAmount;
        userData[_msgSender()].boostedAmount += boostedAmount;
        userData[_msgSender()].nftAmount = nftBalance;
        userData[_msgSender()].lockedTime = block.timestamp;

        (
        rewards[_msgSender()].totalExcludedEth,
        rewards[_msgSender()].totalExcludedToken
        ) = getCumulativeRewards(userData[_msgSender()].boostedAmount);

        emit NewLock(_msgSender(), totalAmount, boostMultiplier);
    }

    function unlock() public nonReentrant {
        require(lockEnable, "unlock temporary suspended");
        require(!isBlackListed[_msgSender()], "you are blacklisted");
        require(
            block.timestamp >= userData[_msgSender()].lockedTime + minLockTime,
            "lock not ended"
        );
        sharedData.totalAmount -= userData[_msgSender()].amount;
        sharedData.totalBoostedAmount -= userData[_msgSender()].boostedAmount;

        //claim reward
        (uint256 unclaimedAmountEth, uint256 unclaimedAmountToken) = getUnpaid(
            _msgSender()
        );
        if (unclaimedAmountEth > 0 || unclaimedAmountToken > 0) {
            _claim(_msgSender());
        }

        require(
            rewardToken.transfer(_msgSender(), userData[_msgSender()].amount),
            "token transfer failed"
        );
        isLocked[_msgSender()] = false;
        delete userData[_msgSender()];
    }

    function depositRewardEth() external payable {
        require(msg.value > 0, "value must be greater than 0");
        require(
            sharedData.totalBoostedAmount > 0,
            "must be shares deposited to be rewarded rewards"
        );
        sharedData.rewardPerShareEth +=
        (msg.value * ACC_FACTOR) /
        sharedData.totalBoostedAmount;
        emit RewardDeposited(true, msg.value, block.timestamp);
    }

    function depositRewardToken(uint256 amount) external payable {
        require(amount > 0, "value must be greater than 0");
        require(
            sharedData.totalBoostedAmount > 0,
            "must be shares deposited to be rewarded rewards"
        );
        require(
            rewardToken.transferFrom(_msgSender(), address(this), amount),
            "token transfer failed"
        );
        sharedData.rewardPerShareToken +=
        (amount * ACC_FACTOR) /
        sharedData.totalBoostedAmount;
        emit RewardDeposited(false, amount, block.timestamp);
    }

    function getCumulativeRewards(
        uint256 share
    ) internal view returns (uint256, uint256) {
        return (
        (share * sharedData.rewardPerShareEth) / ACC_FACTOR,
        (share * sharedData.rewardPerShareToken) / ACC_FACTOR
        );
    }

    function getUnpaid(
        address shareholder
    ) public view returns (uint256, uint256) {
        if (userData[shareholder].amount == 0) {
            return (0, 0);
        }

        (
        uint256 earnedRewardsEth,
        uint256 earnedRewardsToken
        ) = getCumulativeRewards(userData[shareholder].boostedAmount);
        uint256 rewardsExcludedEth = rewards[shareholder].totalExcludedEth;
        uint256 rewardsExcludedToken = rewards[shareholder].totalExcludedToken;
        if (
            earnedRewardsEth <= rewardsExcludedEth &&
            earnedRewardsToken <= rewardsExcludedToken
        ) {
            return (0, 0);
        }

        return (
        (earnedRewardsEth - rewardsExcludedEth),
        (earnedRewardsToken - rewardsExcludedToken)
        );
    }

    function claim() external nonReentrant {
        _claim(_msgSender());
    }

    function _claim(address user) internal {
        require(
            block.timestamp > rewards[user].lastClaim,
            "can only claim once per block"
        );
        require(!isBlackListed[user], "you are blacklisted");
        require(claimEnable, "claim temporary disabled");
        require(userData[user].amount > 0, "no tokens staked");
        (uint256 amountEth, uint256 amountToken) = getUnpaid(user);
        require(amountEth > 0 || amountToken > 0, "nothing to claim");
        if (amountEth > 0) {
            totalEthClaimed += amountEth;
            (rewards[user].totalExcludedEth,) = getCumulativeRewards(
                userData[user].boostedAmount
            );
            _handleEthTransfer(user, amountEth);
        }
        if (amountToken > 0) {
            totalTokenClaimed += amountToken;
            (, rewards[user].totalExcludedToken) = getCumulativeRewards(
                userData[user].boostedAmount
            );
            require(rewardToken.transfer(user, amountToken));
        }

        rewards[user].lastClaim = block.timestamp;
    }

    function flipZeroLockStatus() external onlyOwner {
        zeroLock = !zeroLock;
    }

    function flipLockStatus() external onlyOwner {
        lockEnable = !lockEnable;
    }

    function flipClaimStatus() external onlyOwner {
        claimEnable = !claimEnable;
    }

    function changeBoostPerNft(uint256 newBoost) external onlyOwner {
        //require(newBoost < Max_Value?, "boost exceed max value");
        boostPerNft = newBoost;
    }

    function changeMaxBoost(uint256 newMaxBoost) external onlyOwner {
        //require(newMaxBoost < Max_Value?, "max boost exceed max value");
        maxBoostAmount = newMaxBoost;
    }

    function setTreasureAddress(address _newTreasure) external onlyOwner {
        treasureAddress = _newTreasure;
    }

    function setSigner(address _signer) external onlyOwner {
        signerAddress = _signer;
    }

    function toggleBlacklistStatus(address[] memory users, bool[] memory status) external onlyOwner {
        require(users.length == status.length && users.length > 0, "wrong input");
        for (uint i = 0; i < users.length; i++) {
            isBlackListed[users[i]] = status[i];
        }
    }

    function toggleExemptionStatus(address[] memory users, bool[] memory status) external onlyOwner {
        require(users.length == status.length && users.length > 0, "wrong input");
        for (uint i = 0; i < users.length; i++) {
            isExempted[users[i]] = status[i];
        }
    }

    function changeRefFee(uint256 _newRefFee) external onlyOwner {
        require(_newRefFee <= 100, "More than 100%");
        uint256 oldRefFee = refFee;
        refFee = _newRefFee;
        emit RefFeeUpdated(_newRefFee, oldRefFee, block.timestamp);
    }

    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    //Multi ERC-Special

    //Add ERC20 Payment Tokens
    function addCurrency(
        string memory _name,
        address _add,
        uint256 _priceInWei,
        bool _enabled
    ) external onlyOwner {
        allowedCrypto[addedTokens] = TokenInfo(
            _name,
            _add,
            _priceInWei,
            _enabled
        );
        addedTokens++;
    }

    // Disable Payment Tokens
    function disableToken(uint256 _id, bool _toggle) external onlyOwner {
        allowedCrypto[_id].enabled = _toggle;
    }

    function setSpecialMint(
        address tokenAddress,
        uint256 ethPrice,
        uint256 tokenPrice
    ) external onlyOwner {
        require(tokenAddress != address(0), "zero address");
        specialToken = tokenAddress;
        specialEthPrice = ethPrice;
        specialTokenPrice = tokenPrice;
    }

    function specialMint(uint256 _quantity) external payable {
        require(specialToken != address(0), "special method not set");
        require(specialsaleEnable, "Special Sale is not Enabled");
        require(
            _quantity + _numberMinted(_msgSender()) <= MAX_MINTS,
            "Exceeded the limit"
        );
        require(
            totalSupply() + _quantity <= MAX_SUPPLY,
            "Not enough tokens left"
        );
        require(
            msg.value >= specialEthPrice * _quantity,
            "Not enough ETH send"
        );
        _handleEthTransfer(owner(), msg.value);
        IERC20 tokenAddress = IERC20(specialToken);
        uint256 totalTokenPrice = specialTokenPrice * _quantity;
        require(
            tokenAddress.transferFrom(msg.sender, owner(), totalTokenPrice),
            "token transfer failed"
        );
        _safeMint(_msgSender(), _quantity);
        emit MintedNft(_quantity, _msgSender());
    }

    function specialMintByRef(
        uint256 _quantity,
        address _refAddress,
        bytes memory signature
    ) external payable {
        address _toAddress = _msgSender();
        require(specialToken != address(0), "special method not set");
        require(specialsaleEnable, "Special Sale is not Enabled");
        require(
            _quantity + _numberMinted(_msgSender()) <= MAX_MINTS,
            "Exceeded the limit"
        );
        require(
            totalSupply() + _quantity <= MAX_SUPPLY,
            "Not enough tokens left"
        );
        require(
            getSigner(_toAddress, _quantity, _refAddress, signature) ==
            signerAddress,
            "ECDSA check failed"
        );
        require(_refAddress != _toAddress, "Don't cheat");

        //transfer eth
        uint256 amountToRefEth = (msg.value * refFee) / 100;
        uint256 mintFeeEth = msg.value - amountToRefEth;
         _handleEthTransfer(owner(), mintFeeEth);
        _handleEthTransfer(_refAddress, amountToRefEth);
       

        //transfer tokens
        IERC20 tokenAddress = IERC20(specialToken);
        uint256 totalPrice = specialTokenPrice * _quantity;
        uint256 amountToRefToken = (totalPrice * refFee) / 100;
        uint256 mintFeeToken = totalPrice - amountToRefToken;
        require(
            tokenAddress.transferFrom(
                msg.sender,
                _refAddress,
                amountToRefToken
            ),
            "transfer to ref failed"
        );
        require(
            tokenAddress.transferFrom(msg.sender, owner(), mintFeeToken),
            "transfer to owner failed"
        );

        _safeMint(_msgSender(), _quantity);
        emit MintedNft(_quantity, _msgSender());
    }

    function specialTransferFrom(
        address from,
        address to,
        uint256[] memory tokenIds
    ) public payable virtual {
        require(!isBlackListed[from], "you are blacklisted");
        require(!isLocked[from], "unlock tokens before transfer");
        require(tokenIds.length > 0, "empty array");
        require(
            msg.value >= tokenIds.length * transferPrice,
            "not enough eth sent"
        );
        for (uint i = 0; i < tokenIds.length; i++) {
            super.transferFrom(from, to, tokenIds[i]);
        }
        _handleEthTransfer(owner(), msg.value);
    }

    function _handleEthTransfer(address recipient, uint256 amount) internal {
        (bool success,) = payable(recipient).call{value : amount}("");
        require(success, "ETH transfer failed");
    }

    //Multi ERC20 Payment mint
    function multiMint(uint256 _quantity, uint256 _id) external payable {
        require(multisaleEnable, "Multi Sale is not Enabled");
        require(
            _quantity + _numberMinted(_msgSender()) <= MAX_MINTS,
            "Exceeded the limit"
        );
        require(
            totalSupply() + _quantity <= MAX_SUPPLY,
            "Not enough tokens left"
        );
        require(allowedCrypto[_id].enabled, "This payment method is disabled");
        uint256 _price = allowedCrypto[_id].price;
        _handleMintPayment(_id, _price, _quantity);
        _safeMint(_msgSender(), _quantity);
        emit MintedNft(_quantity, _msgSender());
    }

    function multiMintbyref(
        uint256 _quantity,
        uint256 _id,
        address _refAddress,
        bytes memory signature
    ) external payable {
        address _toAddress = _msgSender();
        require(multisaleEnable, "Multi Sale is not Enabled");
        // _safeMint's second argument now takes in a quantity, not a tokenId.
        require(
            _quantity + _numberMinted(_msgSender()) <= MAX_MINTS,
            "Exceeded the limit"
        );
        require(
            totalSupply() + _quantity <= MAX_SUPPLY,
            "Not enough tokens left"
        );
        require(getSigner(_toAddress, _quantity, _refAddress, signature) == signerAddress, "ECDSA check failed");
        require(_refAddress != _toAddress, "Don't cheat");
        require(allowedCrypto[_id].enabled, "This payment method is disabled");
        uint256 _price = allowedCrypto[_id].price;
        _handleRefFee(_id, _price, _quantity, _refAddress);
        _safeMint(_msgSender(), _quantity);
        ref[_refAddress] += _quantity;
        emit MintedNft(_quantity, _msgSender());
    }

    //Mint by price 
    function mintByPriceRef(
        uint256 _quantity,
        uint256 _id,
        uint256 _price,
        address _refAddress,
        bytes memory signature
    ) external payable {
        address _toAddress = _msgSender();
        require(bypricesaleEnable, "Sale is not Enabled");
        require(
            _quantity + _numberMinted(_msgSender()) <= MAX_MINTS,
            "Exceeded the limit"
        );
        require(
            totalSupply() + _quantity <= MAX_SUPPLY,
            "Not enough tokens left"
        );
        require(getSignerWithPriceRef(_toAddress, _quantity, _price, _refAddress, signature) == signerAddress, "ECDSA check failed");
        require(allowedCrypto[_id].enabled, "This payment method is disabled");
        _handleRefFee(_id, _price, _quantity, _refAddress);
        _safeMint(_msgSender(), _quantity);
        emit MintedNft(_quantity, _msgSender());
    }

    //mint by price and ref
    function mintByPrice(
        uint256 _quantity,
        uint256 _id,
        uint256 _price,
        bytes memory signature
    ) external payable {
        address _toAddress = _msgSender();
        require(bypricesaleEnable, "Sale is not Enabled");
        require(
            _quantity + _numberMinted(_msgSender()) <= MAX_MINTS,
            "Exceeded the limit"
        );
        require(
            totalSupply() + _quantity <= MAX_SUPPLY,
            "Not enough tokens left"
        );
        require(getSignerWithPrice(_toAddress, _quantity, _price, signature) == signerAddress, "ECDSA check failed");
        require(allowedCrypto[_id].enabled, "This payment method is disabled");
        _handleMintPayment(_id, _price, _quantity);
        _safeMint(_msgSender(), _quantity);
        emit MintedNft(_quantity, _msgSender());
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override (ERC721A, IERC721A) {
        require(!isBlackListed[from], "you are blacklisted");
        require(!isLocked[from], "unlock tokens before transfer");
        if (!transferEnabled) {
            require(from == address(0) || isExempted[from], "transfer disabled");
        }
        super.transferFrom(from, to, tokenId);
    }

    function _handleRefFee(uint256 _id, uint256 _price, uint256 _quantity, address _refAddress) internal {
        if (_id == 0) {
            //ETH Payment
            require(msg.value >= _price * _quantity, "Not enough ETH sent");
            uint256 amountToRef = msg.value * refFee / 100;
            uint256 mintFee = msg.value - amountToRef;
              _handleEthTransfer(owner(), mintFee);
            _handleEthTransfer(_refAddress, amountToRef);
          
        } else {
            // ERC20 Payment
            IERC20 tokenAddress = IERC20(allowedCrypto[_id].addr);
            uint256 totalPrice = _price * _quantity;
            uint256 amountToRef = totalPrice * refFee / 100;
            uint256 mintFee = totalPrice - amountToRef;
            require(tokenAddress.transferFrom(msg.sender, owner(), mintFee), "transfer to owner failed");
            require(tokenAddress.transferFrom(msg.sender, _refAddress, amountToRef), "transfer to ref failed");
        }
    }

    function _handleMintPayment(uint256 _id, uint256 _price, uint256 _quantity) internal {
        if (_id == 0) {
            //ETH Payment
            require(msg.value >= _price * _quantity, "Not enough ETH send");
            _handleEthTransfer(owner(), msg.value);
        } else {
            // ERC20 Payment
            IERC20 tokenAddress = IERC20(allowedCrypto[_id].addr);
            uint256 totalPrice = _price * _quantity;
            require(tokenAddress.transferFrom(msg.sender, owner(), totalPrice), "transfer failed");
        }
    }

    receive() external payable {}
}