// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {HeyMintERC721AUpgradeable} from "./HeyMintERC721AUpgradeable.sol";
import {AdvancedConfig, HeyMintStorage} from "../libraries/HeyMintStorage.sol";
import {MerkleProofUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract HeyMintERC721AExtensionD is HeyMintERC721AUpgradeable {
    using HeyMintStorage for HeyMintStorage.State;

    event Loan(address from, address to, uint256 tokenId);
    event LoanRetrieved(address from, address to, uint256 tokenId);

    // Address of the HeyMint admin address
    address public constant heymintAdminAddress =
        0x52EA5F96f004d174470901Ba3F1984D349f0D3eF;
    // Address where burnt tokens are sent.
    address public constant burnAddress =
        0x000000000000000000000000000000000000dEaD;

    // ============ HEYMINT FEE ============

    /**
     * @notice Allows the heymintAdminAddress to set the heymint fee per token
     * @param _heymintFeePerToken The new fee per token in wei
     */
    function setHeymintFeePerToken(uint256 _heymintFeePerToken) external {
        require(msg.sender == heymintAdminAddress, "MUST_BE_HEYMINT_ADMIN");
        HeyMintStorage.state().data.heymintFeePerToken = _heymintFeePerToken;
    }

    // ============ HEYMINT DEPOSIT TOKEN REDEMPTION ============

    /**
     * @notice Returns the deposit payment in wei. Deposit payment is stored with 5 decimals (1 = 0.00001 ETH), so total 5 + 13 == 18 decimals
     */
    function remainingDepositPaymentInWei() public view returns (uint256) {
        return
            uint256(HeyMintStorage.state().advCfg.remainingDepositPayment) *
            10 ** 13;
    }

    /**
     * @notice To be updated by contract owner to allow burning a deposit token to mint
     * @param _depositClaimActive If true deposit tokens can be burned in order to mint
     */
    function setDepositClaimState(bool _depositClaimActive) external onlyOwner {
        AdvancedConfig storage advCfg = HeyMintStorage.state().advCfg;
        if (_depositClaimActive) {
            require(advCfg.depositMerkleRoot != bytes32(0), "NOT_CONFIGURED");
            require(
                advCfg.depositContractAddress != address(0),
                "NOT_CONFIGURED"
            );
        }
        advCfg.depositClaimActive = _depositClaimActive;
    }

    /**
     * @notice Set the merkle root used to validate the deposit tokens eligible for burning
     * @dev Each leaf in the merkle tree is the token id of a deposit token
     * @param _depositMerkleRoot The new merkle root
     */
    function setDepositMerkleRoot(
        bytes32 _depositMerkleRoot
    ) external onlyOwner {
        HeyMintStorage.state().advCfg.depositMerkleRoot = _depositMerkleRoot;
    }

    /**
     * @notice Set the address of the HeyMint deposit contract eligible for burning to mint
     * @param _depositContractAddress The new deposit contract address
     */
    function setDepositContractAddress(
        address _depositContractAddress
    ) external onlyOwner {
        HeyMintStorage
            .state()
            .advCfg
            .depositContractAddress = _depositContractAddress;
    }

    /**
     * @notice Set the remaining payment required in order to mint along with burning a deposit token
     * @param _remainingDepositPayment The new remaining payment in centiETH
     */
    function setRemainingDepositPayment(
        uint32 _remainingDepositPayment
    ) external onlyOwner {
        HeyMintStorage
            .state()
            .advCfg
            .remainingDepositPayment = _remainingDepositPayment;
    }

    /**
     * @notice Allows for burning deposit tokens in order to mint. The tokens must be eligible for burning.
     * Additional payment may be required in addition to burning the deposit tokens.
     * @dev This contract must be approved by the caller to transfer the deposit tokens being burned
     * @param _tokenIds The token ids of the deposit tokens to burn
     * @param _merkleProofs The merkle proofs for each token id verifying eligibility
     */
    function burnDepositTokensToMint(
        uint256[] calldata _tokenIds,
        bytes32[][] calldata _merkleProofs
    ) external payable nonReentrant {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        require(state.advCfg.depositMerkleRoot != bytes32(0), "NOT_CONFIGURED");
        require(
            state.advCfg.depositContractAddress != address(0),
            "NOT_CONFIGURED"
        );
        require(state.advCfg.depositClaimActive, "NOT_ACTIVE");
        uint256 numberOfTokens = _tokenIds.length;
        require(numberOfTokens > 0, "NO_TOKEN_IDS_PROVIDED");
        require(
            numberOfTokens == _merkleProofs.length,
            "ARRAY_LENGTHS_MUST_MATCH"
        );
        require(
            totalSupply() + numberOfTokens <= state.cfg.maxSupply,
            "MAX_SUPPLY_EXCEEDED"
        );
        require(
            msg.value == remainingDepositPaymentInWei() * numberOfTokens,
            "INCORRECT_REMAINING_PAYMENT"
        );
        IERC721 DepositContract = IERC721(state.advCfg.depositContractAddress);
        for (uint256 i = 0; i < numberOfTokens; i++) {
            require(
                MerkleProofUpgradeable.verify(
                    _merkleProofs[i],
                    state.advCfg.depositMerkleRoot,
                    keccak256(abi.encodePacked(_tokenIds[i]))
                ),
                "INVALID_MERKLE_PROOF"
            );
            require(
                DepositContract.ownerOf(_tokenIds[i]) == msg.sender,
                "MUST_OWN_TOKEN"
            );
            DepositContract.transferFrom(msg.sender, burnAddress, _tokenIds[i]);
        }
        _safeMint(msg.sender, numberOfTokens);
    }

    // ============ CONDITIONAL FUNDING ============

    /**
     * @notice Returns the funding target in wei. Funding target is stored with 2 decimals (1 = 0.01 ETH), so total 2 + 16 == 18 decimals
     */
    function fundingTargetInWei() public view returns (uint256) {
        return uint256(HeyMintStorage.state().cfg.fundingTarget) * 10 ** 16;
    }

    /**
     * @notice To be called by anyone once the funding duration has passed to determine if the funding target was reached
     * If the funding target was not reached, all funds are refundable. Must be called before owner can withdraw funds
     */
    function determineFundingSuccess() external {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        require(state.cfg.fundingEndsAt > 0, "NOT_CONFIGURED");
        require(
            address(this).balance >= fundingTargetInWei(),
            "FUNDING_TARGET_NOT_MET"
        );
        require(
            !state.data.fundingSuccessDetermined,
            "SUCCESS_ALREADY_DETERMINED"
        );
        state.data.fundingTargetReached = true;
        state.data.fundingSuccessDetermined = true;
    }

    /**
     * @notice Burn tokens and return the price paid to the token owner if the funding target was not reached
     * Can be called starting 1 day after funding duration ends
     * @param _tokenIds The ids of the tokens to be refunded
     */
    function burnToRefund(uint256[] calldata _tokenIds) external nonReentrant {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        // Prevent refunding tokens on a contract where conditional funding has not been enabled
        require(state.cfg.fundingEndsAt > 0, "NOT_CONFIGURED");
        require(
            block.timestamp > uint256(state.cfg.fundingEndsAt) + 1 days,
            "FUNDING_PERIOD_STILL_ACTIVE"
        );
        require(!state.data.fundingTargetReached, "FUNDING_TARGET_WAS_MET");
        require(
            address(this).balance < fundingTargetInWei(),
            "FUNDING_TARGET_WAS_MET"
        );

        uint256 totalRefund = 0;

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(ownerOf(_tokenIds[i]) == msg.sender, "MUST_OWN_TOKEN");
            require(
                state.data.pricePaid[_tokenIds[i]] > 0,
                "TOKEN_WAS_NOT_PURCHASED"
            );
            safeTransferFrom(
                msg.sender,
                0x000000000000000000000000000000000000dEaD,
                _tokenIds[i]
            );
            totalRefund += state.data.pricePaid[_tokenIds[i]];
        }

        (bool success, ) = payable(msg.sender).call{value: totalRefund}("");
        require(success, "TRANSFER_FAILED");
    }

    // ============ LOANING ============

    /**
     * @notice To be updated by contract owner to allow for loan functionality to turned on and off
     * @param _loaningActive The new state of loaning (true = on, false = off)
     */
    function setLoaningActive(bool _loaningActive) external onlyOwner {
        HeyMintStorage.state().advCfg.loaningActive = _loaningActive;
    }

    /**
     * @notice Allow owner to loan their tokens to other addresses
     * @param _tokenId The id of the token to loan
     * @param _receiver The address of the receiver of the loan
     */
    function loan(uint256 _tokenId, address _receiver) external nonReentrant {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        require(
            state.data.tokenOwnersOnLoan[_tokenId] == address(0),
            "CANNOT_LOAN_BORROWED_TOKEN"
        );
        require(state.advCfg.loaningActive, "NOT_ACTIVE");
        require(ownerOf(_tokenId) == msg.sender, "MUST_OWN_TOKEN");
        require(_receiver != msg.sender, "CANNOT_LOAN_TO_SELF");
        // Transfer the token - must do this before updating the mapping otherwise transfer will fail; nonReentrant modifier will prevent reentrancy
        safeTransferFrom(msg.sender, _receiver, _tokenId);
        // Add it to the mapping of originally loaned tokens
        state.data.tokenOwnersOnLoan[_tokenId] = msg.sender;
        // Add to the owner's loan balance
        state.data.totalLoanedPerAddress[msg.sender] += 1;
        state.data.currentLoanTotal += 1;
        emit Loan(msg.sender, _receiver, _tokenId);
    }

    /**
     * @notice Allow the original owner of a token to retrieve a loaned token
     * @param _tokenId The id of the token to retrieve
     */
    function retrieveLoan(uint256 _tokenId) external nonReentrant {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        address borrowerAddress = ownerOf(_tokenId);
        require(borrowerAddress != msg.sender, "MUST_OWN_TOKEN");
        require(
            state.data.tokenOwnersOnLoan[_tokenId] == msg.sender,
            "MUST_OWN_TOKEN"
        );
        // Remove it from the array of loaned out tokens
        delete state.data.tokenOwnersOnLoan[_tokenId];
        // Subtract from the owner's loan balance
        state.data.totalLoanedPerAddress[msg.sender] -= 1;
        state.data.currentLoanTotal -= 1;
        // Transfer the token back
        _directApproveMsgSenderFor(_tokenId);
        safeTransferFrom(borrowerAddress, msg.sender, _tokenId);
        emit LoanRetrieved(borrowerAddress, msg.sender, _tokenId);
    }

    /**
     * @notice Allow contract owner to retrieve a loan to prevent malicious floor listings
     * @param _tokenId The id of the token to retrieve
     */
    function adminRetrieveLoan(uint256 _tokenId) external onlyOwner {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        address borrowerAddress = ownerOf(_tokenId);
        address loanerAddress = state.data.tokenOwnersOnLoan[_tokenId];
        require(loanerAddress != address(0), "TOKEN_NOT_LOANED");
        // Remove it from the array of loaned out tokens
        delete state.data.tokenOwnersOnLoan[_tokenId];
        // Subtract from the owner's loan balance
        state.data.totalLoanedPerAddress[loanerAddress] -= 1;
        state.data.currentLoanTotal -= 1;
        // Transfer the token back
        _directApproveMsgSenderFor(_tokenId);
        safeTransferFrom(borrowerAddress, loanerAddress, _tokenId);
        emit LoanRetrieved(borrowerAddress, loanerAddress, _tokenId);
    }

    /**
     * Returns the total number of loaned tokens
     */
    function totalLoaned() public view returns (uint256) {
        return HeyMintStorage.state().data.currentLoanTotal;
    }

    /**
     * Returns the loaned balance of an address
     * @param _owner The address to check
     */
    function loanedBalanceOf(address _owner) public view returns (uint256) {
        return HeyMintStorage.state().data.totalLoanedPerAddress[_owner];
    }

    /**
     * Returns all the token ids loaned by a given address
     * @param _owner The address to check
     */
    function loanedTokensByAddress(
        address _owner
    ) external view returns (uint256[] memory) {
        uint256 totalTokensLoaned = loanedBalanceOf(_owner);
        uint256 mintedSoFar = totalSupply();
        uint256 tokenIdsIdx = 0;
        uint256[] memory allTokenIds = new uint256[](totalTokensLoaned);
        for (
            uint256 i = 1;
            i <= mintedSoFar && tokenIdsIdx != totalTokensLoaned;
            i++
        ) {
            if (HeyMintStorage.state().data.tokenOwnersOnLoan[i] == _owner) {
                allTokenIds[tokenIdsIdx] = i;
                tokenIdsIdx++;
            }
        }
        return allTokenIds;
    }

    // ============ REFUND ============

    /**
     * @notice Returns the refund price in wei. Refund price is stored with 5 decimals (1 = 0.00001 ETH), so total 5 + 13 == 18 decimals
     */
    function refundPriceInWei() public view returns (uint256) {
        return uint256(HeyMintStorage.state().advCfg.refundPrice) * 10 ** 13;
    }

    /**
     * Will return true if token holders can still return their tokens for a refund
     */
    function refundGuaranteeActive() public view returns (bool) {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        return block.timestamp < state.advCfg.refundEndsAt;
    }

    /**
     * @notice Set the address where tokens are sent when refunded
     * @param _refundAddress The new refund address
     */
    function setRefundAddress(address _refundAddress) external onlyOwner {
        require(_refundAddress != address(0), "CANNOT_SEND_TO_ZERO_ADDRESS");
        HeyMintStorage.state().advCfg.refundAddress = _refundAddress;
    }

    /**
     * @notice Increase the period of time where token holders can still return their tokens for a refund
     * @param _newRefundEndsAt The new timestamp when the refund period ends. Must be greater than the current timestamp
     */
    function increaseRefundEndsAt(uint32 _newRefundEndsAt) external onlyOwner {
        AdvancedConfig storage advCfg = HeyMintStorage.state().advCfg;
        require(
            _newRefundEndsAt > advCfg.refundEndsAt,
            "MUST_INCREASE_DURATION"
        );
        HeyMintStorage.state().advCfg.refundEndsAt = _newRefundEndsAt;
    }

    /**
     * @notice Refund token and return the refund price to the token owner.
     * @param _tokenId The id of the token to refund
     */
    function refund(uint256 _tokenId) external nonReentrant {
        require(refundGuaranteeActive(), "REFUND_GUARANTEE_EXPIRED");
        require(ownerOf(_tokenId) == msg.sender, "MUST_OWN_TOKEN");
        HeyMintStorage.State storage state = HeyMintStorage.state();

        // In case refunds are enabled with conditional funding, don't allow burnToRefund on refunded tokens
        if (state.cfg.fundingEndsAt > 0) {
            delete state.data.pricePaid[_tokenId];
        }

        address addressToSendToken = state.advCfg.refundAddress != address(0)
            ? state.advCfg.refundAddress
            : owner();

        safeTransferFrom(msg.sender, addressToSendToken, _tokenId);

        (bool success, ) = payable(msg.sender).call{value: refundPriceInWei()}(
            ""
        );
        require(success, "TRANSFER_FAILED");
    }
}