// SPDX-License-Identifier: GPL 3.0
pragma solidity >=0.8.10 <0.9.0;

import "@divergencetech/ethier/contracts/erc721/BaseTokenURI.sol";
import "@divergencetech/ethier/contracts/erc721/ERC721ACommon.sol";
import "@divergencetech/ethier/contracts/sales/FixedPriceSeller.sol";
import "@divergencetech/ethier/contracts/utils/Monotonic.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

interface ITokenURIGenerator {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract GoblinHipsters is
    ERC721ACommon,
    BaseTokenURI,
    FixedPriceSeller,
    ERC2981
{
    using Monotonic for Monotonic.Increaser;

    constructor(
        string memory name,
        string memory symbol,
        address payable beneficiary,
        address payable royaltyReceiver
    )
        ERC721ACommon(name, symbol)
        BaseTokenURI("")
        FixedPriceSeller(
            0.00 ether,
            Seller.SellerConfig({
                totalInventory: 10000,
                lockTotalInventory: true,
                maxPerAddress: 5,
                maxPerTx: 5,
                freeQuota: 1000,
                lockFreeQuota: true,
                reserveFreeQuota: true
            }),
            beneficiary
        )
    {
        _setDefaultRoyalty(royaltyReceiver, 750);
    }

    /**
    @dev Mint tokens purchased via the Seller.
     */
    function _handlePurchase(
        address to,
        uint256 n,
        bool
    ) internal override {
        _safeMint(to, n);
    }

    /**
    @dev Required override to select the correct baseTokenURI.
     */
    function _baseURI()
        internal
        view
        override(BaseTokenURI, ERC721A)
        returns (string memory)
    {
        return BaseTokenURI._baseURI();
    }

    /**
    @notice Mint as a non-holder of PROOF tokens.
     */
    function mint(
        address to,
        uint256 amount
    ) external payable {
        _purchase(to, amount);
    }

    /**
    @notice If set, contract to which tokenURI() calls are proxied.
     */
    ITokenURIGenerator public renderingContract;

    /**
    @notice Sets the optional tokenURI override contract.
     */
    function setRenderingContract(ITokenURIGenerator _contract)
        external
        onlyOwner
    {
        renderingContract = _contract;
    }

    /**
    @notice If renderingContract is set then returns its tokenURI(tokenId)
    return value, otherwise returns the standard baseTokenURI + tokenId.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (address(renderingContract) != address(0)) {
            return renderingContract.tokenURI(tokenId);
        }
        return super.tokenURI(tokenId);
    }

    /**
    @notice Sets the contract-wide royalty info.
     */
    function setRoyaltyInfo(address receiver, uint96 feeBasisPoints)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721ACommon, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}