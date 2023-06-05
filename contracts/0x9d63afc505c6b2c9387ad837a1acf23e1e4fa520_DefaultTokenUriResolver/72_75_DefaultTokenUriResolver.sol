//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Utility imports specific to this project
import {Theme} from "./Structs/Theme.sol";
import {StringSlicer} from "./Libraries/StringSlicer.sol";

// Utility imports
import {Base64} from "base64-sol/base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Font, ITypeface} from "typeface/interfaces/ITypeface.sol";
import {LibColor, Color, newColorFromRGBString} from "solcolor/src/Color.sol";

// Juicebox imports
import {IJBTokenUriResolver} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBTokenUriResolver.sol";
import {IJBToken, IJBTokenStore} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBTokenStore.sol";
import {JBFundingCycle} from "@jbx-protocol/juice-contracts-v3/contracts/structs/JBFundingCycle.sol";
import {IJBPaymentTerminal} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPaymentTerminal.sol";
import {JBTokens} from "@jbx-protocol/juice-contracts-v3/contracts/libraries/JBTokens.sol";
import {JBCurrencies} from "@jbx-protocol/juice-contracts-v3/contracts/libraries/JBCurrencies.sol";
import {IJBController} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBController.sol";
import {IJBController3_1, IJBDirectory, IJBFundingCycleStore} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBController3_1.sol";
import {IJBOperatorStore} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBOperatorStore.sol";
import {IJBPayoutRedemptionPaymentTerminal} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPayoutRedemptionPaymentTerminal.sol";
import {IJBSingleTokenPaymentTerminalStore, IJBSingleTokenPaymentTerminal} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBSingleTokenPaymentTerminalStore.sol";
import {JBPayoutRedemptionPaymentTerminal} from "@jbx-protocol/juice-contracts-v3/contracts/abstract/JBPayoutRedemptionPaymentTerminal.sol";
import {IJBProjects} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBProjects.sol";
import {IJBProjectHandles} from "@jbx-protocol/project-handles/contracts/interfaces/IJBProjectHandles.sol"; // Will need updating if NPM is renamed to /juice-project-handles
import {JBOperatable} from "@jbx-protocol/juice-contracts-v3/contracts/abstract/JBOperatable.sol";
import {JBUriOperations} from "./Libraries/JBUriOperations.sol";
import {IJBFundAccessConstraintsStore} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBFundAccessConstraintsStore.sol";

contract DefaultTokenUriResolver is IJBTokenUriResolver, JBOperatable, Ownable {
    using Strings for uint256;
    using LibColor for Color;

    /// @notice Emitted when a theme is set. Emitted when setting default and custom themes.
    event ThemeSet(uint256 projectId, Color textColor, Color bgColor, Color bgColorAlt);

    /// @notice Emitted when a project's custom theme is reset to the default.
    event ThemeReset(uint256 projectId);

    /// @notice The address of the Juicebox Funding Cycle Store contract.
    IJBFundingCycleStore public immutable fundingCycleStore;

    /// @notice The address of the Juicebox Projects contract.
    IJBProjects public immutable projects;

    /// @notice The address of the Juicebox Directory contract.
    IJBDirectory public immutable directory;

    /// @notice The address of the Juicebox Project Handles contract.
    IJBProjectHandles public immutable projectHandles;

    /// @notice The address of the Capsules typeface contract.
    ITypeface public immutable capsulesTypeface;

    /// @notice The address of the Juicebox Controller contract.
    IJBController public immutable controller;
    IJBController3_1 public immutable controller3_1;

    /**
     * @notice Mapping containing each project's theme, if one is set. Themes describe the color palette to be used when generating the token uri SVG.
     * @dev Theme 0 is the default theme used for all projects without custom themes.
     */
    mapping(uint256 => Theme) private themes;

    constructor(
        IJBOperatorStore _operatorStore,
        IJBDirectory _directory,
        IJBController _controller,
        IJBController3_1 _controller3_1,
        IJBProjectHandles _projectHandles,
        ITypeface _capsulesTypeface
    ) JBOperatable(_operatorStore) {
        directory = _directory;
        projects = directory.projects();
        controller = _controller;
        controller3_1 = _controller3_1;
        fundingCycleStore = directory.fundingCycleStore();
        projectHandles = _projectHandles;
        capsulesTypeface = _capsulesTypeface;
        setDefaultTheme("FF9213", "44190F", "3A0F0C");
    }

    /**
     * @notice Gets the Theme for a given id in the private themes mapping.
     * @param id The id of the theme to fetch. This is the project's ID for all values except 0, which is the default theme.
     * @return Theme The Theme corresponding to the id passed as an argument.
     */
    function getTheme(uint256 id) external view returns (Theme memory) {
        return themes[id];
    }

    /**
     * @notice Gets the Base64 encoded Capsules-500.otf typeface.
     * @return fontSource The Base64 encoded font file.
     */
    function getFontSource() internal view returns (bytes memory fontSource) {
        return ITypeface(capsulesTypeface).sourceOf(Font({weight: 500, style: "normal"})); // Capsules font source
    }

    /**
     * @notice Transform strings to target length by abbreviating or padding with spaces.
     * @dev Shortens long strings to 13 characters including an ellipsis and adds left padding spaces to short strings. Allows variable target length to account for strings that have unicode characters that are longer than 1 byte but only take up 1 character space.
     * @param left True adds padding to the left of the passed string, and false adds padding to the right.
     * @param str The string to transform.
     * @param targetLength The length of the string to return.
     * @return string The transformed string.
     */
    function pad(bool left, string memory str, uint256 targetLength) internal pure returns (string memory) {
        uint256 length = bytes(str).length;

        // If string is already target length, return it
        if (length == targetLength) {
            return str;
        }

        // If string is longer than target length, abbreviate it and add an ellipsis
        // Note that the ellipsis character is 3 bytes, so the bytes length of the returned string will exceed targetLength by 2 bytes.
        if (length > targetLength) {
            str = string.concat(
                StringSlicer.slice(str, 0, targetLength - 1), // Abbreviate to 1 character less than target length
                unicode"…" // And add an ellipsis.
            );
            return str;
        }

        // If string is shorter than target length, pad it on the left or right as specified
        string memory padding;
        uint256 _paddingToAdd = targetLength - length;
        for (uint256 i; i < _paddingToAdd; ) {
            // Accumulate desired padding
            padding = string.concat(padding, " ");
            unchecked {
                ++i;
            }
        }
        str = left ? string.concat(padding, str) : string.concat(str, padding); // Add padding to left or right
        return str;
    }

    /**
     * @notice Returns either a project's handle, if set, or a string with the project's ID number if no project handle is found.
     */
    function getProjectName(uint256 _projectId) internal view returns (string memory projectName) {
        // Project Handle
        string memory _projectName;
        // If handle is set
        if (keccak256(abi.encode(projectHandles.handleOf(_projectId))) != keccak256(abi.encode(string("")))) {
            // Set projectName to handle
            _projectName = string.concat("@", projectHandles.handleOf(_projectId));
        } else {
            // Set projectName to name to 'Project #projectId'
            _projectName = string.concat("Project #", _projectId.toString());
        }
        // Abbreviate handle to 27 chars if longer
        if (bytes(_projectName).length > 26) {
            _projectName = string.concat(StringSlicer.slice(_projectName, 0, 26), unicode"…");
        }
        return _projectName;
    }

    /**
     * @notice Gets the IJBSingleTokenPaymentTerminalStore for a given project.
     */
    function getTerminalStore(uint256 _projectId) internal view returns (IJBSingleTokenPaymentTerminalStore) {
        return
            IJBSingleTokenPaymentTerminalStore(
                IJBPayoutRedemptionPaymentTerminal(
                    address(IJBPaymentTerminal(directory.primaryTerminalOf(_projectId, JBTokens.ETH)))
                ).store()
            );
    }

    /**
     * @notice Returns a right-padded string containing the project's current cycle number.
     */
    function getRightPaddedCycle(
        JBFundingCycle memory _fundingCycle
    ) internal pure returns (string memory rightPaddedCycleString) {
        uint256 currentFundingCycleId = _fundingCycle.number; // Project's current funding cycle id
        string memory fundingCycleIdString = currentFundingCycleId.toString();
        return pad(false, string.concat(unicode"  cʏcʟᴇ ", fundingCycleIdString), 19);
    }

    /**
     * @notice Returns a left-padded string containing the time left in the project's current cycle.
     */
    function getLeftPaddedTimeLeft(
        JBFundingCycle memory _fundingCycle
    ) internal view returns (string memory leftPaddedTimeLeftString) {
        // Time Left
        uint256 start = _fundingCycle.start; // Project's funding cycle start time
        uint256 duration = _fundingCycle.duration; // Project's current funding cycle duration
        uint256 timeLeft;
        string memory paddedTimeLeft;
        string memory countString;
        if (duration == 0) {
            paddedTimeLeft = string.concat(pad(true, string.concat(unicode" ɴoᴛ sᴇᴛ"), 22), "  "); // If the cycle has no duration, show NOT SET
        } else {
            timeLeft = start + duration - block.timestamp; // Time left in project's current cycle
            if (timeLeft > 2 days) {
                countString = (timeLeft / 1 days).toString();
                paddedTimeLeft = string.concat(
                    pad(true, string.concat(unicode"", " ", countString, unicode" ᴅᴀʏs"), 20),
                    "  "
                );
            } else if (timeLeft > 2 hours) {
                countString = (timeLeft / 1 hours).toString(); // 12 bytes || 8 visual + countString
                paddedTimeLeft = string.concat(
                    pad(true, string.concat(unicode"", " ", countString, unicode" ʜouʀs"), 17),
                    "  "
                );
            } else if (timeLeft > 2 minutes) {
                countString = (timeLeft / 1 minutes).toString();
                paddedTimeLeft = string.concat(
                    pad(true, string.concat(unicode"", " ", countString, unicode" ᴍɪɴuᴛᴇs"), 23),
                    "  "
                );
            } else {
                countString = (timeLeft / 1 seconds).toString();
                paddedTimeLeft = string.concat(
                    pad(true, string.concat(unicode"", " ", countString, unicode" sᴇcoɴᴅs"), 20),
                    "  "
                );
            }
        }
        return paddedTimeLeft;
    }

    /**
     * @notice Returns a string containing the cycle count and time left.
     */
    function getCycleTimeLeftRow(
        JBFundingCycle memory fundingCycle
    ) internal view returns (string memory cycleTimeLeftRow) {
        return string.concat(getRightPaddedCycle(fundingCycle), getLeftPaddedTimeLeft(fundingCycle));
    }

    /**
     * @notice Returns the balance row string.
     */
    function getBalanceRow(
        IJBPaymentTerminal primaryEthPaymentTerminal,
        uint256 _projectId
    ) internal view returns (string memory balanceRow) {
        // Balance
        uint256 balance = getTerminalStore(_projectId).balanceOf(
            IJBSingleTokenPaymentTerminal(address(primaryEthPaymentTerminal)),
            _projectId
        ) / 10 ** 18; // Project's ETH balance
        string memory paddedBalanceLeft = string.concat(
            pad(true, string.concat(unicode"Ξ", balance.toString()), 14),
            "  "
        ); // Project's ETH balance as a string
        string memory paddedBalanceRight = pad(false, unicode"  ʙᴀʟᴀɴcᴇ     ", 24);
        return string.concat(paddedBalanceRight, paddedBalanceLeft);
    }

    /**
     * @notice Returns a string containing the projects payouts. Used in the JSON metadata.
     */
    function getPayouts(
        IJBPaymentTerminal primaryEthPaymentTerminal,
        uint256 _projectId
    ) internal view returns (string memory payouts) {
        uint256 latestConfiguration = fundingCycleStore.latestConfigurationOf(_projectId); // Get project's current cycle configuration
        address controllerAddress = directory.controllerOf(_projectId); // Get project's controller address
        uint256 payoutsPreprocessed;
        uint256 payoutsCurrencyPreprocessed;
        if (controllerAddress == address(controller3_1)) {
            // If the project is using Controller v3.1
            IJBFundAccessConstraintsStore fundAccessConstraintStore = IJBFundAccessConstraintsStore(
                controller3_1.fundAccessConstraintsStore()
            );
            (payoutsPreprocessed, payoutsCurrencyPreprocessed) = fundAccessConstraintStore.distributionLimitOf(
                _projectId,
                latestConfiguration,
                primaryEthPaymentTerminal,
                JBTokens.ETH
            ); // Get raw payouts data
        }
        if (controllerAddress == address(controller)) {
            // If the project is using the original Controller
            (payoutsPreprocessed, payoutsCurrencyPreprocessed) = controller.distributionLimitOf(
                _projectId,
                latestConfiguration,
                primaryEthPaymentTerminal,
                JBTokens.ETH
            ); // Project's payouts and currency
        }
        if (payoutsPreprocessed == type(uint232).max) {
            // If are set to unlimited
            return unicode"∞"; // Return Payouts = infinity
        }
        string memory payoutsCurrency;
        payoutsCurrencyPreprocessed == 1 ? payoutsCurrency = unicode"Ξ" : payoutsCurrency = "$"; // Translate payouts currency into appropriate string
        return (string.concat(payoutsCurrency, (payoutsPreprocessed / 10 ** 18).toString())); // Return string containing currency and payouts limit
    }

    /**
     * @notice Returns the payouts row string. Used in the SVG.
     */
    function getPayoutsRow(
        IJBPaymentTerminal primaryEthPaymentTerminal,
        uint256 _projectId
    ) internal view returns (string memory payoutsRow) {
        uint256 latestConfiguration = fundingCycleStore.latestConfigurationOf(_projectId); // Get project's current cycle configuration
        string memory payoutsCurrency;
        address controllerAddress = directory.controllerOf(_projectId); // Get project's controller address
        uint256 payoutsPreprocessed;
        uint256 payoutsCurrencyPreprocessed;
        // If the project is using Controller v3.1
        if (controllerAddress == address(controller3_1)) {
            IJBFundAccessConstraintsStore fundAccessConstraintStore = IJBFundAccessConstraintsStore(
                controller3_1.fundAccessConstraintsStore()
            );
            (payoutsPreprocessed, payoutsCurrencyPreprocessed) = fundAccessConstraintStore.distributionLimitOf(
                _projectId,
                latestConfiguration,
                primaryEthPaymentTerminal,
                JBTokens.ETH
            ); // Get raw payouts data
        }
        // If the project is using the original Controller
        if (controllerAddress == address(controller)) {
            (payoutsPreprocessed, payoutsCurrencyPreprocessed) = controller.distributionLimitOf(
                _projectId,
                latestConfiguration,
                primaryEthPaymentTerminal,
                JBTokens.ETH
            ); // Project's payouts and currency
        }
        if (payoutsPreprocessed == type(uint232).max) {
            // If are set to unlimited
            return string.concat(pad(false, unicode"  ᴘᴀʏouᴛs", 22), pad(true, string.concat(unicode"∞"), 15)); // Return Payouts = infinity
        }
        if (payoutsCurrencyPreprocessed == 1) {
            payoutsCurrency = unicode"Ξ";
        } else {
            payoutsCurrency = "$";
        }
        string memory payouts = string.concat(payoutsCurrency, (payoutsPreprocessed / 10 ** 18).toString()); // Project's payouts
        string memory paddedPayoutsLeft = string.concat(pad(true, payouts, 12 + bytes(payoutsCurrency).length), "  ");
        string memory paddedPayoutsRight = string.concat(pad(false, unicode"  ᴘᴀʏouᴛs", 22));
        return string.concat(paddedPayoutsRight, paddedPayoutsLeft);
    }

    /**
     * @notice Returns the token store.
     */
    function getTokenStore(uint256 _projectId) internal view returns (IJBTokenStore) {
        address _controller = directory.controllerOf(_projectId);
        if (_controller == address(controller)) {
            IJBController c = IJBController(_controller);
            return c.tokenStore();
        }
        if (_controller == address(controller3_1)) {
            IJBController3_1 c = IJBController3_1(_controller);
            return c.tokenStore();
        }
        revert("getTokenStore: UNRECOGNIZED_CONTROLLER");
    }

    /**
     * @notice Returns the token supply row string.
     */
    function getTokenSupplyRow(uint256 _projectId) internal view returns (string memory tokenSupplyRow) {
        IJBTokenStore tokenStore = getTokenStore(_projectId);
        uint256 totalSupply = tokenStore.totalSupplyOf(_projectId) / 10 ** 18; // Project's fungible token total supply
        string memory paddedTokenSupplyLeft = string.concat(pad(true, totalSupply.toString(), 13), "  "); // Project's token token supply as a string
        string memory paddedTokenSupplyRight = pad(false, unicode"  ᴛoᴋᴇɴ suᴘᴘʟʏ", 28);
        return string.concat(paddedTokenSupplyRight, paddedTokenSupplyLeft);
    }

    /**
     *  @notice Set theme colors for a given project. Values should be 6 character strings and all letters must be uppercase (e.g, "FFFFFF").
     *  @dev Available only to project owners or operators with permission to set the token resolver on their behalf.
     *  @param _projectId The project's ID number.
     *  @param _textColor The color of the text.
     *  @param _bgColor The primary background color.
     *  @param _bgColorAlt The secondary background color.
     */
    function setTheme(
        uint256 _projectId,
        string memory _textColor,
        string memory _bgColor,
        string memory _bgColorAlt
    ) external requirePermission(projects.ownerOf(_projectId), _projectId, JBUriOperations.SET_TOKEN_URI) {
        Color textColor = newColorFromRGBString(_textColor);
        Color bgColor = newColorFromRGBString(_bgColor);
        Color bgColorAlt = newColorFromRGBString(_bgColorAlt);
        themes[_projectId] = Theme(true, textColor, bgColor, bgColorAlt); // Custom themes have the customTheme value set to True
        emit ThemeSet(_projectId, textColor, bgColor, bgColorAlt);
    }

    /**
     *  @notice Reset theme for a given project to the default.
     *  @dev Available only to project owners or operators with permission to set the token resolver on their behalf.
     *  @param _projectId The project's ID number.
     */
    function resetTheme(
        uint256 _projectId
    ) external requirePermission(projects.ownerOf(_projectId), _projectId, JBUriOperations.SET_TOKEN_URI) {
        delete themes[_projectId];
        emit ThemeReset(_projectId);
    }

    /**
     *  @notice Set default theme colors. Values should be 6 character strings and all letters must be uppercase (e.g, "FFFFFF").
     *  @dev Available only to the owner of this contract.
     *  @param _textColor The color of the text.
     *  @param _bgColor The primary background color.
     *  @param _bgColorAlt The secondary background color.
     */
    function setDefaultTheme(
        string memory _textColor,
        string memory _bgColor,
        string memory _bgColorAlt
    ) public onlyOwner {
        Color textColor = newColorFromRGBString(_textColor);
        Color bgColor = newColorFromRGBString(_bgColor);
        Color bgColorAlt = newColorFromRGBString(_bgColorAlt);
        themes[0] = Theme(true, textColor, bgColor, bgColorAlt);
        emit ThemeSet(0, textColor, bgColor, bgColorAlt);
    }

    /**
     * @notice Returns a string containing an abbreviated address as a string.
     */
    function getOwnerName(address owner) internal pure returns (string memory ownerName) {
        return
            string.concat(
                "0x",
                StringSlicer.slice(toAsciiString(owner), 0, 4),
                unicode"…",
                StringSlicer.slice(toAsciiString(owner), 36, 40)
            ); // Abbreviate owner address
    }

    /**
     * @notice Returns a string containing the project's ETH balance.
     */
    function getBalance(
        uint256 _projectId,
        IJBPaymentTerminal primaryEthPaymentTerminal
    ) internal view returns (string memory) {
        uint256 balance = getTerminalStore(_projectId).balanceOf(
            IJBSingleTokenPaymentTerminal(address(primaryEthPaymentTerminal)),
            _projectId
        ) / 10 ** 18;
        return string(abi.encodePacked(unicode"Ξ", balance.toString()));
    }

    /**
     * @notice Returns a string containing the project's ETH balance.
     */
    function getTokenSupply(uint256 _projectId) internal view returns (string memory) {
        IJBTokenStore tokenStore = getTokenStore(_projectId);
        return (tokenStore.totalSupplyOf(_projectId) / 10 ** 18).toString();
    }

    function getUpgradePromptUri(uint256 _projectId, string memory projectName) internal pure returns (string memory) {
        return
            string.concat(
                string("data:application/json;base64,"),
                Base64.encode(
                    abi.encodePacked(
                        '{"name":"',
                        projectName,
                        '", "description":"',
                        projectName,
                        " is a project on the Juicebox Protocol. The project owner must upgrade this project to V3 to enable this NFT's image. Visit https://juicebox.money/v2/p/",
                        _projectId.toString(),
                        "/settings?page=upgrades to upgrade this project.",
                        '"}'
                    )
                )
            );
    }

    /**
     *  @notice Get the token uri for a project.
     *  @dev Creates metadata for the given project ID using either the default Theme colors, or custom colors if they are set.
     *  @param _projectId The id of the project.
     *  @return tokenUri The token uri for the project.
     */
    function getUri(uint256 _projectId) external view override returns (string memory tokenUri) {
        string[] memory parts = new string[](2);
        {
            // Project Name
            string memory projectName = getProjectName(_projectId);

            // Get Project's Primary ETH Terminal
            IJBPaymentTerminal primaryEthPaymentTerminal = directory.primaryTerminalOf(_projectId, JBTokens.ETH);

            // If no primary ETH terminal is set on DirectoryV3, return upgrade prompt
            if (primaryEthPaymentTerminal == IJBPaymentTerminal(address(0))) {
                return getUpgradePromptUri(_projectId, projectName);
            }

            // Create JSON metadata and properties
            parts[0] = string(
                abi.encodePacked(
                    '{"name":"',
                    projectName,
                    '", "description":"',
                    projectName,
                    ' is a project on the Juicebox Protocol.",',
                    '"attributes":[',
                    '{"trait_type":"Balance","value":"',
                    getBalance(_projectId, primaryEthPaymentTerminal),
                    '"},',
                    '{"trait_type":"Payouts","value":"',
                    getPayouts(primaryEthPaymentTerminal, _projectId),
                    '"},',
                    '{"trait_type":"Token Supply","value":"',
                    getTokenSupply(_projectId),
                    '"}],',
                    '"image":"data:image/svg+xml;base64,'
                )
            );

            // Owner
            address owner = projects.ownerOf(_projectId); // Project's owner

            // Create SVG
            // Each line (row) of the SVG is 30 monospaced characters long
            // The first half of each line (15 chars) is the title
            // The second half of each line (15 chars) is the value
            // The first and last characters on the line are two spaces
            // The first line (head) has exceptional layout.
            parts[1] = Base64.encode(
                getPartThree(
                    getPartTwo(
                        getPartOne(_projectId, projectName),
                        _projectId,
                        primaryEthPaymentTerminal,
                        pad(false, unicode"  ᴘʀoᴊᴇcᴛ owɴᴇʀ", 28),
                        owner
                    ),
                    _projectId
                )
            );
        }

        // Complete the JSON metadata
        string memory uri = string.concat(
            string("data:application/json;base64,"),
            Base64.encode(abi.encodePacked(parts[0], parts[1], string('"}')))
        );
        return uri;
    }

    /**
     * @notice Get SVG part one.
     */
    function getPartOne(uint256 _projectId, string memory projectName) internal view returns (bytes memory) {
        Theme memory theme = themes[_projectId].customTheme == true ? themes[_projectId] : themes[0]; // Get Theme

        return
            abi.encodePacked(
                abi.encodePacked(
                    '<svg width="289" height="150" viewBox="0 0 289 150" xmlns="http://www.w3.org/2000/svg"><style>@font-face{font-family:"Capsules-500";src:url(data:font/truetype;charset=utf-8;base64,',
                    getFontSource(), // get Capsules typeface
                    ');format("opentype");}a,a:visited,a:hover{fill:inherit;text-decoration:none;}text{font-size:16px;fill:#',
                    theme.textColor.toString(),
                    ';font-family:"Capsules-500",monospace;font-weight:500;white-space:pre;}#head text{fill:#',
                    theme.bgColor.toString(),
                    ';}</style><g clip-path="url(#clip0)"><path d="M289 0H0V150H289V0Z" fill="url(#paint0)"/><rect width="289" height="22" fill="#',
                    theme.textColor.toString()
                ),
                '"/><g id="head" filter="url(#filter2)"><a href="https://juicebox.money/v2/p/',
                _projectId.toString(),
                '">', // Line 0: Head
                '<text x="16" y="16">',
                projectName,
                '</text></a><a href="https://juicebox.money"><text x="259.25" y="16">',
                unicode"",
                "</text></a></g>"
            );
    }

    /**
     * @notice Get SVG part two.
     */
    function getPartTwo(
        bytes memory _base,
        uint256 _projectId,
        IJBPaymentTerminal _primaryEthPaymentTerminal,
        string memory _projectOwnerPaddedRight,
        address owner
    ) internal view returns (bytes memory) {
        JBFundingCycle memory fundingCycle = fundingCycleStore.currentOf(_projectId);

        return
            abi.encodePacked(
                abi.encodePacked(
                    _base, // Part one
                    // Line 1: Cycle + Time left
                    '<g filter="url(#filter1)"><text x="0" y="48">',
                    getCycleTimeLeftRow(fundingCycle),
                    "</text>",
                    // Line 2: Spacer
                    '<text x="0" y="64">',
                    unicode"                              ",
                    "</text>",
                    // Line 3: Balance
                    '<text x="0" y="80">',
                    getBalanceRow(_primaryEthPaymentTerminal, _projectId),
                    "</text>"
                ),
                // Line 4: Payouts
                '<text x="0" y="96">',
                getPayoutsRow(_primaryEthPaymentTerminal, _projectId),
                "</text>",
                // Line 5: Token Supply
                '<text x="0" y="112">',
                getTokenSupplyRow(_projectId),
                "</text>",
                // Line 6: Project Owner
                '<text x="0" y="128">',
                _projectOwnerPaddedRight,
                "  ", // additional spaces hard coded for this line, presumes address is 11 chars long
                '<a href="https://etherscan.io/address/',
                toAsciiString(owner),
                '">',
                getOwnerName(owner),
                "</a>"
            );
    }

    /**
     * @notice Get SVG part three
     */
    function getPartThree(bytes memory _base, uint256 _projectId) internal view returns (bytes memory) {
        Theme memory theme = themes[_projectId].customTheme == true ? themes[_projectId] : themes[0]; // Get Theme

        return
            abi.encodePacked(
                abi.encodePacked(
                    _base,
                    '</text></g></g><defs><filter id="filter1" x="-3.36" y="26.04" width="298" height="150" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB"><feMorphology operator="dilate" radius="0.1" in="SourceAlpha" result="thicken"/><feGaussianBlur in="thicken" stdDeviation="0.5" result="blurred"/><feFlood flood-color="#',
                    theme.textColor.toString(),
                    '" result="glowColor"/><feComposite in="glowColor" in2="blurred" operator="in" result="softGlow_colored"/><feMerge><feMergeNode in="softGlow_colored"/><feMergeNode in="SourceGraphic"/></feMerge></filter><filter id="filter2" x="0" y="0" width="298" height="150" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB"><feMorphology operator="dilate" radius="0.05" in="SourceAlpha" result="thicken"/><feGaussianBlur in="thicken" stdDeviation="0.25" result="blurred"/><feFlood flood-color="#',
                    theme.bgColor.toString(),
                    '" result="glowColor"/><feComposite in="glowColor" in2="blurred" operator="in" result="softGlow_colored"/><feMerge><feMergeNode in="softGlow_colored"/><feMergeNode in="SourceGraphic"/></feMerge></filter><linearGradient id="paint0" x1="0" y1="202" x2="289" y2="202" gradientUnits="userSpaceOnUse"><stop stop-color="#',
                    theme.bgColorAlt.toString(),
                    '"/><stop offset="0.119792" stop-color="#'
                ),
                theme.bgColor.toString(),
                '"/><stop offset="0.848958" stop-color="#',
                theme.bgColor.toString(),
                '"/><stop offset="1" stop-color="#',
                theme.bgColorAlt.toString(),
                '"/></linearGradient><clipPath id="clip0"><rect width="289" height="150" /></clipPath></defs></svg>'
            );
    }

    /**
     * @notice Transforms addresses into strings
     * @dev borrowed from https://ethereum.stackexchange.com/questions/8346/convert-address-to-string
     */
    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; ) {
            bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2 ** (8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
            unchecked {
                ++i;
            }
        }
        return string(s);
    }

    /**
     * @notice Helps toAsciiString function
     */
    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}