// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "../interfaces/ICafeStaking.sol";
import "../interfaces/ICafeAccumulator.sol";
import "../interfaces/ISudoApprovable.sol";
import "../staking/StakingCommons.sol";
import "../utils/Errors.sol";
import "../utils/Staking.sol";
import "../utils/locker/ERC721LockerUpgradeable.sol";
import "../utils/ProxyRegistry.sol";
import "../utils/UncheckedIncrement.sol";

contract SoulCafeFrens is
    Initializable,
    OwnableUpgradeable,
    ERC721Upgradeable,
    ERC721LockerUpgradeable,
    ICafeAccumulator
{
    using StringsUpgradeable for uint256;
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AutoStaking for uint256;
    using AutoStaking for StakeAction;
    using AutoStaking for StakeRequest;
    using UncheckedIncrement for uint256;

    event TokenURISet(string indexed uri);
    event PriceUpdate(uint256 indexed newPrice);
    event ContractToggle(bool indexed newState);

    uint256 public constant MAX_SUPPLY = 3333;
    uint256 private constant NEXTANT_ID = MAX_SUPPLY + 1;
    uint256 public constant T1_CAP = 501;
    uint256 public constant T2_CAP = 1001;
    uint256 public constant T3_CAP = 2001;
    uint256 public constant T0_FREN_PRICE = 3000 ether;
    uint256 public constant T1_FREN_PRICE = 3500 ether;
    uint256 public constant T2_FREN_PRICE = 4000 ether;
    uint256 public constant T3_FREN_PRICE = 4800 ether;
    uint256 private constant CAFE_TEAM_SUPPLY = 100;
    address private constant CAFE_TEAM_WALLET = 0x9cD59CD50625C7E2994BA6a2cf9b70c5a775E8db;

    /* ========== STORAGE, APPEND-ONLY ========== */
    bool public paused;
    uint256 public totalSupply;
    uint256 public cafeTeamSupply;
    uint256 internal _stakingTrack;
    ICafeStaking internal _staking;
    IERC20Upgradeable public cafeToken;
    string internal _uri;

    /* ========== INITIALIZER ========== */

    function initialize(address cafeToken_) external initializer {
        if (!cafeToken_.isContract())
            revert ContractAddressExpected(cafeToken_);

        cafeToken = IERC20Upgradeable(cafeToken_);

        __ERC721_init("Soul Cafe Frens", "SCF");
        __Ownable_init();

        ERC721LockerUpgradeable.__init();
        paused = true;
    }

    /* ========== VIEWS ========== */

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function tokensOfOwner(
        address account,
        uint256 page,
        uint256 records
    ) external view returns (uint256[] memory) {
        uint256 from = page * records;
        uint256 to = (from + records > totalSupply)
            ? totalSupply
            : from + records;
        uint256[] memory found = new uint256[](records);
        uint256 counter;

        for (uint256 t = from; t < to; t = t.inc()) {
            if (account == ownerOf(t)) {
                found[t - from] = (t > 0) ? t : NEXTANT_ID;
                counter++;
            }
        }

        uint256[] memory tokenIds = new uint256[](counter);
        uint256 ptr;
        for (uint256 t = 0; t < counter; t = t.inc()) {
            if (found[t] > 0) {
                tokenIds[ptr] = (found[t] == NEXTANT_ID) ? 0 : found[t];
                ptr++;
            }
        }

        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert UnknownToken();

        return string(abi.encodePacked(_uri, tokenId.toString(), ".json"));
    }

    function price() external view returns (uint256) {
        return _price();
    }

    function _price() internal view returns (uint256) {
        if (totalSupply < T1_CAP) {
            return T0_FREN_PRICE;
        } else if (totalSupply < T2_CAP) {
            return T1_FREN_PRICE;
        } else if (totalSupply < T3_CAP) {
            return T2_FREN_PRICE;
        } else {
            return T3_FREN_PRICE;
        }
    }

    /* ========== PUBLIC MUTATORS ========== */

    function mint(uint256 qt, bool autostake) external {
        _whenNotPaused();
        if (qt == 0) revert ZeroTokensRequested();

        if (totalSupply + qt > MAX_SUPPLY)
            revert MintingExceedsSupply(MAX_SUPPLY);

        uint256 cafeCost = qt * _price();

        ISudoApprovable(address(cafeToken)).sudoLimitedApprove(
            msg.sender,
            cafeCost
        );
        cafeToken.safeTransferFrom(msg.sender, address(this), cafeCost);

        _mintN(msg.sender, qt);

        if (autostake) {
            _autostake(msg.sender, qt);
        }
    }

    /* ========== ADMIN MUTATORS ========== */

    function configureStaking(address staking, uint256 trackId) external {
        _onlyOwner();
        _setLockerAdmin(staking);
        _staking = ICafeStaking(staking);
        _stakingTrack = trackId;
    }

    function setTokenURI(string memory uri_) external {
        _onlyOwner();
        emit TokenURISet(uri_);
        _uri = uri_;
    }

    function toggle() external {
        _onlyOwner();
        bool newState = !paused;
        emit ContractToggle(newState);
        paused = newState;
    }

    function mintReserve(uint256 qt) external {
        _onlyOwner();
        if (qt == 0) revert ZeroTokensRequested();
        if (cafeTeamSupply + qt > CAFE_TEAM_SUPPLY) revert MintingExceedsSupply(CAFE_TEAM_SUPPLY);
        if (totalSupply + qt > MAX_SUPPLY) revert MintingExceedsSupply(MAX_SUPPLY);
        cafeTeamSupply += qt;
        _mintN(CAFE_TEAM_WALLET, qt);
    }

    function pull(address destination) external returns (uint256) {
        _onlyLockerAdmin();
        address stakingContract = address(_staking);

        if (msg.sender != stakingContract) revert Unauthorized();

        uint256 cafeBalance = cafeToken.balanceOf(address(this));

        cafeToken.safeTransfer(destination, cafeBalance);

        return cafeBalance;
    }


    /* ========== INTERNALS/MODIFIERS ========== */

    function _mintN(address to, uint256 qt) internal {
        totalSupply += qt;

        for (uint256 t = 0; t < qt; t++) {
            _safeMint(to, totalSupply - qt + t);
        }
    }

    function _autostake(address account, uint256 tokenCount) internal {
        uint256[] memory ids = new uint256[](tokenCount);
        uint256 from = totalSupply - tokenCount;
        uint256 to = totalSupply;
        for (uint256 t = from; t < to; t++) {
            ids[t - from] = t;
        }

        uint256[] memory amounts;

        StakeRequest[] memory msr = StakeRequest(_stakingTrack, ids, amounts)
            .arrayify();

        StakeAction[][] memory actions = new StakeAction[][](1);
        actions[0] = StakeAction.Stake.arrayify();

        _staking.execute4(account, msr, actions);
    }

    function isApprovedForAll(address owner_, address operator)
        public
        view
        override(ERC721Upgradeable, IERC721Upgradeable)
        returns (bool)
    {
        ProxyRegistry proxyRegistry = ProxyRegistry(OS_PROXY_REGISTRY_ADDRESS);
        if (address(proxyRegistry.proxies(owner_)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner_, operator);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        to;
        if (from == address(0)) return;

        if (isLocked(tokenId)) revert StakingLockViolation(tokenId);
    }

    function _onlyOwner() internal view {
        if (msg.sender != owner()) revert Unauthorized();
    }

    function _whenNotPaused() internal view {
        if (paused) revert ContractPaused();
    }
}