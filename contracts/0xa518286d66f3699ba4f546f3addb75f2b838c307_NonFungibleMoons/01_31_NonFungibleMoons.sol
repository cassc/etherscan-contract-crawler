// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC721A} from "@erc721a/contracts/ERC721A.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {LibPRNG} from "../utils/LibPRNG.sol";
import {Utils} from "../utils/Utils.sol";
import {MoonCalculations} from "../moon/MoonCalculations.sol";
import {MoonRenderer} from "../moon/MoonRenderer.sol";
import {MoonSvg} from "../moon/MoonSvg.sol";
import {MoonConfig} from "../moon/MoonConfig.sol";
import {DynamicNftRegistryInterface} from "../interfaces/dynamicNftRegistry/DynamicNftRegistryInterface.sol";
import {AlienArtBase, MoonImageConfig} from "../interfaces/alienArt/AlienArtBase.sol";
import {AlienArtConstellation} from "../alienArt/constellation/AlienArtConstellation.sol";
import {ERC1155TokenReceiver} from "../ext/ERC1155.sol";
import {MoonNFTEventsAndErrors} from "./MoonNFTEventsAndErrors.sol";
import {Ownable} from "../ext/Ownable.sol";
import {IERC2981} from "../interfaces/ext/IERC2981.sol";
import {IERC165} from "../interfaces/ext/IERC165.sol";
import {DefaultOperatorFilterer} from "../ext/DefaultOperatorFilterer.sol";

/*
███╗░░██╗░█████╗░███╗░░██╗
████╗░██║██╔══██╗████╗░██║
██╔██╗██║██║░░██║██╔██╗██║
██║╚████║██║░░██║██║╚████║
██║░╚███║╚█████╔╝██║░╚███║
╚═╝░░╚══╝░╚════╝░╚═╝░░╚══╝

███████╗██╗░░░██╗███╗░░██╗░██████╗░██╗██████╗░██╗░░░░░███████╗
██╔════╝██║░░░██║████╗░██║██╔════╝░██║██╔══██╗██║░░░░░██╔════╝
█████╗░░██║░░░██║██╔██╗██║██║░░██╗░██║██████╦╝██║░░░░░█████╗░░
██╔══╝░░██║░░░██║██║╚████║██║░░╚██╗██║██╔══██╗██║░░░░░██╔══╝░░
██║░░░░░╚██████╔╝██║░╚███║╚██████╔╝██║██████╦╝███████╗███████╗
╚═╝░░░░░░╚═════╝░╚═╝░░╚══╝░╚═════╝░╚═╝╚═════╝░╚══════╝╚══════╝

███╗░░░███╗░█████╗░░█████╗░███╗░░██╗░██████╗
████╗░████║██╔══██╗██╔══██╗████╗░██║██╔════╝
██╔████╔██║██║░░██║██║░░██║██╔██╗██║╚█████╗░
██║╚██╔╝██║██║░░██║██║░░██║██║╚████║░╚═══██╗
██║░╚═╝░██║╚█████╔╝╚█████╔╝██║░╚███║██████╔╝
*/

/// @title NonFungibleMoons
/// @author Aspyn Palatnick (aspyn.eth, stuckinaboot.eth)
/// @notice Interactive on-chain generative moon NFTs with art that closely mirrors the phase of
/// the real world moon. These NFTs support on-chain art composition, art regeneration, and mint referrals.
contract NonFungibleMoons is
    DefaultOperatorFilterer,
    ERC721A,
    IERC2981,
    ERC1155TokenReceiver,
    Ownable,
    MoonNFTEventsAndErrors
{
    using LibPRNG for LibPRNG.PRNG;

    uint256 public constant MAX_SUPPLY = 513;
    uint256 public constant PRICE = 0.04 ether;

    address payable internal constant VAULT_ADDRESS =
        payable(0x39Ab90066cec746A032D67e4fe3378f16294CF6b);

    // On mint, PRICE / FRACTION_OF_PRICE_FOR_REFERRAL will go to referrals
    uint256 internal constant FRACTION_OF_PRICE_FOR_REFERRAL = 4;

    // Maps moon token id to randomness seed
    mapping(uint256 => bytes32) public moonSeeds;
    // Maps moon token id to number of regenerates used by current owner
    mapping(uint256 => uint8) public regeneratesUsedByCurrentOwner;
    uint8 internal constant MAX_REGENERATES_PER_OWNER = 3;
    uint64 internal constant COOLDOWN_PERIOD = 120;

    address public dynamicNftRegistryAddress;
    address public defaultAlienArtAddress;

    // Mapping from token ID to alien art
    mapping(uint256 => address) public alienArtAddressMap;

    uint256 internal constant INTERVAL_BETWEEN_ANIMATION_SAMPLES =
        MoonCalculations.LUNAR_MONTH_LENGTH_IN_MS / 120;

    /***********************************
     ** Welcome to Non-Fungible Moons **
     ***********************************/

    constructor(
        string memory _name,
        string memory _symbol,
        address _defaultAlienArtAddress
    ) ERC721A(_name, _symbol) {
        // Set default alien art contract, which should be the constellations address
        defaultAlienArtAddress = _defaultAlienArtAddress;
    }

    /*************************************************************
     ** Collect moons and explore the potential of on-chain art **
     *************************************************************/

    /// @notice Mint NFT.
    /// @param amount amount of token that the sender wants to mint.
    function mint(uint256 amount) external payable {
        _mintCore(amount);
    }

    function _mintCore(uint256 amount) internal returns (uint256) {
        // Checks

        // Enforce basic mint checks
        if (MAX_SUPPLY < _nextTokenId() + amount) {
            revert MaxSupplyReached();
        }
        if (msg.value != PRICE * amount) {
            revert WrongEtherAmount();
        }

        // Effects
        uint256 nextMoonTokenIdToBeMinted = _nextTokenId();

        // Store moon seeds
        // NOTE: we do not need to set regenerates used for these tokens (regeneratesUsedByCurrentOwner) since the
        // regenerates used for newly minted token ids will default to 0
        for (
            uint256 tokenId = nextMoonTokenIdToBeMinted;
            tokenId < nextMoonTokenIdToBeMinted + amount;
            ++tokenId
        ) {
            moonSeeds[tokenId] = MoonConfig.getMoonSeed(tokenId);
        }

        // Mint moons
        _mint(msg.sender, amount);

        // Interactions

        // Mint constellations
        AlienArtConstellation(defaultAlienArtAddress).mint(
            nextMoonTokenIdToBeMinted,
            amount
        );

        return nextMoonTokenIdToBeMinted;
    }

    /**************************************************************
     ** Once you own a moon, earn on-chain mint referral rewards **
     **************************************************************/

    /// @notice Mint NFT with referrer.
    /// @param amount amount of token that the sender wants to mint.
    /// @param referrer referrer who will receive part of the payment.
    /// @param referrerTokenId token that referrer owns.
    function mintWithReferrer(
        uint256 amount,
        address payable referrer,
        uint256 referrerTokenId
    ) public payable {
        uint256 nextMoonTokenIdToBeMinted = _mintCore(amount);

        // Pay out referral funds if the following conditions are met
        if (
            // 1. Referrer is not 0 address
            referrer != address(0) &&
            // 2. Referrer is not self
            referrer != msg.sender &&
            // 3. Referrer owns the input token
            referrer == ownerOf(referrerTokenId)
        ) {
            // Get referral amounts
            (uint256 referrerValue, uint256 referredValue) = getReferralAmounts(
                referrer,
                msg.sender,
                msg.value
            );

            // Emit minted with referrer event
            emit MintedWithReferrer(
                referrer,
                referrerTokenId,
                msg.sender,
                nextMoonTokenIdToBeMinted,
                amount,
                referrerValue,
                referredValue
            );

            // Transfer ETH to referrer and referred
            referrer.transfer(referrerValue);
            payable(msg.sender).transfer(referredValue);
        }
    }

    /// @notice Get amounts that should be paid out to referrer and referred.
    /// @param referrer referrer who will receive part of the payment.
    /// @param referred referred who will receive part of the payment.
    /// @param value value of the mint.
    /// @return referrerValue value to be paid to referrer, referredValue value to be paid to referred.
    function getReferralAmounts(
        address referrer,
        address referred,
        uint256 value
    ) public view returns (uint256 referrerValue, uint256 referredValue) {
        // Amount from the value that will be distributed between the referrer and referred
        uint256 amtWithheldForReferrals = value /
            FRACTION_OF_PRICE_FOR_REFERRAL;

        LibPRNG.PRNG memory prng;
        prng.seed(
            keccak256(abi.encodePacked(block.difficulty, referrer, referred))
        );
        // Note: integer division will imply the result is truncated (e.g. 5 / 2 = 2).
        // This is the expected behavior.
        referredValue =
            // Random value ranging from 0 to 10000
            (amtWithheldForReferrals * prng.uniform(10001)) /
            10000;
        referrerValue = amtWithheldForReferrals - referredValue;
    }

    /****************************************************
     ** Alter the Alien Art for your moons at any time **
     ****************************************************/

    /// @notice Set alien art address for particular tokens.
    /// @param tokenIds token ids.
    /// @param alienArtAddress alien art contract.
    function setAlienArtAddresses(
        uint256[] calldata tokenIds,
        address alienArtAddress
    ) external {
        if (tokenIds.length > MAX_SUPPLY) {
            revert MaxSupplyReached();
        }

        // If alien art address is not null address, validate that alien
        // art address is pointing to a valid alien art contract
        if (
            alienArtAddress != address(0) &&
            !AlienArtBase(alienArtAddress).supportsInterface(
                type(AlienArtBase).interfaceId
            )
        ) {
            revert AlienArtContractFailedValidation();
        }

        for (uint256 i = 0; i < tokenIds.length; ++i) {
            uint256 tokenId = tokenIds[i];
            if (ownerOf(tokenId) != msg.sender) {
                revert OwnerNotMsgSender();
            }

            alienArtAddressMap[tokenId] = alienArtAddress;
            emit AlienArtAddressUpdated(tokenId, alienArtAddress);
        }
    }

    /// @notice Get alien art address for a particular token.
    /// @param tokenId token id.
    /// @return tuple containing (True if default alien art contract is used; false otherwise, alien art contract).
    function getAlienArtContractForToken(uint256 tokenId)
        external
        view
        returns (bool, AlienArtBase)
    {
        AlienArtBase alienArtContract;
        if (alienArtAddressMap[tokenId] != address(0)) {
            // Use defined alien art contract if alien art address for token is not 0
            alienArtContract = AlienArtBase(alienArtAddressMap[tokenId]);
        } else {
            // Use default alien art contract if alien art address for token is 0
            alienArtContract = AlienArtBase(defaultAlienArtAddress);
        }

        // Default alien art is used if the alien art address is
        // the default alien art address or if alien art address is 0 address
        return (
            alienArtAddressMap[tokenId] == defaultAlienArtAddress ||
                alienArtAddressMap[tokenId] == address(0),
            alienArtContract
        );
    }

    /// @notice Get alien art values.
    /// @param alienArtContract alien art contract to get values from.
    /// @param tokenId token id.
    /// @param rotationInDegrees rotation in degrees.
    /// @return alien art image, alien art moon filter, alien art trait.
    function getAlienArtValues(
        AlienArtBase alienArtContract,
        uint256 tokenId,
        uint256 rotationInDegrees
    )
        internal
        view
        returns (
            string memory,
            string memory,
            string memory
        )
    {
        bytes32 seed = moonSeeds[tokenId];
        MoonImageConfig memory config = MoonConfig.getMoonConfig(seed);
        return (
            alienArtContract.getArt(tokenId, seed, config, rotationInDegrees),
            alienArtContract.getMoonFilter(
                tokenId,
                seed,
                config,
                rotationInDegrees
            ),
            alienArtContract.getTraits(tokenId, seed, config, rotationInDegrees)
        );
    }

    /**************************
     ** Regenerate your moon **
     **************************/

    /// @notice Regenerate a moon's seed, which will permanently regenerate the moon's art and traits.
    /// @param tokenId moon token id.
    function regenerateMoon(uint256 tokenId) external payable {
        // Checks
        if (
            regeneratesUsedByCurrentOwner[tokenId] == MAX_REGENERATES_PER_OWNER
        ) {
            revert NoRegenerationsRemaining();
        }
        if (msg.value != PRICE) {
            revert WrongEtherAmount();
        }
        if (ownerOf(tokenId) != msg.sender) {
            revert OwnerNotMsgSender();
        }

        // Effects

        // Update moon seed
        bytes32 originalMoonSeed = moonSeeds[tokenId];
        moonSeeds[tokenId] = MoonConfig.getMoonSeed(tokenId);
        // Increment regenerates used
        ++regeneratesUsedByCurrentOwner[tokenId];

        // Emit regeneration event
        emit MoonRegenerated(
            msg.sender,
            tokenId,
            moonSeeds[tokenId],
            originalMoonSeed,
            regeneratesUsedByCurrentOwner[tokenId]
        );

        // Interactions

        // Burn existing constellation and mint new one
        AlienArtConstellation(defaultAlienArtAddress).burnAndMint(tokenId);

        // Update dynamic NFT registry if present
        if (dynamicNftRegistryAddress != address(0)) {
            DynamicNftRegistryInterface(dynamicNftRegistryAddress).updateToken(
                address(this),
                tokenId,
                COOLDOWN_PERIOD,
                false
            );
        }
    }

    function _afterTokenTransfers(
        address,
        address,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        // After token transfer, reset regenerates for the new owner
        for (
            uint256 tokenId = startTokenId;
            tokenId < startTokenId + quantity;
            ++tokenId
        ) {
            regeneratesUsedByCurrentOwner[tokenId] = 0;
        }
    }

    /*********************************
     ** Withdraw funds to the vault **
     *********************************/

    /// @notice Withdraw all ETH from the contract to the vault.
    function withdraw() external {
        VAULT_ADDRESS.transfer(address(this).balance);
    }

    /***************************************************************
     ** Generate on-chain SVG and interactive HTML token metadata **
     ***************************************************************/

    /// @notice Get token URI for a particular token.
    /// @param tokenId token id.
    /// @return token uri.
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        ownerOf(tokenId);

        (bool defaultAlienArt, AlienArtBase alienArtContract) = this
            .getAlienArtContractForToken(tokenId);

        uint256 timestamp = block.timestamp * 1e3;
        (, , string memory alienArtTrait) = getAlienArtValues(
            alienArtContract,
            tokenId,
            MoonRenderer.getLunarCycleDistanceFromDateAsRotationInDegrees(
                timestamp
            )
        );

        bytes32 moonSeed = moonSeeds[tokenId];
        string memory traits = MoonConfig.getMoonTraits(
            moonSeed,
            alienArtTrait,
            alienArtContract.getArtName(),
            Strings.toHexString(address(alienArtContract)),
            defaultAlienArt
        );

        string memory moonName = string.concat(
            "Non-Fungible Moon #",
            Utils.uint2str(tokenId)
        );

        (
            string memory moonSvg,
            string memory moonAnimation
        ) = generateOnChainMoon(tokenId, timestamp, alienArtContract);

        return
            Utils.formatTokenURI(
                Utils.svgToImageURI(moonSvg),
                Utils.htmlToURI(moonAnimation),
                moonName,
                "Non-Fungible Moons are on-chain generative moon NFTs. All moon art is generated on-chain and updates in real-time, based on current block time and using an on-chain SVG library, to closely mirror the phase of the moon in the real world.",
                traits
            );
    }

    // Generate moon svg image and interactive moon animation html based on initial timestamp
    function generateOnChainMoon(
        uint256 tokenId,
        uint256 initialTimestamp,
        AlienArtBase alienArtContract
    ) internal view returns (string memory, string memory) {
        bytes32 moonSeed = moonSeeds[tokenId];

        string memory moonSvgText;
        string memory firstSvg;

        for (
            uint256 timestamp = initialTimestamp;
            timestamp <
            initialTimestamp + MoonCalculations.LUNAR_MONTH_LENGTH_IN_MS;
            timestamp += INTERVAL_BETWEEN_ANIMATION_SAMPLES
        ) {
            (
                string memory alienArt,
                string memory alienArtMoonFilter,

            ) = getAlienArtValues(
                    alienArtContract,
                    tokenId,
                    MoonRenderer
                        .getLunarCycleDistanceFromDateAsRotationInDegrees(
                            timestamp
                        )
                );

            string memory moonSvg = MoonRenderer.renderWithTimestamp(
                moonSeed,
                timestamp,
                alienArt,
                alienArtMoonFilter
            );

            if (timestamp == initialTimestamp) {
                firstSvg = moonSvg;
                moonSvgText = string.concat(
                    '<!DOCTYPE html><html><head><style type="text/css">html{overflow:hidden}body{margin:0}#moon{display:block;margin:auto}</style></head><body><div id="moonDiv"></div><script>let gs=[`',
                    moonSvg,
                    "`"
                );
            } else {
                moonSvgText = string.concat(moonSvgText, ",`", moonSvg, "`");
            }
        }

        return (
            firstSvg,
            string.concat(
                moonSvgText,
                '];let $=document.getElementById.bind(document);$("moonDiv").innerHTML=gs[0];let mo=$("moonDiv");let u=e=>{let t=$("moon").getBoundingClientRect();$("moonDiv").innerHTML=gs[Math.max(0,Math.min(Math.floor(((e-t.left)/t.width)*gs.length),gs.length-1))];};mo.onmousemove=e=>u(e.clientX);mo.addEventListener("touchstart",e=>{let t=e=>u(e.touches[0].clientX);n=()=>{e.target.removeEventListener("touchmove",t),e.target.removeEventListener("touchend",n);};e.target.addEventListener("touchmove",t);e.target.addEventListener("touchend",n);});</script></body></html>'
            )
        );
    }

    /**************************
     ** Dynamic NFT registry **
     **************************/

    /// @notice Set up dynamic NFT registry and add default alien art as an allowed updater of this token.
    /// @param _dynamicNftRegistryAddress dynamic NFT registry address.
    function setupDynamicNftRegistry(address _dynamicNftRegistryAddress)
        external
        onlyOwner
    {
        dynamicNftRegistryAddress = _dynamicNftRegistryAddress;
        DynamicNftRegistryInterface registry = DynamicNftRegistryInterface(
            dynamicNftRegistryAddress
        );
        // Register this token with dynamic nft registry
        registry.registerToken(address(this));
        // Add default alien art as an allowed updater of this token
        registry.addAllowedUpdater(address(this), defaultAlienArtAddress);
        // Add this as an allowed updater of this token
        registry.addAllowedUpdater(address(this), address(this));
    }

    /*********************
     ** Operator filter **
     *********************/

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /*************************
     ** Royalty definitions **
     *************************/

    function royaltyInfo(uint256, uint256 salePrice)
        external
        pure
        returns (address receiver, uint256 royaltyAmount)
    {
        return (VAULT_ADDRESS, (salePrice * 250) / 10000);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721A)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /*************
     ** Tip jar **
     *************/

    receive() external payable {}
}