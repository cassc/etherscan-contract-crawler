// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract CSKClaimReward is AccessControl, ReentrancyGuard, EIP712 {
    address payable public adminWallet;
    address public rewardWallet;
    address private signWallet;
    bytes32 public constant DEV_ROLE = keccak256("DEV_ROLE");

    string public constant SIGNING_DOMAIN = "CODESEKAI";
    string public constant SIGNATURE_VERSION = "1";

    uint256 constant MAX_ETH_CLAIM = 25;
    uint256 constant MAXIMUM_ETH_REWARD = 0.1 ether;

    uint256 constant MAX_PHY_CLAIM = 25;

    //ESCAPE CODE REWARD
    uint256 public constant EVENT_ESCP_MYTHIC = 0.4 ether;
    uint256 public constant EVENT_ESCP_LEGEND = 0.1 ether;
    uint256 public constant EVENT_ESCP_EPIC = 0.05 ether;

    uint256 public constant EVENT_ESCP_MYTHIC_MAX = 3;
    uint256 public constant EVENT_ESCP_LEGEND_MAX = 3;
    uint256 public constant EVENT_ESCP_EPIC_MAX = 3;

    //EVENT REWARD
    uint256 public constant EVENT_GRAND_GOLD = 1 ether;
    uint256 public constant EVENT_GRAND_SILV = 0.3 ether;
    uint256 public constant EVENT_GRAND_BRONZ = 0.1 ether;
    uint256 public constant EVENT_GRAND_WOOD = 0.05 ether;
    uint256 public constant EVENT_GRAND_CARBN = 0.01 ether;

    uint256 public constant EVENT_GRAND_GOLD_MAX = 1;
    uint256 public constant EVENT_GRAND_SILV_MAX = 1;
    uint256 public constant EVENT_GRAND_BRONZ_MAX = 1;
    uint256 public constant EVENT_GRAND_WOOD_MAX = 2;
    uint256 public constant EVENT_GRAND_CARBN_MAX = 5;

    enum RewardType {
        ETH,
        PHYS,
        ITEM,
        NFT,
        EVENT_ESCP_MYTHIC,
        EVENT_ESCP_LEGEND,
        EVENT_ESCP_EPIC,
        EVENT_GRAND_GOLD,
        EVENT_GRAND_SILV,
        EVENT_GRAND_BRONZ,
        EVENT_GRAND_WOOD,
        EVENT_GRAND_CARBN
    }

    struct ClaimInfo {
        address claimer;
        bytes32 itemId;
        uint256 shipPrice;
        uint256 timestamp;
        uint256 ids;
        uint256 nonce;
        bytes signature;
    }

    struct rewardInfo {
        address rewardAddr;
        uint256 tokenId;
    }

    mapping(uint256 => bool) public nftClaimStat;
    mapping(uint256 => rewardInfo) public nftRewardAddress;
    mapping(address => uint256) public nonceTracker;

    // RewardType => counter
    mapping(RewardType => uint256) public rewardClaimTracker;

    constructor(
        address payable _adminWallet,
        address _rewardWallet,
        address _signingWallet
    ) EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEV_ROLE, msg.sender);

        require(_adminWallet != address(0), "Invalid: admintWallet");
        require(_rewardWallet != address(0), "Invalid: _rewardWallet");
        require(_signingWallet != address(0), "Invalid: _signingWallet");
        adminWallet = _adminWallet;
        rewardWallet = _rewardWallet;
        signWallet = _signingWallet;
    }

    event ClaimReward(address claimer, bytes32 itemId, uint256 ids, RewardType);
    event ClearRewardAddress(uint256[] indexed ids);

    event SetAdminWallet(
        address indexed prevAdminWallet,
        address indexed adminWallet
    );
    event SetSignWallet(
        address indexed prevSignWallet,
        address indexed signWallet
    );
    event SetRewardWallet(
        address indexed prevRewardWallet,
        address indexed rewardWallet
    );
    event SetRewardAmount(
        uint256 indexed prevRewardAmount,
        uint256 indexed rewardAmount
    );
    event SetNftRewardAddress(
        uint256[] indexed Ids,
        address[] indexed rewardAddress,
        uint256[] indexed tokenIds
    );
    event SetEventRewardAmount(
        uint256[] indexed Ids,
        uint256[] indexed rewards
    );

    function _hash(ClaimInfo calldata _info) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "ClaimInfo(address claimer,bytes32 itemId,uint256 shipPrice,uint256 timestamp,uint256 ids,uint256 nonce)"
                        ),
                        _info.claimer,
                        _info.itemId,
                        _info.shipPrice,
                        _info.timestamp,
                        _info.ids,
                        _info.nonce
                    )
                )
            );
    }

    function _verify(ClaimInfo calldata _info) internal view returns (address) {
        bytes32 digest = _hash(_info);
        return ECDSA.recover(digest, _info.signature);
    }

    function clearRewardAddress(
        uint256[] calldata ids
    ) external onlyRole(DEV_ROLE) {
        require(ids.length > 0, "Must have at least 1");
        for (uint256 i = 0; i < ids.length; i++) {
            delete nftRewardAddress[ids[i]];
        }
        emit ClearRewardAddress(ids);
    }

    function claimItem(
        ClaimInfo calldata _info,
        RewardType _type
    ) external payable nonReentrant {
        //verify
        address signer = _verify(_info);
        require(_info.claimer != address(0), "Invalid address");
        bool sent;

        require(signer == signWallet, "Not signed");
        require(block.timestamp <= _info.timestamp + 13 seconds, "Time's over");
        require(_info.nonce == nonceTracker[msg.sender]++, "Nonce's incorrect");

        //check Reward Type
        if (_type == RewardType.ETH) {
            require(rewardClaimTracker[RewardType.ETH] < MAX_ETH_CLAIM);
            rewardClaimTracker[RewardType.ETH]++;

            address payable receiver = payable(msg.sender);
            (sent, ) = receiver.call{value: MAXIMUM_ETH_REWARD}("");
            require(sent, "Failed to Receiver Wallet");
        } else if (_type == RewardType.PHYS) {
            require(_info.shipPrice > 0, "Invalid ship price");
            require(rewardClaimTracker[RewardType.PHYS] < MAX_PHY_CLAIM);
            rewardClaimTracker[RewardType.PHYS]++;

            require(msg.value >= _info.shipPrice, "eth not enough");
            (sent, ) = adminWallet.call{value: _info.shipPrice}("");
            require(sent, "Failed to Admin Wallet");
        } else if (_type == RewardType.ITEM) {
            require(_info.itemId != "", "Wrong ItemId");
        } else if (_type == RewardType.NFT) {
            require(_info.ids > 0, "Invalid: ids");
            require(nftClaimStat[_info.ids] == false, "This NFT is claimed");
            address nftAddress = nftRewardAddress[_info.ids].rewardAddr;
            uint256 tokenId = nftRewardAddress[_info.ids].tokenId;
            nftClaimStat[_info.ids] = true;

            IERC721(nftAddress).transferFrom(
                rewardWallet,
                _info.claimer,
                tokenId
            );
        } else if (_type == RewardType.EVENT_ESCP_MYTHIC) {
            require(
                rewardClaimTracker[RewardType.EVENT_ESCP_MYTHIC] <
                    EVENT_ESCP_MYTHIC_MAX, "Over EVENT_ESCP_MYTHIC_MAX"
            );
            rewardClaimTracker[RewardType.EVENT_ESCP_MYTHIC]++;
            address payable receiver = payable(msg.sender);
            (sent, ) = receiver.call{value: EVENT_ESCP_MYTHIC}("");
            require(sent, "Failed to Receiver Wallet");
        } else if (_type == RewardType.EVENT_ESCP_LEGEND) {
            require(
                rewardClaimTracker[RewardType.EVENT_ESCP_LEGEND] <
                    EVENT_ESCP_LEGEND_MAX, "Over EVENT_ESCP_LEGEND_MAX"
            );
            rewardClaimTracker[RewardType.EVENT_ESCP_LEGEND]++;
            address payable receiver = payable(msg.sender);
            (sent, ) = receiver.call{value: EVENT_ESCP_LEGEND}("");
            require(sent, "Failed to Receiver Wallet");
        } else if (_type == RewardType.EVENT_ESCP_EPIC) {
            require(
                rewardClaimTracker[RewardType.EVENT_ESCP_EPIC] <
                    EVENT_ESCP_EPIC_MAX, "Over EVENT_ESCP_EPIC_MAX"
            );
            rewardClaimTracker[RewardType.EVENT_ESCP_EPIC]++;
            address payable receiver = payable(msg.sender);
            (sent, ) = receiver.call{value: EVENT_ESCP_EPIC}("");
            require(sent, "Failed to Receiver Wallet");
        } else if (_type == RewardType.EVENT_GRAND_GOLD) {
            require(
                rewardClaimTracker[RewardType.EVENT_GRAND_GOLD] <
                    EVENT_GRAND_GOLD_MAX, "Over EVENT_GRAND_GOLD_MAX"
            );
            rewardClaimTracker[RewardType.EVENT_GRAND_GOLD]++;
            address payable receiver = payable(msg.sender);
            (sent, ) = receiver.call{value: EVENT_GRAND_GOLD}("");
            require(sent, "Failed to Receiver Wallet");
        } else if (_type == RewardType.EVENT_GRAND_SILV) {
            require(
                rewardClaimTracker[RewardType.EVENT_GRAND_SILV] <
                    EVENT_GRAND_SILV_MAX, "Over EVENT_GRAND_SILV_MAX"
            );
            rewardClaimTracker[RewardType.EVENT_GRAND_SILV]++;

            address payable receiver = payable(msg.sender);
            (sent, ) = receiver.call{value: EVENT_GRAND_SILV}("");
            require(sent, "Failed to Receiver Wallet");
        } else if (_type == RewardType.EVENT_GRAND_BRONZ) {
            require(
                rewardClaimTracker[RewardType.EVENT_GRAND_BRONZ] <
                    EVENT_GRAND_BRONZ_MAX, "Over EVENT_GRAND_BRONZ_MAX"
            );
            rewardClaimTracker[RewardType.EVENT_GRAND_BRONZ]++;

            address payable receiver = payable(msg.sender);
            (sent, ) = receiver.call{value: EVENT_GRAND_BRONZ}("");
            require(sent, "Failed to Receiver Wallet");
        } else if (_type == RewardType.EVENT_GRAND_WOOD) {
            require(
                rewardClaimTracker[RewardType.EVENT_GRAND_WOOD] <
                    EVENT_GRAND_WOOD_MAX, "Over EVENT_GRAND_WOOD_MAX"
            );
            rewardClaimTracker[RewardType.EVENT_GRAND_WOOD]++;

            address payable receiver = payable(msg.sender);
            (sent, ) = receiver.call{value: EVENT_GRAND_WOOD}("");
            require(sent, "Failed to Receiver Wallet");
        } else if (_type == RewardType.EVENT_GRAND_CARBN) {
            require(
                rewardClaimTracker[RewardType.EVENT_GRAND_CARBN] <
                    EVENT_GRAND_CARBN_MAX, "Over EVENT_GRAND_CARBN_MAX"
            );
            rewardClaimTracker[RewardType.EVENT_GRAND_CARBN]++;

            address payable receiver = payable(msg.sender);
            (sent, ) = receiver.call{value: EVENT_GRAND_CARBN}("");
            require(sent, "Failed to Receiver Wallet");
        } else {
            revert("Incorrect Reward Type: Out Of Range");
        }
        emit ClaimReward(_info.claimer, _info.itemId, _info.ids, _type);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(AccessControl) returns (bool) {
        return AccessControl.supportsInterface(interfaceId);
    }

    receive() external payable {}

    function withdrawEth() public payable onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 amount = address(this).balance;
        address payable receiver = payable(msg.sender);
        (bool sent, ) = receiver.call{value: amount}("");
        require(sent, "Failed withdraw");
    }

    function setAdminWallet(
        address _adminWallet
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_adminWallet != address(0), "Invalid adminWallet");
        address prevAdminWallet = adminWallet;
        adminWallet = payable(_adminWallet);
        emit SetAdminWallet(prevAdminWallet, adminWallet);
    }

    function setSignWallet(
        address _signWallet
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_signWallet != address(0), "Invalid _signWallet");
        address prevSignWallet = signWallet;
        signWallet = _signWallet;
        emit SetSignWallet(prevSignWallet, signWallet);
    }

    function setRewardWallet(
        address _rewardWallet
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_rewardWallet != address(0), "Invalid rewardWallet");
        address prevRewardWallet = rewardWallet;
        rewardWallet = _rewardWallet;
        emit SetRewardWallet(prevRewardWallet, rewardWallet);
    }

    function setNftRewardAddress(
        address[] calldata _rewardAddress,
        uint256[] calldata _ids,
        uint256[] calldata tokenIds
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_rewardAddress.length > 0, "must have an address");
        require(
            _ids.length == _rewardAddress.length &&
                _ids.length == tokenIds.length,
            "must be equal length"
        );
        for (uint256 i = 0; i < _rewardAddress.length; i++) {
            require(_rewardAddress[i] != address(0), "Invalid _rewardAddress");
            require(_ids[i] > 0, "Invalid ids");
            nftRewardAddress[_ids[i]].rewardAddr = _rewardAddress[i];
            nftRewardAddress[_ids[i]].tokenId = tokenIds[i];
        }
        emit SetNftRewardAddress(_ids, _rewardAddress, tokenIds);
    }

    function grantRole(
        bytes32 role,
        address account
    ) public virtual override(AccessControl) onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(role, account);
    }

    function renounceRole(
        bytes32 role,
        address account
    ) public virtual override(AccessControl) {
        require(
            !(hasRole(DEFAULT_ADMIN_ROLE, account)),
            "AccessControl: cannot renounce the DEFAULT_ADMIN_ROLE account"
        );
        super.renounceRole(role, account);
    }

    function revokeRole(
        bytes32 role,
        address account
    ) public virtual override(AccessControl) onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(role, account);
    }
}