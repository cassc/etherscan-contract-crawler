// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./KaijuMartRedeemable.sol";

error KaijuAugmints_InvalidTraitId();
error KaijuAugmints_InvalidToken();
error KaijuAugmints_SenderNotTokenOwner();
error KaijuAugmints_SupplyLocked();

/**
                        .             :++-
                       *##-          +####*          -##+
                       *####-      :%######%.      -%###*
                       *######:   =##########=   .######*
                       *#######*-#############*-*#######*
                       *################################*
                       *################################*
                       *################################*
                       *################################*
                       *################################*
                       :*******************************+.

                .:.
               *###%*=:
              .##########+-.
              +###############=:
              %##################%+
             =######################
             -######################++++++++++++++++++=-:
              =###########################################*:
               =#############################################.
  +####%#*+=-:. -#############################################:
  %############################################################=
  %##############################################################
  %##############################################################%=----::.
  %#######################################################################%:
  %##########################################+:    :+%#######################:
  *########################################*          *#######################
   -%######################################            %######################
     -%###################################%            #######################
       =###################################-          :#######################
     ....+##################################*.      .+########################
  +###########################################%*++*%##########################
  %#########################################################################*.
  %#######################################################################+
  ########################################################################-
  *#######################################################################-
  .######################################################################%.
     :+#################################################################-
         :=#####################################################:.....
             :--:.:##############################################+
   ::             +###############################################%-
  ####%+-.        %##################################################.
  %#######%*-.   :###################################################%
  %###########%*=*####################################################=
  %####################################################################
  %####################################################################+
  %#####################################################################.
  %#####################################################################%
  %######################################################################-
  .+*********************************************************************.
 * @title Kaiju Augmints
 * @author Augminted Labs, LLC
 */
contract KaijuAugmints is ERC1155, Ownable, AccessControl, KaijuMartRedeemable {
    enum Tokens { GENESIS, BABY, MUTANT, SCIENTIST }

    event Augment(
        uint256 indexed traitId,
        uint256 indexed tokenId,
        Tokens indexed token
    );

    bytes32 public constant KMART_ROLE = keccak256("KMART_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 internal constant _MAX_GENESIS_ID = 3332;

    string public name;
    string public symbol;
    mapping(Tokens => IERC721) public tokenContracts;
    mapping(uint256 => uint256) public redeemableId;
    mapping(uint256 => bool[4]) public validFor;
    mapping(uint256 => bool) public supplyLocked;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory uri,
        address kmart,
        address admin
    )
        ERC1155(uri)
    {
        _transferOwnership(admin);
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(KMART_ROLE, kmart);

        name = _name;
        symbol = _symbol;
    }

    /**
     * @inheritdoc ERC1155
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, AccessControl, KaijuMartRedeemable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Set token URI
     * @dev See ERC1155._setURI(string memory newuri)
     * @param uri New token URI for all tokens
     */
    function setURI(string memory uri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setURI(uri);
    }

    /**
     * @notice Set the contract address of a specified token type
     * @param token Token type to set the contract address of
     * @param tokenContract New contract address
     */
    function setTokenContracts(Tokens token, IERC721 tokenContract) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenContracts[token] = tokenContract;
    }

    /**
     * @notice Set the details for a redeemable trait
     * @param lotId Lot identifier that a trait can be redeemed for
     * @param traitId Identifier of the trait being redeemed
     * @param _validFor List of booleans indicating if a token type is valid for the trait
     */
    function setRedeemableTrait(
        uint256 lotId,
        uint256 traitId,
        bool[4] calldata _validFor
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (traitId == 0) revert KaijuAugmints_InvalidTraitId();
        if (supplyLocked[traitId]) revert KaijuAugmints_SupplyLocked();

        redeemableId[lotId] = traitId;
        validFor[traitId] = _validFor;
    }

    /**
     * @notice Set the token types a specified trait can be used to augment
     * @param traitId Identifier of the trait being updated
     * @param _validFor List of booleans indicating if a token type is valid for the trait
     */
    function setValidFor(
        uint256 traitId,
        bool[4] calldata _validFor
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        validFor[traitId] = _validFor;
    }

    /**
     * @notice Lock the supply of a specified token
     * @dev WARNING: This cannot be undone
     * @param traitId Trait to lock the supply of
     */
    function lockSupply(uint256 traitId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        supplyLocked[traitId] = true;
    }

    /**
     * @notice Mint function to support KaijuMart redeemable functionality
     * @param lotId Kaiju Mart lot identifier
     * @param amount Quantity to mint
     * @param to Address to receive the token
     */
    function kmartRedeem(
        uint256 lotId,
        uint32 amount,
        address to
    )
        public
        override
        onlyRole(KMART_ROLE)
    {
        uint256 traitId = redeemableId[lotId];

        if (traitId == 0) revert KaijuAugmints_InvalidTraitId();

        _mint(to, traitId, amount, "");
    }

    /**
     * @notice Mint a token to a specified address
     * @param to Address receiving the minted token(s)
     * @param id Token identifier to mint
     * @param amount Amount of the token to mint
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount
    )
        public
        onlyRole(MINTER_ROLE)
    {
        if (supplyLocked[id]) revert KaijuAugmints_SupplyLocked();

        _mint(to, id, amount, "");
    }

    /**
     * @notice Mint a batch of tokens to a specified address
     * @param to Address receiving the minted tokens
     * @param ids List of token identifiers to mint
     * @param amounts List of amounts of each token to mint
     */
    function mintBatch(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts
    )
        public
        onlyRole(MINTER_ROLE)
    {
        for (uint256 i; i < ids.length;) {
            if (supplyLocked[ids[i]]) revert KaijuAugmints_SupplyLocked();
            unchecked { ++i; }
        }

        _mintBatch(to, ids, amounts, "");
    }

    /**
     * @notice Augment a token with a trait
     * @param traitId Identifier of the trait to apply to the token
     * @param tokenId Identifier of the token to apply the trait to
     * @param token Type of token specified by `tokenId`
     */
    function augment(uint256 traitId, uint256 tokenId, Tokens token) external {
        if (tokenContracts[token].ownerOf(tokenId) != _msgSender())
            revert KaijuAugmints_SenderNotTokenOwner();
        if (
            !validFor[traitId][uint8(token)]
            || (token == Tokens.GENESIS && tokenId > _MAX_GENESIS_ID)
            || (token == Tokens.BABY && tokenId <= _MAX_GENESIS_ID)
        ) revert KaijuAugmints_InvalidToken();

        _burn(_msgSender(), traitId, 1);

        emit Augment(traitId, tokenId, token);
    }
}