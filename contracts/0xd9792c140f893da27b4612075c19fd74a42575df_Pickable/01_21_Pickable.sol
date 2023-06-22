// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Interfaces
import "@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCore.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IERC721LazyPayableClaim.sol";
import "./IERC721CreatorCoreVersion.sol";

// Abstract
import "./LazyPayableClaim.sol";

/**
 * @title Pickable Claim
 * @author @thedepthofthedaimon
 * @notice Pickable Claim with optional whitelist ERC721 tokens
 */
contract Pickable is IERC165, IERC721LazyPayableClaim, ICreatorExtensionTokenURI, LazyPayableClaim {
    using Strings for uint256;

    // stores mapping from contractAddress/instanceId to the claim it represents
    // { contractAddress => { instanceId => Claim } }
    mapping(address => mapping(uint256 => Claim)) private _claims;

    // stores mapping from contractAddress/instanceId to the _picks information
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) private _tokenToCombination; // _tokenToCombination[contractCreatorAddress][instanceId][tokenId] = combinationId + 1 (0: Available to Reserve)
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) private _combinationToToken; // _combinationToToken[contractCreatorAddress][instanceId][combinationId] = tokenId (0: Available to Reserve, tokenId starts at 1)

    // bitmapped information on picked nfts
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) private _combinationMap; // _combinationMap[contractCreatorAddress][instanceId][bitmapOffset] = uint256
    event ReservedCombination(address indexed creatorContract, uint256 indexed instanceId, uint256 tokenId, uint256 combinationId);

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return interfaceId == type(IERC721LazyPayableClaim).interfaceId ||
            interfaceId == type(ILazyPayableClaim).interfaceId ||
            interfaceId == type(ICreatorExtensionTokenURI).interfaceId ||
            interfaceId == type(IAdminControl).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }


    function checkVersion(address creatorContractAddress) public view returns (uint8) {
        uint8 creatorContractVersion;
        try IERC721CreatorCoreVersion(creatorContractAddress).VERSION() returns(uint256 version) {
            require(version > 0, "Unsupported contract version");
            require(version <= 255, "Unsupported contract version");
            creatorContractVersion = uint8(version);
        } catch {
            creatorContractVersion = 252;
        }
        return creatorContractVersion;
    }

    /**
     * See {IERC721LazyClaim-initializeClaim}.
     */
    function initializeClaim(
        address creatorContractAddress,
        uint256 instanceId,
        ClaimParameters calldata claimParameters
    ) external override creatorAdminRequired(creatorContractAddress) {
        require(instanceId > 0 && instanceId <= MAX_UINT_56, "Invalid instanceId");
        require(_claims[creatorContractAddress][instanceId].contractVersion == 0, "Claim already initialized");
        require(claimParameters.endDate == 0 || claimParameters.startDate < claimParameters.endDate, "Cannot have startDate greater than or equal to endDate");

        uint8 creatorContractVersion = checkVersion(creatorContractAddress);

        // Create the claim
        _claims[creatorContractAddress][instanceId] = Claim({
            total: 0,
            totalMax: claimParameters.totalMax,
            combinationMax: claimParameters.combinationMax,
            startDate: claimParameters.startDate,
            endDate: claimParameters.endDate,
            contractVersion: creatorContractVersion,
            tokenUriStyle: claimParameters.tokenUriStyle,
            reservationState: claimParameters.reservationState,
            location: claimParameters.location,
            extension: claimParameters.extension,
            cost: claimParameters.cost,
            paymentReceiver: claimParameters.paymentReceiver,
            erc20: claimParameters.erc20
        });

        emit ClaimInitialized(creatorContractAddress, instanceId, msg.sender);
    }

    /**
     * See {IERC721LazyClaim-udpateClaim}.
     */
    function updateClaim(
        address creatorContractAddress,
        uint256 instanceId,
        ClaimParameters memory claimParameters
    ) external override creatorAdminRequired(creatorContractAddress) {
        // Sanity checks
        Claim memory claim = _claims[creatorContractAddress][instanceId];
        require(claim.contractVersion != 0, "Claim not initialized");
        require(claimParameters.endDate == 0 || claimParameters.startDate < claimParameters.endDate, "Cannot have startDate greater than or equal to endDate");
        require(claimParameters.erc20 == claim.erc20, "Cannot change payment token");
        if (claimParameters.totalMax != 0 && claim.total > claimParameters.totalMax) {
            claimParameters.totalMax = claim.total;
        }

        // Overwrite the existing claim
        _claims[creatorContractAddress][instanceId] = Claim({
            total: claim.total,
            totalMax: claimParameters.totalMax,
            combinationMax: claimParameters.combinationMax,
            startDate: claimParameters.startDate,
            endDate: claimParameters.endDate,
            contractVersion: claim.contractVersion,
            tokenUriStyle: claimParameters.tokenUriStyle,
            reservationState: claimParameters.reservationState,
            location: claimParameters.location,
            extension: claimParameters.extension,
            cost: claimParameters.cost,
            paymentReceiver: claimParameters.paymentReceiver,
            erc20: claim.erc20
        });
        emit ClaimUpdated(creatorContractAddress, instanceId);
    }

    /**
     * See {IERC721LazyClaim-updateTokenURIParams}.
     */
    function updateTokenURIParams(
        address creatorContractAddress, uint256 instanceId,
        TokenUriStyle tokenUriStyle,
        ReservationState reservationState,
        string calldata location,
        string calldata extension
    ) external override creatorAdminRequired(creatorContractAddress) {
        Claim storage claim = _claims[creatorContractAddress][instanceId];
        require(_claims[creatorContractAddress][instanceId].contractVersion != 0, "Claim not initialized");
        claim.tokenUriStyle = tokenUriStyle;
        claim.reservationState = reservationState;
        claim.location = location;
        claim.extension = extension;
        emit ClaimUpdated(creatorContractAddress, instanceId);
    }

    /**
     * See {ILazyPayableClaim-getClaim}.
     */
    function getClaim(address creatorContractAddress, uint256 instanceId) public override view returns(Claim memory) {
        return _getClaim(creatorContractAddress, instanceId);
    }

    /**
     * See {ILazyPayableClaim-getClaimForToken}.
     */
    function getClaimForToken(address creatorContractAddress, uint256 tokenId) external override view returns(uint256 instanceId, Claim memory claim) {
        // No claim, try to retrieve from tokenData
        uint80 tokenData = IERC721CreatorCore(creatorContractAddress).tokenData(tokenId);
        instanceId = uint56(tokenData >> 24);
        claim = _getClaim(creatorContractAddress, instanceId);
    }

    function _getClaim(address creatorContractAddress, uint256 instanceId) private view returns(Claim storage claim) {
        claim = _claims[creatorContractAddress][instanceId];
        require(claim.contractVersion != 0, "Claim not initialized");
    }

    /**
     * See {ILazyPayableClaim-mint}.
     */
    function mint(address creatorContractAddress, uint256 instanceId) external payable override {
        Claim storage claim = _getClaim(creatorContractAddress, instanceId);

        // Check totalMax
        require((++claim.total <= claim.totalMax || claim.totalMax == 0) && claim.total <= MAX_UINT_24, "Maximum tokens already minted for this claim");

        // Validate mint
        _validateMintTime(claim.startDate, claim.endDate);

        // Transfer funds
        _transferFunds(claim.erc20, claim.cost, claim.paymentReceiver, 1);

        // Do mint
        uint80 tokenData = uint56(instanceId) << 24 | uint24(claim.total);
        IERC721CreatorCore(creatorContractAddress).mintExtension(msg.sender, tokenData);

        emit ClaimMint(creatorContractAddress, instanceId);
    }

    /**
     * See {ILazyPayableClaim-mintBatch}.
     */
    function mintBatch(address creatorContractAddress, uint256 instanceId, uint16 mintCount) external payable override {
        Claim storage claim = _getClaim(creatorContractAddress, instanceId);

        // Check totalMax
        claim.total += mintCount;
        require((claim.totalMax == 0 || claim.total <= claim.totalMax) && claim.total <= MAX_UINT_24, "Too many requested for this claim");

        // Validate mint
        _validateMintTime(claim.startDate, claim.endDate);
        uint256 newMintIndex = claim.total - mintCount + 1;

        // Transfer funds
        _transferFunds(claim.erc20, claim.cost, claim.paymentReceiver, mintCount);

        uint80[] memory tokenData = new uint80[](mintCount);
        for (uint256 i; i < mintCount;) {
            tokenData[i] = uint56(instanceId) << 24 | uint24(newMintIndex+i);
            unchecked { ++i; }
        }
        IERC721CreatorCore(creatorContractAddress).mintExtensionBatch(msg.sender, tokenData);

        emit ClaimMintBatch(creatorContractAddress, instanceId, mintCount);
    }

    /**
     * See {IERC721LazyClaim-airdrop}.
     */
    function airdrop(address creatorContractAddress, uint256 instanceId, address[] calldata recipients,
            uint16[] calldata amounts) external override creatorAdminRequired(creatorContractAddress) {
        require(recipients.length == amounts.length, "Unequal number of recipients and amounts");

        Claim storage claim = _claims[creatorContractAddress][instanceId];
        uint256 newMintIndex = claim.total+1;

        for (uint256 i; i < recipients.length;) {
            uint16 mintCount = amounts[i];
            uint80[] memory tokenDatas = new uint80[](mintCount);
            for (uint256 j; j < mintCount;) {
                tokenDatas[j] = uint56(instanceId) << 24 | uint24(newMintIndex+j);
                unchecked { ++j; }
            }
            IERC721CreatorCore(creatorContractAddress).mintExtensionBatch(recipients[i], tokenDatas);
            unchecked{ newMintIndex += mintCount; }
            unchecked{ ++i; }
        }

        require(newMintIndex - claim.total - 1 <= MAX_UINT_24, "Too many requested");
        claim.total += uint32(newMintIndex - claim.total - 1);
        if (claim.totalMax != 0) {
            require( claim.total <= claim.totalMax, "Requested > Max");
        }
    }

    function getCombinationMapPage(address creatorContractAddress, uint256 instanceId, uint256 page) external view returns(uint256) {
        return _combinationMap[creatorContractAddress][instanceId][page];
    }


    function _reserve(address creatorContractAddress, uint256 instanceId, uint256 tokenId, uint256 combinationId) internal {
        Claim storage claim = _claims[creatorContractAddress][instanceId];
        AdminControl creatorCoreContract = AdminControl(creatorContractAddress);
        if(creatorCoreContract.isAdmin(msg.sender) == false) {
            require( msg.sender == IERC721(creatorContractAddress).ownerOf(tokenId), "Caller not owner" );
        }
        require( claim.reservationState == ReservationState.RESERVATION_OPEN, "Reservations Closed");
        require( tokenId < claim.totalMax, "Invalid Token");
        require( combinationId < claim.combinationMax, "Invalid Combination"); // maxCombintion = 100, valid combinationId = 0..99

        // Solidity 0.8 required 
        uint256 combinationPage = combinationId / 256;
        uint256 combinationMask = 1 << (combinationId % 256);

        // Mark Combination Map
        require (_combinationMap[creatorContractAddress][instanceId][combinationPage] & combinationMask == 0, "Combination Unavailable");
        _combinationMap[creatorContractAddress][instanceId][combinationPage] |= combinationMask;

        // Map Token => Combination
        require (_tokenToCombination[creatorContractAddress][instanceId][tokenId] == 0, "Token Has Reservation");
        _tokenToCombination[creatorContractAddress][instanceId][tokenId] = combinationId + 1; /* offset by 1, unused = 0 */

        // Map Combination => Token
        _combinationToToken[creatorContractAddress][instanceId][combinationId] = tokenId;

        // Finish
        emit ReservedCombination(creatorContractAddress, instanceId, tokenId, combinationId);
    }

    function reserve(address creatorContractAddress, uint256 instanceId, uint256 tokenId, uint256 combinationId) external {
        _reserve(creatorContractAddress, instanceId, tokenId, combinationId);
    }

    function reserveBatch(address creatorContractAddress, uint256 instanceId, uint256[] calldata tokenIds, uint256[] calldata combinationIds) external {
        require(tokenIds.length == combinationIds.length, "Unequal number of tokens and combinations");
        for (uint256 i; i < tokenIds.length;) {
            _reserve(creatorContractAddress, instanceId, tokenIds[i], combinationIds[i]);
            unchecked{ ++i; }
        }
    }
            

    function getTokenData(address creatorContractAddress, uint256 tokenId) external view returns(uint80 tokenData) {
        return IERC721CreatorCore(creatorContractAddress).tokenData(tokenId);
    }

    function getCombinationForInstanceToken(address creatorContractAddress, uint256 instanceId, uint256 tokenId) external view returns(uint256 combinationId) {
        combinationId = _tokenToCombination[creatorContractAddress][instanceId][tokenId]; 
        require (combinationId > 0, "No Reservation");
        return combinationId - 1;
    }

    function getInstanceIdForToken(address creatorContractAddress, uint256 tokenId) external view returns(uint56 instanceId ) {
        // No claim, try to retrieve from tokenData
        uint80 tokenData = IERC721CreatorCore(creatorContractAddress).tokenData(tokenId);
        instanceId = uint56(tokenData >> 24);
        return instanceId;
    }

    function getCombinationForToken(address creatorContractAddress, uint256 tokenId) external view returns(uint256 combinationId) {
        // No claim, try to retrieve from tokenData
        uint80 tokenData = IERC721CreatorCore(creatorContractAddress).tokenData(tokenId);
        uint56 instanceId = uint56(tokenData >> 24);

        combinationId = _tokenToCombination[creatorContractAddress][instanceId][tokenId]; 
        require (combinationId > 0, "No Reservation");
        return combinationId - 1;
    }

    /**
     * See {ICreatorExtensionTokenURI-tokenURI}.
     */
    function tokenURI(address creatorContractAddress, uint256 tokenId) external override view returns(string memory uri) {
        Claim memory claim;
        uint256 mintOrder;

        uint80 tokenData = IERC721CreatorCore(creatorContractAddress).tokenData(tokenId);
        uint56 instanceId = uint56(tokenData >> 24);
        require(instanceId != 0, "Token does not exist");
        claim = _claims[creatorContractAddress][instanceId];
        mintOrder = uint24(tokenData & MAX_UINT_24); // mintOrder duplicated across multible instanceIds

        if (claim.tokenUriStyle == TokenUriStyle.COMBINATION_ID) {
            // During Reservation { COMBINTAION_ID }
            uint256 combinationId = _tokenToCombination[creatorContractAddress][instanceId][tokenId]; 
            if (combinationId > 0) {
                uri = string(abi.encodePacked(claim.location, uint256(combinationId - 1).toString(), claim.extension)); // remove +1 offset
            } else {
                uri = string(abi.encodePacked(claim.location, "default", claim.extension));
            }
        } else if (claim.tokenUriStyle == TokenUriStyle.MINT_ORDER) {
            // Reservations Disabled { MINT_ORDER } - claim+instanceId Index
            uri = string(abi.encodePacked(claim.location, uint256(mintOrder).toString(), claim.extension));  
        } else {
            // Reservations Disabled { INVALID, TOKEN_ID } - Absolute Index
            uri = string(abi.encodePacked(claim.location, uint256(tokenId).toString(), claim.extension)); 
        }
    }
}