// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import {IMetaSportsToken} from "./interfaces/IMetaSportsToken.sol";
import {IMetaSportsLeague} from "./interfaces/IMetaSportsLeague.sol";
import {IDEXRouter} from "./interfaces/IDEXRouter.sol";

contract MetaSportsClub is
    Ownable,
    Pausable,
    AccessControl,
    IERC721Receiver,
    ReentrancyGuard
{
    using SafeERC20 for IMetaSportsToken;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeMath for uint256;

    enum ClubStatus {
        Open,
        Close
    }

    struct MintInfo {
        uint256 maxBuyByDay;
        uint256 mintedAmount;
        uint256 startTime;
        uint256 endTime;
    }

    struct ClubInfo {
        uint256 clubId;
        address clubOwner;
        address clubRoot;
        uint256 clubRewardRate;
        uint256 inviteRewardRate;
        uint256 userCount;
        ClubStatus status;
    }

    struct ClubUserInfo {
        uint256 clubId;
        address clubUser;
    }

    bytes32 public constant CLUB_ROLE = keccak256("CLUB_ROLE");
    bytes32 public constant NODE_ROLE = keccak256("NODE_ROLE");
    IERC721 public immutable MS_NFT;
    IMetaSportsToken public immutable MST_TOKEN;
    IERC20 public immutable USDT_TOKEN;
    IDEXRouter public immutable ROUTER_MST_USDT;
    address private burnAddress =
        address(0x000000000000000000000000000000000000dEaD);
    uint256 public MAX = ~uint256(0);
    uint256 public salePrice = 800 ether;
    uint256 public mintPrice = 400 ether;
    uint256 public rewardRate = 30;
    uint256 public rewardRootRate = 20;
    uint256 public rewardClubMaxRate = 30;
    uint256 public rewardClubMinRate = 10;
    uint256 public mintedMST = 0;
    bool public saleActive = false;
    bool public isUSDTApproveRouter;

    mapping(address => bool) public whiteList;
    mapping(uint256 => ClubInfo) clubs; // clubId => ClubInfo
    mapping(uint256 => EnumerableSet.AddressSet) clubUserList; // clubId => userlist
    mapping(address => ClubUserInfo) clubUserInfo; // user => ClubUserInfo
    mapping(uint256 => mapping(address => uint256)) rewardMap; // clubId => user => reward
    mapping(address => uint256) public addressMinted; // user => mintedAmount
    MintInfo[] public mintInfos;
    address[] public nodeContracts;
    EnumerableSet.UintSet NFTsForMint;
    EnumerableSet.UintSet clubIds;

    error ExceedsRoundSaleSupply();
    error ExceedsAddressSaleSupply();
    error InsufficientTokenSent();
    error NotInTimePeriod();
    error saleInactive();

    event CreateClub(
        uint256 indexed clubId,
        address indexed clubOwner,
        uint256 inviteRewardRate,
        uint256 clubRewardRate
    );
    event SaveClub(
        uint256 indexed clubId,
        address indexed clubOwner,
        uint256 inviteRewardRate,
        uint256 clubRewardRate
    );
    event OpenClub(uint256 indexed clubId, address indexed clubOwner);
    event CloseClub(uint256 indexed clubId, address indexed clubOwner);
    event JoinClubUser(uint256 indexed clubId, address indexed userOwner);
    event LeaveClubUser(uint256 indexed clubId, address indexed userOwner);
    event MintNFT(address indexed user, uint256 tokenId);
    event BuyMST(address indexed user, uint256 amountIn, uint256 amountOut);
    event Reward(
        address indexed user,
        address indexed club,
        address clubRoot,
        address inviter,
        uint256 clubReward,
        uint256 clubRootReward,
        uint256 inviteReward
    );
    event Minted(
        address indexed user,
        uint256 indexed clubId,
        address inviteAddress,
        address clubRoot,
        uint256 amount,
        uint256 clubReward,
        uint256 inviteReward,
        uint256 clubRootReward
    );

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor(
        address _NFT,
        address _MST,
        address _USDT,
        address _pancakeRouter,
        address _league
    ) {
        MS_NFT = IERC721(_NFT);
        MST_TOKEN = IMetaSportsToken(_MST);
        USDT_TOKEN = IERC20(_USDT);
        ROUTER_MST_USDT = IDEXRouter(_pancakeRouter);
        nodeContracts.push(_league);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function createClub(
        uint256 _clubId,
        uint256 _clubRewardRate,
        address _clubRoot
    ) external nonReentrant whenNotPaused {
        require(_clubId > 0, "Illegal clubId");
        require(_getRole(msg.sender), "User is not the league creator");
        if (!whiteList[msg.sender]) {
            require(whiteList[_clubRoot], "Club root is not in whitelist");
            require(
                clubs[clubUserInfo[_clubRoot].clubId].clubOwner == _clubRoot,
                "Club does not exist"
            );
        } else {
            require(_clubRoot == address(0), "Club root is not allowed");
        }

        require(clubs[_clubId].clubOwner == address(0), "Club have created");
        require(
            _clubRewardRate >= rewardClubMinRate &&
                _clubRewardRate <= rewardClubMaxRate,
            "Club reward rate Out of range"
        );

        clubs[_clubId].clubId = _clubId;
        clubs[_clubId].clubOwner = msg.sender;
        clubs[_clubId].clubRoot = _clubRoot;
        clubs[_clubId].inviteRewardRate = 100 - _clubRewardRate;
        clubs[_clubId].clubRewardRate = _clubRewardRate;
        clubs[_clubId].userCount = 1;
        clubs[_clubId].status = ClubStatus.Open;

        clubUserInfo[msg.sender].clubId = _clubId;
        clubUserInfo[msg.sender].clubUser = msg.sender;

        clubUserList[_clubId].add(msg.sender);

        clubIds.add(_clubId);

        _grantRole(CLUB_ROLE, msg.sender);

        emit CreateClub(
            _clubId,
            msg.sender,
            100 - _clubRewardRate,
            _clubRewardRate
        );
    }

    function saveClub(uint256 _clubId, uint256 _clubRewardRate)
        external
        whenNotPaused
        onlyRole(CLUB_ROLE)
    {
        require(_clubId > 0, "Illegal clubId");
        require(clubs[_clubId].clubId == _clubId, "Club does not exist");
        require(
            clubs[_clubId].clubOwner == msg.sender,
            "It is not owner of the club"
        );
        require(
            clubs[_clubId].status == ClubStatus.Open,
            "Club status must be close"
        );
        require(
            _clubRewardRate >= rewardClubMinRate &&
                _clubRewardRate <= rewardClubMaxRate,
            "Club reward rate Out of range"
        );

        clubs[_clubId].inviteRewardRate = 100 - _clubRewardRate;
        clubs[_clubId].clubRewardRate = _clubRewardRate;

        emit SaveClub(
            _clubId,
            msg.sender,
            100 - _clubRewardRate,
            _clubRewardRate
        );
    }

    function closeClub(uint256 _clubId)
        external
        whenNotPaused
        onlyRole(CLUB_ROLE)
    {
        require(_clubId > 0, "Illegal clubId");
        require(clubs[_clubId].clubId == _clubId, "Club does not exist");
        require(
            clubs[_clubId].clubOwner == msg.sender,
            "It is not owner of the club"
        );
        require(
            clubs[_clubId].status == ClubStatus.Open,
            "Club status must be open"
        );

        address[] memory addressArray = clubUserList[_clubId].values();
        for (uint256 i = 0; i < addressArray.length; i++) {
            delete clubUserInfo[addressArray[i]];
        }
        delete clubUserList[_clubId];
        delete clubs[_clubId];

        clubIds.remove(_clubId);
        emit CloseClub(_clubId, msg.sender);
    }

    function joinClubUser(address _address)
        external
        nonReentrant
        whenNotPaused
    {
        require(_address != address(0), "Address can not be zero");
        require(
            clubUserInfo[_address].clubUser == _address,
            "Club does not exist"
        );
        uint256 _clubId = clubUserInfo[_address].clubId;
        require(
            clubs[_clubId].clubOwner == _address,
            "Address not is owner of the club"
        );
        require(
            clubs[_clubId].clubOwner != msg.sender,
            "You is owner of the club"
        );
        require(
            clubs[_clubId].status == ClubStatus.Open,
            "Club status must be Open"
        );
        require(
            clubUserInfo[msg.sender].clubUser != msg.sender,
            "You can only join one club"
        );
        require(
            !clubUserList[_clubId].contains(msg.sender),
            "Has joined the club"
        );

        clubs[_clubId].userCount += 1;
        clubUserList[_clubId].add(msg.sender);

        clubUserInfo[msg.sender].clubId = _clubId;
        clubUserInfo[msg.sender].clubUser = msg.sender;

        emit JoinClubUser(_clubId, msg.sender);
    }

    function leaveClubUser(uint256 _clubId)
        external
        nonReentrant
        whenNotPaused
    {
        require(_clubId > 0, "Illegal clubId");
        require(clubs[_clubId].clubId == _clubId, "Club does not exist");
        require(
            clubs[_clubId].clubOwner != msg.sender,
            "You is owner of the club"
        );
        require(
            clubUserInfo[msg.sender].clubUser == msg.sender,
            "Not joined club"
        );
        require(clubUserList[_clubId].contains(msg.sender), "Not joined club");

        clubs[_clubId].userCount -= 1;
        clubUserList[_clubId].remove(msg.sender);

        delete clubUserInfo[msg.sender];

        emit LeaveClubUser(_clubId, msg.sender);
    }

    function batchSetWhitelist(address[] calldata _addresses, bool _bool)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whiteList[_addresses[i]] = _bool;
        }
    }

    function _getRole(address _user) internal view returns (bool isNodeRole) {
        for (uint256 i = 0; i < nodeContracts.length; i++) {
            isNodeRole = IMetaSportsLeague(nodeContracts[i]).hasRole(
                NODE_ROLE,
                _user
            );
            if (isNodeRole) break;
        }
    }

    function addNodeContract(address _contract) external onlyOwner {
        nodeContracts.push(_contract);
    }

    function saveRewardRate(uint256 _rewardRate) external onlyOwner {
        rewardRate = _rewardRate;
    }

    function saveClubRewardRate(uint256 _maxRate, uint256 _minRate)
        external
        onlyOwner
    {
        rewardClubMaxRate = _maxRate;
        rewardClubMinRate = _minRate;
    }

    function saveClubRootRewardRate(uint256 _rewardRootRate)
        external
        onlyOwner
    {
        rewardRootRate = _rewardRootRate;
    }

    function savePrice(uint256 _salePrice, uint256 _mintPrice)
        external
        onlyOwner
    {
        salePrice = _salePrice;
        mintPrice = _mintPrice;
    }

    function startSales() external onlyOwner {
        saleActive = true;
    }

    function stopSales() external onlyOwner {
        saleActive = false;
    }

    function addMintInfo(
        uint256 _maxBuyByDay,
        uint256 _startTime,
        uint256 _endTime
    ) public onlyOwner {
        mintInfos.push(MintInfo(_maxBuyByDay, 0, _startTime, _endTime));
    }

    function updateMintInfo(
        uint256 _index,
        uint256 _maxBuyByDay,
        uint256 _mintedAmount,
        uint256 _startTime,
        uint256 _endTime
    ) public onlyOwner {
        require(_index <= (mintInfos.length - 1), "Out of indexs of the array");
        MintInfo storage mintInfo = mintInfos[_index];
        mintInfo.maxBuyByDay = _maxBuyByDay;
        mintInfo.startTime = _startTime;
        mintInfo.endTime = _endTime;
        mintInfo.mintedAmount = _mintedAmount;
    }

    function getMintInfoIndex() public view returns (uint256 index) {
        for (uint256 i = 0; i < mintInfos.length; i++) {
            MintInfo memory info = mintInfos[i];
            if (
                block.timestamp >= info.startTime &&
                block.timestamp <= info.endTime
            ) {
                return i;
            }
        }
    }

    function getMintInfo() public view returns (MintInfo memory mintInfo) {
        return mintInfos[getMintInfoIndex()];
    }

    function mint(uint256 _amount, address _address)
        external
        nonReentrant
        whenNotPaused
        callerIsUser
    {
        if (!saleActive) revert saleInactive();
        require(_address != address(0), "Invite address can not be zero");
        if (_amount > NFTsForMint.length()) revert ExceedsRoundSaleSupply();
        require(
            clubUserInfo[_address].clubUser == _address,
            "The invitation address is not a member of the club"
        );
        ClubInfo storage clubInfo = clubs[clubUserInfo[_address].clubId];
        require(clubInfo.status == ClubStatus.Open, "Club status must be Open");
        MintInfo storage mintInfo = mintInfos[getMintInfoIndex()];
        if (
            block.timestamp < mintInfo.startTime ||
            block.timestamp > mintInfo.endTime
        ) revert NotInTimePeriod();
        if (mintInfo.mintedAmount + _amount > mintInfo.maxBuyByDay)
            revert ExceedsAddressSaleSupply();
        if (salePrice * _amount > USDT_TOKEN.balanceOf(msg.sender))
            revert InsufficientTokenSent();

        if (!isUSDTApproveRouter) {
            isUSDTApproveRouter = USDT_TOKEN.approve(
                address(ROUTER_MST_USDT),
                MAX
            );
        }

        // transfer USDT
        USDT_TOKEN.safeTransferFrom(
            msg.sender,
            address(this),
            salePrice * _amount
        );

        // mint NFT
        _mintCommon(_amount);
        mintInfo.mintedAmount += _amount;
        addressMinted[msg.sender] += _amount;

        // buy MST
        uint256 buyMST = 0;
        for (uint256 i = 0; i < _amount; i++) {
            buyMST += _buyMST(salePrice - mintPrice);
        }

        // burn MST
        MST_TOKEN.safeTransfer(burnAddress, buyMST);

        // mint mst
        uint256 reward = (buyMST * rewardRate) / 100;
        uint256 clubReward = (reward * clubInfo.clubRewardRate) / 100;
        uint256 inviteReward = reward - clubReward;
        uint256 clubRootReward;
        if (clubInfo.clubRoot != address(0)) {
            clubRootReward = (clubReward * rewardRootRate) / 100;
            clubReward = clubReward - clubRootReward;
        }
        bool mintStatus = MST_TOKEN.mint(address(this), reward);
        if (mintStatus) {
            mintedMST += reward;
            // send reward
            MST_TOKEN.safeTransfer(clubInfo.clubOwner, clubReward);
            MST_TOKEN.safeTransfer(
                clubUserInfo[_address].clubUser,
                inviteReward
            );
            if (clubRootReward > 0) {
                MST_TOKEN.safeTransfer(clubInfo.clubRoot, clubRootReward);
                uint256 _clubId = clubUserInfo[clubInfo.clubRoot].clubId;
                rewardMap[_clubId][clubInfo.clubOwner] =
                    rewardMap[_clubId][clubInfo.clubOwner] +
                    clubRootReward;
            }
            rewardMap[clubInfo.clubId][clubInfo.clubOwner] =
                rewardMap[clubInfo.clubId][clubInfo.clubOwner] +
                clubReward;
            rewardMap[clubInfo.clubId][clubUserInfo[_address].clubUser] =
                rewardMap[clubInfo.clubId][clubUserInfo[_address].clubUser] +
                inviteReward;

            emit Reward(
                msg.sender,
                clubInfo.clubOwner,
                clubInfo.clubRoot,
                clubUserInfo[_address].clubUser,
                clubReward,
                clubRootReward,
                inviteReward
            );
        }

        emit Minted(
            msg.sender,
            clubInfo.clubId,
            _address,
            clubInfo.clubRoot,
            _amount,
            clubReward,
            inviteReward,
            clubRootReward
        );
    }

    function _buyMST(uint256 _usdtAmount) internal returns (uint256 amount) {
        uint256 balanceBefore = MST_TOKEN.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = address(USDT_TOKEN);
        path[1] = address(MST_TOKEN);

        ROUTER_MST_USDT.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _usdtAmount,
            0, //swap any amount about MST
            path,
            address(this),
            block.timestamp
        );

        amount = MST_TOKEN.balanceOf(address(this)).sub(balanceBefore);
        emit BuyMST(msg.sender, _usdtAmount, amount);
    }

    function _mintCommon(uint256 _amount) internal {
        uint256[] memory tokenIds = NFTsForMint.values();
        // transfer to user
        for (uint256 i = 0; i < _amount; i++) {
            MS_NFT.safeTransferFrom(address(this), msg.sender, tokenIds[i]);
            NFTsForMint.remove(tokenIds[i]);
            emit MintNFT(msg.sender, tokenIds[i]);
        }
    }

    function getClubInfo(address _address)
        public
        view
        returns (
            uint256 clubId,
            address clubOwner,
            address clubRoot,
            uint256 clubRewardRate,
            uint256 inviteRewardRate,
            uint256 userCount
        )
    {
        require(_address != address(0), "Address can not be zero");
        uint256 _clubId = clubUserInfo[_address].clubId;
        return (
            clubs[_clubId].clubId,
            clubs[_clubId].clubOwner,
            clubs[_clubId].clubRoot,
            clubs[_clubId].clubRewardRate,
            clubs[_clubId].inviteRewardRate,
            clubs[_clubId].userCount
        );
    }

    function getClubReward(uint256 _clubId, address _address)
        public
        view
        returns (uint256 reward)
    {
        require(_clubId > 0, "Illegal clubId");
        require(clubs[_clubId].clubId == _clubId, "Club does not exist");
        require(_address != address(0), "Address can not be zero");
        return rewardMap[_clubId][_address];
    }

    function getClubUserList(uint256 _clubId)
        public
        view
        returns (address[] memory clubUsers)
    {
        return clubUserList[_clubId].values();
    }

    function getClubUserInfo(address _address)
        public
        view
        returns (uint256 clubId, address clubUser)
    {
        require(_address != address(0), "Address can not be zero");
        return (clubUserInfo[_address].clubId, clubUserInfo[_address].clubUser);
    }

    function getClubIdList() public view returns (uint256[] memory clubIdList) {
        return clubIds.values();
    }

    function withdrawBalance() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            Address.sendValue(payable(owner()), balance);
        }
    }

    function withdrawERC20(address _tokenContract)
        external
        onlyOwner
        nonReentrant
    {
        uint256 balance = IERC20(_tokenContract).balanceOf(address(this));
        if (balance > 0) {
            IERC20(_tokenContract).safeTransfer(owner(), balance);
        }
    }

    function depositNFTs(uint256[] memory _tokenIds) external onlyOwner {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            if (MS_NFT.ownerOf(_tokenIds[i]) == msg.sender) {
                MS_NFT.safeTransferFrom(
                    msg.sender,
                    address(this),
                    _tokenIds[i]
                );
                NFTsForMint.add(_tokenIds[i]);
            }
        }
    }

    function withdrawNFTs(uint256[] memory _tokenIds) external onlyOwner {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            if (NFTsForMint.contains(_tokenIds[i])) {
                MS_NFT.safeTransferFrom(
                    address(this),
                    msg.sender,
                    _tokenIds[i]
                );
                NFTsForMint.remove(_tokenIds[i]);
            }
        }
    }

    function getNFTs() public view returns (uint256[] memory tokenIds) {
        return NFTsForMint.values();
    }

    function onERC721Received(
        address _operator,
        address,
        uint256,
        bytes calldata
    ) public override nonReentrant returns (bytes4) {
        require(
            _operator == address(this),
            "received NFT from unauthenticated contract"
        );
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }
}