//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "lib/ERC721A-Upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/token/common/ERC2981Upgradeable.sol";
import {OperatorFilterer} from "lib/closedsea/src/OperatorFilterer.sol";
import "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import {IBanksy} from "./Banksy.sol";
import "./Errors.sol";

contract DAUpgradeable is ERC721AQueryableUpgradeable, OwnableUpgradeable, OperatorFilterer, ERC2981Upgradeable {
    using ECDSA for bytes32;

    //--------PRICING VARIABLES--------//
    uint256 public normalStartPrice;
    uint256 public minimumDutchAuctionPrice;
    uint256 public step;
    uint256 public stepInterval;
    uint256 public startTime;

    //--------SUPPLY VARIABLES--------//
    // uint256 public maxBanksySupply;
    uint256 public maxCreatorSupply;
    uint256 public maxNormalSupply;

    //--------COUNTERS--------//
    // uint256 public banksyPassCounter;
    uint256 public creatorSupplyCounter;
    uint256 public normalSupplyCounter;

    //--------MISC VARIABLES--------//
    uint256 public maxMintsPerTxRegular;
    bool public operatorFilteringEnabled;

    //--------METADATA--------//
    bool public revealed;
    bool public metadata_revised;
    string public baseURI;
    string public creator_pass_uri;
    string public membership_pass_uri;
    string public not_revealed_uri;
    string public baseExtension;

    //--------REVEALED--------//
    bool public normalMintOn;

    //--------SIGNER USED FOR RNG GENERATION--------//
    address private signer;
    address private banksy;

    mapping(uint256 => Tier) public tokenTier;

    enum Tier {
        Normal,
        CreatorPass,
        HighTierRNG
    }

    uint256 constant MAX_TIER_INDEX = 3;
    /*
    0 = normal
    1 = creator pass
    2 = high tier RNG
    */

    mapping(address => uint256) public userNonce;

    function initialize() public initializerERC721A initializer {
        __ERC721A_init("Banksy Membership Pass", "BMP");
        _mint(msg.sender, 20);
        //15 membership passes,
        //5 creator passes
        normalSupplyCounter = 15;
        creatorSupplyCounter = 5;
        unchecked {
            //tokens 0-14 are normal so we can skip them
            //tokens 15-19 are creator passes (5 of them)
            for (uint256 i = 15; i < 20; ++i) {
                tokenTier[i] = Tier.CreatorPass;
            }
        }

        __Ownable_init();
        __ERC2981_init();
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;

        // Set royalty receiver to the contract creator,
        // at 5% (default denominator is 10000).
        _setDefaultRoyalty(msg.sender, 750);

        assembly {
            //Supply SSTORES
            sstore(maxCreatorSupply.slot, 233) //maxCreatorSupply = 233
            sstore(maxNormalSupply.slot, 3000) //maxNormalSupply = 3000
            // sstore(maxBanksySupply.slot, 100) //maxBanksySupply = 100

            //DA Vars SSTORES
            sstore(normalStartPrice.slot, mul(1, exp(10, 17))) //normalStartPrice = 0.1 ether
            sstore(minimumDutchAuctionPrice.slot, mul(65, exp(10, 15))) //minimumDutchAuctionPrice = 0.065 ether
            sstore(step.slot, mul(5, exp(10, 15))) //step = 0.005 ether
            sstore(stepInterval.slot, mul(60, 10)) //stepInterval = 10 minutes

            //Max Mints Per TX SSTORES
            sstore(maxMintsPerTxRegular.slot, 2) //maxMintsPerTxRegular = 2

            //DA START TIMESTAMP SSTORE
            // sstore(startTime.slot, timestamp()) //startTime = block.timestamp , starts as whitelist so we set this later
        }
        //Be sure to set the signer... Storage slots may be batched so we don't use assembly
        signer = 0x9825E451c4869F4A166552dBEe1b7B5cB47aca65;
        creator_pass_uri = "ipfs://QmZvfcxiUwNGmriK1chcTBXCQQVsybfyMzAEhUMmrm7KJo/creator_pass.json";
        membership_pass_uri = "ipfs://QmZvfcxiUwNGmriK1chcTBXCQQVsybfyMzAEhUMmrm7KJo/membership_pass.json";
        not_revealed_uri = "ipfs://QmaPnLcum2LMap5Hr8wRJuQEvww65y5LtCrtZ9R9uxw4dY";

        //Be sure to set banksy
    }

    function getDutchPrice() public view returns (uint256) {
        uint256 steps = getSteps();
        uint256 price = normalStartPrice - (step * steps);
        return max(price, minimumDutchAuctionPrice);
    }

    function getSigner() external view returns (address) {
        return signer;
    }

    function getSteps() internal view returns (uint256) {
        uint256 timeSinceStart = block.timestamp - startTime;
        uint256 steps = timeSinceStart / stepInterval;
        uint256 maxTotalStepsPossible = (normalStartPrice - minimumDutchAuctionPrice) / step;
        if (steps > maxTotalStepsPossible) {
            return maxTotalStepsPossible;
        }
        return steps;
    }

    function mintNormal(uint256 amount, uint256 numNonStandard, uint8[] calldata tierStatuses, bytes memory signature)
        external
        payable
    {
        if (tierStatuses.length != numNonStandard) _revert(StatusLengthMustMatchNumNonStandardMintAmount.selector);
        if (numNonStandard > amount) _revert(NumNonStandardCannotExceedAmount.selector);
        uint256 nextTokenId = _nextTokenId();
        if (amount > maxMintsPerTxRegular) _revert(MintingTooMany.selector);
        if (!normalMintOn) _revert(Paused.selector);
        if (msg.value < getDutchPrice() * amount) _revert(Underpriced.selector);
        if (numNonStandard > 0) {
            /// @Validate the signature
            bytes32 hash =
                keccak256(abi.encodePacked(msg.sender, userNonce[msg.sender], amount, numNonStandard, tierStatuses));
            address hashSigner = hash.toEthSignedMessageHash().recover(signature);
            if (hashSigner != signer) _revert(InvalidSignature.selector);
            // @Cache the values to save gas
            uint256 _maxCreatorSupply = maxCreatorSupply;
            uint256 _creatorSupplyCounter = creatorSupplyCounter;
            uint256 timesNotHighTierRNG;
            // uint256 _maxBanskySupply = maxBanksySupply;
            // uint256 _banksySupplyCounter = banksyPassCounter;

            // @Update the counters and storage
            for (uint256 i = 0; i < numNonStandard;) {
                Tier tier = Tier(tierStatuses[i]);
                if (uint256(tier) > _maxTokenTier()) _revert(InvalidTier.selector);
                if (tier == Tier.CreatorPass) {
                    if (_creatorSupplyCounter + 1 > _maxCreatorSupply) _revert(SoldOut.selector);
                    ++_creatorSupplyCounter;
                } else if (tier == Tier.HighTierRNG) {
                    --amount;
                    IBanksy(banksy).mintFromOther(msg.sender, 1);
                    // if()
                    // if (_banksySupplyCounter + 1 > _maxBanskySupply) _revert(SoldOut.selector);
                    // ++_banksySupplyCounter;
                } else {
                    _revert(InvalidTier.selector);
                }
                if (tier != Tier.HighTierRNG) {
                    tokenTier[nextTokenId + timesNotHighTierRNG++] = tier;
                }

                unchecked {
                    ++i;
                }
            }

            if (_creatorSupplyCounter != creatorSupplyCounter) {
                creatorSupplyCounter = _creatorSupplyCounter;
            }

            // if (_banksySupplyCounter != banksyPassCounter) {
            //     banksyPassCounter = _banksySupplyCounter;
            // }
        }

        assembly {
            if gt(amount, numNonStandard) {
                sstore(normalSupplyCounter.slot, add(sload(normalSupplyCounter.slot), sub(amount, numNonStandard)))
            }
        }

        if (normalSupplyCounter > maxNormalSupply) _revert(SoldOut.selector);

        ++userNonce[msg.sender];
        if (amount > 0) {
            _mint(msg.sender, amount);
        }
    }

    function burn(uint256 tokenId) external {
        if (tokenTier[tokenId] != Tier.CreatorPass) _revert(OnlyCreatorPassCanBurn.selector);
        _burn(tokenId, true);
    }

    function getTierStatusesForTokenIDS(uint256[] calldata tokenIds) external view returns (uint8[] memory) {
        uint8[] memory statuses = new uint8[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            statuses[i] = uint8(tokenTier[tokenIds[i]]);
        }
        return statuses;
    }

    function getTierStatusSingleId(uint256 tokenId) external view returns (uint8) {
        require(_exists(tokenId), "Token does not exist");
        return uint8(tokenTier[tokenId]);
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    function _startTokenId() internal pure override(ERC721AUpgradeable) returns (uint256) {
        return 0;
    }
    //SETTERS

    function setBaseExtensionURI(string calldata _baseExtensionURI) external onlyOwner {
        baseExtension = _baseExtensionURI;
    }

    function setBanksy(address _banksy) external onlyOwner {
        banksy = _banksy;
    }

    function setNormalStartPrice(uint256 _normalStartPrice) external onlyOwner {
        normalStartPrice = _normalStartPrice;
    }

    function setStep(uint256 _step) external onlyOwner {
        step = _step;
    }

    function setStepInterval(uint256 _stepInterval) external onlyOwner {
        stepInterval = _stepInterval;
    }

    function setMaxMintsPerTxRegular(uint256 _maxMintsPerTxRegular) external onlyOwner {
        maxMintsPerTxRegular = _maxMintsPerTxRegular;
    }

    function setNormalMintOn(bool _normalMintOn) external onlyOwner {
        normalMintOn = _normalMintOn;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function setStartTime(uint256 _startTime) external onlyOwner {
        if (_startTime < block.timestamp) _revert(StartTimeInPast.selector);
        startTime = _startTime;
    }

    function setStartTimeDanger(uint256 _startTime) external onlyOwner {
        startTime = _startTime;
    }

    function setStartTimeToCurrentBlockTimestamp() external onlyOwner {
        startTime = block.timestamp;
    }

    function setMinimumDutchAuctionPrice(uint256 _minimumDutchAuctionPrice) external onlyOwner {
        minimumDutchAuctionPrice = _minimumDutchAuctionPrice;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        returns (string memory)
    {
        if (!revealed) return not_revealed_uri;
        if (metadata_revised) {
            return string(abi.encodePacked(baseURI, _toString(tokenId), baseExtension));
        }

        uint256 tier = uint256(tokenTier[tokenId]);
        if (tier == 0) return membership_pass_uri;
        if (tier == 1) return creator_pass_uri;
    }

    function setRevealed(bool _revealed) external onlyOwner {
        revealed = _revealed;
    }

    function setMetadataRevised(bool _metadata_revised) external onlyOwner {
        metadata_revised = _metadata_revised;
    }

    function setCreatorPassURI(string calldata _creator_pass_uri) external onlyOwner {
        creator_pass_uri = _creator_pass_uri;
    }

    function setMembershipPassURI(string calldata _membership_pass_uri) external onlyOwner {
        membership_pass_uri = _membership_pass_uri;
    }

    function setNotRevealedURI(string calldata _not_revealed_uri) external onlyOwner {
        not_revealed_uri = _not_revealed_uri;
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function batchConfigMetadata(
        bool _revealed,
        bool _metadata_revised,
        string calldata _creator_pass_uri,
        string calldata _membership_pass_uri,
        string calldata _not_revealed_uri,
        string calldata _baseURI
    ) external onlyOwner {
        revealed = _revealed;
        metadata_revised = _metadata_revised;
        creator_pass_uri = _creator_pass_uri;
        membership_pass_uri = _membership_pass_uri;
        not_revealed_uri = _not_revealed_uri;
        baseURI = _baseURI;
    }

    //-----------CLOSEDSEA----------------

    function setApprovalForAll(address operator, bool approved)
        public
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC721AUpgradeable, ERC721AUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return ERC721AUpgradeable.supportsInterface(interfaceId) || ERC2981Upgradeable.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }

    function getTotalBurned() external view returns (uint256) {
        return _totalBurned();
    }

    function _maxTokenTier() internal pure returns (uint256) {
        return 2;
    }

    function getDashboardParams() external view returns (DashboardParams memory) {
        return DashboardParams({
            // maxSupply: maxSupply,
            normalStartPrice: normalStartPrice,
            step: step,
            stepInterval: stepInterval,
            maxCreatorSupply: maxCreatorSupply,
            // banksySupply: maxBanksySupply,
            // bansyMaxSupply: banksyPassCounter,
            creatorSupplyCounter: creatorSupplyCounter,
            maxMintsPerTxRegular: maxMintsPerTxRegular,
            normalMintOn: normalMintOn,
            totalSupply: totalSupply(),
            balance: address(this).balance,
            normalSupplyCounter: normalSupplyCounter,
            maxNormalSupply: maxNormalSupply
        });
        // totalBurned: _totalBurned()
    }

    function withdraw() external onlyOwner {
        (bool os,) = payable(0x2fB6B5c3Fc4e0D3d2673aFb43b223fEd00452EDa).call{value: address(this).balance}("");
        require(os, "Withdraw failed");
    }
}

struct DashboardParams {
    // uint maxSupply;
    uint256 normalStartPrice;
    uint256 step;
    uint256 stepInterval;
    uint256 maxCreatorSupply;
    uint256 creatorSupplyCounter;
    // uint256 banksySupply;
    // uint256 bansyMaxSupply;
    uint256 maxMintsPerTxRegular;
    bool normalMintOn;
    uint256 totalSupply;
    uint256 balance;
    uint256 normalSupplyCounter;
    uint256 maxNormalSupply;
}
// uint totalBurned;