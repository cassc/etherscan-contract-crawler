// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import './AvastarsMarketplaceBase.sol';

contract AvastarsMarketplace is AvastarsMarketplaceBase {
    struct TraitOffer {
        uint256    primeId;
        uint256    traitNumber;
        uint256    price;
        uint256    expiration;
        uint256    nonce;            
    }

    struct SignedTraitOffer {
        TraitOffer offer;
        bytes      signature;
    }

    struct TraitSource {
        uint     primeId;
        bool[12] traitConsumed;
    }

    struct ReplicantMintRequest {
        uint8              generation;
        uint8              gender;
        uint               traitHash;
        uint8              ranking;
        TraitSource[]      traitSources; 
        SignedTraitOffer[] consumedOffers; 
    }

    struct SignedReplicantMintRequest {
        ReplicantMintRequest request;
        bytes                signature;
    }

    struct PrimeOffer {
        uint    primeId;
        uint    price;
        uint    expiration;
        uint    nonce;            
    }

    struct SignedPrimeOffer {
        PrimeOffer offer;
        bytes      signature;
    }

    struct PurchasePrimeRequest {
        SignedPrimeOffer consumeOffer;
        bool[12] requiredAvailableTraits;
    }

    struct TokenOffer {
        address tokenAddress;
        uint    tokenId;
        uint    price;
        uint    expiration;
        uint    nonce;            
    }

    struct SignedTokenOffer {
        TokenOffer offer;
        bytes      signature;
    }

    struct VerifiedBuyer {
        address buyer;
    }

    /**
        * @notice Add a valid Minter to the contract
        * @dev this is only callable by the Owner
        */
    function addMinter(address minter) public onlyOwner {
        Minters[minter] = true;
    }

    /**
        * @notice remove a Minter from the contract
        * @dev this is only callable by the owner
        */
    function removeMinter(address minter) public onlyOwner {
        Minters[minter] = false;
    }

        /**
        * @notice Add a valid AllowedToken to the contract
        * @dev this is only callable by the Owner
        */
    function addAllowedToken(address tokenAddress) public onlyOwner {
        AllowedTokens[tokenAddress] = true;
    }

    /**
        * @notice remove a AllowedToken from the contract
        * @dev this is only callable by the owner
        */
    function removeAllowedToken(address tokenAddress) public onlyOwner {
        AllowedTokens[tokenAddress] = false;
    }

    /**
     * @notice set an override for the royalties on a specific token collection
     * @param tokenAddress the collection to override
     * @param royaltyOverrides the schedule of royalty payouts for that collection
     */
    function setRoyaltyOverride(address tokenAddress, RoyaltyScheduleEntry[] calldata royaltyOverrides) public onlyOwner whenPaused {
        RoyaltyOverridden[tokenAddress] = true;
        delete(RoyaltyOverrides[tokenAddress]);
        for (uint i = 0; i < royaltyOverrides.length; i++) {
            RoyaltyOverrides[tokenAddress].push(royaltyOverrides[i]);
        }
    }

    /**
     * @notice clear the royalty override for a specific collection
     * @param tokenAddress the collection to override
     */
    function clearRoyaltyOverride(address tokenAddress) public onlyOwner whenPaused {
        RoyaltyOverridden[tokenAddress] = false;
        delete(RoyaltyOverrides[tokenAddress]);
    }

    /**
     * @notice set the royalties on traits
     * @param royaltySchedule the schedule of royalty payouts on traits
     */
    function setTraitRoyalty(RoyaltyScheduleEntry[] calldata royaltySchedule) public onlyOwner whenPaused {
        RoyaltyOverridden[FakeAvastarsTraitCollection] = true;
        delete(RoyaltyOverrides[FakeAvastarsTraitCollection]);
        for (uint i = 0; i < royaltySchedule.length; i++) {
            RoyaltyOverrides[FakeAvastarsTraitCollection].push(royaltySchedule[i]);
        }
    }

    /**
     * @notice clear the royalty for traits
     */
    function clearTraitRoyalty() public onlyOwner whenPaused {
        RoyaltyOverridden[FakeAvastarsTraitCollection] = false;
        delete(RoyaltyOverrides[FakeAvastarsTraitCollection]);
    }

    /**
        * @notice withdraw escrowed payments due
        * @dev to prevent a DoS on mint by a contract-based-wallet we allow a "pull" if the payment fails. this does not prevent a malicious wallet from blocking the sale by burning gas
        */
    function withdraw() public {
        address payable sender = payable(msg.sender);
        require(EscrowedPayments[sender] != 0);
        uint payment = EscrowedPayments[sender];
        EscrowedPayments[sender] = 0;

        (bool success, ) = sender.call{value:payment}('');
        require(success);
    }

    /**
        * @notice read-only call to check if an address is a minter
        */
    function isValidMinter(address minter) internal view returns (bool) {
        return Minters[minter];
    }

    function hashTraitOffer(TraitOffer memory offer) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            keccak256("TraitOffer(uint256 primeId,uint256 traitNumber,uint256 price,uint256 expiration,uint256 nonce)"),
            offer
        ));
    }

    /**
        * @notice check a single offer to see if the parameters match the expected values and that the signature is valid and from the offer's owner
        */
    function offerIsValid(address owner, SignedTraitOffer memory signedOffer) internal view returns (bytes32) {
        if (signedOffer.offer.expiration < block.timestamp) {
            return bytes32(0);
        }

        bytes32 digest = _hashTypedDataV4(hashTraitOffer(signedOffer.offer));

        if (BurnedOffers[digest] == true) {
            return bytes32(0);
        }

        address signer = ECDSA.recover(digest, signedOffer.signature);
        if (signer != owner) {
            return bytes32(0);
        }

        return digest;
    }

    function offerIsValid(address owner, SignedPrimeOffer memory sOffer) internal view returns (bytes32) {
        if (sOffer.offer.expiration < block.timestamp) {
            return bytes32(0);
        }

        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
            keccak256("PrimeOffer(uint256 primeId,uint256 price,uint256 expiration,uint256 nonce)"),
            sOffer.offer
        )));


        if (BurnedOffers[digest] == true) {
            return bytes32(0);
        }

        address signer = ECDSA.recover(digest, sOffer.signature);
        if (signer != owner) {
            return bytes32(0);
        }

        return digest;
    }

    function offerIsValid(address owner, SignedTokenOffer memory sOffer) internal view returns (bytes32) {
        if (sOffer.offer.expiration < block.timestamp) {
            return bytes32(0);
        }

        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
            keccak256("TokenOffer(address tokenAddress,uint256 tokenId,uint256 price,uint256 expiration,uint256 nonce)"),
            sOffer.offer
        )));


        if (BurnedOffers[digest] == true) {
            return bytes32(0);
        }

        address signer = ECDSA.recover(digest, sOffer.signature);
        if (signer != owner) {
            return bytes32(0);
        }

        return digest;
    }

    function buyerIsVerified(address buyer, bytes memory signature) internal view returns (bool) {
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
            keccak256("VerifiedBuyer(address buyer)"),
            buyer
        )));

        address signer = ECDSA.recover(digest, signature);
        if (!isValidMinter(signer)) {
            return false;
        }
        return true;
    }

    function hasArt(address who, uint256 amountInEther) internal view returns (bool) {
        return AvastarReplicantToken.balanceOf(who) >= amountInEther * 1 ether;
    }

    /**
        * @notice check a set of traits to make sure we have the rights to consume them.  Rights are conferred when either of the following is true:
        * - the transaction signer is the owner of the associated Prime
        * - there is a valid signed offer for the associated Prime and Trait
        */
    function hasAccessToTraits(
        TraitSource[] memory traitSources, 
        SignedTraitOffer[] memory offers
    ) internal view returns (bool success, bytes32[] memory) {
        uint nextOffer = 0;
        bytes32[] memory digests = new bytes32[](offers.length);
        for (uint s_idx = 0; s_idx < traitSources.length; s_idx++) {
            address primeOwner = Avastars.ownerOf(traitSources[s_idx].primeId);
                
            for(uint t_idx = 0; t_idx < 12; t_idx++) {
                if (traitSources[s_idx].traitConsumed[t_idx]) {
                    if (primeOwner == msg.sender) {
                        continue;
                    }

                    if (offers[nextOffer].offer.primeId != traitSources[s_idx].primeId) {
                        return (false,digests);
                    }

                    if (offers[nextOffer].offer.traitNumber != t_idx) {
                        return (false, digests);
                    }

                    bytes32 digest = offerIsValid(primeOwner, offers[nextOffer]);

                    if (digest == bytes32(0)) {
                        return (false, digests);
                    }

                    digests[nextOffer] = digest;
                    nextOffer++;
                }
            }
        }

        if (nextOffer != offers.length) {
            return (false, digests);
        }

        return (true, digests);
    }

    function hashTraitBools(bool[12] memory values) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            uint256(values[0]  == true ? 1 : 0),
            uint256(values[1]  == true ? 1 : 0),
            uint256(values[2]  == true ? 1 : 0),
            uint256(values[3]  == true ? 1 : 0),
            uint256(values[4]  == true ? 1 : 0),
            uint256(values[5]  == true ? 1 : 0),
            uint256(values[6]  == true ? 1 : 0),
            uint256(values[7]  == true ? 1 : 0),
            uint256(values[8]  == true ? 1 : 0),
            uint256(values[9]  == true ? 1 : 0),
            uint256(values[10] == true ? 1 : 0),
            uint256(values[11] == true ? 1 : 0)
        ));
    }

    function hashTraitSources(TraitSource[] memory input) internal pure returns (bytes32) {
        bytes memory result = bytes('');
        for (uint i = 0; i < input.length; i++) {
            bytes32 traitSourceHash = keccak256(abi.encode(
                keccak256('TraitSource(uint256 primeId,bool[12] traitConsumed)'),
                input[i].primeId,
                hashTraitBools(input[i].traitConsumed)
            ));
            result = abi.encodePacked(result, traitSourceHash);
        }

        return keccak256(result);
    }

    function hashConsumedOffers(SignedTraitOffer[] memory input) internal pure returns (bytes32 ) {
        bytes memory result = bytes('');
        for (uint i = 0; i < input.length; i++) {
            bytes32 signedTraitOfferHash = keccak256(abi.encode(
                keccak256('SignedTraitOffer(TraitOffer offer,bytes signature)TraitOffer(uint256 primeId,uint256 traitNumber,uint256 price,uint256 expiration,uint256 nonce)'),
                hashTraitOffer(input[i].offer),
                keccak256(input[i].signature)
            ));
            result = abi.encodePacked(result, signedTraitOfferHash);
        }

        return keccak256(result);
    }

    /**
        * @notice check the parameters to the function to make sure that a minter has validated this combination
        */
    function isValidMint(
        SignedReplicantMintRequest memory sRequest
    ) internal view returns (bool) {
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(     
            keccak256("ReplicantMintRequest(uint8 generation,uint8 gender,uint256 traitHash,uint8 ranking,TraitSource[] traitSources,SignedTraitOffer[] consumedOffers)SignedTraitOffer(TraitOffer offer,bytes signature)TraitOffer(uint256 primeId,uint256 traitNumber,uint256 price,uint256 expiration,uint256 nonce)TraitSource(uint256 primeId,bool[12] traitConsumed)"),
            sRequest.request.generation,
            sRequest.request.gender,
            sRequest.request.traitHash,
            sRequest.request.ranking,
            hashTraitSources(sRequest.request.traitSources),
            hashConsumedOffers(sRequest.request.consumedOffers)
        )));

        address signer = ECDSA.recover(digest, sRequest.signature);
        if (!isValidMinter(signer)) {
            return false;
        }
        return true;
    }

    function primeHasTraitsAvailable(uint256 primeId, bool[12] memory traits) internal view returns (bool) {
        (,bool[12] memory usedTraits) = Avastars.getPrimeReplicationByTokenId(primeId);
        for (uint i = 0; i < 12; i++) {
            if (traits[i] && usedTraits[i] ) {
                return false;
            }
        }

        return true;
    }

    function isValidTokenAddress(address tokenAddress) internal view returns (bool) {
        return AllowedTokens[tokenAddress];
    }

    function isReplicant(address tokenAddress, uint256 tokenId) internal view returns (bool) {
        return tokenAddress == address(Avastars) && Avastars.getAvastarWaveByTokenId(tokenId) == IAvastarsTeleporter.Wave.REPLICANT;
    }

    function burnArt(address who, uint256 amountInEther) internal {
        AvastarReplicantToken.transferFrom(who,address(this),amountInEther * 1 ether);
        AvastarReplicantToken.burnArt(amountInEther);
    }

    /**
        * @notice burn traits for this mint
        */
    function burnTraits(TraitSource[] memory traitSources) internal {
        for (uint i = 0; i < traitSources.length; i++) {
            Avastars.useTraits(traitSources[i].primeId,traitSources[i].traitConsumed); 
        }
    }

    function burnOffers(bytes32[] memory digests) internal {
        for (uint i = 0; i < digests.length; i++) {
            BurnedOffers[digests[i]] = true;
        }
    }


    function burnOffer(bytes32 digest) internal {
        BurnedOffers[digest] = true;
    }

    function processTraitPayouts(SignedTraitOffer[] memory offers) internal returns (uint totalPaid) {
        totalPaid = 0;
        for(uint i = 0; i < offers.length; i++) {
            address payable payee = payable(Avastars.ownerOf(offers[i].offer.primeId));
            totalPaid += processPayoutAndRoyalty(FakeAvastarsTraitCollection, offers[i].offer.primeId, payee, offers[i].offer.price);
        }
    }

    function processPrimePayout(SignedPrimeOffer memory sOffer, address seller) internal returns (uint totalPaid) {
        return processPayoutAndRoyalty(address(Avastars), sOffer.offer.primeId, payable(seller), sOffer.offer.price);
    }

    function processTokenPayout(SignedTokenOffer memory sOffer, address seller) internal returns (uint totalPaid) {
        return processPayoutAndRoyalty(sOffer.offer.tokenAddress, sOffer.offer.tokenId, payable(seller), sOffer.offer.price);
    }

    function processPayoutAndRoyalty(address tokenAddress, uint256 tokenId, address payable seller, uint price ) internal returns (uint totalPaid) {
        uint remaining = price;
        if (RoyaltyOverridden[tokenAddress]) {
            RoyaltyScheduleEntry[] memory schedule = RoyaltyOverrides[tokenAddress];
            for (uint idx = 0; idx < schedule.length; idx++) {
                uint amount = price * uint(schedule[idx].bps) / uint(10000);
                processPayout(schedule[idx].recipient, amount);
                remaining -= amount;
            }
        } else if (tokenAddress != FakeAvastarsTraitCollection){
            (address payable[] memory recipients, uint[] memory amounts)  = RoyaltyEngine.getRoyalty(tokenAddress, tokenId, price);
            for (uint idx = 0; idx < recipients.length; idx++) {
                processPayout(recipients[idx], amounts[idx]);
                remaining -= amounts[idx];
            }
        }

        processPayout(payable(seller), remaining);
        return price;
    }
    
    function processPayout(address payable payee, uint payment) internal {
        bool success = payee.send(payment);
        if(!success) {
            EscrowedPayments[payee] += payment;
        }
    }

    function processReplicantMintRequest(
        SignedReplicantMintRequest memory sRequest
    ) internal returns (uint256 totalPaid) {
        require(hasArt(msg.sender, 1));
        (bool accessToTraits, bytes32[] memory digests) = hasAccessToTraits(sRequest.request.traitSources, sRequest.request.consumedOffers);
        require(accessToTraits);
        require(isValidMint(sRequest));

        burnTraits(sRequest.request.traitSources);
        burnOffers(digests);
        burnArt(msg.sender, 1);

        /*!!! is paymentTier === ranking? */
        Avastars.mintReplicant(msg.sender, sRequest.request.traitHash, sRequest.request.generation, sRequest.request.gender, sRequest.request.ranking );

        totalPaid = processTraitPayouts(sRequest.request.consumedOffers);
    }

    function processPurchasePrime(
        PurchasePrimeRequest memory request
    ) internal returns (uint256 totalPaid) {
        require(Avastars.getAvastarWaveByTokenId(request.consumeOffer.offer.primeId) == IAvastarsTeleporter.Wave.PRIME);
        address primeOwner = Avastars.ownerOf(request.consumeOffer.offer.primeId);
        
        bytes32 digest = offerIsValid(primeOwner, request.consumeOffer);
        require(digest != bytes32(0));
        require(primeHasTraitsAvailable(request.consumeOffer.offer.primeId, request.requiredAvailableTraits));
        
        burnOffer(digest);

        Avastars.safeTransferFrom(primeOwner, msg.sender, request.consumeOffer.offer.primeId);
        
        totalPaid = processPrimePayout(request.consumeOffer, primeOwner);
    }

    function processPurchaseToken(
        SignedTokenOffer memory sOffer
    ) internal returns (uint256 totalPaid) {
        require(isValidTokenAddress(sOffer.offer.tokenAddress) || isReplicant(sOffer.offer.tokenAddress, sOffer.offer.tokenId));
        IERC721 tokenContract = IERC721(sOffer.offer.tokenAddress);
        
        address tokenOwner = tokenContract.ownerOf(sOffer.offer.tokenId);
        
        bytes32 digest = offerIsValid(tokenOwner, sOffer);
        require(digest != bytes32(0));
        
        burnOffer(digest);

        tokenContract.safeTransferFrom(tokenOwner, msg.sender, sOffer.offer.tokenId);
        
        totalPaid = processTokenPayout(sOffer, tokenOwner);
    }

    /**
        * @notice Process a market order which can be a combination of replicant mints, and token purchases.
        */
    function processOrder(
        SignedReplicantMintRequest[] memory replicantMints,
        PurchasePrimeRequest[] memory primePurchases,
        SignedTokenOffer[] memory tokenPurchases,
        bytes memory verifiedBuyerSignature
    ) public payable nonReentrant whenNotPaused {
        require(buyerIsVerified(msg.sender, verifiedBuyerSignature));
        
        uint totalPaid = 0;

        for (uint idx = 0; idx < replicantMints.length; idx++) {
            uint paid = processReplicantMintRequest(replicantMints[idx]);
            totalPaid += paid;
        }

        for (uint idx = 0; idx < primePurchases.length; idx++) {
            totalPaid += processPurchasePrime(primePurchases[idx]);
        }

        for (uint idx = 0; idx < tokenPurchases.length; idx++) {
            totalPaid += processPurchaseToken(tokenPurchases[idx]);
        }

        require(totalPaid == msg.value);
    }

    function cancelTraitOffer(SignedTraitOffer memory offer) internal {
        bytes32 digest = offerIsValid(msg.sender, offer);
        require(digest != bytes32(0));
        burnOffer(digest);
    }

    function cancelPrimeOffer(SignedPrimeOffer memory offer) internal {
        bytes32 digest = offerIsValid(msg.sender, offer);
        require(digest != bytes32(0));
        burnOffer(digest);
    }

    function cancelTokenOffers(SignedTokenOffer memory offer) internal {
        bytes32 digest = offerIsValid(msg.sender, offer);
        require(digest != bytes32(0));
        burnOffer(digest);
    }

    /**
        cancel a batch of offers that must be signed by the sender and otherwise
        still valid
    */
    function cancelOffers(
        SignedTraitOffer[] memory traitOffers,
        SignedPrimeOffer[] memory primeOffers,
        SignedTokenOffer[] memory tokenOffers
    ) public {
        for (uint idx = 0; idx < traitOffers.length; idx++) {
            cancelTraitOffer(traitOffers[idx]);
        }

        for (uint idx = 0; idx < primeOffers.length; idx++) {
            cancelPrimeOffer(primeOffers[idx]);
        }

        for (uint idx = 0; idx < tokenOffers.length; idx++) {
            cancelTokenOffers(tokenOffers[idx]);
        }
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    ///@dev required by the OZ UUPS module
    function _authorizeUpgrade(address) internal override onlyOwner {}
}