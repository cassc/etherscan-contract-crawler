// SPDX-License-Identifier: UNLICENSED
// Copyright 2021 David Huber (@cxkoda)
// All Rights Reserved

pragma solidity >=0.8.0 <0.9.0;

import "./solvers/IAttractorSolver.sol";
import "./renderers/ISvgRenderer.sol";
import "./utils/BaseOpenSea.sol";
import "./utils/ERC2981SinglePercentual.sol";
import "./utils/SignedSlotRestrictable.sol";
import "./utils/ColorMixer.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/PullPayment.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @notice Fully on-chain interactive NFT project performing numerical
 * simulations of chaotic, multi-dimensional _systems.
 * @dev This contract implements tokenonmics of the project, conforming to the
 * ERC721 and ERC2981 standard.
 * @author David Huber (@cxkoda)
 */
contract StrangeAttractors is
    BaseOpenSea,
    SignedSlotRestrictable,
    ERC2981SinglePercentual,
    ERC721Enumerable,
    Ownable,
    PullPayment
{
    /**
     * @notice Maximum number of editions per system.
     */
    uint8 private constant MAX_PER_SYSTEM = 128;

    /**
     * @notice Max number that the contract owner can mint in a specific system.
     * @dev The contract assumes that the owner mints the first pieces.
     */
    uint8 private constant OWNER_ALLOCATION = 2;

    /**
     * @notice Mint price
     */
    uint256 public constant MINT_PRICE = (35 ether) / 100;

    /**
     * @notice Contains the configuration of a given _systems in the collection.
     */
    struct AttractorSystem {
        string description;
        uint8 numLeftForMint;
        bool locked;
        ISvgRenderer renderer;
        uint8 defaultRenderSize;
        uint32[] defaultColorAnchors;
        IAttractorSolver solver;
        SolverParameters solverParameters;
    }

    /**
     * @notice Systems in the collection.
     * @dev Convention: The first system is the fullset system.
     */
    AttractorSystem[] private _systems;

    /**
     * @notice Token configuration
     */
    struct Token {
        uint8 systemId;
        bool usedForFullsetToken;
        bool useDefaultColors;
        bool useDefaultProjection;
        uint8 renderSize;
        uint256 randomSeed;
        ProjectionParameters projectionParameters;
        uint32[] colorAnchors;
    }

    /**
     * @notice All existing _tokens
     * @dev Maps tokenId => token configuration
     */
    mapping(uint256 => Token) private _tokens;

    // -------------------------------------------------------------------------
    //
    //  Collection setup
    //
    // -------------------------------------------------------------------------

    /**
     * @notice Contract constructor
     * @dev Sets the owner as default 10% royalty receiver.
     */
    constructor(
        string memory name,
        string memory symbol,
        address slotSigner,
        address openSeaProxyRegistry
    ) ERC721(name, symbol) {
        if (openSeaProxyRegistry != address(0)) {
            _setOpenSeaRegistry(openSeaProxyRegistry);
        }
        _setRoyaltyReceiver(owner());
        _setRoyaltyPercentage(1000);
        _setSlotSigner(slotSigner);
    }

    /**
     * @notice Adds a new attractor system to the collection
     * @dev This is used to set up the collection after contract deployment.
     * If `systemId` is a valid ID, the corresponding, existing system will
     * be overwritten. Otherwise a new system will be added.
     * Further system modification is prevented if the system is locked.
     * Both adding and modifying were merged in this single method to avoid
     * hitting the contract size limit.
     */
    function newAttractorSystem(
        string calldata description,
        address solver,
        SolverParameters calldata solverParameters,
        address renderer,
        uint32[] calldata defaultColorAnchors,
        uint8 defaultRenderSize,
        uint256 systemId
    ) external onlyOwner {
        AttractorSystem memory system = AttractorSystem({
            numLeftForMint: MAX_PER_SYSTEM,
            description: description,
            locked: false,
            solver: IAttractorSolver(solver),
            solverParameters: solverParameters,
            renderer: ISvgRenderer(renderer),
            defaultColorAnchors: defaultColorAnchors,
            defaultRenderSize: defaultRenderSize
        });
        if (systemId < _systems.length) {
            require(!_systems[systemId].locked, "System locked");
            system.numLeftForMint = _systems[systemId].numLeftForMint;
            _systems[systemId] = system;
        } else {
            _systems.push(system);
        }
    }

    /**
     * @notice Locks a system against further modifications.
     */
    function lockSystem(uint8 systemId) external onlyOwner {
        _systems[systemId].locked = true;
    }

    // -------------------------------------------------------------------------
    //
    //  Minting
    //
    // -------------------------------------------------------------------------

    function setSlotSigner(address signer) external onlyOwner {
        _setSlotSigner(signer);
    }

    /**
     * @notice Enable or disable the slot restriction for minting.
     */
    function setSlotRestriction(bool enabled) external onlyOwner {
        _setSlotRestriction(enabled);
    }

    /**
     * @notice Interface to mint the remaining owner allocated pieces.
     * @dev This has to be executed before anyone else has minted.
     */
    function safeMintOwner() external onlyOwner {
        bool mintedSomething = false;
        for (uint8 systemId = 1; systemId < _systems.length; systemId++) {
            for (
                ;
                MAX_PER_SYSTEM - _systems[systemId].numLeftForMint <
                OWNER_ALLOCATION;

            ) {
                _safeMintInAttractor(systemId);
                mintedSomething = true;
            }
        }

        // To get some feedback if there are no pieces left for the owner.
        require(mintedSomething, "Owner allocation exhausted.");
    }

    /**
     * @notice Mint interface for regular users.
     * @dev Mints one edition piece from a randomly selected system. The
     * The probability to mint a given system is proportional to the available
     * editions.
     */
    function safeMintRegularToken(uint256 nonce, bytes calldata signature)
        external
        payable
    {
        require(msg.value == MINT_PRICE, "Invalid payment.");
        _consumeSlotIfEnabled(_msgSender(), nonce, signature);
        _asyncTransfer(owner(), msg.value);

        // Check how many _tokens there are left in total.
        uint256 numAvailableTokens = 0;
        for (uint8 idx = 1; idx < _systems.length; ++idx) {
            numAvailableTokens += _systems[idx].numLeftForMint;
        }

        if (numAvailableTokens > 0) {
            // Draw a pseudo-random number in [0, numAvailableTokens) that
            // determines which system to mint.
            uint256 rand = _random(numAvailableTokens) % numAvailableTokens;

            // Check in which bracket `rand` is and mint an edition of the
            // corresponding system
            for (uint8 idx = 1; idx < _systems.length; ++idx) {
                if (rand < _systems[idx].numLeftForMint) {
                    _safeMintInAttractor(idx);
                    return;
                } else {
                    rand -= _systems[idx].numLeftForMint;
                }
            }
        }

        revert("All _systems sold out");
    }

    /**
     * @notice Interface to mint a special token for fullset holders.
     * @dev The sender needs to supply one unused token of every regular
     * system.
     */
    function safeMintFullsetToken(uint256[4] calldata tokenIds)
        external
        onlyApprovedOrOwner(tokenIds[0])
        onlyApprovedOrOwner(tokenIds[1])
        onlyApprovedOrOwner(tokenIds[2])
        onlyApprovedOrOwner(tokenIds[3])
    {
        require(isFullsetMintEnabled, "Fullset mint is disabled.");

        bool[4] memory containsSystem = [false, false, false, false];
        for (uint256 idx = 0; idx < 4; ++idx) {
            // Check if already used
            require(
                !_tokens[tokenIds[idx]].usedForFullsetToken,
                "Token already used."
            );

            // Set an ok flag if a given system was found
            containsSystem[_getTokenSystemId(tokenIds[idx]) - 1] = true;

            // Mark as used
            _tokens[tokenIds[idx]].usedForFullsetToken = true;
        }

        // Check if all _systems are present
        require(
            containsSystem[0] &&
                containsSystem[1] &&
                containsSystem[2] &&
                containsSystem[3],
            "Tokens of each system required"
        );

        uint256 tokenId = _safeMintInAttractor(0);

        // Although we technically  don't need to set this flag onr the fullset
        // system, let's set it anyways to display the correct value in
        // `tokenURI`.
        _tokens[tokenId].usedForFullsetToken = true;
    }

    /**
     * @notice Flag for enabling fullset token minting.
     */
    bool public isFullsetMintEnabled = false;

    /**
     * @notice Toggles the ability to mint fullset _tokens.
     */
    function enableFullsetMint(bool enable) external onlyOwner {
        isFullsetMintEnabled = enable;
    }

    /**
     * @dev Mints the next token in the system.
     */
    function _safeMintInAttractor(uint8 systemId)
        internal
        returns (uint256 tokenId)
    {
        require(systemId < _systems.length, "Mint in non-existent system.");
        require(
            _systems[systemId].numLeftForMint > 0,
            "System capacity exhausted"
        );

        tokenId =
            (systemId * _tokenIdSystemMultiplier) +
            (MAX_PER_SYSTEM - _systems[systemId].numLeftForMint);

        _tokens[tokenId] = Token({
            systemId: systemId,
            randomSeed: _random(tokenId),
            projectionParameters: ProjectionParameters(
                new int256[](0),
                new int256[](0),
                new int256[](0)
            ),
            colorAnchors: new uint32[](0),
            usedForFullsetToken: false,
            useDefaultColors: true,
            useDefaultProjection: true,
            renderSize: _systems[systemId].defaultRenderSize
        });
        _systems[systemId].numLeftForMint--;

        _safeMint(_msgSender(), tokenId);
    }

    /**
     * @notice Defines the system prefix in the `tokenId`.
     * @dev Convention: The `tokenId` will be given by
     * `edition + _tokenIdSystemMultiplier * systemId`
     */
    uint256 private constant _tokenIdSystemMultiplier = 1e3;

    /**
     * @notice Retrieves the `systemId` from a given `tokenId`.
     */
    function _getTokenSystemId(uint256 tokenId) internal pure returns (uint8) {
        return uint8(tokenId / _tokenIdSystemMultiplier);
    }

    /**
     * @notice Retrieves the `edition` from a given `tokenId`.
     */
    function _getTokenEdition(uint256 tokenId) internal pure returns (uint8) {
        return uint8(tokenId % _tokenIdSystemMultiplier);
    }

    /**
     * @notice Draw a pseudo-random number.
     * @dev Although the drawing can be manipulated with this implementation,
     * it is sufficiently fair for the given purpose.
     * Multiple evaluations on the same block with the same `modSeed` from the
     * same sender will yield the same random numbers.
     */
    function _random(uint256 modSeed) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(block.timestamp, _msgSender(), modSeed)
                )
            );
    }

    /**
     * @notice Re-draw a _tokens `randomSeed`.
     * @dev This is implemented as a last resort if a _tokens `randomSeed`
     * produces starting values that do not converge to the attractor.
     * Although this never happened while testing, you never know for sure
     * with random numbers.
     */
    function rerollTokenRandomSeed(uint256 tokenId) external onlyOwner {
        _tokens[tokenId].randomSeed = _random(_tokens[tokenId].randomSeed);
    }

    // -------------------------------------------------------------------------
    //
    //  Rendering
    //
    // -------------------------------------------------------------------------

    /**
     * @notice Assembles the name of a token
     * @dev Composed of the system name provided by the solver and the tokens
     * edition number. The returned string has been escapted for usage in
     * data-uris.
     */
    function getTokenName(uint256 tokenId) public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    _systems[_getTokenSystemId(tokenId)].solver.getSystemType(),
                    // " #",
                    " %23", // Uri encoded
                    Strings.toString(_getTokenEdition(tokenId))
                )
            );
    }

    /**
     * @notice Renders a given token with externally supplied parameters.
     * @return The svg string.
     */
    function renderWithConfig(
        uint256 tokenId,
        ProjectionParameters memory projectionParameters,
        uint32[] memory colorAnchors,
        uint8 renderSize
    ) public view returns (string memory) {
        AttractorSystem storage system = _systems[_getTokenSystemId(tokenId)];

        return
            system.renderer.render(
                system.solver.computeSolution(
                    system.solverParameters,
                    system.solver.getRandomStartingPoint(
                        _tokens[tokenId].randomSeed
                    ),
                    projectionParameters
                ),
                ColorMixer.getColormap(colorAnchors),
                renderSize
            );
    }

    /**
     * @notice Returns the `ProjectionParameters` for a given token.
     * @dev Checks if default settings are used and computes them if needed.
     */
    function getProjectionParameters(uint256 tokenId)
        public
        view
        returns (ProjectionParameters memory)
    {
        if (_tokens[tokenId].useDefaultProjection) {
            return
                _systems[_getTokenSystemId(tokenId)]
                    .solver
                    .getDefaultProjectionParameters(_getTokenEdition(tokenId));
        } else {
            return _tokens[tokenId].projectionParameters;
        }
    }

    /**
     * @notice Returns the `colormap` for a given token.
     * @dev Checks if default settings are used and retrieves them if needed.
     */
    function getColorAnchors(uint256 tokenId)
        public
        view
        returns (uint32[] memory colormap)
    {
        if (_tokens[tokenId].useDefaultColors) {
            return _systems[_getTokenSystemId(tokenId)].defaultColorAnchors;
        } else {
            return _tokens[tokenId].colorAnchors;
        }
    }

    /**
     * @notice Returns data URI of token metadata.
     * @dev The output conforms to the Opensea attributes metadata standard.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        AttractorSystem storage system = _systems[_getTokenSystemId(tokenId)];

        bytes memory data = abi.encodePacked(
            'data:application/json,{"name":"',
            getTokenName(tokenId),
            '",',
            '"description":"',
            system.description,
            '","attributes":[{"trait_type": "System","value":"',
            system.solver.getSystemType(),
            '"},{"trait_type": "Random Seed", "value":"',
            Strings.toHexString(_tokens[tokenId].randomSeed)
        );

        if (isFullsetMintEnabled) {
            data = abi.encodePacked(
                data,
                '"},{"trait_type": "Dimensions", "value":"',
                Strings.toString(system.solver.getDimensionality()),
                '"},{"trait_type": "Completed", "value":"',
                _tokens[tokenId].usedForFullsetToken ? "Yes" : "No"
            );
        }

        return
            string(
                abi.encodePacked(
                    data,
                    '"}],"image":"data:image/svg+xml,',
                    renderWithConfig(
                        tokenId,
                        getProjectionParameters(tokenId),
                        getColorAnchors(tokenId),
                        _tokens[tokenId].renderSize
                    ),
                    '"}'
                )
            );
    }

    // -------------------------------------------------------------------------
    //
    //  Token interaction
    //
    // -------------------------------------------------------------------------

    /**
     * @notice Set the projection parameters for a given token.
     */
    function setProjectionParameters(
        uint256 tokenId,
        ProjectionParameters calldata projectionParameters
    ) external onlyApprovedOrOwner(tokenId) {
        require(
            _systems[_getTokenSystemId(tokenId)]
                .solver
                .isValidProjectionParameters(projectionParameters),
            "Invalid projection parameters"
        );

        _tokens[tokenId].projectionParameters = projectionParameters;
        _tokens[tokenId].useDefaultProjection = false;
    }

    /**
     * @notice Set or reset the color anchors for a given token.
     * @dev To revert to the _systems default, `colorAnchors` has to be empty.
     * On own method for resetting was omitted to remain below the contract size
     * limit.
     * See `ColorMixer` for more details on the color system.
     */
    function setColorAnchors(uint256 tokenId, uint32[] calldata colorAnchors)
        external
        onlyApprovedOrOwner(tokenId)
    {
        // Lets restrict this to something sensible.
        require(
            colorAnchors.length > 0 && colorAnchors.length <= 64,
            "Invalid amount of color anchors."
        );
        _tokens[tokenId].colorAnchors = colorAnchors;
        _tokens[tokenId].useDefaultColors = false;
    }

    /**
     * @notice Set the rendersize for a given token.
     */
    function setRenderSize(uint256 tokenId, uint8 renderSize)
        external
        onlyApprovedOrOwner(tokenId)
    {
        _tokens[tokenId].renderSize = renderSize;
    }

    /**
     * @notice Reset various rendering parameters for a given token.
     * @dev Setting the individual flag to true resets the associated parameters.
     */
    function resetRenderParameters(
        uint256 tokenId,
        bool resetProjectionParameters,
        bool resetColorAnchors,
        bool resetRenderSize
    ) external onlyApprovedOrOwner(tokenId) {
        if (resetProjectionParameters) {
            _tokens[tokenId].useDefaultProjection = true;
        }
        if (resetColorAnchors) {
            _tokens[tokenId].useDefaultColors = true;
        }
        if (resetRenderSize) {
            _tokens[tokenId].renderSize = _systems[_getTokenSystemId(tokenId)]
                .defaultRenderSize;
        }
    }

    // -------------------------------------------------------------------------
    //
    //  External getters, metadata and steering
    //
    // -------------------------------------------------------------------------

    /**
     * @notice Retrieve a system with a given ID.
     * @dev This was necessay because for some reason the default public getter
     * does not return `defaultColorAnchors` correctly.
     */
    function systems(uint8 systemId)
        external
        view
        returns (AttractorSystem memory)
    {
        return _systems[systemId];
    }

    /**
     * @notice Retrieve a token with a given ID.
     * @dev This was necessay because for some reason the default public getter
     * does not return `colorAnchors` correctly.
     */
    function tokens(uint256 tokenId) external view returns (Token memory) {
        return _tokens[tokenId];
    }

    /**
     * @dev Sets the royalty percentage (in units of 0.01%)
     */
    function setRoyaltyPercentage(uint256 percentage) external onlyOwner {
        _setRoyaltyPercentage(percentage);
    }

    /**
     * @dev Sets the address to receive the royalties
     */
    function setRoyaltyReceiver(address receiver) external onlyOwner {
        _setRoyaltyReceiver(receiver);
    }

    // -------------------------------------------------------------------------
    //
    //  Internal stuff
    //
    // -------------------------------------------------------------------------

    /**
     * @dev Approves the opensea proxy for token transfers.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        return
            super.isApprovedForAll(owner, operator) ||
            isOwnersOpenSeaProxy(owner, operator);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    modifier onlyApprovedOrOwner(uint256 tokenId) {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "Neither owner nor approved for this token"
        );
        _;
    }
}