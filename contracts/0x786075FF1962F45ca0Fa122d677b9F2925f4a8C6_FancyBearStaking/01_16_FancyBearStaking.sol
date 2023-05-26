// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./interfaces/ILevels.sol";
import "./Tag.sol";

contract FancyBearStaking is Ownable, AccessControlEnumerable, IERC721Receiver {
    
    struct TokenStakingData {
        address owner;
        uint256 timestamp;
    }

    enum Status {
        Off,
        Active
    }

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    IERC721Enumerable fancyBearContract;
    ILevels levelsContract;

    mapping(uint256 => TokenStakingData) public stakingDataByTokenId;
    uint256 public minimumHoneyConsumption;
    uint256 public cooldown;
    Status public status;

    event FancyBearStaked(uint256 _tokenId, address _sender);
    event FancyBearUnstaked(uint256 _tokenId, address _sender);

    constructor(
        IERC721Enumerable _fancyBearContract,
        ILevels _levelsContract,
        uint256 _minimumHoneyConsumption,
        uint256 _cooldown
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        fancyBearContract = _fancyBearContract;
        levelsContract = _levelsContract;
        minimumHoneyConsumption = _minimumHoneyConsumption;
        cooldown = _cooldown;
        status = Status.Active;
    }

    function _stakeFancyBear(address _sender, uint256 _tokenId) internal {
        require(
            status == Status.Active,
            "_stakeFancyBear: staking is not active"
        );
        require(
            levelsContract.getConsumedToken(address(fancyBearContract), _tokenId, levelsContract.honeyContract()) >=
                minimumHoneyConsumption,
            "_stakeFancyBear: fancy bear does not meet honey consumption level for this pool"
        );

        // function getConsumedToken(address _collectionAddress, uint256 _collectionTokenId, address _tokenAddress) public view returns (uint256) {

        stakingDataByTokenId[_tokenId] = TokenStakingData({
            owner: _sender,
            timestamp: 0
        });

        emit FancyBearStaked(_tokenId, _sender);
    }

    function _requestToUnstakeFancyBear(address _sender, uint256 _tokenId) internal {

        require(
            stakingDataByTokenId[_tokenId].owner == _sender,
            "_requestToUnstakeFancyBear: caller does not own fancy bear"
        );

        require(
            stakingDataByTokenId[_tokenId].timestamp == 0,
            "_requestToUnstakeFancyBear: already requested to unstake"
        );

        stakingDataByTokenId[_tokenId].timestamp = block.timestamp;

    }

    function _requestToUnstakeFancyBear(uint256[] calldata _tokenIds) external {
        uint256 i;
        for(;i < _tokenIds.length;){
            _requestToUnstakeFancyBear(msg.sender, _tokenIds[i]);
            unchecked{
                i++;
            }
        }
    }

    function _unstakeFancyBear(address _sender, uint256 _tokenId) internal {
        require(
            stakingDataByTokenId[_tokenId].owner == _sender,
            "_unstakeFancyBear: caller does not own fancy bear"
        );

        require(
            stakingDataByTokenId[_tokenId].timestamp >=
                block.timestamp - cooldown,
            "_unstakeFancyBear: cooldown not met"
        );

        fancyBearContract.safeTransferFrom(address(this), _sender, _tokenId);
        emit FancyBearUnstaked(_tokenId, _sender);
        delete stakingDataByTokenId[_tokenId];
    }

    function unstakeFancyBears(uint256[] calldata _tokenIds) public {
        for (uint256 i; i < _tokenIds.length; ) {
            _unstakeFancyBear(msg.sender, _tokenIds[i]);
            unchecked {
                i++;
            }
        }
    }

    function updateMinimumHoneyConsumption(uint256 _miniumHoneyConsumption)
        public
        onlyRole(MANAGER_ROLE)
    {
        minimumHoneyConsumption = _miniumHoneyConsumption;
    }

    function getOwnerOf(uint256 _tokenId) public view returns (address) {
        return stakingDataByTokenId[_tokenId].owner;
    }

    function getTimestampOf(uint256 _tokenId) public view returns (uint256) {
        return stakingDataByTokenId[_tokenId].timestamp;
    }

    function setStatus(Status _status) public onlyRole(MANAGER_ROLE) {
        status = _status;
    }

    function updateCooldown(uint256 _cooldown) public onlyRole(MANAGER_ROLE) {
        cooldown = _cooldown;
    }

    function onERC721Received(
        address,
        address _from,
        uint256 _tokenId,
        bytes memory
    ) external override returns (bytes4) {
        require(
            address(fancyBearContract) == msg.sender, "onERC721Received: caller must send a token from an approved contract"
        );

        _stakeFancyBear(_from, _tokenId);
        return this.onERC721Received.selector;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}