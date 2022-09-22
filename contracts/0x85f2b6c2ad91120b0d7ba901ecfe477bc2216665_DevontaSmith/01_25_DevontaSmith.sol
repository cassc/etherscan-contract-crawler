// contracts/DevontaSmith.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./VariableEndstateNFT.sol";
import "./IPaperCompatibleInterface1155.sol";

/**
 * @title DevontaSmith
 * DevontaSmith - a contract for my non-fungible Devonta Smith shoes
 */
contract DevontaSmith is
    VariableEndstateNFT,
    IPaperCompatibleInterface1155
{
    using Strings for uint256;
    using Counters for Counters.Counter;

    uint256 public constant KELLY_GREEN = 0;
    uint256 public constant BLUE_PINK = 1;
    uint256 public constant BLACK_GOLD = 2;

    // 250 supply of each colorway
    uint256[] colorways = [500, 500, 500];
    string internal _contractUri = "https://mint.endstate.io/devontasmith/metadata.json";
    uint256 _price = 0.2 ether;

    constructor()
        VariableEndstateNFT(
            "DeVonta Smith x Endstate",
            "ENDSTATE",
            "https://api.endstate.io/metadata/devontasmith/",
            colorways,
            15
        )
    {}

    function _variationExists(uint256 variation)
        internal
        pure
        override
        returns (bool)
    {
        return variation < 3;
    }

    function contractURI() public view returns (string memory) {
        return _contractUri;
    }

    function setContractURI(string memory contractUri_) public {
        require(
            hasRole(ENDSTATE_ADMIN_ROLE, _msgSender()),
            "DevontaSmith: must have admin role to update contract URI"
        );

        _contractUri = contractUri_;
    }

    /**
     * Updates the contract price directly
     */
    function setPrice(uint256 price_) public {
        require(
            hasRole(ENDSTATE_ADMIN_ROLE, _msgSender()),
            "DevontaSmith: must have admin role to update contract price"
        );

        _price = price_;
    }

    /**
     * Allows a user to mint their own DevontaSmith NFT by sending the NFT price to this contract
     */
    function mint(uint256 variation) public payable returns (uint256) {
        require(msg.value >= _price, "DevontaSmith: incorrect amount");
        return _mintOne(variation, _msgSender(), false);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(VariableEndstateNFT) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(VariableEndstateNFT)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(VariableEndstateNFT)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // IPaperCompatibleInterface

    function getClaimIneligibilityReason(
        address userWallet,
        uint256 quantity,
        uint256 variation
    ) public view override returns (string memory) {
        if (variation > 2) {
            return "Variation doesn't exist.";
        }
        if (quantity > unclaimedSupply(variation)) {
            return "Not enough supply left for variation and quantity.";
        }
        return ""; // MUST RETURN EMPTY STRING TO PREVENT PAPER FROM FAILING MINT
    }

    function unclaimedSupply(uint256 _variation)
        public
        view
        override
        returns (uint256)
    {
        return
            maxVariationSupply[_variation] -
            specialMintReserve -
            _variationSupply[_variation].current();
    }

    function price(uint256 _variation) public view override returns (uint256) {
        require(_variation < 3, "Variation doesn't exist.");
        return _price;
    }

    function claimTo(
        address _userWallet,
        uint256 _quantity,
        uint256 _variation
    ) public payable override {
        require(msg.value >= (_quantity * _price), "DevontaSmith: incorrect amount");
        for (uint256 i = 0; i < _quantity; i++) {
            _mintOne(_variation, _userWallet, false);
        }
    }
}