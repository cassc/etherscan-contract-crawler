/**
 *Glitch was here
 */

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.19;
/*
            ____ _ _ _       _     _          _
           / ___| (_) |_ ___| |__ ( )___     / \   _ __ _ __ ___  _   _
          | |  _| | | __/ __| '_ \|// __|   / _ \ | '__| '_ ` _ \| | | |
          | |_| | | | || (__| | | | \__ \  / ___ \| |  | | | | | | |_| |
           \____|_|_|\__\___|_| |_| |___/ /_/   \_\_|  |_| |_| |_|\__, |
                                                                  |___/

             ____             _      _____
            |  _ \  __ _ _ __| | __ | ____|_ __   ___ _ __ __ _ _   _
            | | | |/ _` | '__| |/ / |  _| | '_ \ / _ \ '__/ _` | | | |
            | |_| | (_| | |  |   <  | |___| | | |  __/ | | (_| | |_| |
            |____/ \__,_|_|  |_|\_\ |_____|_| |_|\___|_|  \__, |\__, |
                                                          |___/ |___/
*/


import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./GlitchGeneralMintSpots.sol";
import "../interfaces/ISeaDrop.sol";
import "../util/OwnableAndAdministrable.sol";
import "../libraries/UriEncode.sol";
import "../interfaces/IDarkEnergy.sol";
import "../libraries/DarkEnergyPackedStruct.sol";

/**
 * @title  DarkEnergy
 * @author mouradif.eth
 * @notice Optimized ERC721 base for use with LazyLion's missing 80 Open
 *         Edition: DarkEnergy
 */
contract DarkEnergy is
    OwnableAndAdministrable,
    ReentrancyGuard,
    IDarkEnergy
{
    string internal constant NAME = "Glitchs Army: Dark Energy";
    string internal constant SYMBOL = "DE";
    uint256 internal constant ENERGY_PER_MINT = 100;

    using DarkEnergyPackedStruct for bytes32;
    using DarkEnergyPackedStruct for DarkEnergyPackedStruct.GameRules;
    using Strings for uint256;
    using Strings for int256;
    using UriEncode for string;

    /// @notice Missing80 Ordinals Vouchers contract
    address public ordinalsVouchers;

    /// @notice Track the allowed SeaDrop addresses.
    mapping(address => bool) internal _allowedSeaDrop;

    /// @notice Track the enumerated allowed SeaDrop addresses.
    address[] internal _enumeratedAllowedSeaDrop;

    /// @notice Mapping from address to ownership details in binary format
    ///
    /// Bits Layout:
    /// - [0]        bool   isHolder
    /// - [1..40]    int40  energyAmount
    /// - [41..56]   uint16 gamePasses
    /// - [57..72]   uint16 mintCount
    /// - [73..88]   uint16 mergeCount
    /// - [89..104]  uint16 noRiskPlayCount
    /// - [105..120] uint16 noRiskWinCount
    /// - [121..136] uint16 highStakesPlayCount
    /// - [137..152] uint16 highStakesWinCount
    /// - [153..168] uint16 highStakesLossCount
    /// - [169..200] uint32 totalEarned
    /// - [201..232] uint32 totalRugged
    /// - [233..255] 23bits unused
    mapping(address => bytes32) internal _playerData;

    /// @notice Game configuration
    ///
    /// @dev for the Odds:
    ///              Each uint16 is a number that divided by 120_000
    ///              returns the probability of an event to occur
    /// Bits layout:
    /// - [0]        bool isActive (bool)
    /// - [1..16]    uint16 oddsNoRiskEarn100
    /// - [17..32]   uint16 oddsNoRiskEarn300
    /// - [33..48]   uint16 oddsNoRiskEarn500
    /// - [49..64]   uint16 oddsHighStakesWinOrdinal
    /// - [65..80]   uint16 oddsHighStakesLose100
    /// - [81..96]   uint16 oddsHighStakesLose300
    /// - [97..112]  uint16 oddsHighStakesLose500
    /// - [113..128] uint16 oddsHighStakesLose1000
    /// - [129..144] uint16 oddsHighStakesEarn100
    /// - [145..160] uint16 oddsHighStakesEarn300
    /// - [161..176] uint16 oddsHighStakesEarn500
    /// - [177..192] uint16 oddsHighStakesEarn1000
    /// - [193..208] uint16 oddsHighStakesDoubles
    /// - [209..224] uint16 oddsHighStakesHalves
    /// - [225..240] uint16 oddsGamePassOnMint
    /// - [241..248] uint8  remainingOrdinals
    /// - [249]      bool   flagA
    /// - [250]      bool   flagB
    /// - [251]      bool   flagC
    /// - [252]      bool   flagD
    /// - [253]      bool   flagE
    /// - [254]      bool   flagF
    /// - [255]      bool   flagG

    bytes32 internal _gameRules =
        0x0026ea60096009602ee03e805dc0bb802ee03e805dc0bb80003c096012c02ee1;

    /// @notice The maximum supply
    uint64 internal _maxSupply;

    /// @notice The current circulating supply
    uint64 internal _totalSupply;

    /// @notice The current circulating energy
    int256 internal _circulatingEnergy;

    /// @notice Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) internal _operatorApprovals;

    /// @notice Mapping from token ID to approved address.
    mapping(uint256 => address) internal _tokenApprovals;

    /// @notice Track the royalty info: address to receive royalties, and
    ///         royalty basis points.
    RoyaltyInfo _royaltyInfo;

    /// @notice AllowList of marketplaces
    mapping(address => bool) internal _allowedOperators;

    /**
     * @notice Deploy the token contract with its name and symbol.
     */
    constructor(address admin, address[] memory allowedSeaDrop) {
        _setOwner(msg.sender);
        _setRole(admin, 0, true);
        // Put the length on the stack for more efficient access.
        uint256 allowedSeaDropLength = allowedSeaDrop.length;

        // Set the mapping for allowed SeaDrop contracts.
        for (uint256 i = 0; i < allowedSeaDropLength; ) {
            _allowedSeaDrop[allowedSeaDrop[i]] = true;
            unchecked {
                ++i;
            }
        }
        GlitchGeneralMintSpots _ordinalsVouchers = new GlitchGeneralMintSpots();
        ordinalsVouchers = address(_ordinalsVouchers);
        _royaltyInfo.royaltyBps = 500;
        _royaltyInfo.royaltyAddress = msg.sender;
        emit SeaDropTokenDeployed();
        emit OrdinalsVouchersDeployed(ordinalsVouchers);
    }

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     */
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Returns the total number of energy in circulation
     */
    function circulatingEnergy() external view returns (int256) {
        return _circulatingEnergy;
    }

    /**
     * @notice Returns the token collection name.
     */
    function name() external pure override returns (string memory) {
        return NAME;
    }

    /**
     * @notice Returns the token collection symbol.
     */
    function symbol() external pure override returns (string memory) {
        return SYMBOL;
    }

    /**
     * @notice Checks wether a token exists or not
     */
    function exists(uint256 tokenId) external view returns(bool) {
        address potentialOwner = address(uint160(tokenId));
        return _playerData[potentialOwner].isHolder();
    }

    /**
     * @notice Returns the expected ball size in the SVG
     */
    function _getBallSize(uint32 x) internal pure returns (uint256) {
        if (x < 150) return x;
        if (x < 1000) return 150 + (x - 150) / 20;
        if (x < 4000) return 193 + (x - 1000) / 30;
        if (x < 10000) return 293 + (x - 4000) / 80;
        if (x < 300000) return 368 + (x - 10000) / 2200;
        return 500;
    }

    /**
     * @notice Returns the expected center of the ball in the SVG
     */
    function _getCenter(uint256 x) internal pure returns (uint256) {
        if (x < 150) return 1000 + x / 4;
        if (x < 1000) return 1070 - x / 5;
        if (x < 4000) return 870 - (x - 1000) / 20;
        if (x < 9500) return 720 - (x - 4000) / 25;
        return 500;
    }

    /**
     * @notice Special metadata for dead tokens
     */
    function _deadToken() internal pure returns (string memory) {
        string memory svgData = string(abi.encodePacked(
                "<svg viewBox='0 0 1e3 1e3' xmlns='http://www.w3.org/2000/svg'><style>svg{background:#000000}</style></svg>"
            ));
        return string(
            abi.encodePacked(
                'data:application/json,{"name":"Energy Waste","image_data":"',
                svgData,
                '","attributes":[{"trait_type":"energy","value":0},',
                '{"trait_type":"Game Passes","value":0},',
                '{"trait_type":"Burned","value":"yes"}',
                ']}'
            )
        ).uriEncode();
    }

    /**
     * @notice Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        address potentialOwner = address(uint160(tokenId));
        bytes32 data = _playerData[potentialOwner];
        if (!data.isHolder()) {
            return _deadToken();
        }
        int40 energy = data.getEnergy();
        uint16 gamePasses = data.getGamePasses();
        uint32 absEnergy = uint32(uint40(energy < 0 ? -energy : energy));
        uint256 size = _getBallSize(absEnergy);
        uint256 center = _getCenter(absEnergy);
        bytes6 color = energy < 0 ? bytes6(bytes("B46278")) : bytes6(bytes("5C6BBA"));
        bytes6 background = gamePasses == 0 ? bytes6(bytes("0B0B0B")) : bytes6(bytes("1B309F"));

        string memory svgData = string(abi.encodePacked(
            "<svg viewBox='0 0 1e3 1e3' xmlns='http://www.w3.org/2000/svg'><defs><radialGradient id='a' cx='500' cy='",
            center.toString(),
            "' r='",
            size.toString(),
            "' gradientUnits='userSpaceOnUse'><stop stop-color='#fff' stop-opacity='.6' offset='.17'/><stop stop-color='#fff' stop-opacity='0' offset='1'/></radialGradient></defs><circle cx='500' cy='",
            center.toString(),
            "' r='",
            size.toString(),
            "' fill='#",
            color,
            "'/><circle id='cg' cx='500' cy='",
            center.toString(),
            "' r='",
            size.toString(),
            "' fill='url(#a)' opacity='0'/><style>svg{background:#",
            background,
            "}#cg{-webkit-animation:1.5s ease-in-out infinite alternate p;animation:1.5s ease-in-out infinite alternate p}@-webkit-keyframes p{to{opacity:1}}@keyframes p{to{opacity:1}}</style></svg>"
        ));

        return string(
            abi.encodePacked(
                'data:application/json,{"name":"Dark Energy: ',
                int256(energy).toString(),
                '","image_data":"',
                svgData,
                '","attributes":[{"trait_type":"Energy","value":"',
                int256(energy).toString(),
                '"},{"trait_type":"Game Passes","value":"',
                uint256(gamePasses).toString(),
                '"}]}'
            )
        ).uriEncode();
    }

    /**
     * @notice Returns the contract URI for contract metadata.
     */
    function contractURI() external view override returns (string memory) {
        return string(
            abi.encodePacked(
                'data:application/json,{"name":"',
                NAME,
                '","totalSupply":',
                uint256(_totalSupply).toString(),
                '}'
            )
        ).uriEncode();
    }

    /**
     * @notice Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     */
    function approve(address to, uint256 tokenId) external virtual override {
        address _owner = ownerOf(tokenId);

        if (msg.sender != _owner) {
            if (!_operatorApprovals[_owner][msg.sender]) {
                revert CallerNotOwnerNorApproved();
            }
        }
        _tokenApprovals[tokenId] = to;

        emit Approval(_owner, to, tokenId);
    }

    /**
     * @notice Returns the account approved for `tokenId` token.
     */
    function getApproved(
        uint256 tokenId
    ) public view virtual override returns (address) {
        ownerOf(tokenId);
        return _tokenApprovals[tokenId];
    }

    /**
     * @notice Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom}, {safeTransferFrom} or {approve}
     * for any token owned by the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual override {
        if (!_allowedOperators[operator]) {
            revert OperatorNotAllowed();
        }
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(
        address owner,
        address operator
    ) external view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function _transferFrom(address from, address to, uint256 tokenId) internal {
        address potentialOwner = ownerOf(tokenId);

        if (potentialOwner != from) revert TransferFromIncorrectOwner();
        if (to == address(0)) revert QueryForZeroAddress();
        if (!_isApprovedOrOwner(msg.sender, tokenId))
            revert CallerNotOwnerNorApproved();
        if (from != msg.sender && !_allowedOperators[msg.sender])
            revert OperatorNotAllowed();

        bytes32 senderData = _playerData[from];
        bytes32 recipientData = _playerData[to];
        int40 senderEnergy = senderData.getEnergy();
        int40 recipientEnergy = recipientData.getEnergy();
        uint256 newTokenId = uint256(uint160(to));

        emit Transfer(from, to, tokenId);

        if (recipientData.isHolder()) {
            if (senderEnergy < 0 && recipientEnergy >= 0)
                revert NegativeEnergyToPositiveHolder();
            recipientEnergy += senderEnergy;
            uint256 realTotalGamePasses;
            unchecked {
                realTotalGamePasses = senderData.getGamePasses() +
                recipientData.getGamePasses();
            }
            uint16 gamePasses = realTotalGamePasses > 0xFFFF
            ? 0xFFFF
            : uint16(realTotalGamePasses);
            uint16 mergeCount = recipientData.getMergeCount();

            recipientData = recipientData.setHolder(true);
            recipientData = recipientData.setEnergy(recipientEnergy);
            recipientData = recipientData.setGamePasses(gamePasses);
            recipientData = recipientData.setMergeCount(mergeCount + 1);
            unchecked {
                _totalSupply--;
            }
        } else {
            recipientData = recipientData.setHoldingData(senderData);
            emit Transfer(address(0), to, newTokenId);
        }
        _playerData[from] = senderData.clearHoldingData();
        _playerData[to] = recipientData;
        _tokenApprovals[tokenId] = address(0);

        // Burn of the sent token
        emit Transfer(to, address(0), tokenId);
        emit MetadataUpdate(tokenId);
        emit MetadataUpdate(newTokenId);
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal {
        _transferFrom(from, to, tokenId);
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                revert TransferToNonERC721ReceiverImplementer();
            }
    }

    /**
     * @notice Transfers `tokenId` from `from` to `to`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override {
        _transferFrom(from, to, tokenId);
    }

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @notice Safely transfers `tokenId` token from `from` to `to`.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        _safeTransferFrom(from, to, tokenId, _data);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     */
    function _mint(
        address to,
        uint16 quantity
    ) internal virtual returns (uint256) {
        uint256 tokenId = uint256(uint160(to));
        bytes32 data = _playerData[to];
        uint16 mintCount = data.getMintCount();
        int40 energy = data.getEnergy();
        unchecked {
            energy += int40(uint40(quantity * ENERGY_PER_MINT));
            mintCount += quantity;
        }
        uint16 gamePasses = 0;
        bool isHolder = data.isHolder();
        if (quantity >= 4) {
            unchecked { gamePasses = uint16(quantity / 4); }
        }
        uint8 remainder = uint8(quantity % 4);
        for (uint256 i = 0; i < remainder;) {
            uint256 base;
            unchecked {
                base = block.prevrandao - i;
                ++i;
            }

            uint256 n = uint256(keccak256(abi.encode(base))) % 120000;
            if (n < _gameRules.getUint16(225)) {
                unchecked { gamePasses++; }
            }
        }
        if (isHolder) {
            uint16 mergeCount = data.getMergeCount();
            data = data.setMergeCount(mergeCount + 1);
        } else {
            unchecked { _totalSupply++; }
            if (_totalSupply > _maxSupply) {
                revert MaxSupplyExceeded();
            }
            emit Transfer(address(0), to, tokenId);
        }

        data = data.setHolder(true);
        data = data.setEnergy(energy);
        data = data.setGamePasses(gamePasses + data.getGamePasses());
        data = data.setMintCount(mintCount);
        _playerData[to] = data;
        unchecked { _circulatingEnergy += int256(ENERGY_PER_MINT * quantity); }
        emit GlitchMint(to, quantity * ENERGY_PER_MINT, gamePasses);
        emit MetadataUpdate(tokenId);
        return isHolder ? 0 : tokenId;
    }

    function _noRiskEarn(int40 amount, bytes32 data) internal {
        _circulatingEnergy += amount;
        uint256 tokenId = uint256(uint160(msg.sender));
        int40 energy = data.getEnergy();
        uint16 winCount = data.getNoRiskWinCount();
        uint32 totalEarned = data.getTotalEarned();
        data = data.setEnergy(energy + amount);
        data = data.setNoRiskWinCount(winCount + 1);
        data = data.setTotalEarned(totalEarned + uint32(uint40(amount)));
        _playerData[msg.sender] = data;
        emit EnergyUpdate(msg.sender, int40(amount));
        emit MetadataUpdate(tokenId);
    }

    function _winOrdinal(address winner, bytes32 data) internal {
        uint256 tokenId = uint256(uint160(winner));
        int40 energy = data.getEnergy();
        _circulatingEnergy -= energy;
        data = data.setEnergy(int40(0));
        _playerData[winner] = data;

        GlitchGeneralMintSpots vouchers = GlitchGeneralMintSpots(ordinalsVouchers);
        uint256 voucherId = vouchers.nextId();
        if (energy < 0) {
            energy = -energy;
        }
        uint256 ballSize = _getBallSize(uint32(uint40(energy)));
        vouchers.adminMint(winner, voucherId, ballSize);

        emit MetadataUpdate(tokenId);
        emit OrdinalWon(winner);
    }

    function _highStakesResult(int40 result, bytes32 data) internal {
        _circulatingEnergy += result;
        uint256 tokenId = uint256(uint160(msg.sender));
        emit EnergyUpdate(msg.sender, result);
        data = data.setEnergy(data.getEnergy() + result);
        if (result < 0) {
            result = -result;
            data = data.setHighStakesLossCount(
                data.getHighStakesLossCount() + 1
            );
            data = data.setTotalRugged(
                data.getTotalRugged() + uint32(uint40(result))
            );
        } else {
            data = data.setHighStakesWinCount(
                data.getHighStakesWinCount() + 1
            );
            data = data.setTotalEarned(
                data.getTotalEarned() + uint32(uint40(result))
            );
        }
        _playerData[msg.sender] = data;
        emit MetadataUpdate(tokenId);
    }

    function playNoRisk() external {
        if (!_gameRules.getBool(0)) {
            revert GameNotActive();
        }
        emit PlayNoRisk(msg.sender);
        bytes32 data = _playerData[msg.sender];
        uint16 gamePasses = data.getGamePasses();
        if (gamePasses == 0) {
            revert NoGamePass();
        }
        data = data.setNoRiskPlayCount(data.getNoRiskPlayCount() + 1);
        data = data.setGamePasses(gamePasses - 1);
        bytes32 rules = _gameRules;

        uint256 randomNumber = uint256(
            keccak256(abi.encode(block.prevrandao))
        ) % 120000;
        uint32 treshold = rules.getUint16(1);
        if (randomNumber < treshold) {
            _noRiskEarn(100, data);
            return;
        }
        treshold += rules.getUint16(17);
        if (randomNumber < treshold) {
            _noRiskEarn(300, data);
            return;
        }
        treshold += rules.getUint16(33);
        if (randomNumber < treshold) {
            _noRiskEarn(500, data);
            return;
        }
        _playerData[msg.sender] = data;
        emit MetadataUpdate(uint256(uint160(msg.sender)));
    }

    function playHighStakes() external {
        if (!_gameRules.getBool(0)) {
            revert GameNotActive();
        }
        emit PlayHighStakes(msg.sender);
        bytes32 data = _playerData[msg.sender];
        uint16 gamePasses = data.getGamePasses();
        if (gamePasses == 0) {
            revert NoGamePass();
        }
        data = data.setHighStakesPlayCount(data.getHighStakesPlayCount() + 1);
        data = data.setGamePasses(gamePasses - 1);
        bytes32 rules = _gameRules;
        uint256 randomNumber = uint256(
            keccak256(abi.encode(block.prevrandao))
        ) % 120000;
        uint32 treshold = uint32(rules.getUint16(49)) * uint32(rules.getUint8(241));
        if (randomNumber < treshold) {
            _gameRules = _gameRules.setUint8(241, _gameRules.getUint8(241) - 1);
            return _winOrdinal(msg.sender, data);
        }
        treshold = rules.getUint16(65);
        if (randomNumber < treshold) {
            return _highStakesResult(-100, data);
        }
        treshold += rules.getUint16(81);
        if (randomNumber < treshold) {
            return _highStakesResult(-300, data);
        }
        treshold += rules.getUint16(97);
        if (randomNumber < treshold) {
            return _highStakesResult(-500, data);
        }
        treshold += rules.getUint16(113);
        if (randomNumber < treshold) {
            return _highStakesResult(-1000, data);
        }
        treshold += rules.getUint16(129);
        if (randomNumber < treshold) {
            return _highStakesResult(100, data);
        }
        treshold += rules.getUint16(145);
        if (randomNumber < treshold) {
            return _highStakesResult(300, data);
        }
        treshold += rules.getUint16(161);
        if (randomNumber < treshold) {
            return _highStakesResult(500, data);
        }
        treshold += rules.getUint16(177);
        if (randomNumber < treshold) {
            return _highStakesResult(1000, data);
        }
        int40 energy = data.getEnergy();
        uint256 tokenId = uint256(uint160(msg.sender));
        treshold += rules.getUint16(193);
        if (randomNumber < treshold && energy != 0) {
            emit EnergyDoubled(msg.sender, energy);
            return _highStakesResult(energy, data);
        }
        treshold += rules.getUint16(209);
        if (randomNumber < treshold && energy != 0) {
            emit EnergyHalved(msg.sender, energy);
            int40 diff = energy / 2;
            return _highStakesResult(-diff, data);
        }
        _playerData[msg.sender] = data;
        emit MetadataUpdate(tokenId);
    }

    /**
     * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * `from` - Previous owner of the given token ID.
     * `to` - Target address that will receive the token.
     * `tokenId` - Token ID to be transferred.
     * `_data` - Optional data to send along with the call.
     *
     * Returns whether the call correctly returned the expected magic value.
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try
        IERC721Receiver(to).onERC721Received(
            msg.sender,
            from,
            tokenId,
            _data
        )
        returns (bytes4 retval) {
            return retval == IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            }
            assembly {
                revert(add(32, reason), mload(reason))
            }
        }
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal virtual {
        uint256 tokenId = _mint(to, uint16(quantity));
        if (tokenId == 0) {
            return;
        }

        unchecked {
            if (to.code.length != 0) {
                if (
                    !_checkContractOnERC721Received(
                    address(0),
                    to,
                    tokenId,
                    _data
                )
                ) {
                    revert TransferToNonERC721ReceiverImplementer();
                }
            }
        }
    }

    function _onlyAllowedSeaDrop(address seaDrop) internal view {
        if (!_allowedSeaDrop[seaDrop]) {
            revert OnlyAllowedSeaDrop();
        }
    }

    /**
     * @notice Mint tokens, restricted to the SeaDrop contract.
     */
    function mintSeaDrop(
        address minter,
        uint256 quantity
    ) external override nonReentrant {
        _onlyAllowedSeaDrop(msg.sender);
        _safeMint(minter, quantity, "");
    }

    /**
     * @notice Mint tokens, restricted to the SeaDrop contract.
     */
    function adminMint(
        address minter,
        int40 energy,
        uint16 gamePasses
    ) external nonReentrant {
        _checkRoleOrOwner(msg.sender, 1);
        _safeMint(minter, 0, "");
        bytes32 data = _playerData[minter];
        emit AdminMint(minter, energy - data.getEnergy(), gamePasses - data.getGamePasses());
        _circulatingEnergy += energy - data.getEnergy();
        data = data.setEnergy(energy);
        data = data.setGamePasses(gamePasses);
        _playerData[minter] = data;
    }

    /**
     * @notice Admin function to distribute rewards to the raffle winners
     */
    function raffleReward(address winner) external nonReentrant {
        _checkRoleOrOwner(msg.sender, 1);
        bytes32 data = _playerData[winner];
        if (!data.isHolder()) {
            revert AddressNotHolder();
        }
        _winOrdinal(winner, data);
    }

    /**
     * @notice Sets the address and basis points for royalties.
     *
     * @param newInfo The struct to configure royalties.
     */
    function setRoyaltyInfo(RoyaltyInfo calldata newInfo) external {
        // Ensure the sender is only the owner or contract itself.
        _checkRoleOrOwner(msg.sender, 1);

        // Revert if the new royalty address is the zero address.
        if (newInfo.royaltyAddress == address(0)) {
            revert RoyaltyAddressCannotBeZeroAddress();
        }

        // Revert if the new basis points is greater than 10_000.
        if (newInfo.royaltyBps > 10_000) {
            revert InvalidRoyaltyBasisPoints(newInfo.royaltyBps);
        }

        // Set the new royalty info.
        _royaltyInfo = newInfo;

        // Emit an event with the updated params.
        emit RoyaltyInfoUpdated(newInfo.royaltyAddress, newInfo.royaltyBps);
    }

    /**
     * @notice Returns the address that receives royalties.
     */
    function royaltyAddress() external view returns (address) {
        return _royaltyInfo.royaltyAddress;
    }

    /**
     * @notice Returns the royalty basis points out of 10_000.
     */
    function royaltyBasisPoints() external view returns (uint256) {
        return _royaltyInfo.royaltyBps;
    }

    /**
     * @notice Called with the sale price to determine how much royalty
     *         is owed and to whom.
     *
     * @return receiver      Address of who should be sent the royalty payment.
     * @return royaltyAmount The royalty payment amount for _salePrice.
     */
    function royaltyInfo(
        uint256,
        uint256 _salePrice
    ) external view returns (address receiver, uint256 royaltyAmount) {
        royaltyAmount = (_salePrice * _royaltyInfo.royaltyBps) / 10_000;
        receiver = _royaltyInfo.royaltyAddress;
    }

    /**
     * @dev Returns whether `tokenId` exists.
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        address potentialOwner = address(uint160(tokenId));
        return _playerData[potentialOwner].isHolder();
    }

    /**
     * @dev Returns whether `address` is approved for transfering `tokenId`
     */
    function _isApprovedOrOwner(
        address spender,
        uint256 tokenId
    ) internal view returns (bool) {
        address potentialOwner = ownerOf(tokenId);
        if (spender == potentialOwner) return true;
        return spender == _tokenApprovals[tokenId] ||
        _operatorApprovals[potentialOwner][spender];
    }

    /**
     * @notice Returns whether the interface is supported.
     *
     * @param interfaceId The interface id to check against.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IDarkEnergy) returns (bool) {
        return
        interfaceId == 0x01ffc9a7 || // ER165
        interfaceId == 0x80ac58cd || // ERC721
        interfaceId == 0x5b5e139f || // ERC721-Metadata
        interfaceId == 0x2a55205a || // ERC2981
        interfaceId == 0x49064906 || // ERC4906
        interfaceId == type(INonFungibleSeaDropToken).interfaceId ||
        interfaceId == type(ISeaDropTokenContractMetadata).interfaceId;
    }

    // =============================================================
    //                      Game configuration
    // =============================================================

    function _checkNoRiskOdds(
        uint16 earn1,
        uint16 earn3,
        uint16 earn5
    ) internal pure {
        uint256 total = earn1 + earn3 + earn5;
        if (total > 120000) {
            revert InvalidGameRules();
        }
    }

    function _checkHighStakesOdds(
        uint16 lose1,
        uint16 lose3,
        uint16 lose5,
        uint16 lose10,
        uint16 earn1,
        uint16 earn3,
        uint16 earn5,
        uint16 earn10,
        uint16 double,
        uint16 halve
    ) internal pure {
        uint256 total = lose1 + lose3 + lose5;
        total = total + lose10 + earn1;
        total = total + earn3 + earn5;
        total = total + earn10 + double + halve;
        if (total > 120000) {
            revert InvalidGameRules();
        }
    }

    function _checkOrdinalsRules(
        uint16 odds,
        uint8 amount
    ) internal pure {
        uint256 total = uint256(odds) * uint256(amount);
        if (total > 120000) {
            revert InvalidGameRules();
        }
    }

    function setRules(
        DarkEnergyPackedStruct.GameRules calldata config
    ) external {
        _checkRoleOrOwner(msg.sender, 1);
        _checkNoRiskOdds(
            config.oddsNoRiskEarn100,
            config.oddsNoRiskEarn300,
            config.oddsNoRiskEarn500
        );
        _checkHighStakesOdds(
            config.oddsHighStakesLose100,
            config.oddsHighStakesLose300,
            config.oddsHighStakesLose500,
            config.oddsHighStakesLose1000,
            config.oddsHighStakesEarn100,
            config.oddsHighStakesEarn300,
            config.oddsHighStakesEarn500,
            config.oddsHighStakesEarn1000,
            config.oddsHighStakesDoubles,
            config.oddsHighStakesHalves
        );
        _checkOrdinalsRules(
            config.oddsHighStakesWinOrdinal,
            config.remainingOrdinals
        );
        bytes32 newRules = config.packGameRules();
        emit GameRulesUpdated(_gameRules, newRules);
        _gameRules = newRules;
    }

    function gameRules()
    external
    view
    returns (DarkEnergyPackedStruct.GameRules memory) {
        return _gameRules.gameRules();
    }

    // =============================================================
    //                  Administrative functions
    // =============================================================

    /**
     * @notice Sets the max token supply and emits an event.
     *
     * @param operator   The operator account or contract address
     * @param status        The status (true = approved, false = denied)
     */
    function setOperatorStatus(address operator, bool status) external {
        _checkRoleOrOwner(msg.sender, 1);
        _allowedOperators[operator] = status;
    }

    /**
     * @notice Sets the max token supply and emits an event.
     *
     * @param newMaxSupply The new max supply to set.
     */
    function setMaxSupply(uint256 newMaxSupply) external {
        _checkRoleOrOwner(msg.sender, 1);
        uint64 supply = uint64(newMaxSupply);
        if (supply < _totalSupply) {
            supply = _totalSupply;
        }
        _maxSupply = supply;
        emit MaxSupplyUpdated(supply);
    }

    /**
     * @notice Internal function to update the allowed SeaDrop contracts.
     *
     * @param allowedSeaDrop The allowed SeaDrop addresses.
     */
    function _updateAllowedSeaDrop(address[] calldata allowedSeaDrop) internal {
        // Put the length on the stack for more efficient access.
        uint256 enumeratedAllowedSeaDropLength = _enumeratedAllowedSeaDrop
        .length;
        uint256 allowedSeaDropLength = allowedSeaDrop.length;

        // Reset the old mapping.
        for (uint256 i = 0; i < enumeratedAllowedSeaDropLength; ) {
            _allowedSeaDrop[_enumeratedAllowedSeaDrop[i]] = false;
            unchecked {
                ++i;
            }
        }

        // Set the new mapping for allowed SeaDrop contracts.
        for (uint256 i = 0; i < allowedSeaDropLength; ) {
            _allowedSeaDrop[allowedSeaDrop[i]] = true;
            unchecked {
                ++i;
            }
        }

        // Set the enumeration.
        _enumeratedAllowedSeaDrop = allowedSeaDrop;

        // Emit an event for the update.
        emit AllowedSeaDropUpdated(allowedSeaDrop);
    }


    function updateAllowedSeaDrop(address[] calldata allowedSeaDrop) external {
        _checkRoleOrOwner(msg.sender, 0);

        _updateAllowedSeaDrop(allowedSeaDrop);
    }

    function updateCreatorPayoutAddress(
        address seaDrop,
        address creator
    ) external {
        _checkRoleOrOwner(msg.sender, 1);
        _onlyAllowedSeaDrop(seaDrop);
        ISeaDrop(seaDrop).updateCreatorPayoutAddress(creator);
    }

    function updatePublicDrop(
        address seaDrop,
        PublicDrop memory dropData
    ) external {
        _checkRoleOrOwner(msg.sender, 0);
        _onlyAllowedSeaDrop(seaDrop);
        PublicDrop memory r = ISeaDrop(seaDrop).getPublicDrop(address(this));
        if (!_hasRole(msg.sender, 0)) {
            if (r.maxTotalMintableByWallet == 0) {
                revert AdministratorMustInitializeWithFee();
            }
            dropData.feeBps = r.feeBps;
            dropData.restrictFeeRecipients = true;
        } else {
            uint256 maxTotalMintableByWallet = r.maxTotalMintableByWallet;
            r.maxTotalMintableByWallet = maxTotalMintableByWallet > 0 ?
                uint16(maxTotalMintableByWallet) :
                1;
            r.feeBps = dropData.feeBps;
            r.restrictFeeRecipients = true;
            dropData = r;
        }
        ISeaDrop(seaDrop).updatePublicDrop(dropData);
    }

    /**
     * @notice Update the drop URI for this nft contract on SeaDrop.
     *         Only the owner or administrator can use this function.
     *
     * @param seaDropImpl The allowed SeaDrop contract.
     * @param dropURI     The new drop URI.
     */
    function updateDropURI(address seaDropImpl, string calldata dropURI)
        external
        virtual
        override
    {
        _checkRoleOrOwner(msg.sender, 0);
        // Ensure the SeaDrop is allowed.
        _onlyAllowedSeaDrop(seaDropImpl);

        // Update the drop URI.
        ISeaDrop(seaDropImpl).updateDropURI(dropURI);
    }

    /**
     * @notice Update the allow list data for this nft contract on SeaDrop.
     *         Only the owner or administrator can use this function.
     *
     * @param seaDropImpl   The allowed SeaDrop contract.
     * @param allowListData The allow list data.
     */
    function updateAllowList(
        address seaDropImpl,
        AllowListData calldata allowListData
    ) external virtual override {
        _checkRoleOrOwner(msg.sender, 0);
        // Ensure the SeaDrop is allowed.
        _onlyAllowedSeaDrop(seaDropImpl);

        // Update the allow list on SeaDrop.
        ISeaDrop(seaDropImpl).updateAllowList(allowListData);
    }

    /**
     * @notice Update the allowed fee recipient for this nft contract
     *         on SeaDrop.
     *         Only the administrator can set the allowed fee recipient.
     *
     * @param seaDrop      The allowed SeaDrop contract.
     * @param feeRecipient The new fee recipient.
     * @param status       If the fee recipient is allowed.
     */
    function updateAllowedFeeRecipient(
        address seaDrop,
        address feeRecipient,
        bool status
    ) external {
        _checkRole(msg.sender, 0);
        _onlyAllowedSeaDrop(seaDrop);
        ISeaDrop(seaDrop).updateAllowedFeeRecipient(feeRecipient, status);
    }

    /**
     * @notice Update the allowed payers for this nft contract on SeaDrop.
     *         Only the owner or administrator can use this function.
     *
     * @param seaDropImpl The allowed SeaDrop contract.
     * @param payer       The payer to update.
     * @param allowed     Whether the payer is allowed.
     */
    function updatePayer(
        address seaDropImpl,
        address payer,
        bool allowed
    ) external virtual override {
        _checkRoleOrOwner(msg.sender, 0);
        // Ensure the SeaDrop is allowed.
        _onlyAllowedSeaDrop(seaDropImpl);

        // Update the payer.
        ISeaDrop(seaDropImpl).updatePayer(payer, allowed);
    }

    /**
     * @notice Configure multiple properties at a time.
     *
     *         Note: The individual configure methods should be used
     *         to unset or reset any properties to zero, as this method
     *         will ignore zero-value properties in the config struct.
     *
     * @param config The configuration struct.
     */
    function multiConfigure(MultiConfigureStruct calldata config)
    external
    {
        _checkRoleOrOwner(msg.sender, 1);
        if (config.maxSupply > 0) {
            this.setMaxSupply(config.maxSupply);
        }
        if (
            config.publicDrop.startTime != 0 ||
            config.publicDrop.endTime != 0
        ) {
            this.updatePublicDrop(config.seaDropImpl, config.publicDrop);
        }
        if (bytes(config.dropURI).length != 0) {
            this.updateDropURI(config.seaDropImpl, config.dropURI);
        }
        if (config.allowListData.merkleRoot != bytes32(0)) {
            this.updateAllowList(config.seaDropImpl, config.allowListData);
        }
        if (config.creatorPayoutAddress != address(0)) {
            this.updateCreatorPayoutAddress(
                config.seaDropImpl,
                config.creatorPayoutAddress
            );
        }
        if (config.allowedFeeRecipients.length > 0) {
            for (uint256 i = 0; i < config.allowedFeeRecipients.length; ) {
                this.updateAllowedFeeRecipient(
                    config.seaDropImpl,
                    config.allowedFeeRecipients[i],
                    true
                );
                unchecked {
                    ++i;
                }
            }
        }
        if (config.disallowedFeeRecipients.length > 0) {
            for (uint256 i = 0; i < config.disallowedFeeRecipients.length; ) {
                this.updateAllowedFeeRecipient(
                    config.seaDropImpl,
                    config.disallowedFeeRecipients[i],
                    false
                );
                unchecked {
                    ++i;
                }
            }
        }
        if (config.allowedPayers.length > 0) {
            for (uint256 i = 0; i < config.allowedPayers.length; ) {
                this.updatePayer(
                    config.seaDropImpl,
                    config.allowedPayers[i],
                    true
                );
                unchecked {
                    ++i;
                }
            }
        }
        if (config.disallowedPayers.length > 0) {
            for (uint256 i = 0; i < config.disallowedPayers.length; ) {
                this.updatePayer(
                    config.seaDropImpl,
                    config.disallowedPayers[i],
                    false
                );
                unchecked {
                    ++i;
                }
            }
        }
    }

    // =============================================================
    //   No-op or low-op functions to ensure compatibility
    // =============================================================

    function setBaseURI(string calldata) external override {}

    function setContractURI(string calldata) external override {}


    function setProvenanceHash(bytes32) external {}

    function updateSignedMintValidationParams(
        address,
        address,
        SignedMintValidationParams memory
    ) external {}

    function updateTokenGatedDrop(
        address,
        address,
        TokenGatedDropStage calldata
    ) external {}

    function baseURI() external pure override returns (string memory) {
        return "";
    }

    // =============================================================
    //        NFT and Game stats
    // =============================================================


    function maxSupply() external view returns (uint256) {
        return _maxSupply;
    }

    function provenanceHash() external pure override returns (bytes32) {
        return bytes32(0);
    }

    function getMintStats(
        address minter
    ) external view returns (uint256, uint256, uint256) {
        bytes32 data = _playerData[minter];
        return (
        uint256(data.getMintCount()),
        _totalSupply,
        _maxSupply
        );
    }

    /**
     * @notice Returns the address that owns the given token.
     *
     * @dev The tokenId is the numeric representation of the owner's address.
     *      If that address holds a token, its last bit will be 1 and we can
     *      return the address representation of the tokenId. If not, then
     *      the token doesn't exist.
     */
    function ownerOf(
        uint256 tokenId
    ) public view virtual override returns (address) {
        address potentialOwner = address(uint160(tokenId));
        if (!_playerData[potentialOwner].isHolder()) {
            revert QueryForNonExistentToken();
        }
        return potentialOwner;
    }

    /**
     * @notice Returns the number of tokens in `owner`'s account.
     *
     * @dev An address may have at most one token. If the data of an
            address has 1 as a last bit, then that address has a token.
     */
    function balanceOf(address _owner) public view override returns (uint256) {
        if (_owner == address(0)) {
            revert QueryForZeroAddress();
        }
        bool isHolder = _playerData[_owner].isHolder();
        if (isHolder) {
            return 1;
        }
        return 0;
    }

    /**
     * @notice Returns the amount of energy in a given tokenId
     */
    function playerData(
        address player
    ) external view returns (DarkEnergyPackedStruct.PlayerData memory) {
        return _playerData[player].playerData();
    }
}