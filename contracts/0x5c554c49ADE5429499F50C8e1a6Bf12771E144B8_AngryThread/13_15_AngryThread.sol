// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./ERC721G_Full.sol";
import "./iWTF.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "hardhat/console.sol";

error IncorrectPrice();
error NotUser();
error InvalidSaleState();
error ZeroAddress();
error PublicSoldOut();
error SoldOut();
error InvalidSignature();
error LimitPerWalletExceeded();
error NotEnabledYet();
error NotOwner();
error AlreadySet();
error NotSet();
error TooMuch();

abstract contract RewardContract {
    function getEmissionRate(
        uint256 index_
    ) public view virtual returns (uint256);

    function claimRewards(
        uint256 index_,
        address to_,
        uint256 total_
    ) public virtual;
}

contract AngryThread is ERC721G, Ownable, DefaultOperatorFilterer {
    constructor(
        address signer_,
        address payable deployerAddress_,
        string memory unrevealURI_,
        string memory contractURI_
    ) ERC721G("Angry Thread", "ANGRY", 1, 100) {
        setSignerAddress(signer_);
        setWithdrawAddress(deployerAddress_);
        setBaseURI(unrevealURI_);
        setContractMetadataURI(contractURI_);
    }

    /* WTF */
    address public wtfAddress;
    uint256 public thisAddressIndexInRewardContract = 0;

    /* SIGNATURE */

    using ECDSA for bytes32;
    address public signerAddress;
    string public salePublicKey = "Public";
    string public saleWhitelistKey = "WHITELIST";

    /* DETAILS */
    uint256 public publicMintPrice = 0.001 ether;
    uint256 public wtfMintPriceInWei; //Mint with $WTF

    uint256 public maxSupply = 10000;
    uint256 public collectionSize = 20000;
    uint256 public publicLimitPerWallet = 10;
    uint256 public whitelistLimitPerWallet = 1;

    uint256 public firstBatch = 10000;
    string public firstProvenance; //<= 10K (0-10K)
    uint256 public firstStartingIndex;

    uint256 public secondBatch = 10000;
    string public secondProvenance; //>10K (10K-20K)
    uint256 public secondStartingIndex;

    string private contractMetadataURI;

    /* SALE STATE */
    enum SaleState {
        CLOSED,
        WHITELIST,
        PUBLIC
    }
    SaleState public saleState;

    /* EVENT */
    event Minted(address indexed receiver, uint256 quantity);
    event WTF(address indexed receiver, uint256 quantity);
    event SaleStateChanged(SaleState saleState);

    /* MINT */
    function whitelistMint(
        uint256 quantity_,
        bytes calldata signature_
    ) external isSaleState(SaleState.WHITELIST) {
        if (!verifySignature(signature_, saleWhitelistKey))
            revert InvalidSignature();
        if (
            _balanceData[msg.sender].mintedAmount + quantity_ >
            whitelistLimitPerWallet
        ) revert LimitPerWalletExceeded();

        _mint(msg.sender, quantity_);
        emit Minted(msg.sender, quantity_);
    }

    function publicMint(
        uint256 quantity_,
        bytes calldata signature_
    ) external payable isSaleState(SaleState.PUBLIC) {
        if (!verifySignature(signature_, salePublicKey))
            revert InvalidSignature();
        if (totalSupply() + quantity_ > maxSupply) revert PublicSoldOut();
        if (
            _balanceData[msg.sender].mintedAmount + quantity_ >
            publicLimitPerWallet
        ) revert LimitPerWalletExceeded();
        if (msg.value != quantity_ * publicMintPrice) revert IncorrectPrice();
        if (quantity_ > publicLimitPerWallet) revert LimitPerWalletExceeded();

        _mint(msg.sender, quantity_);
        emit Minted(msg.sender, quantity_);
    }

    function verifySignature(
        bytes memory signature_,
        string memory saleStateName_
    ) internal view returns (bool) {
        return
            signerAddress ==
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    bytes32(abi.encodePacked(msg.sender, saleStateName_))
                )
            ).recover(signature_);
    }

    function reserve(address to_, uint256 amount_) external onlyOwner {
        _mint(to_, amount_);
    }

    /* STAKING */

    mapping(uint256 => uint256) internal latestTokenIdClaimTimestamp;

    bool public stakingIsEnabled;
    bool public unstakingIsEnabled;
    bool public claimIsEnabled;
    uint256 public endStakingTime;

    function setStakingIsEnabled(bool bool_) external onlyOwner {
        stakingIsEnabled = bool_;
    }

    function setUnstakingIsEnabled(bool bool_) external onlyOwner {
        unstakingIsEnabled = bool_;
    }

    function setClaimIsEnabled(bool bool_) external onlyOwner {
        claimIsEnabled = bool_;
    }

    function stake(uint256[] calldata tokenIds_) public override {
        if (!stakingIsEnabled) revert NotEnabledYet();
        ERC721G.stake(tokenIds_);

        for (uint256 i = 0; i < tokenIds_.length; i++) {
            latestTokenIdClaimTimestamp[tokenIds_[i]] = block.timestamp;
        }
    }

    function unstake(uint256[] calldata tokenIds_) public override {
        if (!unstakingIsEnabled) revert NotEnabledYet();
        ERC721G.unstake(tokenIds_);

        // Automatically claim
        _claimInternal(tokenIds_);
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /* WTF */

    function WTFClaim(uint256[] calldata tokenIds_) external {
        if (!claimIsEnabled) revert NotEnabledYet();

        _claimInternal(tokenIds_);
    }

    function _claimInternal(uint256[] calldata tokenIds_) internal {
        if (endStakingTime == 0) revert NotSet();
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            if (_trueOwnerOf(tokenIds_[i]) != msg.sender) revert NotOwner();
        }

        RewardContract wtfContract = RewardContract(wtfAddress);
        uint256 emissionRate = wtfContract.getEmissionRate(
            thisAddressIndexInRewardContract
        );

        uint256 time = min(block.timestamp, endStakingTime);
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            uint256 totalRewards = (time -
                latestTokenIdClaimTimestamp[tokenIds_[i]]) * emissionRate;
            wtfContract.claimRewards(
                thisAddressIndexInRewardContract,
                msg.sender,
                totalRewards
            );

            latestTokenIdClaimTimestamp[tokenIds_[i]] = block.timestamp;
        }
    }

    function getTotalClaimable(uint256 tokenId_) public view returns (uint256) {
        RewardContract wtfContract = RewardContract(wtfAddress);
        uint256 emissionRate = wtfContract.getEmissionRate(
            thisAddressIndexInRewardContract
        );

        uint256 time = min(block.timestamp, endStakingTime);
        uint256 totalRewards = (time - latestTokenIdClaimTimestamp[tokenId_]) *
            emissionRate;
        return totalRewards; //$WTF
    }

    function WTFMint(uint256 quantity_) external {
        if (!stakingIsEnabled) revert NotEnabledYet();
        if (wtfAddress == address(0)) revert ZeroAddress();
        if (totalSupply() + quantity_ > collectionSize) revert SoldOut();
        if (quantity_ > publicLimitPerWallet) revert TooMuch();

        iWTF(wtfAddress).burnFrom(msg.sender, wtfMintPriceInWei * quantity_);

        _mint(msg.sender, quantity_);
        emit WTF(msg.sender, quantity_);
    }

    /* PROVENANCE */

    using SafeMath for uint256;

    function setFirstStartingIndex(
        uint256 random1_,
        uint256 random2_,
        uint256 random3_
    ) public {
        if (firstStartingIndex != 0) revert AlreadySet();

        firstStartingIndex =
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        random1_,
                        block.difficulty,
                        block.coinbase,
                        block.gaslimit,
                        blockhash(block.number),
                        random2_,
                        random3_
                    )
                )
            ) %
            firstBatch;

        // Prevent default sequence
        if (firstStartingIndex == 0 || firstStartingIndex == 1) {
            firstStartingIndex = 2;
        }
    }

    function setSecondStartingIndex(
        uint256 random1_,
        uint256 random2_,
        uint256 random3_
    ) public {
        if (secondStartingIndex != 0) revert AlreadySet();

        secondStartingIndex =
            uint256(
                keccak256(
                    abi.encodePacked(
                        random1_,
                        block.timestamp,
                        block.difficulty,
                        block.coinbase,
                        block.gaslimit,
                        random2_,
                        blockhash(block.number),
                        random3_
                    )
                )
            ) %
            secondBatch;

        // Prevent default sequence
        if (secondStartingIndex == 0 || secondStartingIndex == 1) {
            secondStartingIndex = 2;
        }
    }

    function setFirstProvenance0To10K(
        string memory firstProvenance_
    ) external onlyOwner {
        firstProvenance = firstProvenance_;
    }

    function setSecondProvenance10KTo20K(
        string memory secondProvenance_
    ) external onlyOwner {
        secondProvenance = secondProvenance_;
    }

    function setFirstBatch(uint256 firstBatch_) external onlyOwner {
        firstBatch = firstBatch_;
    }

    function setSecondBatch(uint256 secondBatch_) external onlyOwner {
        secondBatch = secondBatch_;
    }

    /* OWNER */

    function setWTFAddress(address wtfAddress_) external onlyOwner {
        wtfAddress = wtfAddress_;
    }

    function setSaleState(uint256 saleState_) external onlyOwner {
        saleState = SaleState(saleState_);
        emit SaleStateChanged(saleState);
    }

    modifier isSaleState(SaleState saleState_) {
        if (msg.sender != tx.origin) revert NotUser();
        if (saleState != saleState_) revert InvalidSaleState();
        _;
    }

    function setSignerAddress(address signerAddress_) public onlyOwner {
        if (signerAddress_ == address(0)) revert ZeroAddress();
        signerAddress = signerAddress_;
    }

    function setWithdrawAddress(
        address payable withdrawAddress_
    ) public onlyOwner {
        if (withdrawAddress_ == address(0)) revert ZeroAddress();
        withdrawAddress = withdrawAddress_;
    }

    function setContractMetadataURI(
        string memory contractMetadataURI_
    ) public onlyOwner {
        contractMetadataURI = contractMetadataURI_;
    }

    function setMaxSupply(uint256 maxSupply_) public onlyOwner {
        maxSupply = maxSupply_;
    }

    function setCollectionSize(uint256 collectionSize_) public onlyOwner {
        collectionSize = collectionSize_;
    }

    function setPublicMintPrice(uint256 publicMintPrice_) public onlyOwner {
        publicMintPrice = publicMintPrice_;
    }

    function setWTFMintPriceInWei(uint256 wtfMintPriceInWei_) public onlyOwner {
        wtfMintPriceInWei = wtfMintPriceInWei_;
    }

    function setWhitelistLimitPerWallet(
        uint256 whitelistLimitPerWallet_
    ) public onlyOwner {
        whitelistLimitPerWallet = whitelistLimitPerWallet_;
    }

    function setPublicLimitPerWallet(
        uint256 publicLimitPerWallet_
    ) public onlyOwner {
        publicLimitPerWallet = publicLimitPerWallet_;
    }

    function setThisAddressIndexInRewardContract(
        uint256 thisAddressIndexInRewardContract_
    ) public onlyOwner {
        thisAddressIndexInRewardContract = thisAddressIndexInRewardContract_;
    }

    function setSalePublicKey(string memory salePublicKey_) public onlyOwner {
        salePublicKey = salePublicKey_;
    }

    function setSaleWhitelistKey(
        string memory saleWhitelistKey_
    ) public onlyOwner {
        saleWhitelistKey = saleWhitelistKey_;
    }

    function setEndStakingTime(uint256 endStakingTime_) public onlyOwner {
        endStakingTime = endStakingTime_;
    }

    // Token URI Configurations
    string internal baseURI;
    string internal baseURI_EXTENSION;

    function setBaseURI(string memory uri_) public onlyOwner {
        baseURI = uri_;
    }

    function setBaseURI_EXTENSION(string memory extension_) external onlyOwner {
        baseURI_EXTENSION = extension_;
    }

    function _toString(uint256 value_) internal pure returns (string memory) {
        if (value_ == 0) {
            return "0";
        }
        uint256 _iterate = value_;
        uint256 _digits;
        while (_iterate != 0) {
            _digits++;
            _iterate /= 10;
        }
        bytes memory _buffer = new bytes(_digits);
        while (value_ != 0) {
            _digits--;
            _buffer[_digits] = bytes1(uint8(48 + uint256(value_ % 10)));
            value_ /= 10;
        }
        return string(_buffer);
    }

    function tokenURI(
        uint256 tokenId_
    ) public view override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    baseURI,
                    _toString(tokenId_),
                    baseURI_EXTENSION
                )
            );
    }

    /* WITHDRAW */

    address payable public withdrawAddress;

    function withdraw() external onlyOwner {
        (bool success, ) = withdrawAddress.call{value: address(this).balance}(
            ""
        );
        require(success, "Transfer failed.");
    }

    /* OPERATOR FILTERER */

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}