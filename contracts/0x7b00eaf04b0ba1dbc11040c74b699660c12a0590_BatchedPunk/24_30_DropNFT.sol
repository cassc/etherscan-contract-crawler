// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./VRFv2Consumer.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./ITokenDNAStorage.sol";

/// @title Tribute Drop NFT Abstract Contract
/// @author Tribute Brand LLC
/// @notice This contract defines the interface and default behavior of drop nft contracts.
/// @dev This contract is meant to be implemented by actual drop contracts.
///		 It is mainly interacted with through the TributeBrand contract.
abstract contract DropNFT is DefaultOperatorFilterer, ERC721Royalty, VRFv2Consumer, Ownable {
    error AwaitingEntropy();
    error WrongReveal();
    error MintingPaused();
    error ReservedSupplyReached();
    error TotalSupplyReached();

    string private _revealedBaseURI;
    uint256 private _reservedMinted;
    address immutable deployer;
    uint256 internal _totalMinted;

    bool public mintingPaused;

    ITokenDNAStorage public DNAResolverContract;

    constructor(
        address tributeBrandFactory,
        address dnaContract,
        string memory name_,
        string memory symbol_,
        uint64 chainlinkKey
    ) VRFv2Consumer(chainlinkKey) ERC721(name_, symbol_) {
        DNAResolverContract = ITokenDNAStorage(dnaContract);
        deployer = msg.sender;
        _setDefaultRoyalty(deployer, 750); // 750 basis points <=> 7.5 % royalty fee
        transferOwnership(tributeBrandFactory);
    }

    // =============================================================
    //            ROYALTY OVERRIDES (OPERATOR FILTER)
    // =============================================================

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // =============================================================
    //                        OWNER METHODS
    // =============================================================
    modifier onlyOwnerOrDeployer() {
        require(owner() == _msgSender() || deployer == msg.sender, "Ownable: caller is not the owner or deployer");
        _;
    }

    function mint(address to, uint256) external virtual onlyOwner returns (uint256) {
        if (_totalMinted + 1 > _maxSupply() - _reservedSupply()) {
            revert TotalSupplyReached();
        }
        return _mintTo(to);
    }

    function reservedMint(address to, uint256 quantity, uint256)
        external
        virtual
        onlyOwnerOrDeployer
        returns (uint256 startTokenId)
    {
        if (quantity > _reservedRemaining()) revert ReservedSupplyReached();
        startTokenId = _totalMinted;
        for (uint256 i; i < quantity; i++) {
            _mintTo(to);
        }
        _reservedMinted += quantity;
    }

    function manualSetEntropy() external virtual onlyOwnerOrDeployer {
        if (entropy == 0) {
            entropy = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        }
    }

    function requestEntropy() public virtual returns (uint256) {
        if (entropy > 0) return 0;
        return requestRandomWords();
    }

    function reveal(string calldata realBaseTokenURI) external onlyOwnerOrDeployer {
        _reveal(realBaseTokenURI);
    }

    function pause(bool on) external onlyOwnerOrDeployer {
        mintingPaused = on;
    }

    function usesEntropy() external pure returns (bool) {
        return _useEntropy();
    }

    // =============================================================
    //              CONSTANTS / TYPES / OVERRIDEABLES
    // =============================================================

    struct Trait {
        string trait_type;
        string trait_value;
        string trait_extra;
    }

    function tokenDNA(uint256 tokenId) public view virtual returns (bytes16 dna) {
        dna = DNAResolverContract.getTokenDNA(tokenId, entropy);
    }

    // ------ REQUIRED ------

    function dropUUID() external pure virtual returns (string memory);

    function contractURI() external pure virtual returns (string memory);

    function provenanceHash() external pure virtual returns (string memory);

    function _encodedBaseURI() internal pure virtual returns (bytes32);

    function _unrevealedBaseURI() internal pure virtual returns (string memory);

    function _reservedSupply() internal pure virtual returns (uint256);

    // ------ OPTIONAL ------
    function _traitsToAttributeString(Trait[] memory traits) internal pure virtual returns (string memory) {
        string memory bStr;

        for (uint256 idx = 0; idx < traits.length; idx++) {
            bStr = string.concat(
                bStr, '{"trait_type":"', traits[idx].trait_type, '","value":"', traits[idx].trait_value, '"}'
            );

            if (idx < traits.length - 1) bStr = string.concat(bStr, ",");
        }

        return bStr;
    }

    function _maxSupply() internal pure virtual returns (uint256) {
        return 10000;
    }

    function _useEntropy() internal pure virtual returns (bool) {
        return false;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _isRevealed() ? _revealedBaseURI : _unrevealedBaseURI();
    }

    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    function _isRevealed() internal view virtual returns (bool) {
        return bytes(_revealedBaseURI).length > 0;
    }

    function _mintTo(address to) internal virtual returns (uint256 tokenId) {
        // We only have one entropy for the first drop. This is here so that no one can mint between the moment of nft contract publishing
        // (which is when the entropy is requested from chainlink VFR) and the moment that request is fulfilled (~30s later).
        if (mintingPaused) revert MintingPaused();
        if (_useEntropy() && entropy == 0) revert AwaitingEntropy();
        tokenId = _totalMinted++;
        super._mint(to, tokenId);
    }

    // =============================================================
    //                        OTHER
    // =============================================================
    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(`totalSupply`) in complexity.
     * It is meant to be called off-chain.
     *
     * (off-chain calls to view/pure functions are free, but calling
     * them on-chain, for instance from the TributeBrand contract, is not free).
     *
     * To get all the tokens in all drops that an account owns: first read drops() from the
     * TributeBrand contract, then for each of these addresses call this function.
     */

    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwner;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            for (uint256 i = 0; tokenIdsIdx != tokenIdsLength; ++i) {
                if (currOwner == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }

    function checkClaimEligibility(uint256 quantity) external view returns (string memory) {
        if (mintingPaused || (_useEntropy() && entropy == 0)) {
            return "not live yet";
        } else if (_totalMinted + quantity > _maxSupply() - _reservedSupply()) {
            return "not enough supply";
        }
        return "";
    }

    // =============================================================
    //                        INTERNAL UTILS
    // =============================================================

    function _reservedRemaining() private view returns (uint256) {
        return _reservedSupply() - _reservedMinted;
    }

    function _reveal(string calldata realBaseTokenURI) private {
        if (keccak256(abi.encodePacked(realBaseTokenURI)) != _encodedBaseURI()) {
            revert WrongReveal();
        }

        _revealedBaseURI = realBaseTokenURI;
    }

    function withdraw(address _receiver) public onlyOwnerOrDeployer {
        (bool os,) = payable(_receiver).call{value: address(this).balance}("");
        require(os, "Withdraw unsuccesful");
    }
}