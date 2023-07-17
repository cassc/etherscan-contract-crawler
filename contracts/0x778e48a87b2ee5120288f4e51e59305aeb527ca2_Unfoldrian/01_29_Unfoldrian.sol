//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../interfaces/INOwnerResolver.sol";
import "../interfaces/IN.sol";
import "./UnfoldrianPricing.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "hardhat/console.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                       //
//      ___           ___           ___           ___           ___       ___           ___                       ___           ___      //
//     /\__\         /\__\         /\  \         /\  \         /\__\     /\  \         /\  \          ___        /\  \         /\__\     //
//    /:/  /        /::|  |       /::\  \       /::\  \       /:/  /    /::\  \       /::\  \        /\  \      /::\  \       /::|  |    //
//   /:/  /        /:|:|  |      /:/\:\  \     /:/\:\  \     /:/  /    /:/\:\  \     /:/\:\  \       \:\  \    /:/\:\  \     /:|:|  |    //
//  /:/  /  ___   /:/|:|  |__   /::\~\:\  \   /:/  \:\  \   /:/  /    /:/  \:\__\   /::\~\:\  \      /::\__\  /::\~\:\  \   /:/|:|  |__  //
// /:/__/  /\__\ /:/ |:| /\__\ /:/\:\ \:\__\ /:/__/ \:\__\ /:/__/    /:/__/ \:|__| /:/\:\ \:\__\  __/:/\/__/ /:/\:\ \:\__\ /:/ |:| /\__\ //
// \:\  \ /:/  / \/__|:|/:/  / \/__\:\ \/__/ \:\  \ /:/  / \:\  \    \:\  \ /:/  / \/_|::\/:/  / /\/:/  /    \/__\:\/:/  / \/__|:|/:/  / //
//  \:\  /:/  /      |:/:/  /       \:\__\    \:\  /:/  /   \:\  \    \:\  /:/  /     |:|::/  /  \::/__/          \::/  /      |:/:/  /  //
//   \:\/:/  /       |::/  /         \/__/     \:\/:/  /     \:\  \    \:\/:/  /      |:|\/__/    \:\__\          /:/  /       |::/  /   //
//    \::/  /        /:/  /                     \::/  /       \:\__\    \::/__/       |:|  |       \/__/         /:/  /        /:/  /    //
//     \/__/         \/__/                       \/__/         \/__/     ~~            \|__|                     \/__/         \/__/     //
//                                                                                                                                       //
//                                                                                                                                       //
//  Art: Adam Swaab                                                                                                                      //
//  Contract Dev: Archethect                                                                                                             //
//  Description: Contract for the creation of on-chain                                                                                   //
//               Unfoldrian art.                                                                                                         //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract Unfoldrian is UnfoldrianPricing, EIP712 {

    using Strings for uint256;

    bytes32 public constant SIGNER_ROLE = keccak256("SIGNING");

    bool public publicSale;
    bool public nSale;
    bool public preSale;
    bytes32 public merkleRoot;
    uint256[] private mintedIds;
    string public metadataUri;
    string public metadataExtension;
    address private signerAddress;
    INOwnerResolver public immutable nOwnerResolver;

    mapping (uint256 => bool) usedN;

    struct ContractAddresses {
        address n;
        address masterMint;
        address dao;
        address karmaAddress;
        address signer;
        address nOwnersRegistry;
    }

    DerivativeParameters params = DerivativeParameters(false, false, 0, 88, 2);

    constructor(
        ContractAddresses memory contractAddresses
    )
        EIP712("Unfoldrian", "1.0.0")
        UnfoldrianPricing(
            "Unfoldrian",
            "UNFLD",
            IN(contractAddresses.n),
            params,
            250000000000000000,
            250000000000000000,
            contractAddresses.masterMint,
            contractAddresses.dao
        )
    {
        metadataUri = "https://arweave.net/aIbzGchq9jFEnaFcnop1-oBJZORbLTaQbhbrXC8ti5U/";
        metadataExtension = ".json";
        nOwnerResolver = INOwnerResolver(contractAddresses.nOwnersRegistry);
        signerAddress = contractAddresses.signer;
        _setupRole(SIGNER_ROLE, contractAddresses.signer);
        _setRoleAdmin(SIGNER_ROLE, ADMIN_ROLE);

    }


    function _hash(address minter, uint256[] memory tokenIds, uint256 expiry) internal view returns (bytes32)
    {
        return _hashTypedDataV4(keccak256(abi.encode(
        keccak256("Voucher(uint256[] tokenIds,address minter,uint256 expiry)"),
            keccak256(abi.encodePacked(tokenIds)),
            minter,
            expiry
        )));
    }

    function _verify(bytes32 digest, bytes memory signature)
    internal view returns (bool)
    {
        return hasRole(SIGNER_ROLE, ECDSA.recover(digest, signature));
    }

    function _leaf(address account, uint256 tokenId)
    internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(tokenId,account));
    }

    function _verifyMerkleProof(bytes32 leaf, bytes32[] memory proof)
    internal view returns (bool)
    {
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    function getMintedIds() public view returns(uint256[] memory) {
        return mintedIds;
    }

    function verifyWhitelist(uint256[] memory tokenIds, address recipient, bytes32[][] memory proofs) internal view returns (bool) {
        bool allowed = true;
        for(uint16 i = 0;i < tokenIds.length; i++) {
           allowed = allowed && _verifyMerkleProof(_leaf(recipient, tokenIds[i]), proofs[i]);
        }
        return allowed;
    }

    function setMerkleRoot(bytes32 newRoot) external onlyAdmin {
        merkleRoot = newRoot;
    }


    function setPublicSaleState(bool state) external onlyAdmin {
        publicSale = state;
    }

    function setPreSaleState(bool state) external onlyAdmin {
        preSale = state;
    }

    function setNSaleState(bool state) external onlyAdmin {
        nSale = state;
    }

    /**
     * @notice Allow a n token holder to bulk mint tokens with id of their n tokens' id
     * @param recipient Recipient of the mint
     * @param tokenIds Ids to be minted
     * @param paid Amount paid for the mint
     */
    function mintWithN(
        address recipient,
        uint256[] calldata tokenIds,
        uint256 paid,
        bytes calldata data
    ) public virtual override nonReentrant {
        require((preSale || nSale) && !publicSale, "UNFOLDRIAN:N_MINT_ONLY_DURING_PRESALE_AND_NSALE");
        uint256 maxTokensToMint = tokenIds.length;
        require(maxTokensToMint <= derivativeParams.maxMintAllowance, "UNFOLDRIAN:MINT_ABOVE_MAX_MINT_ALLOWANCE");
        require(balanceOf(recipient) + maxTokensToMint <= derivativeParams.maxMintAllowance, "UNFOLDRIAN:ADDRESS_MAX_ALLOCATION_REACHED");
        require(
            totalSupply() + maxTokensToMint <= derivativeParams.maxTotalSupply,
            "UNFOLDRIAN:MAX_ALLOCATION_REACHED"
        );
        require(paid == getNextPriceForNHoldersInWei(maxTokensToMint, recipient, data), "UNFOLDRIAN:INVALID_PRICE");
        if(nSale) {
            (uint256[] memory tokens, uint256 expiry, bytes memory signature) = abi.decode(data,(uint256[],uint256, bytes));
            require(_verify(_hash(recipient, tokens, expiry), signature), "UNFOLDRIAN:INVALID_SIGNATURE");
            for (uint256 i = 0; i < maxTokensToMint; i++) {
                require(!usedN[tokenIds[i]], "UNFOLDRIAN:N_ALREADY_USED");
                _safeMint(recipient,tokens[i]);
                mintedIds.push(tokens[i]);
                usedN[tokenIds[i]] = true;
            }
        } else
        if (preSale) {
            require(verifyWhitelist(tokenIds, recipient, abi.decode(data,(bytes32[][]))), "UNFOLDRIAN:MINT_UNAUTHORISED");
            for (uint256 i = 0; i < maxTokensToMint; i++) {
                require(!usedN[tokenIds[i]], "UNFOLDRIAN:N_ALREADY_USED");
                _safeMint(recipient,tokenIds[i]);
                mintedIds.push(tokenIds[i]);
                usedN[tokenIds[i]] = true;
            }
        }
    }
    /**
     * @notice Allow anyone to mint a token with the supply id if this pass is unrestricted.
     *         n token holders can use this function without using the n token holders allowance,
     *         this is useful when the allowance is fully utilized.
     * @param recipient Recipient of the mint
     * @param paid Amount paid for the mint
     */
    function mint(
        address recipient,
        uint8,
        uint256 paid,
        bytes calldata data
    ) public virtual override nonReentrant {
        require(publicSale, "UNFOLDRIAN:MINT_ONLY_DURING_PUBLIC_SALE");
        (uint256[] memory tokens, uint256 expiry, bytes memory signature) = abi.decode(data,(uint256[],uint256, bytes));
        require(block.timestamp <= expiry, "UNFOLDRIAN:VOUCHER_EXPIRED");
        require(_verify(_hash(recipient, tokens, expiry), signature), "UNFOLDRIAN:INVALID_SIGNATURE");
        uint256 maxTokensToMint = tokens.length;
        require(maxTokensToMint <= derivativeParams.maxMintAllowance, "UNFOLDRIAN: MINT_ABOVE_MAX_MINT_ALLOWANCE");
        require(balanceOf(recipient) + maxTokensToMint <= derivativeParams.maxMintAllowance, "UNFOLDRIAN:ADDRESS_MAX_ALLOCATION_REACHED");
        require(
            totalSupply() + maxTokensToMint <= derivativeParams.maxTotalSupply,
            "UNFOLDRIAN:MAX_ALLOCATION_REACHED"
        );
        require(paid == getNextPriceForOpenMintInWei(maxTokensToMint, recipient, data), "UNFOLDRIAN:INVALID_PRICE");

        for (uint256 i = 0; i < maxTokensToMint; i++) {
            _safeMint(recipient,tokens[i]);
            mintedIds.push(tokens[i]);
        }
    }

    function mintTokenId(
        address,
        uint256[] calldata,
        uint256,
        bytes calldata
    ) public virtual override nonReentrant {
        require(false, "UNFOLDRIAN:MINT_TOKEN_ID_NOT_ALLOWED");
    }

    function airdrop() external onlyAdmin {
        super._safeMint(0xC8679c5F9C01dd6A45C5860D8b68F38354F1109D, 2350, "");
        mintedIds.push(2350);
    }

    /**
     * @notice Calculate the total available number of mints
     * @return total mint available
     */
    function totalMintsAvailable() public view override returns (uint256) {
        return derivativeParams.maxTotalSupply - totalSupply();
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(super.tokenURI(tokenId), metadataExtension));
    }

    function setMetadataURIAndExtension(string calldata metadataUri_, string calldata metadataExtension_)
        external
        onlyDAO
    {
        metadataUri = metadataUri_;
        metadataExtension = metadataExtension_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return metadataUri;
    }

    function canMint(address account, bytes calldata data) public view virtual override returns (bool) {
        uint256 balance = balanceOf(account);
        uint256 nBalance = nOwnerResolver.balanceOf(account);
        if(publicSale && totalMintsAvailable() > 0 && balance < derivativeParams.maxMintAllowance) {
            return true;
        }
        if(nSale && !publicSale && nBalance > 0 && totalMintsAvailable() > 0 && balance < derivativeParams.maxMintAllowance) {
           return true;
        }
        if(preSale && !nSale && !publicSale && totalMintsAvailable() > 0 && balance < derivativeParams.maxMintAllowance) {
            (uint256[] memory tokenIds, bytes32[][] memory proofs) = abi.decode(data,(uint256[],bytes32[][]));
            if(verifyWhitelist(tokenIds, account, proofs)) {
                return true;
            }
        }
        return false;
    }

    function nUsed(uint256 nid) external override view returns (bool) {
        return usedN[nid];
    }

    function vouchersActive() external view returns (bool) {
        return nSale || publicSale;
    }

    function mintWithNEnabled() external view returns (bool) {
        return ((preSale || nSale) && !publicSale);
    }

    function mintEnabled() external view returns (bool) {
        return publicSale;
    }

    function contractURI() public pure returns (string memory) {
        return "https://arweave.net/SpA333yK3NQ4zWn1j0Cr_ptRBGgqrbjVwXOlix1zJhw/metadata.json";
    }
}