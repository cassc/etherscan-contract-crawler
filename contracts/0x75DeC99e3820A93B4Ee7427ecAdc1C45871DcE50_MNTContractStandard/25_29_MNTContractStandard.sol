pragma solidity ^0.8.13;

import "./MNTContract.sol";

/// @author Monumental Team
/// @title Standard Contract
contract MNTContractStandard is MNTContract {

    /// Initialize
    /// @param creator creator address
    /// @param pinCode pinCode
    /// @param nftName nft name
    /// @param nftSymbol symbol
    /// @param baseUrl baseUrl
    /// @param royalties royalties
    /// @param maxSupply maxSupply
    /// @notice Standard constructor
    function initializeStandard(
        address creator,
        uint256 pinCode,
        string memory nftName,
        string memory nftSymbol,
        string memory baseUrl,
        uint256 royalties,
        uint256 maxSupply
    ) public override returns (bool){
        super.initializeStandard(creator, pinCode, nftName, nftSymbol, baseUrl, royalties, maxSupply);
        mintStandard(_creator,pinCode);
        transferOwnership(_creator);
        return true;
    }


    /// Mint a standard contract
    /// @param _owner owner
    /// @param _pinCode pinCode
    /// @notice Mint a standard contract
    /// @return newTokenId
    /// @dev Only owner
    function mintStandard(address _owner,  uint256 _pinCode)
    public nonReentrant onlyOwner
    returns (uint256)
    {
        require(getCurrentTokenId() < maxSupply() + getTokenBurntId(), "All tokens already minted !");
        incrementTokenId();

        uint256 newItemId = getCurrentTokenId();
        _safeMint(_owner, newItemId);

        emit MNTMintDone(_owner, _pinCode, newItemId);

        return newItemId;
    }

    /// Override of the beforeTokenTransfer (emitting an event)
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
    internal
    whenNotPaused
    virtual override(ERC721Upgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        emit MNTBeforeTokenTransfer(from, to, tokenId);
    }
}