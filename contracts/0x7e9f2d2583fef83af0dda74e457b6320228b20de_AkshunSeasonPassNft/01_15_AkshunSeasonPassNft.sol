// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

import "./IAkshunSeasonPassNft.sol";

// NOTE: With multiple inheritance, there is an issue caused by the Diamond Problem, so the order of inheritance is important to avoid it. Solidity solves this problem like Python in that it uses C3 Linearization to force a specific order in the directed acyclic graph (DAG) of base classes. This results in the desirable property of monotonicity but disallows some inheritance graphs, especially, the order in which the base classes are given in the `is` directive is important. You have to list the direct base contracts in the order from "most base-like" (i.e. classes on the top level of inheritance) to "most derived" (i.e. classes on lower levels). Note that this order is the reverse of the one used in Python. When a function is called that is defined multiple times in different contracts, the given bases are searched from right to left (left to right in Python) in a depth-first manner, stopping at the first match. If a base contract has already been searched, it is skipped. E.g. in `contract C is A, B {}`, `C` requests `B` to override `A` (by specifying `A, B` in this order), and then `C` overrides `B`. Note that this means the default preference is to specify the inherited interfaces and directly inherited/dependent (abstract) contracts at the beginning. See https://docs.soliditylang.org/en/develop/contracts.html#multiple-inheritance-and-linearization
// NOTE: Not implementing the `Ownable` standard in an ERC721 or ERC1155 smart contract can lead to NFTs not being displayed on many popular markets, as the implementation of this standard is often required by them.
// NOTE: This can work without implementing the `IAkshunSeasonPassNft` interface, but this could introduce potential issues, as the code will still compile despite (later) modifications in this contract, which could result in errors.
// NOTE: The enumeration extension `ERC721Enumerable` allows your contract to publish its full list of NFTs and make them discoverable. See all extensions: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
contract AkshunSeasonPassNft is IAkshunSeasonPassNft, ERC721Burnable, Ownable  {

    // =======================================================================
    // Errors.
    // =======================================================================

    error SenderInvalid();

    error ParamInvalid(uint8 paramPosIdx);
    error ArrayParamInvalid(uint8 paramPosIdx, uint256 arrayPosIdx);

    error NoSubcollectionExists();
    error SubcollectionAlreadyUsed();

    error BaseURINonexistent();
    error TokenNonexistent();

    // =======================================================================
    // Events.
    // =======================================================================

    event MinterSetOrUpdated(address indexed oldMinter, address indexed newMinter);

    event ContractURIUpdated(string contractURI);
    event BaseURIAdded(uint16 indexed subcollectionIdx, string baseURI);

    // =======================================================================
    // State vars.
    // =======================================================================

    address public minter;

    // NOTE: For token IDs `uint40` possible values altogether should be enough for all the sports, all the sport's leagues, all the league's seasons, all the season's sales and all the sale's tiers, altogether (i.e. across all seasons of all leagues and sports), i.e. for all (seasons') subcollections, because this allows us 256 sports * 256 leagues * 256 seasons (e.g. for 256 years, or half of that if the season is every half year) * 256 sales * 256 tiers. But because the inherited contracts already use `uint256` (hence it wouldn't be compatibel with our amounts), and sent ETH amount `msg.value` also uses `uint256` (hence it wouldn't be compatibel with our prices/costs), we use that instead. Hence the limit shouldn't be reachable.
    uint256 private lastTokenId = 0;

    // NOTE: The var could be optimized by marking it as `immutable`, as it is only initiated in the constructor and never changed again, but it can't be, because not all types for `constant`s and `immutable`s are implemented at this time; the only supported types are strings (only for constants) and value types.
    string public contractURI;

    struct Subcollection {
        // Whether any NFTs for this subcollection have been minted yet.
        bool used;

        // The default/pre-revealed token metadatas for each type of collection's token, used until the actual base URI for each specific token type (and hence implicitly the actual full URI for each specific token) is set via `baseURIs` field.
        // NOTE: We implicitly limit the array size to `uint8` possible values via `tokenPresetURIIdxs` field.
        string[] presetURIs;
        // Specific token's index to its preset base URI in `presetURIs`.
        mapping(uint256 => uint8) tokenPresetURIIdxs;

        // URI file extension for all URIs in `baseURIs` field.
        string baseURIExtension;
        // The actual/revealed token metadatas for each collection's token.
        // NOTE: A new base URI is added for each new batch of minted but not yet reveald tokens, or potentially already revealed in case of new swapped tokens (i.e. also newly minted), since each batch needs to use a new IPFS directory.
        // NOTE: We implicitly limit the array size to `uint8` possible values via `tokenBaseURIIdxs` field.
        string[] baseURIs;
        // Specific token's index to its base URI in `baseURIs`.
        // NOTE: The tokens whose IDs are not (put) in this mapping (i.e. the first batch of revealed tokens for the subcollection, excluding its later reveals and potentially swapped tokens), implicitly use the original/first base URI, because `0` is returned for an inexistent mapping key (to save some gas by not re-setting the value to the same one, i.e. `0`).
        // NOTE: We use `uint8` type, because 2^8 = 256 possible values should be enough for the season's unique base URI and a few extra ones to be used for the NFT swaps (for replacing NFTs of injured or transferred players). Hence the limit shouldn't be reachable.
        mapping(uint256 => uint8) tokenBaseURIIdxs;
    }

    // NOTE: We implicitly limit the array size to `uint16` possible values via `hTokenSubcollectionIdx` var.
    Subcollection[] subcollections;
    mapping(uint256 => uint16) hTokenSubcollectionIdx; // NOTE: Helper field derivable from `subcollections` and `Subcollection.tokenPresetURIIdxs`/`Subcollection.tokenBaseURIIdxs` combination.

    // =======================================================================
    // Modifiers.
    // =======================================================================

    modifier onlyMinter() {
        address sender = _msgSender();
        if (sender != minter) revert SenderInvalid();

       _; // NOTE: Continue executing the rest of the calling method body.
    }

    // =======================================================================
    // Setter & deleter functions.
    // =======================================================================

    constructor(string memory _name, string memory _symbol, string memory _contractURI) ERC721(_name, _symbol) {
        updateContractURI(_contractURI);
    }

    function setOrUpdateMinter(address _newMinter)
        external
        onlyOwner
    {
        // Validate input params.

        // NOTE: Minter should be a smart contract, so it, and solely, defines and governs the rules for minting and burning tokens.
        if(_newMinter == address(0) || _newMinter == owner()) revert ParamInvalid(0);

        // Update/set state vars.

        address oldMinter = minter;
        minter = _newMinter;

        // Emit events.

        emit MinterSetOrUpdated(oldMinter, _newMinter);
    }

    // NOTE: OpenSea and some other NFT marketplaces won't update this on their website when the preset base URI changes, but it can be updated manually via their website.
    // NOTE: If we had only one collection, we probably wouldn't want to change preset base URI, but instead we have many subcollections, so this NFT contract could be used for a long time, and hence the preset base URI should be updatable.
    function updateContractURI(string memory _contractURI)
        public
        onlyOwner
    {
        // Validate input params.

        if (bytes(_contractURI).length == 0) revert ParamInvalid(0);

        // Update/set state vars.

        contractURI = _contractURI;

        // Emit events.

        emit ContractURIUpdated(_contractURI);
    }

    // NOTE: Could be improved by setting one base URI for all the preset base URIs added together (e.g. for all particular sale's tiers).
    function addSubcollection(string[] memory _presetURIs, string memory _baseURIExtension)
        external
        onlyOwner
    {
        // Validate input params.

        if (_presetURIs.length == 0) revert ParamInvalid(0);
        if (bytes(_baseURIExtension).length == 0) revert ParamInvalid(1);

        // Update/set state vars.

        Subcollection storage subcollection = subcollections.push();
        subcollection.baseURIExtension = _baseURIExtension;
        addpresetURIs(uint16(subcollections.length - 1), _presetURIs);

        // NOTE: No event emitted, because it's a part of a purily operational management which shouldn't have any real-time direct effects on the users.
    }

    function deleteLastSubcollection()
        external
        onlyOwner
    {
        // Validate state vars.

        if (subcollections.length == 0) revert NoSubcollectionExists();

        Subcollection storage lastSubcollection = subcollections[subcollections.length - 1];
        if (lastSubcollection.used) revert SubcollectionAlreadyUsed();

        // Update/set state vars.

        subcollections.pop();

        // NOTE: No event emitted, because it's a part of a purily operational management which shouldn't have any real-time direct effects on the users.
    }

    function addpresetURIs(uint16 subcollectionIdx, string[] memory _presetURIs)
        public
        onlyOwner
    {
        // Validate input params.

        if (subcollectionIdx >= subcollections.length) revert ParamInvalid(0);
        if (_presetURIs.length == 0) revert ParamInvalid(1);

        Subcollection storage subcollection = subcollections[subcollectionIdx];

        for (uint8 i = 0; i < _presetURIs.length;) {
            if (bytes(_presetURIs[i]).length == 0) revert ArrayParamInvalid(1, i);

            // Update/set state vars.

            subcollection.presetURIs.push(_presetURIs[i]);
            unchecked { i++; }
        }

        // NOTE: No event emitted, because it should be set before the minting (i.e. as part of the subcollection setup) which shouldn't have any real-time direct effects on the users.
    }

    // This acts as a token reveal mechanism (i.e. the tokens which are assigned to this newly added base URI will from now on return the actual/revealed URI).
    // NOTE: We don't allow updating the base URI once it's added, hence take extra care the right URI is stored.
    function addBaseURI(uint16 _subcollectionIdx, string memory _baseURI)
        external
        onlyOwner
    {
        // Validate input params.

        if (_subcollectionIdx >= subcollections.length) revert ParamInvalid(0);
        if (bytes(_baseURI).length == 0) revert ParamInvalid(1);

        // Update/set state vars.

        Subcollection storage subcollection = subcollections[_subcollectionIdx];

        subcollection.baseURIs.push(_baseURI);

        // Emit events.

        emit BaseURIAdded(_subcollectionIdx, _baseURI);
    }

    // Minting & burning management.

    function mint(uint16 subcollectionIdx, uint8 _tokenPresetURIIdx, uint8 _tokenBaseURIIdx, address _to)
        external
        onlyMinter
        returns(uint256 _tokenId)
    {
        // Validate input params.

        if (subcollectionIdx >= subcollections.length) revert ParamInvalid(0);
        // NOTE: If the token's base URI isn't set yet (i.e. unrevealed), it uses it's preset base URI until it is (i.e. revealed).
        // NOTE: Can't validate like this, since it's an index (i.e. it starts from `0`).
        // if (_tokenPresetURIIdx == 0) revert ParamInvalid(1);

        // Update/set state vars.

        Subcollection storage subcollection = subcollections[subcollectionIdx];

        lastTokenId += 1;
        subcollection.tokenPresetURIIdxs[lastTokenId] = _tokenPresetURIIdx;
        hTokenSubcollectionIdx[lastTokenId] = subcollectionIdx;

        if (!subcollection.used) {
            subcollection.used = true;
        }
        // NOTE: The tokens whose IDs are not (put) in this mapping (i.e. the first batch of revealed tokens for the subcollection, excluding its later reveals and potentially swapped tokens), implicitly use the original/first base URI, because `0` is returned for an inexistent mapping key (to save some gas by not re-setting the value to the same one, i.e. `0`).
        if (_tokenBaseURIIdx > 0) {
            subcollection.tokenBaseURIIdxs[lastTokenId] = _tokenBaseURIIdx;
        }

        // NOTE: All the state changes should be done before this comment (e.g. to prevent reentrancy attack).

        _mint(_to, lastTokenId);

        return lastTokenId;
    }

    // NOTE: We need to override this function, because we inherit from two contracts which implement this function, otherwise we wouldn't have to, since `burn` is already exposed in both of the inherited cotracts (with `external` and `public` visibility, respectively). Otherwise an error would be thrown: `TypeError: Derived contract must override function "burn". Two or more base classes define function with same name and parameter types.`.
    // NOTE: Function modifier could be `external`, but can't be because we are overriding a function with a `public` (could be also `internal`) modifier (i.e. from `ERC721Burnable` contract).
    function burn(uint256 _tokenId)
        public
        override(IAkshunSeasonPassNft, ERC721Burnable)
        onlyMinter
    {
        // NOTE: We dont call `super.burn(_tokenId)` instead, because then we would need to get an approval (i.e. an additional TX and hence gas cost), for the Store contract, from the user, to burn his Season Pass NFT, because the `_msgSender()` call inside `_isApprovedOrOwner` function (which is inside Season Pass NFT's `burn` function) will return Store contract's address, since even though the user calls the Store contract's swap function, the Store contract then consequently calls the Season Pass NFT's burn method.
        return super._burn(_tokenId);
    }

    // =======================================================================
    // Getter functions.
    // =======================================================================

    function getSubcollection(uint16 _subcollectionIdx)
        external
        view
        returns(bool _used, string memory _baseURIExtension, string[] memory _presetURIs, string[] memory _baseURIs)
    {
        // Validate input params.

        if (_subcollectionIdx >= subcollections.length) revert ParamInvalid(0);

        // Get state vars.

        Subcollection storage subcollection = subcollections[_subcollectionIdx];

        return (subcollection.used, subcollection.baseURIExtension, subcollection.presetURIs, subcollection.baseURIs);
    }

    function _getBaseURI(Subcollection storage _subcollection, uint256 _tokenId)
        internal
        view
        returns(string memory)
    {
        // Get state vars.
        // NOTE: If the token's base URI isn't set yet (i.e. unrevealed), it uses it's preset base URI until it is (i.e. revealed).

        uint8 tokenBaseURIIdx = _subcollection.tokenBaseURIIdxs[_tokenId];
        if (tokenBaseURIIdx < _subcollection.baseURIs.length) {
            // Revealed token.
            return _subcollection.baseURIs[tokenBaseURIIdx];
        } else {
            // Unrevealed token.
            return "";
        }
    }

    // NOTE: Function modifier could be `external`, but can't be because we are overriding a function with a `public` modifier.
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns(string memory)
    {
        // Validate input params.

        // NOTE: Could also do this instead; it's cheaper to deploy, but costs more gas if TX is reverted because of this check:
        // _requireMinted(_tokenId);
        if (_tokenId == 0 || _tokenId > lastTokenId) revert TokenNonexistent();

        // Get state vars.

        Subcollection storage subcollection = subcollections[hTokenSubcollectionIdx[_tokenId]];

        string memory baseURI = _getBaseURI(subcollection, _tokenId);
        if (bytes(baseURI).length > 0) {
            return string(abi.encodePacked(baseURI, Strings.toString(_tokenId), subcollection.baseURIExtension));
        } else {
            uint8 tokenPresetURIIdx = subcollection.tokenPresetURIIdxs[_tokenId];
            return  subcollection.presetURIs[tokenPresetURIIdx];
        }
    }

    // NOTE: We need to override this function, because we inherit from two contracts which implement this function, otherwise we wouldn't have to, since `ownerOf` is already exposed in both of the inherited cotracts (with `external` and `public` visibility, respectively). Otherwise an error would be thrown: `TypeError: Derived contract must override function "ownerOf". Two or more base classes define function with same name and parameter types.`.
    // NOTE: Function modifier could be `external`, but can't be because we are overriding a function with a `public` (could be also `internal`) modifier (i.e. from `ERC721` contract).
    function ownerOf(uint256 _tokenId)
        public
        view
        override(IAkshunSeasonPassNft, ERC721)
        returns(address)
    {
        return super.ownerOf(_tokenId);
    }

}